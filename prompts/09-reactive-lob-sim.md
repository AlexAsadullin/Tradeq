---
id: S3
title: Reactive Crypto Simulator + Sim-to-Real Gap Score
repository: reactive-lob-sim
path: ./reactive-lob-sim
package: reactive_lob_sim
track: Science
priority: A
default_port: 8609
depends_on: [I1 tape, I2, I6 fills]
used_by: [I5, I6, S4, I8]
contracts_produced: "6.5 (simulation service, impact calibration, scenario library)"
contracts_consumed: "6.2, 6.3, 6.4 (fills)"
spec_section: "quant_platform_plan_full.md, project S3"
conventions: ./00-platform-conventions.md
version: 1.0
date: 2026-10-21
---

# S3 - Reactive Crypto Simulator + Sim-to-Real Gap Score

You are the sole developer of the `reactive-lob-sim` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Build a reactive crypto limit-order-book simulator with an explicitly calibrated impact coupling, and the missing quantity of the field: a sim-to-real gap score.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/reactive-lob-sim/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/reactive-lob-sim/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `reactive_lob_sim`. Contracts you produce: 6.5 (simulation service, impact calibration, scenario library). Contracts you consume: 6.2, 6.3, 6.4 (fills).

- Matching engine: L3 price-time priority with limit, market, cancel and modify, IOC/FOK/post-only, and
  maker/taker fees from config. Numba where it pays. Property tests (hypothesis) for book invariants and
  conservation.
- Replay mode from I1 tape (book deltas + trades, contract 6.2), with an experimental agent's orders injected
  and queue position tracked.
- Agent-based mode: zero-intelligence, multivariate Hawkes order flow (MLE calibration on tape), noise,
  momentum and fundamental traders, and a liquidation-cascade agent conditioned on funding and open interest.
- Impact coupling: an explicit, calibrated parameter (propagator / square-root law, fitted from tape) that sets
  how strongly agent order flow reacts to the experimental agent's trades. Fitted parameters are written to the
  contract 6.5 calibration file.
- Generative order flow: a small conditional autoregressive torch model over tokenised order events
  (conditioned on funding, OI, volatility regime), trainable on CPU on small data.
- Realism scoring: stylised facts (fat tails, volatility clustering, absence of return autocorrelation, spread
  and depth distributions, order-flow imbalance -> return relation) and LOB-Bench-style distributional distances
  (Wasserstein, KS) plus the market-impact response function.
- Sim-to-real gap score: given the same strategy set run in replay, ABM, generative sim and live/shadow
  (fills from I6, contract 6.4), score each simulator by how well it predicts live outcomes (rank correlation
  and calibrated error of PnL, fill rate, slippage, with CIs). Rank the simulators.
- Counterfactual stress library (spread widening, liquidity withdrawal, liquidation cascade, funding shock) as
  YAML scenarios under the data root. Simulation service per contract 6.5.
- `make reproduce`: generate a synthetic "real" tape from a hidden ground-truth process, calibrate the
  simulators on part of it, run three simple strategies in each, compute stylised facts and the gap score
  against held-out "live" results, and write the report.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### S3. Generative and agent-based market simulation

**Disputed question.** Can simulators be realistic and reactive enough to train and stress-test strategies, and how is realism measured?

[JAX-LOB](https://arxiv.org/pdf/2308.13289) is the first GPU LOB simulator, processing thousands of books in parallel with [up to 75x faster per-message processing](https://ora.ox.ac.uk/objects/uuid:eafe039c-38eb-4845-8252-05def202b71a). [LOB-Bench (ICML 2025)](https://arxiv.org/pdf/2502.09172) provides realism metrics including market-impact response functions and finds autoregressive state-space generators beat GAN and parametric baselines. [TRADES](https://www.arxiv.org/abs/2502.07071) is a transformer diffusion engine, released with [DeepMarket, described as the first open-source Python framework for deep-learning LOB simulation](https://api.crossref.org/works/10.3233%2FFAIA251249). [DiffLOB](https://arxiv.org/pdf/2602.03776) adds regime-conditioned counterfactuals. [LOB-ID (2026)](https://arxiv.org/pdf/2608.13082) proposes inception-distance evaluation and notes that judging realism remains a central challenge. For LLM-agent markets, a 2026 replication found [fat tails appear only when price-impact coupling is strong enough](https://arxiv.org/pdf/2608.11215): the mechanism, not the agent, determines realism; other work finds [LLM-agent markets often look "too rational"](https://arxiv.org/pdf/2602.07023.pdf), and [small prompt changes toward trade aversion can stop trading altogether](https://arxiv.org/html/2503.00320v2).

| Analog | Can | Cannot / limits |
|---|---|---|
| [ABIDES](https://github.com/jpmorganchase/abides-jpmc-public) | Agent-based discrete-event market, RL gym | CPU; hand-crafted agents; manual calibration |
| [JAX-LOB](https://arxiv.org/pdf/2308.13289) | GPU parallel books + RL | Reactive realism not benchmarked |
| [TRADES / DeepMarket](https://www.arxiv.org/abs/2502.07071) | Diffusion order flow reacting to an experimental agent | Two equity stocks; realism via predictive score and plots |
| [LOB-Bench](https://github.com/peernagy/lob_bench) | Rigorous realism metrics | Benchmark separate from strategy testing; equity LOBSTER data |
| [DiffLOB](https://arxiv.org/pdf/2602.03776) | Counterfactual regimes | Level-2 snapshots, not messages |
| [Lopez-Lira LLM market sim](https://arxiv.org/pdf/2504.10789) | Open-source LLM trading agents in a market | Expensive, small scale |

**Gap.** Nobody closes the loop generator -> realism -> strategy trained in sim -> live paper trading -> measured degradation. Missing quantity: a sim-to-real gap score. No open generator trained on crypto message data with funding and liquidation events.

**Project: Reactive Crypto Simulator + Sim-to-Real Gap Score**
- Base: replay, matching engine, zero-intelligence/Hawkes agents, generative order flow, stylised-fact checks.
- Unique: sim-to-real gap score (same strategies in replay, ABM, generative sim and I6 shadow exchange; simulators ranked by how well they predict live results); hybrid engine with an explicit calibrated impact coupling; crypto conditioning on funding, liquidations, open interest; counterfactual stress library.
- Platform: `sim-service` used by S4, I6 and terminal stress tests.
- Deliverable: `reactive-lob-sim` + public synthetic crypto LOB dataset + LOB-Bench-compatible scores.
