---
id: S1
title: TSFM Arena + Rank-Tuned Finance FM
repository: tsfm-arena
path: ./tsfm-arena
package: tsfm_arena
track: Science
priority: A
default_port: 8604
depends_on: [I2, S6]
used_by: [I8, I9, I7, S8]
contracts_produced: "6.5 (forecast service)"
contracts_consumed: "6.1, 6.3"
spec_section: "quant_platform_plan_full.md, project S1"
conventions: ./00-platform-conventions.md
version: 2.0
date: 2026-10-29
---

# S1 - TSFM Arena + Rank-Tuned Finance FM

You are the sole developer of the `tsfm-arena` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Build a living, cutoff-aware benchmark of time-series foundation models on financial returns, scored by decision metrics instead of MSE, with a rank-tuned finance model.

## Revision 2 (2026-10-29): MOEX scope

Crypto in the quoted spec is deferred. The data source for the next run is the MOEX stock panel from I2 (`tape.candles` daily and intraday bars of TQBR stocks); the synthetic panel stays for tests. See `../docs/moex-sources.md` and section 5.4 of the spec.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/tsfm-arena/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/tsfm-arena/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `tsfm_arena`. Contracts you produce: 6.5 (forecast service). Contracts you consume: 6.1, 6.3.

- Model registry (`config/models.yaml`): each entry has an adapter, HF id or path, and a declared
  `pretraining_cutoff`. Adapters behind one `Forecaster` protocol (point + quantile forecasts): Chronos-2 /
  Chronos-Bolt via `chronos-forecasting`, Kronos (loaded from its published HF weights when available; adapter
  documented, optional), and strong baselines (random walk, historical mean, AR/ridge on lagged returns, a
  small PatchTST-style torch model). Model downloads go to the data root and never happen in tests.
- Rolling-origin evaluation that is cutoff-aware: an origin is eligible for a model only when
  `origin > pretraining_cutoff + embargo`. The leaderboard shows the eligible window per model.
- Metrics: MAE and CRPS (quantile-based) as secondary; primary are rank IC, ICIR, cost-adjusted long-short
  Sharpe (costs from config), and DSR. Every evaluated (model, config) is logged to S6 as a trial; the
  leaderboard shows the S6 verdict when available, otherwise a local DSR clearly labelled as such. Also
  measure cross-sectional "forecast collapse" (dispersion of forecasts vs realised).
- Rank-tuning: a cross-sectional ranking loss (pairwise logistic and ListNet, or a differentiable Spearman
  surrogate), LoRA/adapter fine-tuning via `peft` on Chronos, and a small from-scratch pretraining script for
  the "pretrain on finance" comparison. Tiny configs run in tests on CPU in seconds.
- Data sources behind a protocol: an I2 HTTP client (contract 6.3, with `known_at` = origin), plus local
  Parquet/CSV and a synthetic cross-section generator with planted, weak, decaying signal.
- `forecast-service`: FastAPI per contract 6.5.
- Leaderboard: generated Markdown + static HTML page with CIs (bootstrap over origins).
- `make reproduce`: synthetic cross-section of ~30 assets. Run the baselines and the tiny rank-tuned model
  through the arena (Chronos only when `TSFM_ALLOW_DOWNLOADS=true`), log trials, write the leaderboard.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### S1. Financial time-series foundation models

**Disputed question.** Do general pre-trained forecasters work on returns, and how should they be adapted?

[Rahimikia et al. (2025)](https://arxiv.org/abs/2511.18578v1), the first large study of TSFMs in global markets, found off-the-shelf models weak zero-shot and after fine-tuning, while pre-training from scratch on financial data gave substantial forecasting and economic gains. [Noguer i Alonso & Franklin (2026)](https://econpapers.repec.org/paper/arxpapers/2606.27100.htm) compared TimeGPT, TimesFM-2.5, Moirai-2.0, Chronos and Chronos-2 against NBEATS, NHITS, PatchTST, iTransformer and KAN on five US large caps and concluded TSFMs are useful priors, not alpha engines. [Forecast Collapse in TSFMs (2026)](https://www.alphaxiv.org/abs/2608.14106) shows models succeed on volume but fail on returns because of low signal-to-noise, and that per-series metrics hide failures in cross-sectional structure. A [Chronos study on daily index forecasting](https://isd2025.fon.bg.ac.rs/wp-content/uploads/ISD_2025_camera_ready_265.pdf) found only moderate returns.

**Analogs**

| Analog | Can | Cannot / limits |
|---|---|---|
| [Chronos](https://github.com/amazon-science/chronos-forecasting), [TimesFM](https://github.com/google-research/timesfm), [Moirai / uni2ts](https://github.com/SalesforceAIResearch/uni2ts) | Zero-shot probabilistic forecasting across domains | Not trained for low-SNR returns; per-series objectives; no control over pretraining-cutoff leakage |
| [Kronos](https://github.com/shiyu-coder/Kronos) ([AAAI paper](https://ojs.aaai.org/index.php/AAAI/article/download/39730/43691)) | Finance-native K-line tokenizer, trained on 45+ exchanges; forecasting, volatility, synthetic data; fine-tuning and backtest scripts | Context 512 for small/base; Kronos-large not released; OHLCV only; [its headline gains are zero-shot vs general models, not vs a tuned asset-specific quant model](https://themenonlab.blog/blog/kronos-foundation-model-financial-markets-candlestick) |
| [Nixtla neuralforecast](https://github.com/Nixtla/neuralforecast) | Strong supervised baselines | Generic losses and metrics |

**Gap.** No living benchmark that (a) evaluates each model only after its pretraining cutoff, (b) scores rank IC, cost-adjusted long-short Sharpe and deflated Sharpe instead of MSE, (c) covers crypto and intraday horizons.

**Project: TSFM Arena + Rank-Tuned Finance FM**
- Base functions: model loading, rolling-origin evaluation, point/quantile forecasts, MAE/CRPS, fine-tuning scripts.
- Unique: cutoff-aware evaluation (no analog enforces it); decision metrics first (addresses forecast collapse); LoRA/adapter fine-tuning of Kronos and Chronos with a cross-sectional ranking loss vs small from-scratch pretraining (tests the Rahimikia finding on crypto); monthly refreshed leaderboard on new data.
- Secondary: one API for all models, cached GPU serving.
- Platform: `forecast-service` (`/forecast`, `/rank`) used by the terminal (I8), agents (I9) and robots (I7).
- Deliverable: `tsfm-arena` repo, leaderboard page, tech report.
