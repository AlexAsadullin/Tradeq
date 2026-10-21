---
id: I6
title: Shadow Exchange
repository: shadow-exchange
path: ./shadow-exchange
package: shadow_exchange
track: Infra
priority: B
default_port: 8610
depends_on: [I1, I2, S3 calibration and scenarios]
used_by: [I5 (fills), S3 (gap score), I9, I8]
contracts_produced: "6.4 (order API, fills export)"
contracts_consumed: "6.2, 6.3, 6.5 (sim)"
spec_section: "quant_platform_plan_full.md, project I6"
conventions: ./00-platform-conventions.md
version: 1.0
date: 2026-10-21
---

# I6 - Shadow Exchange

You are the sole developer of the `shadow-exchange` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Build a sandbox that trades against real order books, not testnets, with queue-aware fills, calibrated impact, and injectable micro and macro scenarios with time-travel replay.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/shadow-exchange/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/shadow-exchange/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `shadow_exchange`. Contracts you produce: 6.4 (order API, fills export). Contracts you consume: 6.2, 6.3, 6.5 (sim).

- Order API per contract 6.4 (FastAPI). The schema is identical to the future I7. Virtual accounts and
  positions with exact `Decimal` accounting: fees from config per venue tier, perp funding payments, and
  realised/unrealised PnL.
- Market feed protocol with two implementations: live mainnet books via `ccxt` WebSocket streams (venues and
  symbols from config; gated tests only), and tape replay from I1 Parquet (contract 6.2) for time travel.
- Shadow fill engine: market orders walk the real book with impact (S3 calibration file, contract 6.5, or a
  config default). Limit orders get a queue position at entry; it is decremented by trades at that level and
  pro-rata by cancels, and fills happen only when the queue ahead is exhausted. A latency model applies to order
  arrival and cancels. Your own orders never consume liquidity twice.
- Micro scenarios as composable book/flow transforms: spread widening, liquidity withdrawal, and liquidation
  cascades (loaded from S3 scenario YAML when present, otherwise from built-ins).
- Macro scenarios: CPI or rate-surprise replay keyed on ALFRED vintages via I2 (contract 6.3), funding shocks
  and volatility shocks, defined in YAML.
- Time-travel mode: replay any past day exactly as known (I2 `known_at`), including news timing when the text
  dataset exists.
- Fills export per contract 6.4 for I5 calibration and S3 gap scoring.
- CLI `shadow serve | replay | scenario run`.
- `make reproduce`: a synthetic day of tape. Run a passive market maker and an aggressive taker through
  baseline, spread-widening and liquidation-cascade scenarios; compare fill rates, slippage and PnL against a
  naive "testnet-style ideal fills" engine; export fills.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### I6. Shadow Exchange: sandbox with micro and macro factors

| Analog | Can | Cannot / limits |
|---|---|---|
| Exchange testnets ([Bybit, Binance futures](https://www.spark.money/glossary/paper-trading)) | Virtual balances, API practice | [Ideal fills, no slippage, testnet downtime](https://medadsabz.com/2024/10/1884.html); [thin books where orders expire unfilled](https://datawookie.dev/blog/2021/11/binance-spot-trading-liquidity/) |
| [Alpaca paper trading](https://alpaca.markets/agentic) | Equities/crypto paper accounts for agents | Simplified fills |
| [Rithmic paper trading](https://community.optimusfutures.com/t/is-rithmic-paper-trading-environment-realistic/2413) | Live-data exchange simulator | Futures only; separate servers, fill realism unclear |
| [fredapi/ALFRED](https://pypi.org/project/fredapi), [OpenBB](https://github.com/OpenBB-finance/OpenBB) | Macro data and vintages | No scenario engine |

**Gap.** A sandbox that trades against the live real order book (not a testnet), simulates queue-aware fills and impact, and lets you inject micro and macro scenarios with time-travel replay using vintage macro data.

**Project: Shadow Exchange**
- Base: virtual accounts, order API identical to I7, PnL accounting.
- Unique:
  1. Shadow fills on live mainnet books (I1 feeds) with queue position and S3-calibrated impact; fills feed I5's calibration.
  2. Micro scenarios: spread widening, liquidity withdrawal, liquidation cascades from S3 counterfactuals.
  3. Macro scenarios: CPI/rate surprise replay with ALFRED vintages, funding shocks, volatility surface shocks from S12.
  4. Time-travel mode: replay any past day exactly as it was known (I2), including news timing (I3).
  5. The live end of the S3 sim-to-real gap score.
