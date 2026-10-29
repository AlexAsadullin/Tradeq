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

- [ ] 0. Read MOEX AlgoPack and T-Bank Invest API docs; record endpoints, payload shapes and limits in
       `docs/moex-sources.md` (umbrella repo), so every repository codes against one summary.
- [ ] 1. Spec and system tasks: update `quant_platform_plan_full.md` (sections 1.3 with a status column,
       1.2, I1, I2, I6, I9, S3, 5, 6), `prompts/00-platform-conventions.md` (venues, symbols, channels,
       new contract for the market slice and the broker-adapter boundary), and prompts 02, 03, 08, 09, 10.
       Mark crypto-only items elsewhere (S1, S2, S4, S5, S12) as deferred, not deleted.
- [ ] 2. I1 market-tape-recorder: remove the Binance, Bybit, OKX and Hyperliquid adapters, fixtures,
       settings and experiments that depend on them; add an AlgoPack adapter (REST: order book snapshots,
       trades, candles, tradestats/orderstats/obstats) and a T-Bank adapter (gRPC or REST market-data
       stream: order book, trades, last price, candles; plus historical candles); keep the certificate
       logic with MOEX trading-session windows; scheduler gives the recorder top priority (process nice,
       bounded queues, back-pressure that drops analytics, never capture).
- [ ] 3. I2 point-in-time-store: MOEX datasets (tape.trades, tape.book_snapshot, candles, super candles);
       live append path from I1 (tail the staging tape or push endpoint); market-slice API
       (`GET /v1/slice?known_at=` returns every metric per instrument as of T) and a streaming variant
       (WebSocket or SSE) for the terminal; registry entries for MOEX calendars.
- [ ] 4. I9 risk-gated-mcp-gateway: broker-adapter protocol (venue-agnostic); a built-in sandbox broker that
       mirrors the real market from I2/I1 data (order book replay or live) with queue-aware fills from I6;
       T-Bank sandbox adapter as the first external broker; MOEX lots, tick sizes and session hours in risk
       checks.
- [ ] 5. S3 reactive-lob-sim: MOEX equity microstructure (lot size, tick size, price limits, auctions,
       trading-session schedule, no funding or liquidations); calibration from MOEX tape; scenarios
       for MOEX (opening auction, dividend gap, liquidity withdrawal, CBR rate surprise).
- [ ] 6. I6 shadow-exchange: MOEX tape and live T-Bank feed; MOEX fees and lots; T-Bank sandbox order
       adapter (contract 6.4 orders mirrored to the T-Bank sandbox to compare fills); CBR key-rate and
       CPI macro scenarios instead of funding shocks.
- [ ] 7. Docs: table 1.3 statuses, README of the umbrella, HANDOVER.md of every touched repo,
       root `CLAUDE.md` (new), memory notes.
- [ ] 8. Verify: `make lint typecheck test` in every touched repo; integration tests that already exist
       must still pass; commit each repository.

## Out of scope in this pass (recorded so it is not forgotten)

- The RL agent itself (S4) and the terminal UI (I8): not started; this pass builds their inputs (storage,
  slice API, sandbox). They are the next projects.
- Report reruns (`make report`) for I1, S3 and I6: their reports cite crypto-shaped synthetic data; they are
  marked as outdated in the HANDOVER notes until a MOEX rerun.
