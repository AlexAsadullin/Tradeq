# Headline results

Each number with its source. "Synthetic" means data with a planted, known truth; it tests whether a method
behaves correctly, not the market. Re-check the source README before quoting a number; reruns can change it.

## S6 research-ledger (`research-ledger/README.md`, `docs/report.md`; synthetic, 3 years of daily Student-t returns, 300 runs per cell)

| Result | Value |
|---|---|
| Noise promoted, best of 200 noise trials, single-test PSR | 100% (98.7 to 100) |
| Same, ledger gate (DSR with N_eff) | 0.0% (0.0 to 1.3) |
| Noise promoted, 200 noise trials plus one edge trial, single-test PSR | 8.0% (5.4 to 11.6) |
| PSR noise pass at K = 10 / 50 / 200 trials | 43.7% [38.2, 49.3] / 93.0% / 100% |
| Bonferroni at K = 10 / 50 / 200 | 5.3% / 4.7% / 6.0% |
| Correlated sweeps ρ = 0.5 / 0.8 / 0.95: edge promoted, ledger DSR with N_eff | 49.0% / 56.5% / 53.5% |
| Same, DSR with nominal N | 28.5% / 8.5% / 1.0% |
| Noise promoted in sweeps, ledger | 0.5% at ρ = 0.5, 0.0% otherwise |
| N_eff for 100 variants at ρ = 0.95 | clustering 10.0, Li–Ji 19.4 |
| DSR worked example of Bailey and López de Prado (2014) | 0.9004 reproduced |

**Caveat on 8.0% vs 100%:** 8.0% is for the setup "200 noise + 1 edge"; with noise only, PSR passes noise in
100% of runs. An early hackathon answer quoted "8%"; it refers to the first setup. The deck uses 43.7% vs 0.5%
because the user found 100% vs 0% too round.

## I2 point-in-time-store (synthetic)

Naive "latest data" backtest overstates Sharpe by 0.71 (0.67 to 0.76, 500 paths); guard refused 1,484 of 1,484
leaking queries; served rows from the future 0%; a valid-time-only store returned future rows for 32.4%;
fingerprints replay 100%; 186 ms vs 1,600 ms for SQLite at 1M rows. Data certificates (I1): 600 of 600 defects
caught per type, 0 false alarms on 600 clean runs.

## I6 shadow-exchange (real T-Bank books, 2026-11-05, SBER, GAZP, LKOH, about 2 minutes)

| Metric | Queue model (shadow) | T-Bank sandbox rules | Ideal |
|---|---|---|---|
| Passive fill rate, 1-lot quotes | 0.517 [0.344, 0.686] | 0.238 [0.106, 0.451] | 0.831 |
| Taker slippage, 10 lots, bps | 1.46 | 0.12 | 0.97 |
| Market order 10,000 lots SBER / GAZP / LKOH, bps | 5.94 / 13.14 / 26.84 | 0.00 / 0.09 / 0.00 | 0.27 / 1.58 / 0.86 |

- LKOH 10,000 shares at 6,033.5 ₽ = 60.3 million ₽; 26.84 bps is about 162,000 ₽ of hidden cost.
- Fill-rate difference: about 29 and 21 orders, two-sample z ≈ 2.0, p ≈ 0.046. Since 2026-11-07 the deck and the
  research call it **confirmed at α = 0.05** with a small margin (the user wants only "confirmed" or "refuted").
- This is a replay of recorded books with three execution models, not real fills.
- Synthetic market maker: −18 thousand ₽/day before commission, −2.21 million ₽/day after (sandbox 0.05% fee
  understates costs fivefold).

## I5 backtest-orchestrator (synthetic MOEX, 8 seeds)

Fill-probability error: calibrated 0.015 (0.012 to 0.018), touch fills 0.764, fills-only 0.104. Gated ladder:
0/240 false promotions, 3.0 s vs 51.6 s on hftbacktest alone. Parity classifier caught 64/64 planted engine bugs.

## S1 tsfm-arena (synthetic 30-asset panel, 722 origins, 90% intervals)

Rank IC after cutoff: PatchTST 0.021 [0.009, 0.033]; on its own training dates 0.170 (overstated about 8×);
rank-tuned PatchTST 0.028; Chronos-Bolt small zero-shot 0.037; ridge on 10 lags 0.057 (best).

## S3 reactive-lob-sim (synthetic MOEX world)

Gap score G: tape replay 0.133 (0.090 to 0.223); Hawkes ABM 0.328; zero-intelligence 0.483; GRU 0.523. Impact κ
0 → 4 raises excess kurtosis of 1 s returns 4.27 → 10.21. Numba kernel 81.8 million vs 0.46 million events/s
(177×). Calibrated κ 0.0 vs true 1.0 on one 1,800 s tape (a known weakness).

## S8 agent-arena (synthetic agents with known skill)

Wrong winner, one run per agent: 51.7% [46.0, 57.3] of 300 seasons; arena protocol 0.0% [0.0, 1.3], correct
71.3%, abstains otherwise. False passes without skill: PSR 8.2% vs DSR 0.0%.

## I9 risk-gated-mcp-gateway (200 adversarial episodes, MOEX fakes)

Blocked 1,181 / 1,181 violations, 0 / 2,730 false refusals; pass-through baseline blocked 42 / 1,225 and leaked
11,620 future rows. MCP overhead 1.74 ms (stdio), 2.29 ms (HTTP).

## S7 llm-leakage-probe (synthetic corpus, planted leaks, 3 seeds)

Precision 0.894, recall 0.882 vs 0.375 for the anonymisation contrast; false-flag rate after cutoff 0.059;
gating removes 93% of the return earned from leaks (4.48% → 0.31% per leaked cell). TinyChrono tiny preset has
0.99 M parameters. No public LLM has been probed yet.

## Cost arithmetic (docs/hackathon/calculation.md)

100 SBER at 292.70 ₽ = 29,270 ₽; commission 73.18 ₽ per side, 146.36 ₽ round trip; breakeven 294.17 ₽ move =
147 ticks of 0.01 ₽ on 100 shares; spread edge 1 ₽; sandbox fee 0.05% gives 14.64 ₽ (understates fivefold).

## Hypotheses (deck slide 10 and research conclusion, 2026-11-07)

All confirmed: H1 trial accounting cuts noise (synthetic); H2 sandbox understates large-order costs (real
books) and passive fill rate (real books, z ≈ 2.0); H3 probe finds LLM memory (synthetic); H4 arena protocol
does not name a wrong winner (synthetic); gateway blocks violations (synthetic episodes).

## S4 robust-mm-rl (pipeline checks, not research results; 2026-11-08)

One Adam step of a 64-256-256-1 MLP, batch 4,096: 9.7 to 10.3 ms on the CPU (torch 2.14.1, 12 threads, Xeon
E5-2673 v3); 150 ms for 64-1024-1024-1 at batch 8,192. tinygrad on OpenCL (rusticl) hung the RX 580. Source:
robust-mm-rl `docs/gpu.md`.
Night run 2026-11-08 (`robust-mm-rl/results/runs.jsonl`, run `20261108T013845Z-ppo-s7`; real MOEX 1-minute bars,
bar-level fill model with assumed impact): PPO on 10 liquid shares, 256 M steps in 7.1 h on CPU. Validation
split, 1,000 paired episodes: shortfall 26.41 bps vs TWAP 27.80 bps, gain 1.39 bps, 95% CI [0.36, 2.42]. One seed;
test split still locked.

GPU (RX 580, ROCm 5.4 container, torch 1.13): the PPO loop runs at 7,340 steps/s on the GPU vs 10,731 on the CPU
in the same build (0.68×) and 15,991 with the platform torch 2.14 on the CPU. An Adam step is 1.8× faster on the
GPU at 64-256×2/batch 4,096 and 7.2× faster at 400-1024×4/batch 8,192. Source: robust-mm-rl `docs/gpu.md`.
