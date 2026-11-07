# Data and T-Bank access

## Token rules (hard rules from the user)

- The T-Invest API token is for **market-data download only**. It is stored as `TBANK_TOKEN` in exactly two
  gitignored files: the umbrella `.env` and `market-tape-recorder/.env`. Not in the gateway or any other repo.
- Never print the token, never put it in prompts, docs, logs, commits or URLs.
- **No trading through T-Bank**, not even the T-Bank sandbox. All trading runs locally: I9 mirror sandbox and I6
  shadow exchange. The T-Bank sandbox broker adapter in I9 is disabled; I6 reproduces the documented T-Bank
  sandbox fill rules offline as a baseline.

## TLS without the Russian CA

T-Bank serves certificates from the Russian Trusted Root CA. The user does not trust that CA and refused to
install it ("Russian services might use harmful software through my trust"). I1 therefore reaches T-Bank with
**SPKI key pinning**: it checks the server's public-key hash instead of the CA chain, and nothing is added to the
system trust store. The client uses a read-only allowlist of API methods. The user is in the Netherlands; T-Bank
did not geo-block it. If a block ever appears, stop and give the user manual instructions instead of working
around it.

## Sources

- T-Bank Invest API (gRPC/REST): instruments, candles, order books, trades, streams. Protos in
  `docs/tinvest-contracts/`. Free token, limits handled by a retrying `LimitedFetcher`.
- MOEX ISS (public): reference data and daily candles, used to fill gaps.
- MOEX AlgoPack (paid): adapter written from the docs, not used, waiting for a token.
- CBR key rate and CPI vintages: `cd point-in-time-store && .venv/bin/pit fetch-macro`.
- Summary of endpoints and limits: `docs/moex-sources.md`.

## Downloaded data (full run 2026-11-06, 17:22 to 20:52 MSK)

`scripts/download-all.sh` (resumable; `--smoke` runs three instruments; works on macOS bash 3.2):

| Item | Value |
|---|---|
| Universe | 282 instruments: 254 TQBR shares + 28 T-Capital funds (TQTF) |
| Daily candles | 829,744 rows, full history (about 2,940 trading days, about 11.7 years per instrument); 765,090 from T-Invest, 63,826 from ISS |
| 1-minute candles | 28.6 million rows, last 12 months |
| Requests | 85,124 T-Invest requests for minute candles, about 290 per minute |
| Errors | 0 failed requests |
| Duration | about 3.5 hours |

Then certificates per instrument-day and ingest into I2. The universe listing uses instrument status BASE,
because the ALL listing timed out after about 30 s.

Real order-book captures: only short T-Bank samples so far (2026-11-05 evening session, SBER, GAZP, LKOH,
about 2 minutes). Real calibration of S3 and a firm fill-rate result need weeks of recording.

## Data root layout

`TRADEQ_DATA_DIR=/home/alexasadullin/PycharmProjects/Tradeq/data` on the Linux host (was
`/Users/alexasadullin/PycharmProjects/Tradeq/data` on the Mac), one folder per repo plus `cache/`. About 3.6 GB
on the Mac on 2026-11-07. Never committed. The Mac data was not copied; the Linux host downloads it again with
`scripts/download-all.sh` once `TBANK_TOKEN` is in `market-tape-recorder/.env` (the user adds it by hand).
S4 datasets: `data/robust-mm-rl/datasets/<id>/` (layout in robust-mm-rl `docs/datasets.md`).

## Bitemporal model (I2)

Every row has valid time (what moment the fact describes) and knowledge time (when it became knowable).
Bulk-downloaded history has knowledge time = download time (I1 `ts_local`), so a slice or query at a
historical T returns none of it; S4 extracts at the build cutoff and enforces bar-close causality itself. Research
queries are answered as known at a session clock T; queries that would read the future are refused and
reported to S6. Each query returns a fingerprint that reproduces it exactly (the fingerprint excludes
live-cache settings). The market slice (`GET /v1/slice?known_at=`) returns every metric per instrument as of T,
with a streaming variant for the terminal; the live edge is cached (p95 20 ms).

## Linux host runs (2026-11-08)

- Token: in the umbrella `.env` and copied to `market-tape-recorder/.env` (both mode 600, gitignored).
- `scripts/download-all.sh` started 01:19 MSK: daily done (829,995 rows, 282 instruments); 1-minute running
  (84,860 chunks, about 3 hours). Logs in `data/logs/`. Live progress in
  `data/market-tape-recorder/download/progress-<1d|1m>.json`.
- Continuous T-Bank recording of 22 liquid shares (books 20 levels, trades, candles, status) since 01:20 MSK with
  `data/market-tape-recorder/config/record-liquid.yaml`; the funds TMOS and TGLD fail resolution (`ShareBy` 404).
- Long-running background processes on the host: `tape record`, `pit serve` (8603), `rl serve` (8612),
  `terminal serve` (8611). They don't survive a reboot; restart them with the `make serve` / `tape record`
  commands above.
