#!/usr/bin/env bash
# Fund-trading RL pipeline (T-Capital funds, 0% commission): data -> dataset -> offline PPO -> locked test ->
# live continual training on new bars and live order books -> results committed (robust-mm-rl, not pushed).
#
# The whole run holds a sleep and idle inhibitor (systemd-inhibit + GNOME); nothing in the system settings
# changes. Each step is resumable; the dashboard (http://127.0.0.1:8611/#rl) shows every step.
#
# Usage: scripts/funds-run.sh [--offline-hours N] [--live-until "YYYY-MM-DD HH:MM"] [--skip-refresh]
#                             [--offline-until "YYYY-MM-DD HH:MM"] [--rounds N]
#                             [--resume-from RUN_DIR/policy.pt --dataset-id ID]
#   --offline-hours  PPO time budget on history (default 6), used when --offline-until is not given
#   --offline-until  stop time of the offline training, MSK (overrides --offline-hours)
#   --rounds         training rounds with different seeds sharing that time (default 3); the best by
#                    validation is tested once and fine-tuned live
#   --live-until     end of the live phase, MSK (default: next weekday 19:00, after the main session)
#   --skip-refresh   use the data already in I2
#   --resume-from    continue the offline training from these weights (skips refresh and dataset build)
#   --dataset-id     dataset to train on (default: newest fund dataset)
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
    exec systemd-inhibit --what=sleep:idle:handle-power-key --who="Tradeq funds RL run" \
      --why="Training the fund-trading RL agent" --mode=block "${inner[@]}"
  fi
  echo "warning: systemd-inhibit not found; the PC may sleep" >&2
  exec "${inner[@]}"
fi

offline_hours=6; offline_until=""; rounds=3; live_until=""; skip_refresh=0; resume_from=""; dataset_id=""
stop_requested=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --offline-hours) offline_hours="${2:?}"; shift ;;
    --live-until) live_until="${2:?}"; shift ;;
    --skip-refresh) skip_refresh=1 ;;
    --offline-until) offline_until="${2:?}"; shift ;;
    --rounds) rounds="${2:?}"; shift ;;
    --resume-from) resume_from="${2:?}"; skip_refresh=1; shift ;;
    --dataset-id) dataset_id="${2:?}"; shift ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
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
  if [[ $current -eq 3 || $current -eq 4 ]]; then
    stop_requested=1; echo "stop requested: training ends, evaluates and records"; return
  fi
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

if [[ -n "$resume_from" ]]; then
  step 2 "resume: dataset kept (${dataset_id:-newest})"
else
  step 2 "rl funds-build"
  (cd "$ROOT/robust-mm-rl" && .venv/bin/rl funds-build | tail -n 12)
fi

# Offline training in rounds with different seeds (round 1 continues from --resume-from when given). Each round
# gets an equal share of the time left until the stop time and is scored on validation only; the round with the
# best validation return goes once to the locked test and is the starting point of the live phase.
if [[ -z "$offline_until" ]]; then
  offline_until="$(python3 -c "
import datetime as d, zoneinfo
print((d.datetime.now(zoneinfo.ZoneInfo('Europe/Moscow')) + d.timedelta(hours=float('$offline_hours'))).strftime('%Y-%m-%d %H:%M'))")"
fi
SEEDS=(7 11 13 17 19); best=""; best_val=""
for r in $(seq 1 "$rounds"); do
  round_end="$(python3 -c "
import datetime as d, zoneinfo
msk = zoneinfo.ZoneInfo('Europe/Moscow'); now = d.datetime.now(msk)
end = d.datetime.strptime('$offline_until', '%Y-%m-%d %H:%M').replace(tzinfo=msk)
print((now + (end - now) / ($rounds - $r + 1)).strftime('%Y-%m-%d %H:%M'))")"
  step 3 "round $r/$rounds (seed ${SEEDS[$((r-1))]}): PPO until $round_end MSK, then validation; stop $offline_until"
  args=(--until "$round_end" --seed "${SEEDS[$((r-1))]}" --no-test --tag "funds-ppo-r$r")
  if [[ -n "$dataset_id" ]]; then args+=(--dataset-id "$dataset_id"); fi
  if [[ $r -eq 1 && -n "$resume_from" ]]; then args+=(--init-from "$resume_from"); fi
  out="$(cd "$ROOT/robust-mm-rl" && .venv/bin/rl funds-train "${args[@]}")"
  echo "$out" | tail -n 25
  read -r run_dir val < <(echo "$out" | python3 -c "
import json,sys; d=json.load(sys.stdin); print(d['run_dir'], d.get('val_total_return_pct', -1e9))")
  echo "round $r: validation return ${val}% ($run_dir)"
  if [[ -z "$best" ]] || python3 -c "import sys; sys.exit(0 if $val > $best_val else 1)"; then
    best="$run_dir"; best_val="$val"
  fi
  if [[ -n "$stop_requested" ]]; then break; fi
done
step 3 "locked test of the best round by validation ($(basename "$best"), ${best_val}%)"
(cd "$ROOT/robust-mm-rl" && .venv/bin/rl funds-eval "$best/policy.pt" --split test | tail -n 30)
weights="$best/policy.pt"

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
