---
id: S6
title: Research Ledger
repository: research-ledger
path: ./research-ledger
package: research_ledger
track: Science core
priority: A
default_port: 8601
depends_on: []
used_by: [I5, S1, S3, S7, S8, I9, I2, I7]
contracts_produced: "6.1"
contracts_consumed: "none"
spec_section: "quant_platform_plan_full.md, project S6"
conventions: ./00-platform-conventions.md
version: 1.0
date: 2026-10-21
---

# S6 - Research Ledger

You are the sole developer of the `research-ledger` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Build the statistical gate of the whole platform: every experiment, from any source, becomes a counted trial, and nothing is promoted without a deflated verdict.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/research-ledger/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/research-ledger/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `research_ledger`. Contracts you produce: 6.1. Contracts you consume: none.

- `stats/`: Sharpe with autocorrelation-aware standard error, PSR, DSR (Bailey & Lopez de Prado 2014: expected
  maximum Sharpe from N trials and the cross-trial Sharpe variance), MinTRL, PBO via CSCV (Bailey et al. 2017),
  CPCV split generator with purging and embargo, walk-forward splits, and performance stats (Sharpe, Sortino,
  max drawdown, Calmar, skew, kurtosis, hit rate, turnover if supplied). Test against worked examples from the
  papers and against Monte Carlo under the null.
- `effective_trials/`: estimate the effective number of independent trials by clustering trial return streams
  (correlation distance + hierarchical clustering with silhouette selection, or the ONC algorithm) and by an
  eigenvalue-based estimator. Report both, with documented choices. N_eff, not N, feeds the DSR.
- `store/`: a DuckDB database under `$TRADEQ_DATA_DIR/research-ledger/` holding trials, families, strategies,
  verdicts, leakage events and overrides. Append-only audit log.
- `sdk/`: a small client that other projects could vendor: `log_trial(...)`, a `trial()` context manager, and
  HTTP transport with automatic fallback to the inbox file (contract 6.1). Inbox ingestion is idempotent by
  `trial_id`.
- `gate/`: promotion policy from config (min DSR, max PBO, min track record vs MinTRL, leakage `block` flags).
  It returns the `Verdict` with human-readable reasons. Capital tiers are config-driven. Overrides require a
  reason and are always logged.
- `service/`: the FastAPI app implementing contract 6.1, plus `GET /v1/families/{family}` summaries.
- CLI: `ledger serve | ingest-inbox | verdict <strategy_id> | report <family>`.
- `make reproduce`: a synthetic "counting the trials" study. Generate K noise strategies plus one with real
  edge, log them through the SDK, and show how the best raw Sharpe compares with DSR as K grows, and how
  correlated sweeps shrink N_eff. Write a Markdown report with confidence intervals.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### S6. Backtest validity and overfitting statistics (platform core)

The formulas exist: [Deflated Sharpe Ratio](https://www.luxalgo.com/library/concept/deflated-sharpe-ratio.md), PSR, PBO via CSCV, MinTRL. Implementations: [pypbo](https://github.com/esvhd/pypbo) (its TODO still lists optimal N trials and Harvey-Liu thresholds), [R package pbo](https://mirror.linux.duke.edu/pub/cran/web/packages/pbo/pbo.pdf), [qf-lib's OverfittingAnalysis](https://qf-lib.readthedocs.io/en/stable/_modules/qf_lib/analysis/backtests_overfitting/overfitting_analysis.html), [AlphaEngine](https://pypi.org/project/alphaengine/0.1.0/) (sweep plus deflation verdict; open layer of a commercial platform), [Go insyra/quant](https://pkg.go.dev/github.com/HazelnutParadise/insyra/quant), [skfolio's CV](https://arxiv.org/abs/2507.04176v1), and [VectorBT PRO's purged/combinatorial CV (paid)](https://vectorbt.pro/). A [Kestra blueprint](https://kestra.io/blueprints/backtest-overfitting-guard) gates publication on DSR and PBO, showing demand for this as a pipeline step.

| Analog | Can | Cannot / limits |
|---|---|---|
| pypbo, R pbo, qf-lib | PBO, PSR, DSR, MinTRL | User must assemble the trial matrix by hand |
| AlphaEngine | Sweep + deflation verdict | Counts only trials inside its own sweep |
| VectorBT PRO | Purged CV, robustness checks | Proprietary; per-library, not platform-wide |

**Gap.** No open tool captures every experiment across a platform (notebooks, sweeps, RL seeds, agent ideas, miner candidates), estimates effective trials, and hard-gates promotion to live.

**Project: Research Ledger**
- Base: DSR, PSR, PBO/CSCV, CPCV, MinTRL, walk-forward, performance stats.
- Unique: automatic trial capture via SDK hooks in I5, S4, S5 and S8; effective-trials estimation by clustering trial return streams; promotion gate enforced by I7 (no live trading without passing thresholds; overrides logged); leakage hooks from I2 and S7; agents receive verdicts as tool results.
- Deliverable: `research-ledger` (SDK + service) + report "Counting the trials an AI research agent really runs".
