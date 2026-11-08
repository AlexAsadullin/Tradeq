#!/usr/bin/env bash
# Fund-trading RL pipeline (T-Capital funds, 0% commission): data -> dataset -> offline PPO -> locked test ->
# live continual training on new bars and live order books -> results committed (robust-mm-rl, not pushed).
#
# The whole run holds a sleep and idle inhibitor (systemd-inhibit + GNOME); nothing in the system settings
# changes. Each step is resumable; the dashboard (http://127.0.0.1:8611/#rl) shows every step.
#
# Usage: scripts/funds-run.sh [--offline-hours N] [--live-until "YYYY-MM-DD HH:MM"] [--skip-refresh]
#   --offline-hours  PPO time budget on history (default 6)
#   --live-until     end of the live phase, MSK (default: next weekday 19:00, after the main session)
#   --skip-refresh   use the data already in I2
# Run it in the background: scripts/stack.sh start funds -- --offline-hours 6
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"

if [[ -z "${TRADEQ_INHIBITED:-}" ]]; then
  export TRADEQ_INHIBITED=1
  inner=("$0" "$@")
  if command -v gnome-session-inhibit >/dev/null && [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    inner=(gnome-session-inhibit --inhibit suspend:idle --reason "Tradeq funds RL run" "${inner[@]}")
  fi
  if command -v systemd-inhibit >/dev/null; then
    exec systemd-inhibit --what=sleep:idle --who="Tradeq funds RL run" \
      --why="Training the fund-trading RL agent" --mode=block "${inner[@]}"
  fi
  echo "warning: systemd-inhibit not found; the PC may sleep" >&2
  exec "${inner[@]}"
fi

offline_hours=6; live_until=""; skip_refresh=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline-hours) offline_hours="${2:?}"; shift ;;
    --live-until) live_until="${2:?}"; shift ;;
    --skip-refresh) skip_refresh=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
  shift
done
if [[ -z "$live_until" ]]; then
  live_until="$(python3 -c "
import datetime as d
t = d.date.today() + d.timedelta(days=1)
while t.weekday() >= 5: t += d.timedelta(days=1)
print(f'{t} 19:00')")"
fi

DATA="$ROOT/data"
STATE="$DATA/robust-mm-rl/pipeline.json"
mkdir -p "$(dirname "$STATE")"
# the plan lets the dashboard compute the end of the whole run (offline budget + live phase)
python3 -c "
import json, datetime as d, zoneinfo
end = d.datetime.strptime('$live_until', '%Y-%m-%d %H:%M').replace(tzinfo=zoneinfo.ZoneInfo('Europe/Moscow'))
json.dump({'pipeline': 'funds', 'offline_hours': float('$offline_hours'), 'live_until': end.isoformat()},
          open('$DATA/robust-mm-rl/pipeline-plan.json', 'w'), indent=1)"
STEPS=("data refresh" "services" "dataset" "offline training + test" "live training" "results")
started="$(date -u +%FT%TZ)"
mark() {
  python3 - "$STATE" "$1" "$2" "${3:-}" "$started" "${STEPS[@]}" <<'EOF'
import json, sys, datetime, os
path, i, state, detail, started, *steps = sys.argv[1:]
doc = {"schema_version": "1", "pipeline": "funds", "started_at": started, "steps": steps, "step_index": int(i),
       "step": steps[int(i)] if int(i) < len(steps) else "done", "state": state, "detail": detail,
       "updated_at": datetime.datetime.now(datetime.UTC).isoformat().replace("+00:00", "Z")}
open(path + ".tmp", "w").write(json.dumps(doc, indent=1)); os.replace(path + ".tmp", path)
EOF
}
current=0
on_error() { mark "$current" failed "failed at step ${STEPS[$current]} (see the funds log)"; }
on_stop() {
  if [[ $current -eq 3 || $current -eq 4 ]]; then echo "stop requested: training ends, evaluates and records"; return; fi
  mark "$current" failed "stopped at step ${STEPS[$current]}"; exit 130
}
trap on_error ERR
trap on_stop INT TERM
step() { current="$1"; mark "$1" running "${2:-}"; printf '\n== %s (%s)\n' "${STEPS[$1]}" "$(date '+%F %H:%M:%S')"; }

step 0 "fund bars, calendar, macro, live tape -> I2"
if [[ $skip_refresh -eq 0 ]]; then
  SYMS="$(python3 -c "
import json; u=json.load(open('$DATA/market-tape-recorder/reference/universe_moex.json'))
print(','.join(sorted(i['symbol'] for i in u['instruments'] if i['kind']=='fund' and i['class_code']=='TQBR')))")"
  (cd "$ROOT/market-tape-recorder" && .venv/bin/tape download --interval minute --symbols "$SYMS" \
     --since "$(date -d '10 days ago' +%F)" || [[ $? -eq 2 ]])
  (cd "$ROOT/market-tape-recorder" && .venv/bin/tape calendar)
  if ! { [[ -f "$DATA/run/follow.pid" ]] && kill -0 "$(cat "$DATA/run/follow.pid")" 2>/dev/null; }; then
    (cd "$ROOT/point-in-time-store" && .venv/bin/pit follow --once)  # the follow job is not running
  fi
  (cd "$ROOT/point-in-time-store" && .venv/bin/pit fetch-macro \
     --calendar "$DATA/market-tape-recorder/reference/calendar_i2.jsonl")
else
  echo "skipped"
fi

step 1 "I2, S4, terminal, recorder, I2 follower"
"$ROOT/scripts/stack.sh" start i2 s4 terminal record follow
for _ in $(seq 1 60); do curl -sf -m 2 http://127.0.0.1:8603/healthz >/dev/null && break; sleep 2; done

step 2 "rl funds-build"
(cd "$ROOT/robust-mm-rl" && .venv/bin/rl funds-build | tail -n 12)

step 3 "PPO ${offline_hours} h on history, then validation and the locked test"
out="$(cd "$ROOT/robust-mm-rl" && .venv/bin/rl funds-train --hours "$offline_hours")"
echo "$out" | tail -n 40
weights="$(echo "$out" | python3 -c "import json,sys; print(json.load(sys.stdin)['run_dir'])")/policy.pt"

step 4 "fine-tune every hour on new bars and live books until $live_until MSK"
(cd "$ROOT/robust-mm-rl" && .venv/bin/rl funds-live --until "$live_until" --init-from "$weights" | tail -n 5)

step 5 "commit robust-mm-rl/results"
git -C "$ROOT/robust-mm-rl" add results
if ! git -C "$ROOT/robust-mm-rl" diff --cached --quiet; then
  git -C "$ROOT/robust-mm-rl" commit -q -m "Add fund-trading RL results $(date +%F)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
  echo "results committed: $(git -C "$ROOT/robust-mm-rl" log --oneline -1)"
fi
current=6
mark 6 done "finished $(date '+%F %H:%M')"
echo "funds run done; dashboard: http://127.0.0.1:8611/#rl"
