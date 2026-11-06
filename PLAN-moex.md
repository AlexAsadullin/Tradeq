# Plan: MOEX pivot and the real-time RL loop (started 2026-10-29)

Working checklist for the change the user requested on 2026-10-29. Tick items as they land. One session, no
subagents, commit per repository after each working step.

## User decisions (source of truth)

1. Crypto is out of scope for now. The platform targets MOEX only. Data comes from two sources:
   MOEX AlgoPack (paid token, order books, trades, candles, Super Candles; docs at moexalgo.github.io/docs/api)
   and the T-Bank Invest API (free token, free sandbox, real-time streams; developer.tbank.ru/invest).
   T-Bank comes first, because its token arrives sooner.
2. The repositories stay independent blocks that any project can reuse. Together they form a real-time RL
   system: it accumulates live market data, trains an RL trading agent on history and live data, and tests
   it on both.
3. The Point-in-time Store (I2) is the central module. It must also feed a real-time terminal that shows a
   slice of the market (all metrics) at one moment.
4. Computing priority: data collection first. Nothing may starve the recorder.
5. The MCP gateway (I9) must not be bound to an exchange. First build a sandbox behind it that duplicates the
   real market; terminals for other exchanges connect later.
6. S3 (simulator) is adapted to MOEX stocks. I6 (shadow exchange) is adapted to MOEX and the T-Bank API.
7. No live tests are possible without tokens. Code is written from the docs and samples, with tests on
   hand-made fixtures shaped like the documented payloads.

## Steps

- [x] 0. Read MOEX AlgoPack and T-Bank Invest API docs; record endpoints, payload shapes and limits in
       `docs/moex-sources.md` (umbrella repo), so every repository codes against one summary.
- [x] 1. Spec and system tasks: update `quant_platform_plan_full.md` (sections 1.3 with a status column,
       1.2, I1, I2, I6, I9, S3, 5, 6), `prompts/00-platform-conventions.md` (venues, symbols, channels,
       new contract for the market slice and the broker-adapter boundary), and prompts 02, 03, 08, 09, 10.
       Mark crypto-only items elsewhere (S1, S2, S4, S5, S12) as deferred, not deleted.
- [x] 2. I1 market-tape-recorder: remove the Binance, Bybit, OKX and Hyperliquid adapters, fixtures,
       settings and experiments that depend on them; add an AlgoPack adapter (REST: order book snapshots,
       trades, candles, tradestats/orderstats/obstats) and a T-Bank adapter (gRPC or REST market-data
       stream: order book, trades, last price, candles; plus historical candles); keep the certificate
       logic with MOEX trading-session windows; scheduler gives the recorder top priority (process nice,
       bounded queues, back-pressure that drops analytics, never capture).
- [x] 3. I2 point-in-time-store: MOEX datasets (tape.trades, tape.book_snapshot, candles, super candles);
       live append path from I1 (tail the staging tape or push endpoint); market-slice API
       (`GET /v1/slice?known_at=` returns every metric per instrument as of T) and a streaming variant
       (WebSocket or SSE) for the terminal; registry entries for MOEX calendars.
- [x] 4. I9 risk-gated-mcp-gateway: broker-adapter protocol (venue-agnostic); a built-in sandbox broker that
       mirrors the real market from I2/I1 data (order book replay or live) with queue-aware fills from I6;
       T-Bank sandbox adapter as the first external broker; MOEX lots, tick sizes and session hours in risk
       checks.
- [x] 5. S3 reactive-lob-sim (2026-11-06): MOEX equity microstructure (lot size, tick size, price limits, auctions,
       trading-session schedule, no funding or liquidations); calibration from MOEX tape; scenarios
       for MOEX (opening auction, dividend gap, liquidity withdrawal, CBR rate surprise).
- [x] 6. I6 shadow-exchange (2026-11-06; T-Bank sandbox reproduced offline instead of mirrored, per user): MOEX tape and live T-Bank feed; MOEX fees and lots; T-Bank sandbox order
       adapter (contract 6.4 orders mirrored to the T-Bank sandbox to compare fills); CBR key-rate and
       CPI macro scenarios instead of funding shocks.
- [x] 7. Docs: table 1.3 statuses, README of the umbrella, HANDOVER.md of every touched repo, memory notes
       (2026-11-06; root `CLAUDE.md` not written).
- [x] 8. Verify (2026-11-06, all 11 repos green; integration I5, I9, S8 pass; nothing committed): `make lint typecheck test` in every touched repo; integration tests that already exist
       must still pass; commit each repository.

## Out of scope in this pass (recorded so it is not forgotten)

- The RL agent itself (S4) and the terminal UI (I8): not started; this pass builds their inputs (storage,
  slice API, sandbox). They are the next projects.
- Report reruns (`make report`) for I1, S3 and I6: their reports cite crypto-shaped synthetic data; they are
  marked as outdated in the HANDOVER notes until a MOEX rerun.

## Pass of 2026-11-05/06 (user requests after the pivot)

- [x] T-Invest token: data download only, stored in the root and I1 `.env`; T-Bank reached through SPKI key
      pinning (the user refused to trust the Russian Trusted Root CA). No geo-block from the Netherlands.
- [x] Trading local only (I9 mirror sandbox; T-Bank sandbox broker disabled); T-Invest commission 0.25% per
      fill, 0% for T-Capital funds, in I9, I5, S8, S3 (and I6).
- [x] `scripts/download-all.sh`: universe (282 instruments), full daily history, 12 months of 1-minute candles,
      certify, I2 ingest. Full run done 2026-11-06 17:22 to 20:52 MSK: 829,744 day rows, 28.6M 1-minute rows, 0 failures, ingested into I2.
- [x] I2: real tape ingested, live-edge slice cache, CBR key rate and CPI vintages.
- [x] Crypto replaced by MOEX as default in S3, I5, I9, S8 (crypto kept as optional modules).
- [x] I8 research-terminal v0.1 (TradingView-style UI, RL placeholder on `rl/v1`).
- [x] I6 shadow-exchange MOEX adaptation (step 6).
- [ ] S4 RL agent (not started; terminal API ready).
