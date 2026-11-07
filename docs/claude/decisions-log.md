# Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-10 | Build Tradeq as independent repos with HTTP contracts, one per spec project | Reusable blocks, portfolio, no code coupling |
| 2026-10-29 | Pivot from crypto to MOEX; T-Bank Invest API first, AlgoPack later | User's market; T-Bank token comes first |
| 2026-10-29 | I2 is the hub; first goal is the real-time RL loop (spec 5.4) | Data collection first, nothing may starve the recorder |
| 2026-10-29 | I9 is exchange-agnostic with a broker-adapter protocol and a local mirror sandbox | Other exchanges later |
| 2026-11-05 | T-Bank token for data only; trading local only; 0.25% / 0% for T-Capital funds | User's explicit rule |
| 2026-11-05 | SPKI key pinning instead of installing the Russian Trusted Root CA | User does not trust the CA |
| 2026-11-05 | I6 reproduces T-Bank sandbox rules offline instead of mirroring orders to T-Bank | No orders may leave the machine |
| 2026-11-06 | Workflow: main session works sequentially, subagents sparingly | Usage limits |
| 2026-11-06 | Crypto replaced by MOEX as default everywhere, crypto kept as optional modules | User choice |
| 2026-11-06 | Terminal (I8): TradingView-style UI, RL panel is a placeholder on `rl/v1`; data: TQBR + T-funds, 1 year of 1-minute candles | User choices |
| 2026-11-06 | All repos pushed; research-terminal created private | Public creation was not permitted to the tool |
| 2026-11-06 | Research-ledger README clarifies 8.0% (200 noise + 1 edge) vs 100% (noise only) | Avoid a misleading headline |
| 2026-11-07 | Hackathon research docx in Russian academic structure, revised after expert critique | Organiser requirements |
| 2026-11-07 | Deck restructured to the organisers' 11-slide template | Organiser requirements |
| 2026-11-07 | Fill-rate hypothesis reported as confirmed at α = 0.05 (z ≈ 2.0) | User wants binary verdicts |
| 2026-11-07 | Deck and research build sources stored in `docs/hackathon/src`; this memory folder created | Scratch folders are temporary |
