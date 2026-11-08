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
| 2026-11-08 | Workspace moved to a Linux host (Ubuntu 26.04, RX 580); repos re-cloned, uv and Python 3.13 installed | User's training machine |
| 2026-11-08 | S4 lives in a new repo `robust-mm-rl` (spec name); GitHub repo created private | User choice; public creation is blocked for the tool |
| 2026-11-08 | S4 trains on the CPU; torch from the CPU index | RX 580 is gfx803: no official ROCm/PyTorch; OpenCL hung the GPU; Vulkan has no training stack; PPO step 10 ms on CPU |
| 2026-11-08 | S4 datasets: I2 queries at one cutoff with fingerprints, chronological 70/15/15 splits, 2-day embargo, locked test split | Reproducibility, no look-ahead, every test look is a trial |
| 2026-11-08 | Data scope: candles again plus continuous T-Bank book recording for liquid names | Books cannot be downloaded; execution RL needs them |
| 2026-11-08 | RL dashboard lives in the research terminal's RL page, fed by S4 `rl serve` (rl/v1 revision 2, `status`) | User wants one web app with metrics, state, results and progress |
| 2026-11-08 | RL results are kept in git (`robust-mm-rl/results/`, append-only) plus full artifacts in the data root | User: "do not lose them" |
| 2026-11-08 | I1 writes download progress files (contract 6.2) | The dashboard needs progress and ETA |
| 2026-11-08 | No GPU for the night RL run: profiling shows 57% env stepping, 22% small-batch forward, 21% update (GPU at most 1.27x); GPU +~70 W | Measured |
| 2026-11-08 | GPU route for Tradeq = llama.cpp on Vulkan for LLM inference (S7, S8), no ROCm, no Docker | Same ggml Vulkan path that works on this card in another project |
| 2026-11-08 | RL stays on the CPU; the ROCm 5.4 gfx803 container (torch 1.13) is kept for large-network work | Measured: GPU 0.68x on the PPO loop, 7.2x on a large update |
| 2026-11-08 | GPU compute removed (container image, OpenCL packages); guide saved to ~/Downloads/tradeq-rx580-gpu-guide.md | User: not needed for now |
| 2026-11-08 | RL trades only T-Capital funds (0% commission on T-Invest) | User: commission-free, the fund fee is acceptable |
| 2026-11-08 | Inputs chosen from literature first (robust-mm-rl docs/research-funds-features.md), then coded | User asked for research before code |
| 2026-11-08 | Order book: live recording only, agent sees book features with an availability flag; hourly live fine-tuning | No free book history |
| 2026-11-08 | Portfolio action with a trade intensity and a 2% band | Without it the policy churned (12.7 turnover/day); with it 0.08/day |
| 2026-11-08 | The assistant does not register accounts or obtain tokens for the user | Account creation and credential handling stay with the user |
| 2026-11-08 | Datasets screen in the terminal built only from service data (I2 registry + stored stats, S4 dataset files); joins inferred from single-column keys of non-empty datasets | User asked for a schema with connections imported from real data, no hardcoding |
| 2026-11-08 | Funds offline training in seed rounds up to a stop time (06:15); best by validation tested once, then live | User asked for a custom stop time and reruns |
