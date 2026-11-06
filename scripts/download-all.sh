#!/usr/bin/env bash
# Download all historical MOEX data the platform needs, then load it into the Point-in-time Store.
#
#   universe (TQBR shares + MOEX-listed T-Capital funds)
#   -> zero-fee fund list refresh (if older than 7 days)
#   -> daily candles, full history -> 1-minute candles, last 12 months
#   -> quality certificates -> I2 ingest (pit follow --once)
#
# Every step is resumable: rerun after Ctrl-C or a failure and it continues where it stopped.
# Needs TBANK_TOKEN in market-tape-recorder/.env (read-only market data; no trading).
#
# Usage: scripts/download-all.sh [--smoke] [--only daily|minute] [--since YYYY-MM-DD]
#   --smoke   SBER, GAZP, TMOS only: 1 year of daily and the last 3 days of 1-minute candles
#   --only    run only the daily or only the 1-minute history
#   --since   first date for the selected history (default: full daily, 12 months of 1-minute)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
I1="$ROOT/market-tape-recorder"
I2="$ROOT/point-in-time-store"
TAPE="$I1/.venv/bin/tape"
PIT="$I2/.venv/bin/pit"

smoke=0; only=""; since=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --smoke) smoke=1 ;;
    --only) only="${2:?--only needs daily or minute}"; shift ;;
    --since) since="${2:?--since needs a date}"; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 64 ;;
  esac
  shift
done
[[ -z "$only" || "$only" == daily || "$only" == minute ]] || { echo "--only daily|minute" >&2; exit 64; }
[[ -x "$TAPE" ]] || { echo "run 'make setup' in market-tape-recorder first" >&2; exit 1; }
[[ -x "$PIT" ]] || { echo "run 'make setup' in point-in-time-store first" >&2; exit 1; }

trap 'echo; echo "stopped: rerun the same command to resume"; exit 130' INT TERM

step() { printf '\n== %s (%s)\n' "$1" "$(date '+%H:%M:%S')"; }
days_ago() { date -v-"$1"d +%F 2>/dev/null || date -d "$1 days ago" +%F; }

# The recorder reads .env from the working directory only, so every tape command runs in I1.
cd "$I1"
data_dir="$(grep -E '^TRADEQ_DATA_DIR=' .env | cut -d= -f2-)"
ref="$data_dir/market-tape-recorder/reference"

step "zero-fee fund list"
if [[ -z "$(find "$ref/tbank_zero_fee_funds.json" -mtime -7 2>/dev/null)" ]]; then
  "$TAPE" instruments-ref
else
  echo "fresh (less than 7 days old), kept"
fi

step "universe"
"$TAPE" universe

args=()
if [[ $smoke -eq 1 ]]; then args+=(--symbols SBER,GAZP,TMOS); fi

if [[ -z "$only" || "$only" == daily ]]; then
  step "daily candles"
  rc=0
  d_since="$since"
  if [[ $smoke -eq 1 && -z "$d_since" ]]; then d_since="$(days_ago 365)"; fi
  "$TAPE" download --interval day ${d_since:+--since "$d_since"} ${args[@]+"${args[@]}"} || rc=$?
  [[ $rc -eq 0 || $rc -eq 2 ]] || exit "$rc"  # 2 = some chunks failed; rerun retries them
fi

if [[ -z "$only" || "$only" == minute ]]; then
  step "1-minute candles"
  m_since="$since"
  if [[ $smoke -eq 1 && -z "$m_since" ]]; then m_since="$(days_ago 3)"; fi
  rc=0
  "$TAPE" download --interval minute ${m_since:+--since "$m_since"} ${args[@]+"${args[@]}"} || rc=$?
  [[ $rc -eq 0 || $rc -eq 2 ]] || exit "$rc"
fi

step "quality certificates"
"$TAPE" certify --venue moex-tbank
"$TAPE" certify --venue moex-iss

step "I2 ingest"
cd "$I2"
"$PIT" follow --once

step "macro vintages and instrument rules (CBR key rate, CPI; I1 lot/tick)"
"$PIT" fetch-macro --instruments "$ref/moex_instruments_i2.jsonl"

step "done"
echo "download reports: $data_dir/market-tape-recorder/download/reports/"
