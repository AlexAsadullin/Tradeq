# Open items

As of 2026-11-08.

## User actions

- Make `research-terminal` and `robust-mm-rl` public on GitHub (both private; the deck and README link to them).
- Decide the GPU route for the RX 580 (robust-mm-rl `docs/gpu.md`): CPU only, or a community gfx803 ROCm
  container (PyTorch 2.6, needs the `docker` group).
- Decide whether I2 gets a market knowledge time for backfilled history (for example `ts_close` plus a lag),
  so the slice at a historical T is non-empty and `rl/v1` rule 1 can hold in training.
- Share the Slides artifact from its Share menu if judges need the editable version (the PDF is public).
- Provide a MOEX AlgoPack token when available (adapter exists, untested live).

## Next engineering steps (deck slide 10)

1. Record T-Bank order books for several weeks in all session phases; rerun I6 and calibrate S3 on it (the
   real fill-rate sample is about 50 orders from 2 minutes).
2. Buy or obtain the full MOEX order log to reconstruct the queue for calibration.
3. Probe public LLMs for memory on Russian news about MOEX shares (S7 so far is synthetic only).
4. S4 (`robust-mm-rl` v0.1 exists: datasets, bar-level env, TWAP, PPO smoke): log runs to S6 as trials, add
   Almgren-Chriss, SAC and a vectorised env, then an order-book env on recorded books with I6 fills and S3
   domain randomisation over κ and latency; compare with TWAP and GLFT; serve `rl/v1`.
5. Open the incubator to external agents with a capital limit after admission.

## Known gaps

- Most module results are synthetic; reports of I1, S3 and I6 were rerun for MOEX, others still cite
  synthetic panels (S1 to be pointed at MOEX stocks via I2).
- S3 calibration recovers κ = 0 vs true 1 on one short tape.
- S7 TinyChrono is toy-sized; no real LLM probed. S8 has no real LLM season.
- I9: add connection-failure and order-resend scenarios.
- Not started: S2, S5, S9–S12, I3, I4, I7, I10. Root `CLAUDE.md` points here.
- The hackathon application answer texts are not stored in the repo.

## Fund agent (2026-11-08)

- Running: `scripts/stack.sh start funds -- --offline-hours 6 --live-until "2026-11-09 19:00"` (started 13:39 MSK);
  results land in `robust-mm-rl/results/` and the dashboard history; push robust-mm-rl after it finishes.
- Tokens that would add data (user registers, puts them in `.env`): MOEX AlgoPack (`obstats` book history, Super
  Candles) and the full MOEX order log; neither is free.
- Next: several seeds, a deflated-Sharpe check of the test result (S6), oil prices (FORTS) as an input, fund
  holdings beyond IMOEX (bond funds).

## In progress (2026-11-08)

1. 1-minute history download (about 3 hours); then `make -C robust-mm-rl dataset`, `smoke-train`, and commit
   `robust-mm-rl/results/`.
2. I1: resolve T-Capital funds with `EtfBy` in the recorder so TMOS and TGLD books are recorded.
3. Run the background services under systemd user units so they survive a reboot.
4. GPU (RX 580) for LLM inference: `scripts/gpu-llm.sh build` and `model` must be run by the user (the
   assistant may not download and compile external code); then `verify` and `stack.sh start llm` (port 8620).
