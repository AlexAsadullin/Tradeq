#!/usr/bin/env bash
# Run the Tradeq RL stack in the background: every job gets a log in data/logs/ and a PID file in data/run/,
# survives closing the terminal (nohup + setsid), and is stopped by its PID (Ctrl-C equivalent, so the
# downloader saves its checkpoint and the recorder closes its files).
#
# Usage (from anywhere):
#   scripts/stack.sh start [job...]    start jobs (default: services = i2 s4 terminal)
#   scripts/stack.sh stop  [job...]    stop jobs (default: all running)
#   scripts/stack.sh status            what runs, ports, download progress
#   scripts/stack.sh logs  <job>       follow a job's log
#
# Jobs:
#   i2        point-in-time store, port 8603
#   s4        RL status service (robust-mm-rl), port 8612
#   terminal  web app with the RL dashboard, port 8611  ->  http://127.0.0.1:8611/#rl
#   download  scripts/download-all.sh (resumable; extra args after --, e.g. start download -- --only minute)
#   record    T-Bank order-book recording of the liquid names (until stopped)
#   follow    I2 appends the live tape continuously (pit follow; yields to the recorder)
#   funds     scripts/funds-run.sh: fund-trading RL, offline + live phases (no sleep)
#   llm       local LLM on the GPU (llama.cpp on Vulkan, port 8620; set up with scripts/gpu-llm.sh)
#   night     scripts/night-run.sh: download -> dataset -> training until a deadline -> results (no sleep)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGS="$ROOT/data/logs"
RUN="$ROOT/data/run"
mkdir -p "$LOGS" "$RUN"
export PATH="$HOME/.local/bin:$PATH"

SERVICES=(i2 s4 terminal)
ALL=(i2 s4 terminal download record follow night funds llm)

extra_args() {  # each extra argument shell-quoted, so "2026-11-09 19:00" stays one argument
  [[ ${#EXTRA[@]} -gt 0 ]] && printf ' %q' "${EXTRA[@]}"
  return 0
}

cmd_of() {
  case "$1" in
    i2) echo "cd '$ROOT/point-in-time-store' && exec nice -n 5 .venv/bin/pit serve" ;;
    s4) echo "cd '$ROOT/robust-mm-rl' && exec .venv/bin/rl serve" ;;
    terminal) echo "cd '$ROOT/research-terminal' && exec .venv/bin/terminal serve" ;;
    download) echo "cd '$ROOT' && exec scripts/download-all.sh $(extra_args)" ;;
    follow) echo "cd '$ROOT/point-in-time-store' && exec nice -n 5 .venv/bin/pit follow" ;;
    funds) echo "cd '$ROOT' && exec scripts/funds-run.sh $(extra_args)" ;;
    llm) echo "cd '$ROOT' && exec data/cache/llama.cpp/build/bin/llama-server -m '${LLM_MODEL:-$ROOT/data/cache/models/qwen2.5-0.5b-instruct-q4_k_m.gguf}' -ngl 99 --host 127.0.0.1 --port 8620" ;;
    night) echo "cd '$ROOT' && exec scripts/night-run.sh $(extra_args)" ;;
    record) echo "cd '$ROOT/market-tape-recorder' && exec .venv/bin/tape record --venue moex-tbank --config '$ROOT/data/market-tape-recorder/config/record-liquid.yaml'" ;;
    *) echo "unknown job: $1 (one of: ${ALL[*]})" >&2; exit 64 ;;
  esac
}

port_of() { case "$1" in i2) echo 8603 ;; s4) echo 8612 ;; terminal) echo 8611 ;; llm) echo 8620 ;; *) echo "" ;; esac; }

pid_of() {
  local f="$RUN/$1.pid"
  [[ -f "$f" ]] || return 1
  local pid; pid="$(cat "$f")"
  if kill -0 "$pid" 2>/dev/null; then echo "$pid"; else rm -f "$f"; return 1; fi
}

start_job() {
  local job="$1" pid
  if pid="$(pid_of "$job")"; then echo "$job: already running (pid $pid)"; return; fi
  local log="$LOGS/$job-$(date +%Y%m%d-%H%M%S).log"
  local c; c="$(cmd_of "$job")"
  # setsid: own process group, so closing this terminal doesn't stop the job.
  nohup setsid bash -c "$c" >"$log" 2>&1 < /dev/null &
  echo $! >"$RUN/$job.pid"
  ln -sf "$(basename "$log")" "$LOGS/$job.latest.log"
  echo "$job: started (pid $!), log $log"
}

stop_job() {
  local job="$1" pid
  if ! pid="$(pid_of "$job")"; then echo "$job: not running"; return; fi
  # SIGINT to the whole process group = Ctrl-C (download-all.sh's trap and the Python children see it).
  kill -INT -- "-$pid" 2>/dev/null || kill -INT "$pid"
  for _ in $(seq 1 30); do kill -0 "$pid" 2>/dev/null || break; sleep 0.5; done
  if kill -0 "$pid" 2>/dev/null; then kill -TERM -- "-$pid" 2>/dev/null || kill -TERM "$pid"; fi
  rm -f "$RUN/$job.pid"
  echo "$job: stopped"
}

status() {
  for job in "${ALL[@]}"; do
    local pid port state
    port="$(port_of "$job")"
    if pid="$(pid_of "$job")"; then state="running (pid $pid)"; else state="stopped"; fi
    if [[ -n "$port" && "$state" != stopped ]]; then
      if curl -s -o /dev/null -m 2 "http://127.0.0.1:$port/"; then state+=", port $port answers"; else state+=", port $port not answering yet"; fi
    fi
    printf '%-9s %s\n' "$job" "$state"
  done
  for f in "$ROOT"/data/market-tape-recorder/download/progress-*.json; do
    [[ -f "$f" ]] || continue
    python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(f\"download {d['interval']}: {d['state']} {d['done_chunks']}/{d['total_chunks']} chunks ({100*d['fraction']:.1f}%), eta {d.get('eta_s')} s\")" "$f"
  done
  echo "dashboard: http://127.0.0.1:8611/#rl"
}

action="${1:-status}"; shift || true
JOBS=(); EXTRA=()
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--" ]]; then shift; EXTRA=("$@"); break; fi
  JOBS+=("$1"); shift
done

case "$action" in
  start)
    [[ ${#JOBS[@]} -gt 0 ]] || JOBS=("${SERVICES[@]}")
    for j in "${JOBS[@]}"; do cmd_of "$j" >/dev/null; start_job "$j"; done ;;
  stop)
    [[ ${#JOBS[@]} -gt 0 ]] || JOBS=("${ALL[@]}")
    for j in "${JOBS[@]}"; do stop_job "$j"; done ;;
  status) status ;;
  logs)
    [[ ${#JOBS[@]} -eq 1 ]] || { echo "usage: $0 logs <job>" >&2; exit 64; }
    exec tail -f "$LOGS/${JOBS[0]}.latest.log" ;;
  -h|--help|help) awk 'NR>1 && /^#/ {print; next} NR>1 {exit}' "$0" ;;
  *) echo "unknown action: $action" >&2; awk 'NR>1 && /^#/ {print; next} NR>1 {exit}' "$0"; exit 64 ;;
esac
