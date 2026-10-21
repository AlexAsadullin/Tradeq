---
id: I2
title: Point-in-time Store
repository: point-in-time-store
path: ./point-in-time-store
package: pit_store
track: Infra core
priority: A
default_port: 8603
depends_on: [I1 tape files, S6 leakage endpoint]
used_by: [I5, I6, S1, S3, S7, S8, I9]
contracts_produced: "6.3"
contracts_consumed: "6.1 (leakage events), 6.2 (tape input)"
spec_section: "quant_platform_plan_full.md, project I2"
conventions: ./00-platform-conventions.md
version: 1.0
date: 2026-10-21
---

# I2 - Point-in-time Store

You are the sole developer of the `point-in-time-store` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Build the only data path for research: a bitemporal 'as-known-at T' store that refuses queries which would leak the future.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/point-in-time-store/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/point-in-time-store/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `pit_store`. Contracts you produce: 6.3. Contracts you consume: 6.1 (leakage events), 6.2 (tape input).

- Storage backend protocol with a full Parquet + DuckDB implementation (research and offline) under
  `$TRADEQ_DATA_DIR/point-in-time-store/`, and a QuestDB adapter for hot data (ILP/HTTP, URL from settings,
  integration test skipped unless a QuestDB is reachable).
- Dataset registry (`config/datasets.yaml`): key columns, valid-time column, knowledge-time rule, revision
  semantics. Built-in datasets: I1 tape channels (knowledge_time = `ts_local`), SEC XBRL company facts with
  restatements (knowledge_time = filing acceptance time; fetched from SEC's public JSON API, with the
  User-Agent from settings), ALFRED macro vintages (knowledge_time = `realtime_start`; API key from env), and
  text first-seen events (contract 6.5 JSONL).
- Ingestors for each built-in dataset. Network clients are fully mocked in tests with respx and recorded
  fixtures.
- `as_known_at` query engine: bitemporal filtering, latest revision per key as of T, as-of joins across
  datasets (e.g. price at T joined with the fundamentals known at T), in Python and over HTTP (contract 6.3,
  Arrow IPC + JSON).
- Leakage guard: reject or flag in research mode per contract; post `LeakageEvent` to S6 with the inbox-file
  fallback.
- Dataset fingerprints: a deterministic sha256 over the normalised query and the content hashes of the
  partitions it touched. They are stored and resolvable via `GET /v1/fingerprints/{fp}`.
- Feature store: declarative feature definitions (config + Python functions), point-in-time training set
  generation (as-of join, no future rows) and online "latest known" serving.
- CLI: `pit serve | ingest <dataset> | query | features build`.
- `make reproduce`: a synthetic company with two restatements and a macro series with three vintages. Show
  as-known-at results vs naive "latest" results, the backtest difference this causes, a rejected leaking
  query, and a fingerprint that reproduces exactly.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### I2. Point-in-time Store and Feature Store

| Analog | Can | Cannot / limits |
|---|---|---|
| [ArcticDB](https://github.com/man-group/ArcticDB) / [Arctic](https://pypi.org/project/arctic/1.9.0) (Man AHL) | Versioned DataFrames, tick store, [bitemporal storage to see how old data was revised](https://pypi.org/project/arctic/1.20.0) | Storage engine; no feature semantics or leakage checks |
| [QuestDB](https://github.com/questdb/questdb) | [Open SQL TSDB, Parquet tiering to object storage, open formats](https://questdb.com/compare/questdb-vs-kdb/); [~4M rows/s ingestion peak](https://db-engines.com/en/system/Kdb%3BQuestDB) | No as-of-knowledge semantics across data types |
| kdb+ | Industry standard for ticks | [Commercial; licence restricts publishing benchmarks](https://questdb.com/compare/questdb-vs-kdb/); steep learning curve |
| [fredapi / ALFRED](https://pypi.org/project/fredapi) | [Macro vintages: "latest data known on a given date"](https://pypi.org/project/fredapi) | Macro only |

**Gap.** Nothing joins market ticks, fundamentals (restatements), macro vintages and text first-seen timestamps under one "as-known-at" query, and refuses queries that would leak the future.

**Project: Point-in-time Store**
- Base: tick storage (QuestDB for hot, Parquet/ArcticDB for research), feature definitions, offline/online feature serving.
- Unique: bitemporal "as-known-at T" API across all data types (prices, XBRL fundamentals with restatements, ALFRED macro vintages, news first-seen times from I3); leakage guard that rejects or flags queries referencing data not yet known and reports this to S6; dataset fingerprints so every backtest is reproducible.
- Platform: the only data path for I5, I6, S-track services and agents.
