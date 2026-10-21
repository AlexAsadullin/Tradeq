---
id: I1
title: Market Tape Recorder
repository: market-tape-recorder
path: ./market-tape-recorder
package: tape_recorder
track: Infra core
priority: A
default_port: 8602
depends_on: []
used_by: [I2, S3, I6, I5, S1]
contracts_produced: "6.2"
contracts_consumed: "none"
spec_section: "quant_platform_plan_full.md, project I1"
conventions: ./00-platform-conventions.md
version: 1.0
date: 2026-10-21
---

# I1 - Market Tape Recorder

You are the sole developer of the `market-tape-recorder` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Build a self-hosted, quality-certified recorder for crypto CEX, on-chain perp DEX and MOEX market data in one schema.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/market-tape-recorder/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/market-tape-recorder/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `tape_recorder`. Contracts you produce: 6.2. Contracts you consume: none.

- Venue adapters behind one `VenueAdapter` protocol: Binance (spot + USD-M perps), Bybit, OKX, Hyperliquid
  (WebSocket, including public trades and liquidations where available) and MOEX ISS (REST polling of trades
  and order book snapshots; AlgoPack optional, behind an API key from env). Endpoints, symbols, channels and
  depths come from `config/settings.yaml`. Use `cryptofeed` where it exposes the raw sequence ids you need for
  gap detection; otherwise use direct `websockets` clients. Justify each choice in the README.
- Normalisation to the contract 6.2 schema, with both `ts_exchange` and `ts_local` (ns), `capture_region` and
  `connection_id`.
- Resilient sessions: reconnect with backoff, snapshot + delta resynchronisation, and overlapping redundant
  connections (start the new connection before dropping the old one), with dedup that keeps the earliest
  arrival. This removes the re-subscription gap.
- Writer: buffered, partitioned Parquet with rotation and atomic finalisation. No partial files are visible.
- Book reconstruction and the quality certificate per instrument-day: sequence-gap detection (per-venue rules),
  crossed or locked book checks, snapshot vs reconstructed-from-deltas consistency, re-subscription gap
  measurement, clock-skew stats (`ts_local - ts_exchange`) and coverage ratio. The certificate is JSON per
  contract.
- Dual-region support: every process is labelled with a region from config. `tape merge-regions` merges two
  captures of the same stream, picks the earliest message per (venue, seq or trade_id), and writes latency
  distributions per region.
- Monthly archive builder: packs a small configured universe with its certificates and a Markdown quality
  report.
- CLI: `tape record | certify | merge-regions | archive | replay`. A small FastAPI status endpoint reports
  health, lag and last-seen per stream.
- Tests: recorded, hand-made per-venue message fixtures (JSON) replayed through adapters with no network.
  Inject gaps, crossed books, duplicate and out-of-order messages, and resubscriptions, and assert that
  certificates catch each one.
- `make reproduce`: replay the fixtures as two "regions" with injected faults, write tape, certify, merge, and
  print the certificate summary.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### I1. Market Tape Recorder (data collection: order books, trades, funding, liquidations)

**Problem.** Tick-level history is expensive and every self-built collector silently loses data.

| Analog | Can | Cannot / limits |
|---|---|---|
| [Tardis.dev](https://tardis.dev/) + [tardis-node / tardis-machine](https://docs.ccxt.com/docs/comparisons/ccxt-vs-tardis) | Full-depth L2, trades, funding, OI, liquidations, options chains back to 2019; order book reconstruction; open-source clients | [Data is paid ($350-6,000/month)](https://docs.ccxt.com/docs/comparisons/ccxt-vs-tardis); [daily 300-3,000 ms gap at re-subscription](https://docs.tardis.dev/historical-data-details/overview); [historical L3 only for Bitfinex, Coinbase, Bitstamp](https://docs.tardis.dev/faq/order-books) |
| [cryptofeed](https://github.com/bmoscon/cryptofeed) | [Normalised multi-exchange feeds, L2/L3 books and deltas via callbacks](https://pypi.org/project/cryptofeed/0.22.2/) | Feed handler only: no storage, no gap auditing, no archive |
| [CCXT](https://github.com/ccxt/ccxt) | Free unified REST/WS API across exchanges | [Live API client; not a tick archive](https://docs.ccxt.com/docs/comparisons/ccxt-vs-tardis) |
| [data.binance.vision](https://data.binance.vision) | Free bulk files | [Daily bulk only, no intraday](https://www.github.com/akenshaw/flowsurface); one venue |
| MOEX [ISS](https://iss.moex.com/iss/reference/) / [AlgoPack](https://moexalgo.github.io/), [moex-iss client](https://pypi.org/project/moex-iss/), [go-moex-iss](https://github.com/Ruvad39/go-moex-iss) | Free public ISS; AlgoPack analytics | [ISS order books are REST polling snapshots, not streaming; real-time needs Passport; AlgoPack is paid](https://docs.rs/crate/digdigdig3/latest/source/src/l2/free/moex/README.md) |
| [Hyperliquid public API](https://api.hyperliquid.xyz/info) | [No-auth public positions, fills and leaderboard](https://apify.com/zhorex/hyperliquid-scraper.md) | Raw API only |
| [vn.py data_recorder](https://gitee.com/AnyQuant/vnpy) | GUI-configured market data recording through any vn.py gateway, incl. CTP Chinese futures | Bar/tick recording into a database; no completeness certificates or multi-region timestamps |
| [AkShare](https://github.com/akfamily/akshare) | [1,062 credential-free interfaces in v1.18.94](https://apify.com/research_master/akshare-financial-data.md), including all six Chinese futures exchanges (CFFEX, SHFE, DCE, CZCE, GFEX, INE) | Scraped snapshots and history, not a streaming order-book recorder; interfaces change |

**Gap.** No open, self-hosted recorder that (a) proves completeness per day, (b) records both exchange and arrival timestamps from more than one region, (c) covers CEX, on-chain perp DEX and MOEX in one schema, and (d) publishes free archives with quality reports.

**Project: Market Tape Recorder**
- Base: WebSocket subscription, normalisation, snapshot + delta storage, reconnection.
- Unique:
  1. Data-quality certificate per instrument-day: sequence-gap detection, crossed-book checks, snapshot/delta consistency, re-subscription gap measurement (overlapping connections to remove the daily gap Tardis documents).
  2. Dual-region capture (e.g. EU + Tokyo) to measure feed latency and choose the earliest message; latency data reused in S2 and S9.
  3. One schema across Binance/Bybit/OKX, Hyperliquid (on-chain perps, with wallet-level fills) and MOEX (polled ISS + optional AlgoPack), enabling cross-market studies no analog supports. Optional extension: Chinese futures via a vn.py CTP gateway used as a pure feed adapter, with our quality layer on top.
  4. Free monthly public archive for a small universe with quality reports, which creates a public dataset for S2/S3 papers.
- Secondary: Rust/Python collectors, Parquet output.
- Platform: feeds I2; consumers are every other service.
