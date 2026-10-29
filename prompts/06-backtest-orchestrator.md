---
id: I5
title: Multi-fidelity Backtest Orchestrator
repository: backtest-orchestrator
path: ./backtest-orchestrator
package: bt_orchestrator
track: Infra
priority: A
default_port: 8606
depends_on: [I2, S6, I6 fills, S3 sim]
used_by: [I9, S8, I7]
contracts_produced: "6.5 (backtest service)"
contracts_consumed: "6.1, 6.3, 6.4 (fills), 6.5 (sim)"
spec_section: "quant_platform_plan_full.md, project I5"
conventions: ./00-platform-conventions.md
version: 2.0
date: 2026-10-29
---

# I5 - Multi-fidelity Backtest Orchestrator

You are the sole developer of the `backtest-orchestrator` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Orchestrate existing engines (vectorbt, NautilusTrader, hftbacktest) into a fidelity ladder with reality-calibrated fills, cross-engine parity checks and automatic trial logging. Do not build a new engine.

## Revision 2 (2026-10-29): MOEX scope

Use the MOEX venue config (`moex-tbank` or `moex-algopack`, lots, ticks, RUB fees) and calibrate fills from I6 MOEX fills; I2 now serves `tape.book_snapshot` and `tape.candles` for MOEX. See `../docs/moex-sources.md` and section 5.4 of the spec.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/backtest-orchestrator/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/backtest-orchestrator/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `bt_orchestrator`. Contracts you produce: 6.5 (backtest service). Contracts you consume: 6.1, 6.3, 6.4 (fills), 6.5 (sim).

- Engine-agnostic strategy API: a strategy declares parameters and implements either a vectorised
  target-position function or event callbacks. A small adapter layer maps it onto each engine.
- Engine adapters behind one protocol: vectorbt (vectorised screen), NautilusTrader `BacktestEngine`
  (event-driven, bars and trades), hftbacktest (tick/queue with latency), and the S3 reactive simulator via
  contract 6.5 (HTTP client; an in-process fake for tests).
- Fidelity ladder: vectorised -> event -> tick/queue -> reactive sim. Promotion criteria per level come from
  config. The report shows the metric drop per level, with CIs.
- Cross-engine parity: the same strategy in two engines with matching cost and fill settings. Compare trades,
  positions and PnL within tolerances, and classify disagreements (fill timing, fee, rounding, partial fills).
- Reality-calibrated fills: learn fill probability (e.g. logistic on distance to touch, queue ahead, volatility)
  and slippage (regression on size/ADV, spread, volatility) from the I6 fills Parquet (contract 6.4). Models are
  versioned under the data root and injected into the event and tick engines.
- Sweeps (grid/random), walk-forward, standard metrics. Every run is logged to S6 automatically. Data is read
  only through an I2 client (contract 6.3), with a local Parquet source for synthetic data. Store the dataset
  fingerprint in each trial.
- FastAPI `POST /v1/backtests` per contract; CLI `bt run | ladder | parity | calibrate | serve`.
- `make reproduce`: synthetic bars, trades and fills. Run an SMA-cross and a limit-order mean-reversion strategy
  up the ladder, run parity vectorbt vs Nautilus, calibrate a fill model from synthetic fills, and write the
  report.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### I5. Multi-fidelity backtest orchestrator

| Analog | Can | Cannot / limits |
|---|---|---|
| [backtrader](https://github.com/mementum/backtrader) | Flexible Python event-driven | [Slow at minute data over years](https://www.quantt.co.uk/resources/backtesting-platforms-comparison) |
| [zipline-reloaded](https://github.com/stefan-jansen/zipline-reloaded) | Classic equities research | Equities/daily focus |
| [LEAN](https://github.com/QuantConnect/Lean) | Production engine, multi-asset, live brokers | [Designed around QuantConnect's cloud](https://groundy.com/articles/nautilustrader-building-production-ready-algorithmic/); C# core |
| [NautilusTrader](https://github.com/nautechsystems/nautilus_trader) | [Rust core, event-driven, research-to-live parity, infrastructure-agnostic](https://groundy.com/articles/nautilustrader-building-production-ready-algorithmic/) | Fill models generic, not calibrated to your own fills |
| [vectorbt](https://github.com/polakowo/vectorbt) / [PRO](https://vectorbt.pro/) | [Fast vectorised sweeps, walk-forward](https://pypi.org/project/vectorbt/1.1.1/); PRO adds purged CV, limit orders, leverage | [Advanced features and fuller docs in paid PRO](https://www.stork.ai/en/vectorbt) |
| [backtesting.py](https://github.com/kernc/backtesting.py), [ManifoldBT](https://pypi.org/project/manifoldbt/), [ml4t-backtest](https://pypi.org/project/ml4t-backtest/0.1.0a11/), [DQengine](https://pypi.org/project/deployquant/) | Simple or very fast engines; ml4t-backtest offers presets to match vectorbt/backtrader/zipline fill semantics | Each claims speed or parity; none calibrates fills to reality |
| [hftbacktest](https://www.mintlify.com/nkaz001/hftbacktest/introduction) | Queue-position and latency fills | HFT scope |
| [Jesse](https://www.stork.ai/en/jesse), [Freqtrade](https://github.com/freqtrade/freqtrade) | Crypto research + live | Bar-level fills |
| [Hikyuu](https://docsearch.algolia.com/mcp/docs/repo/fasiondog/hikyuu) | Apache-2.0 C++ core with Python layer; [splits a trading system into seven swappable components (environment, condition, signal, stop-loss, money management, profit target, slippage)](https://pypi.org/project/hikyuu/1.2.3/) for fast combinatorial research | Deeply A-share oriented; optional plugins; the combinatorial design multiplies trials, which makes S6 deflation essential |
| [RQAlpha](https://github.com/gaoke966/rqalpha) (RiceQuant) | Modular event-driven backtester for A-shares and futures, [free daily A-share bundle, live trading via an rqalpha-mod-vnpy bridge](https://www.skillsdirectory.com/skills/dvcrn-rqalpha) | Daily-bar focus; no queue or impact modelling |
| [vn.py CTA backtester](https://github.com/snake3342/vnpy) | Backtesting integrated with live vn.py gateways | Bar-level fills |

**Gap.** Engines compete on speed. What is missing is (a) fill models calibrated from your own paper/live fills, (b) a promotion path from cheap to realistic fidelity, (c) automatic cross-engine parity checks, (d) automatic trial logging.

**Project: Multi-fidelity Backtest Orchestrator** (built on NautilusTrader + hftbacktest + vectorbt, not a new engine)
- Base: strategy API, sweeps, walk-forward, metrics, reports.
- Unique:
  1. Reality-calibrated slippage and fill probabilities learned from I6/I7 fills, updated continuously and versioned.
  2. Fidelity ladder: vectorised screen -> event-driven -> tick/queue -> S3 reactive sim; a strategy moves up only if it survives, and the drop in performance per level is reported.
  3. Cross-engine parity test: the same strategy in two engines; disagreements flag fill-semantics bugs (the issue [ManifoldBT documents for backtrader vs vectorbt](https://pypi.org/project/manifoldbt/)).
  4. Every run logged to S6 automatically, data read only through I2.
