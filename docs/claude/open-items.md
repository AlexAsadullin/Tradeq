# Open items

As of 2026-11-07.

## User actions

- Make `research-terminal` public on GitHub (it is private; the deck and README link to it).
- Share the Slides artifact from its Share menu if judges need the editable version (the PDF is public).
- Provide a MOEX AlgoPack token when available (adapter exists, untested live).

## Next engineering steps (deck slide 10)

1. Record T-Bank order books for several weeks in all session phases; rerun I6 and calibrate S3 on it (the
   real fill-rate sample is about 50 orders from 2 minutes).
2. Buy or obtain the full MOEX order log to reconstruct the queue for calibration.
3. Probe public LLMs for memory on Russian news about MOEX shares (S7 so far is synthetic only).
4. S4: train the RL execution agent (PPO and SAC, inventory penalty, domain randomisation over κ and latency)
   and compare it with TWAP and GLFT; observation from the I2 slice, actions through I9, contract `rl/v1`.
5. Open the incubator to external agents with a capital limit after admission.

## Known gaps

- Most module results are synthetic; reports of I1, S3 and I6 were rerun for MOEX, others still cite
  synthetic panels (S1 to be pointed at MOEX stocks via I2).
- S3 calibration recovers κ = 0 vs true 1 on one short tape.
- S7 TinyChrono is toy-sized; no real LLM probed. S8 has no real LLM season.
- I9: add connection-failure and order-resend scenarios.
- Not started: S2, S4, S5, S9–S12, I3, I4, I7, I10. Root `CLAUDE.md` points here.
- The hackathon application answer texts are not stored in the repo.
