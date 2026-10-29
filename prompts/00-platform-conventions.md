---
id: CONVENTIONS
title: Tradeq platform conventions and cross-project contracts
applies_to: [S6, I1, I2, S1, S7, I5, S8, I9, S3, I6]
spec: ../quant_platform_plan_full.md
constraints: ../constraints.txt
python: "3.13"
version: 2.0
date: 2026-10-29
---

# Tradeq platform conventions

Every project brief in this folder includes this file by reference. Read it in full before you start. If a
project brief conflicts with this file, this file wins on engineering rules, and the project brief wins on
scope.

Workspace root: `/Users/alexasadullin/PycharmProjects/Tradeq` (below: `$ROOT`).
Full specification: `$ROOT/quant_platform_plan_full.md`. Read sections 1, 5 and your own project section.

## 1. Repository layout and git

- Your project is its own git repository in `$ROOT/<repository>/` (the name is in your brief header). Run
  `git init -b main` there. Never write outside your repository, except under the shared data root (section 3).
  Never touch `$ROOT/.git` or another project's folder.
- Commit locally, in small logical steps with clear imperative messages (`Add PSR/DSR estimators`). Do not add
  remotes and do not push. End every commit message with this line:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
- Layout (src layout):

```
<repository>/
  pyproject.toml        # metadata, deps, ruff/mypy/pytest config
  uv.lock               # committed
  Makefile              # setup, lint, typecheck, test, reproduce, serve (where relevant)
  README.md             # claim paragraph, quickstart, architecture, contracts, results, limitations, roadmap
  .env.example          # every env variable with a placeholder or safe default
  .gitignore            # .venv/, .env, caches, build artefacts; never data
  config/settings.yaml  # all defaults: endpoints, symbols, thresholds, ports, model ids
  src/<package>/        # code
  tests/                # unit/ and integration/; fixtures under tests/fixtures/
  docs/                 # design notes, tech report draft
```

## 2. Python, venv and dependencies

- Python 3.13 only (`requires-python = ">=3.13,<3.14"`). NautilusTrader has no 3.14 wheels yet, so 3.13 is the
  newest Python the whole platform can share.
- A venv is mandatory: `uv venv --python 3.13 .venv`, and then `uv sync`. Use only the repository's `.venv`
  (`uv run ...` or `.venv/bin/python`). Never install into the system or Homebrew Python.
- `$ROOT/constraints.txt` is the platform's resolved set of the newest mutually compatible versions (all binary
  wheels on this machine). For every package listed there, pin the direct dependency in `pyproject.toml` to
  exactly that version (`numpy==2.5.4`). Put dev tools (pytest, ruff, mypy, respx, hypothesis) in a
  `[dependency-groups] dev` group with the same pins.
- If you need a package that is not in `constraints.txt`, add its newest version that resolves together with
  the pinned set (check with `uv lock`). Prefer binary wheels. List every such addition in your final report, so
  the platform constraints can be updated.
- Add only what you use. Heavy optional stacks (torch, nautilus) go in optional extras only if the core of
  your project does not need them.

## 3. Data: one place for everything

- All persistent data (raw captures, Parquet, DuckDB/SQLite files, model checkpoints, caches, reports and
  artefacts) lives under one root, given by the env variable `TRADEQ_DATA_DIR`. On this machine it is
  `$ROOT/data`. Put it in your `.env`, which is gitignored. `.env.example` shows a placeholder.
- Each project owns exactly one subtree, `$TRADEQ_DATA_DIR/<repository>/`, and reads other projects' subtrees
  only through the contracts in section 6.
- Third-party caches go there too: set `HF_HOME=$TRADEQ_DATA_DIR/cache/huggingface` and similar from settings.
  Do not set them in code with literal paths.
- No data files in git. Only small, hand-made test fixtures (KBs) go in `tests/fixtures/`.
- Tests never read or write the real data root. They use `tmp_path` and a `TRADEQ_DATA_DIR` override in a
  fixture.

## 4. Configuration: no hardcoding

- One typed settings object per project (`pydantic-settings`): defaults come from `config/settings.yaml`,
  are overridden by environment variables (prefix `<PROJECT>_`, nested delimiter `__`, e.g.
  `LEDGER_GATE__MIN_DSR=0.95`), and secrets come only from the environment.
- No literal URLs, ports, hosts, paths, symbol lists, venue lists, thresholds, fees, model ids, API keys or
  magic numbers in code. Named constants are acceptable only for true invariants (e.g. nanoseconds per
  second) and protocol-defined values.
- Default service ports (configurable, listed here so services can run side by side):

| Project | Repository | Package | Default port | Env prefix |
|---|---|---|---|---|
| S6 | research-ledger | research_ledger | 8601 | LEDGER_ |
| I1 | market-tape-recorder | tape_recorder | 8602 | TAPE_ |
| I2 | point-in-time-store | pit_store | 8603 | PIT_ |
| S1 | tsfm-arena | tsfm_arena | 8604 | TSFM_ |
| S7 | llm-leakage-probe | leakage_probe | 8605 | LEAKAGE_ |
| I5 | backtest-orchestrator | bt_orchestrator | 8606 | BT_ |
| S8 | agent-arena | agent_arena | 8607 | ARENA_ |
| I9 | risk-gated-mcp-gateway | mcp_gateway | 8608 | GATEWAY_ |
| S3 | reactive-lob-sim | reactive_lob_sim | 8609 | SIM_ |
| I6 | shadow-exchange | shadow_exchange | 8610 | SHADOW_ |

## 5. Code quality

- Clean, readable, typed code. Small modules with one responsibility each. Pure functions for maths. Protocols
  or ABCs at boundaries (data sources, engines, model backends, transports). Dependency injection instead of
  globals. No dead code, no commented-out code, no TODO stubs that pretend to work.
- Docstrings on public APIs, with formulas or paper references for statistics. Comments explain why, not what.
- `ruff check` and `ruff format` must be clean (enable at least E, F, I, B, UP, SIM, RUF). `mypy --strict` on
  `src/` must be clean, or close to it, with every remaining exception justified in config.
- Logging through `structlog`, no `print` in library code. CLIs use `typer`. Services use `FastAPI` +
  `uvicorn`. Use `httpx` for HTTP clients and `pydantic` v2 for every wire model.
- Times: timezone-aware UTC everywhere. Wire format is ISO-8601 strings; storage is int64 nanoseconds since the
  epoch (UTC) named `ts_*`.
- Money and quantities: float64 in analytics; `decimal.Decimal` where exact accounting matters (balances,
  fees). Document the choice.

## 6. Cross-project contracts (v1)

All projects are built in parallel, so never import another project's package. Integrate only through these
HTTP and file contracts. Implement a small typed client for every contract you consume, with base URLs from
settings. Also provide an offline fallback where the brief requires one (local files or an in-process fake), so
your project runs and tests without the other services. Every wire model includes `"schema_version": "1"`.
If you must extend a contract, add only optional fields and document the change in your README.

### 6.1 Research Ledger (S6): trial capture and verdicts

- `POST /v1/trials` takes a `TrialRecord` and returns `{"trial_id": ...}`. `POST /v1/trials/batch` takes a list.
- Offline fallback: append one JSON `TrialRecord` per line to
  `$TRADEQ_DATA_DIR/research-ledger/inbox/<source>-<yyyymmdd>.jsonl`. The ledger ingests the inbox.
- `TrialRecord`: `trial_id` (uuid4), `family` (experiment family, e.g. `tsfm-arena/rank-ic/btc-1h`),
  `strategy_id`, `source` (`i5|s1|s3|s4|s5|s7|s8|i9|notebook`), `actor` (`{"kind": "human|agent|robot", "id": str}`),
  `params` (object), `dataset_fingerprint` (str or null, from I2), `code_version` (git sha or null), `seed`
  (int or null), `started_at`, `finished_at`, `periods_per_year` (float), `returns` (`{"ts": [ISO...],
  "values": [float...]}`, per-period net returns) or `returns_path` (Parquet with columns `ts`, `ret`),
  `metrics` (object), `tags` (list of str).
- `GET /v1/strategies/{strategy_id}/verdict` returns a `Verdict`: `strategy_id`, `n_trials`, `effective_trials`,
  `sharpe`, `psr`, `dsr`, `pbo` (nullable), `min_trl`, `passed` (bool), `reasons` (list of str), `thresholds`
  (object), `leakage_flags` (list), `computed_at`.
- `POST /v1/leakage` takes a `LeakageEvent`: `source` (`i2|s7`), `strategy_id` and `trial_id` (both nullable),
  `severity` (`info|warn|block`), `kind`, `detail` (object), `observed_at`.
- `POST /v1/strategies/{strategy_id}/override` takes `{actor, reason, tier}` and is always logged, never silent.

### 6.2 Market Tape Recorder (I1): normalised tape on disk

Revision 2 (2026-10-29, MOEX only). The market is the Moscow Exchange. A venue name identifies the feed that
captured the data, because the same instrument is recorded from more than one source: `moex-tbank` (T-Bank
Invest API), `moex-algopack` (MOEX AlgoPack with a token), `moex-iss` (public ISS, delayed). The source facts
are in `$ROOT/docs/moex-sources.md`. Crypto venues and the channels `funding`, `liquidations` and
`open_interest` are deferred; readers must still accept them, so old files stay readable.

- Parquet under `$TRADEQ_DATA_DIR/market-tape-recorder/tape/venue=<venue>/channel=<channel>/symbol=<symbol>/date=<YYYY-MM-DD>/part-<n>.parquet`.
- Channels: `trades`, `book_snapshot`, `book_delta`, `candles`, `trading_status`, `tradestats`, `orderstats`,
  `obstats` (the last three are AlgoPack Super Candles).
- Symbols are `<SECID>-RUB-<BOARD>`, for example `SBER-RUB-TQBR`. `date` is the MOEX trade date (Moscow time).
- `size` is always in shares (lots times the lot size), and `price` in roubles per share. The lot size and the
  price tick per symbol are in I1's settings and in the I2 dataset `instruments`.
- `trades` adds `trading_session` (str, nullable: `0` morning, `1` main, `2` evening). T-Bank trades carry no
  trade id, so their `trade_id` is built from the trade's content and `seq` is null.
- `candles`: `interval` (str, `1m|10m|1h|1d`), `ts_open`, `ts_close` (int64 ns), `open`, `high`, `low`, `close`,
  `volume` (shares), `value` (roubles, nullable).
- `trading_status`: `status` (str; the source's status code), `limit_order_allowed` and `market_order_allowed`
  (bool, nullable).
- `tradestats`, `orderstats`, `obstats`: one row per 5-minute bar; `ts_exchange` is the bar time
  (`tradedate` + `tradetime`), `ts_published` (int64 ns, nullable) is the publication time (`SYSTIME`), which is
  when the bar became knowable, and `ts_local` stays the arrival time. The documented AlgoPack columns follow
  as float64 (for example `pr_vwap`, `disb`, `put_vol_b`, `spread_bbo`, `imbalance_vol`).
- `book_snapshot` from T-Bank: every stream message is a full snapshot of `depth` levels with `seq` null and
  `snapshot_id` `<board>-<exchange time ns>`.
- Live status: I1 serves `GET /v1/load` with `pressure: ok|high`; long jobs on the same host poll it and pause
  while it is high (section 9).
- Common columns: `venue` (str), `symbol` (str), `ts_exchange` (int64 ns, nullable), `ts_local` (int64 ns,
  arrival time), `capture_region` (str), `connection_id` (str), `seq` (int64, nullable; venue sequence or
  update id).
- `trades`: `trade_id` (str), `price`, `size` (float64), `side` (`buy|sell`, aggressor).
- `book_delta`: `side` (`bid|ask`), `price`, `size` (float64; 0 deletes the level), `prev_seq` (nullable).
- `book_snapshot`: `side`, `price`, `size`, `level` (int), `snapshot_id` (str).
- `funding`: `rate`, `mark_price`, `index_price` (nullable), `next_funding_ts` (int64 ns, nullable).
- `liquidations`: `side`, `price`, `size`, `trader` (nullable; on-chain address where public).
- `open_interest`: `open_interest`, `open_interest_value` (nullable).
- Quality certificates: `$TRADEQ_DATA_DIR/market-tape-recorder/certificates/venue=<v>/symbol=<s>/date=<d>.json`,
  with fields `status` (`certified|degraded|failed`), `checks` (list of `{name, passed, value, threshold}`),
  `gaps` (list of `{start_ns, end_ns, kind}`), and `coverage_ratio`.

### 6.3 Point-in-time Store (I2): "as known at T"

- Every stored record carries `valid_time` (when the fact refers to) and `knowledge_time` (when it first became
  knowable on the platform, int64 ns). Revisions add rows; they never overwrite.
- `POST /v1/query` takes `{dataset, start, end, known_at, columns?, filters?, mode: "research|live"}`. It returns
  an Arrow IPC stream (`application/vnd.apache.arrow.stream`), or JSON when `format=json`, plus the header
  `X-Dataset-Fingerprint: sha256:<hex>`. Rows are those with `knowledge_time <= known_at`, keeping the latest
  revision per key as of `known_at`.
- Leakage guard: in `research` mode, a query with `end > known_at`, or one that touches a dataset without
  knowledge times, returns `409` with a `LeakageEvent` body and reports it to S6 (`POST /v1/leakage`).
- `GET /v1/datasets` lists datasets with their schemas, key columns and knowledge-time rules.
- `GET /v1/fingerprints/{fingerprint}` returns the query that produced it, so a backtest can be reproduced.

### 6.4 Order API: shared by Shadow Exchange (I6) and the future execution engine (I7)

- `POST /v1/orders` takes `{client_order_id, account_id, venue, symbol, side: buy|sell, type: market|limit,
  qty, price?, time_in_force: GTC|IOC|FOK|POST_ONLY, strategy_id, actor: {kind, id}}`. It returns an `Order` with
  `order_id`, `status` (`accepted|rejected|partially_filled|filled|cancelled`) and `reject_reason`.
- Also: `GET /v1/orders/{order_id}`, `DELETE /v1/orders/{order_id}`, `GET /v1/accounts/{account_id}`,
  `GET /v1/positions?account_id=`, `GET /v1/fills?account_id=&since=`.
- Fills export (I6) for I5 calibration and S3 gap scores:
  `$TRADEQ_DATA_DIR/shadow-exchange/fills/date=<YYYY-MM-DD>/part-<n>.parquet`, with columns `fill_id, order_id,
  client_order_id, account_id, strategy_id, venue, symbol, side, order_type, ts_submit, ts_fill, price, qty,
  fee, liquidity (maker|taker), arrival_mid, distance_to_touch_bps, queue_ahead_at_entry, latency_ns,
  scenario_id`.

### 6.5 Research services

- Forecast service (S1): `POST /v1/forecast` takes `{model, symbols, horizon, known_at, quantiles}` and returns
  `{forecasts: [{symbol, horizon, mean, quantiles: {"0.1": x, ...}}], model_cutoff}`. `POST /v1/rank` takes
  `{model, symbols, horizon, known_at}` and returns `{ranks: [{symbol, score}]}`.
- Backtest service (I5): `POST /v1/backtests` takes `{strategy, params, universe, start, end, fidelity:
  vectorised|event|tick|reactive_sim, known_at}` and returns `{run_id, trial_id, metrics, fidelity_report?}`.
- Simulation service (S3): `GET /v1/scenarios`; `POST /v1/simulations` takes `{scenario, seed, duration_s,
  venue, symbol}` and returns `{simulation_id, tape_path}`, where the output uses the I1 tape schema. Calibrated
  impact parameters live in `$TRADEQ_DATA_DIR/reactive-lob-sim/calibration/venue=<v>/symbol=<s>/impact.json`
  (`{model, params, fitted_at, sample_start, sample_end}`). The counterfactual stress library is in
  `$TRADEQ_DATA_DIR/reactive-lob-sim/scenarios/*.yaml`.
- Leakage probe (S7): `POST /v1/probe` takes `{model_id, entities, start, end, languages}` and returns a
  `LeakageReport`: `{model_id, window, cells: [{entity, date, memorisation_score, n_probes}], flagged: bool,
  threshold}`. Reports are also written to `$TRADEQ_DATA_DIR/llm-leakage-probe/reports/`.
- Text corpus input (from the future I3; until then produced synthetically or from public datasets): JSONL with
  `{id, source, first_seen (ISO ns), published_at, lang, entities, title, body}`.

### 6.6 MCP gateway (I9) tool contract, used by Agent Arena (S8)

- MCP tools: `clock`, `market_data(venue, symbol, channel, start, end)`, `features(names, symbols, start, end)`,
  `forecast(model, symbols, horizon)`, `run_backtest(strategy, params, universe, start, end, fidelity)`,
  `verdict(strategy_id)`, `place_order(venue, symbol, side, type, qty, price?, strategy_id, rationale)`,
  `cancel_order(order_id)`, `positions()`, `account()`, `budget()`,
  `report_usage(tokens_in, tokens_out, latency_ms, model)`.
- Agents never pass `known_at`. The gateway injects the session clock.
- Admin HTTP, with an admin key from env: `POST /admin/v1/sessions` takes `{agent_id, mode: research|paper|live,
  known_at, budgets}`, and `POST /admin/v1/sessions/{session_id}/clock` takes `{known_at}`. The arena uses these
  to drive episodes.
- Transports: streamable HTTP (port from settings) and stdio.
- Added in revision 2 (2026-10-29): the tool `market_slice(symbols?)`, which returns contract 6.7 at the session
  clock, and the tool `instrument(venue, symbol)`, which returns the broker's trading rules (lot size, tick,
  price band, trading status). `place_order` takes `qty` in shares, and the gateway rejects a quantity that is
  not a whole number of lots or a price off the tick.

### 6.7 Market slice (I2): every metric at one moment (revision 2)

- `GET /v1/slice?known_at=<ISO>&symbols=<a,b>&venue=<v>` returns a `MarketSlice`: `{known_at, venue, instruments:
  [InstrumentSlice], fingerprint}`. Without `known_at` the store answers at its live edge (the newest
  knowledge time it holds), and the response says which time that was.
- `InstrumentSlice`: `symbol`, `as_of` (the knowledge time of the newest row used), `trading_status`, `best_bid`,
  `best_ask`, `mid`, `spread_bps`, `bid_depth`, `ask_depth` (shares in the top N levels, N from settings),
  `imbalance` ((bid_depth - ask_depth) / (bid_depth + ask_depth)), `book_levels` (list of `{side, price, size}`,
  optional), `last_price`, `last_trade_ts`, `vwap` and `volume` and `trades` over a trailing window (window in
  settings), `return_1m`, `return_5m`, candle fields of the latest closed 1-minute candle, the latest Super Candle
  values (`tradestats`, `orderstats`, `obstats` as nested objects, nullable), `stale` (bool, true when the
  newest row is older than the staleness limit) and `quality` (the I1 certificate status of that day, nullable).
- `GET /v1/slice/stream?symbols=&venue=&interval_ms=` is a Server-Sent Events stream of `MarketSlice` documents
  at the live edge, one per interval. It is read-only and never blocks ingestion.
- Every value is computed only from rows with `knowledge_time <= known_at`, so the slice at a historical T is
  exactly what was knowable then. An RL environment, an agent tool and the terminal all read this one function.

### 6.8 Broker adapter (I9): one boundary for every exchange (revision 2)

- I9 talks to execution venues only through a `BrokerAdapter` protocol: `instrument(symbol) -> InstrumentRules`
  (`lot_size`, `tick`, `price_band_low`, `price_band_high`, `currency`, `trading_status`, `tradable`),
  `place(order) -> OrderAck`, `cancel(order_id)`, `order(order_id)`, `positions(account_id)`, `account(account_id)`,
  `fills(account_id, since)`. Orders and results use the contract 6.4 shapes, with `qty` in shares.
- Adapters are chosen per venue in I9's settings (`brokers.<venue>.adapter`). Shipped adapters: `mirror` (the
  built-in sandbox that matches orders against the I2 order book, see I9's README), `shadow` (I6 over contract
  6.4), `tbank-sandbox` (T-Bank SandboxService over REST). A new exchange or terminal is a new adapter class and
  a config entry; the MCP tools, budgets and risk checks do not change.

## 7. Testing

- `pytest` with `pytest-asyncio`, `hypothesis` for invariants, and `respx` to mock HTTP. Target at least 85%
  line coverage on `src/`; report it with `pytest-cov`.
- The default test run (`make test`) is fully offline, deterministic (fixed seeds) and under about 3 minutes on
  this laptop. It downloads no models and opens no network sockets except loopback. Gate live or exchange
  tests behind a marker (`-m live`) that is skipped by default.
- Test the maths against closed forms or published reference values, test contracts with schema round-trips,
  and test every failure path you claim to handle (gaps, leakage, budget breaches, rejects).

## 8. Deliverable and definition of done

The project briefs describe multi-month projects. Your job now is a solid v0.1: the Base functions working end
to end, plus each Unique feature implemented in a real, working first form, not as stubs. Where a feature truly
needs live data, GPUs or months of accumulation, build the full pipeline, prove it on synthetic or fixture data,
and say so in the README.

You are done when all of these hold:
1. `make setup && make lint && make typecheck && make test` passes from a clean clone (inside `.venv`).
2. `make reproduce` runs an offline end-to-end demo that writes outputs under `$TRADEQ_DATA_DIR/<repository>/`
   and prints a short summary.
3. The README opens with a one-paragraph claim, then quickstart, architecture, the contracts you produce and
   consume, results (with confidence intervals where statistical), limitations and roadmap, and a link back to
   the specification section.
4. Everything is committed in the project's own repository, and the working tree is clean.
5. Your final message reports: what was built, test and coverage numbers, any packages added beyond
   `constraints.txt` (with versions), contract extensions, known limitations, and the commit list
   (`git log --oneline`).

## 9. Market scope and computing priority (revision 2, 2026-10-29)

- The platform targets MOEX only (stocks on TQBR first). Crypto code that already exists may stay as an optional
  module where removing it would break a working feature, but no new crypto work is done, and defaults point at
  MOEX. Source facts are in `$ROOT/docs/moex-sources.md`; tokens come only from the environment
  (`TBANK_TOKEN` for T-Bank, `ALGOPACK_TOKEN` for AlgoPack; each project maps them into its own settings).
- No live token exists yet. Code against the documented payloads, test with hand-made fixtures that follow the
  documented shapes exactly, and gate every network test behind `-m live`.
- Data collection has the highest priority on any shared host. I1 collectors never wait on downstream work:
  their queues are bounded, overflow drops analytics and never capture, and every other long job (training,
  backtests, reports) runs at a lower OS priority (`nice`) and backs off when I1 reports queue pressure on its
  status endpoint.
- The repositories remain independent blocks: no imports across repositories, only the contracts above.
