#!/usr/bin/env bash
# Night pipeline: history download -> services -> training dataset -> PPO training until a deadline ->
# evaluation vs TWAP -> results committed to robust-mm-rl (local commit, not pushed).
#
# The whole run holds a sleep and idle inhibitor (systemd-inhibit, plus GNOME's session inhibitor when
# present), so the PC does not suspend while it works; the inhibitor ends with the run, nothing is changed in
# the system settings. Every step is resumable: rerun the same command after an interruption.
#
# Usage: scripts/night-run.sh [--until HH:MM] [--hours N] [--symbols A,B,...] [--skip-download]
#   --until          stop training at this local time (default 09:00; tomorrow if already past)
#   --hours          training budget in hours instead of --until
#   --symbols        dataset universe (default: the 24 liquid names of the book recording)
#   --skip-download  use the data already in I2
# Run it in the background with: scripts/stack.sh start night -- --until 09:00
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"

# Hold the inhibitors for the whole run: re-exec this script under them once.
if [[ -z "${TRADEQ_INHIBITED:-}" ]]; then
  export TRADEQ_INHIBITED=1
  inner=("$0" "$@")
  if command -v gnome-session-inhibit >/dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    inner=(gnome-session-inhibit --inhibit suspend:idle --reason "Tradeq night run: download and RL training" "${inner[@]}")
  fi
  if command -v systemd-inhibit >/dev/null; then
    exec systemd-inhibit --what=sleep:idle --who="Tradeq night run" \
      --why="Downloading MOEX history and training the RL agent" --mode=block "${inner[@]}"
  fi
  echo "warning: systemd-inhibit not found; the PC may sleep" >&2
  exec "${inner[@]}"
fi

until_hm="09:00"; hours=""; skip_download=0
symbols="SBER,GAZP,LKOH,GMKN,NVTK,ROSN,YDEX,TATN,SNGS,VTBR,MGNT,PLZL,CHMF,NLMK,ALRS,MTSS,AFLT,MOEX,T,OZON,X5,SBERP,TMOS,TGLD"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --until) until_hm="${2:?}"; shift ;;
    --hours) hours="${2:?}"; shift ;;
    --symbols) symbols="${2:?}"; shift ;;
    --skip-download) skip_download=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
  shift
done

DATA="$ROOT/data"
STATE="$DATA/robust-mm-rl/pipeline.json"
mkdir -p "$(dirname "$STATE")"
STEPS=("download" "services" "dataset" "training" "results")
started="$(date -u +%FT%TZ)"

mark() {  # mark <step index> <state> [detail]
  local i="$1" state="$2" detail="${3:-}"
  python3 - "$STATE" "$i" "$state" "$detail" "$started" "${STEPS[@]}" <<'EOF'
import json, sys, datetime
path, i, state, detail, started, *steps = sys.argv[1:]
doc = {"schema_version": "1", "started_at": started, "steps": steps, "step_index": int(i),
       "step": steps[int(i)] if int(i) < len(steps) else "done", "state": state, "detail": detail,
       "updated_at": datetime.datetime.now(datetime.UTC).isoformat().replace("+00:00", "Z")}
open(path + ".tmp", "w").write(json.dumps(doc, indent=1)); __import__("os").replace(path + ".tmp", path)
EOF
}
current=0
on_error() { mark "$current" failed "failed at step ${STEPS[$current]} (see the night log)"; }
on_stop() {
  # During training the trainer itself stops gracefully (evaluates and records); then the results get committed.
  if [[ $current -eq 3 ]]; then echo "stop requested: training ends, evaluates and records"; return; fi
  mark "$current" failed "stopped at step ${STEPS[$current]}"
  echo "night run stopped at ${STEPS[$current]}"
  exit 130
}
trap on_error ERR
trap on_stop INT TERM

step() { current="$1"; mark "$1" running "${2:-}"; printf '\n== %s (%s)\n' "${STEPS[$1]}" "$(date '+%H:%M:%S')"; }

# 1. History download (resumable). If the stack's own download job is running, wait for it instead.
step 0 "MOEX history into I1 and I2"
if [[ $skip_download -eq 0 ]]; then
  if [[ -f "$DATA/run/download.pid" ]] && kill -0 "$(cat "$DATA/run/download.pid")" 2>/dev/null; then
    echo "a download job is already running; waiting for it"
    while kill -0 "$(cat "$DATA/run/download.pid")" 2>/dev/null; do sleep 30; done
  fi
  "$ROOT/scripts/download-all.sh"
else
  echo "skipped"
fi

# 2. Services: I2 is needed for the dataset; S4 and the terminal show the dashboard.
step 1 "I2, S4, terminal"
"$ROOT/scripts/stack.sh" start i2 s4 terminal
for _ in $(seq 1 60); do curl -sf -m 2 http://127.0.0.1:8603/healthz >/dev/null && break; sleep 2; done
curl -sf -m 2 http://127.0.0.1:8603/healthz >/dev/null || { echo "I2 did not come up" >&2; false; }

# 3. Training dataset from I2 (resumable per symbol; a rerun keeps its cutoff).
ds_id="${TRADEQ_DATASET_ID:-moex-liquid-v1-$(date +%Y%m%d)}"
step 2 "rl build-dataset ${ds_id}"
(cd "$ROOT/robust-mm-rl" && .venv/bin/rl build-dataset --dataset-id "$ds_id" --symbols "$symbols" | tail -n 25)

# 4. Training until the deadline. SIGINT/SIGTERM end it early, and it still evaluates and records.
if [[ -z "$hours" ]]; then
  hours="$(python3 - "$until_hm" <<'EOF'
import datetime, sys
h, m = map(int, sys.argv[1].split(":"))
now = datetime.datetime.now()
end = now.replace(hour=h, minute=m, second=0, microsecond=0)
if end <= now:
    end += datetime.timedelta(days=1)
print(f"{max((end - now).total_seconds() / 3600 - 0.25, 0.25):.2f}")  # 15 minutes for evaluation
EOF
)"
fi
step 3 "PPO, ${hours} h budget"
(cd "$ROOT/robust-mm-rl" && .venv/bin/rl train --dataset-id "$ds_id" --hours "$hours" --eval-episodes 1000 | tail -n 30)

# 5. Keep the results: commit the registry in the robust-mm-rl repository (not pushed).
step 4 "commit robust-mm-rl/results"
git -C "$ROOT/robust-mm-rl" add results
if ! git -C "$ROOT/robust-mm-rl" diff --cached --quiet; then
  git -C "$ROOT/robust-mm-rl" commit -q -m "Add night training results $(date +%F)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  echo "results committed: $(git -C "$ROOT/robust-mm-rl" log --oneline -1)"
fi
current=5
mark 5 done "finished $(date '+%F %H:%M')"
echo "night run done; dashboard: http://127.0.0.1:8611/#rl"
