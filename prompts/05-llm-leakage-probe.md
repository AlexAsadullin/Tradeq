---
id: S7
title: LLM Leakage Probe + TinyChrono
repository: llm-leakage-probe
path: ./llm-leakage-probe
package: leakage_probe
track: Science
priority: A
default_port: 8605
depends_on: [S6, I3 corpus (contract 6.5)]
used_by: [S6, S8, I9]
contracts_produced: "6.5 (leakage probe)"
contracts_consumed: "6.1, 6.5 (text corpus)"
spec_section: "quant_platform_plan_full.md, project S7"
conventions: ./00-platform-conventions.md
version: 1.0
date: 2026-10-21
---

# S7 - LLM Leakage Probe + TinyChrono

You are the sole developer of the `llm-leakage-probe` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Measure how much an LLM's 'trading skill' is memorised outcomes, per entity and date, and provide point-in-time tiny language models that cannot know the future.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/llm-leakage-probe/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/llm-leakage-probe/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `leakage_probe`. Contracts you produce: 6.5 (leakage probe). Contracts you consume: 6.1, 6.5 (text corpus).

- Probe engine: for (entity, date) cells with known later outcomes (return sign or magnitude, events), run
  probe families: cloze completion of the outcome, date-shift contrasts, anonymisation contrast
  (Glasserman & Lin), and confidence/likelihood gap between the true and counterfactual outcome. Aggregate into a
  memorisation score per cell with a calibrated threshold (set from a null where outcomes are randomised).
  Write the heat-map data plus a PNG/HTML rendering.
- Bilingual templates (English + Chinese, Russian extensible) in `config/templates/*.yaml`. No prompt strings
  in code.
- Model backends behind a protocol: local HF `transformers` causal LMs (log-likelihood access), and an
  OpenAI-compatible HTTP endpoint (vLLM / llama.cpp server; base URL and key from settings) using logprobs
  where offered.
- Bias budget: given strategy returns under raw, anonymised and post-cutoff conditions, decompose the return
  into memorisation, distraction and residual with bootstrap CIs.
- Output: `LeakageReport` per contract 6.5, written to the data root and posted to S6 (`POST /v1/leakage`,
  inbox fallback). FastAPI `POST /v1/probe`.
- TinyChrono pipeline: corpus builder from time-stamped JSONL with strict `first_seen < cutoff` filtering
  (quarterly cutoffs 2020Q1-2026Q3 from config); tokenizer training; a decoder-only training loop
  (`transformers` + `accelerate`) with size presets 50M/150M/300M; and model-card generation recording the cutoff
  and corpus fingerprint. Tests use a ~1M-parameter preset for a few steps on CPU.
- `make reproduce`: a self-validating demo. Build a synthetic corpus in which some "future" facts are planted
  before the cutoff for half the entities. Train a tiny TinyChrono, run the probe, and show that the planted
  cells are flagged and the clean cells are not (report precision and recall).

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### S7. LLM look-ahead leakage and point-in-time language models

[Glasserman & Lin](https://www.alphaxiv.org/abs/2309.17322v1) found that in-sample, a "distraction effect" from company knowledge outweighed look-ahead, and proposed anonymisation. [Look-Ahead-Bench (2026)](https://hedgefundalpha.com/education/your-llms-alpha-might-be-mere-memorization/) shows severe bias across training-cutoff boundaries. [FinCAD (2026)](https://arxiv.org/abs/2605.24564) suppresses memory at inference time, cutting in-sample backtest returns by up to 67% on memorised dates while leaving 2025 out-of-sample results near baseline. [ChronoBERT/ChronoGPT](https://arxiv.org/html/2502.21206v3) train one model per year with cutoffs 1999-2024 and [find look-ahead bias modest for next-day news-return prediction](https://www.eco.usi.ch/en/node/9794). A [2026 position paper](https://www.arxiv.org/pdf/2602.14233) lists look-ahead, survivorship, narrative, objective and cost biases across 164 papers.

| Analog | Can | Cannot / limits |
|---|---|---|
| ChronoBERT / ChronoGPT | Leak-free yearly models | Yearly granularity; cutoffs end 2024; no crypto focus; not tiny fast decoders |
| FinCAD | Inference-time debiasing | Needs a learned memory-activating prompt per model; five mega-caps |
| Anonymisation | Simple debiasing | Does not remove date or numeric memorisation |
| Chinese financial LLMs: [Tongyi-Finance-14B](https://proginn.com/w/1545171) (ModelScope; base, chat, Int4), [DISC-FinLLM](https://arxiv.org/abs/2310.15205v1), [XuanYuan, CFGPT](https://arxiv.org/pdf/2308.09975) | Open weights; Tongyi-Finance extends Qwen-14B with a finance vocabulary, and [FinQwen describes its training on 200B tokens of reports, news and forums](https://www.sourcepulse.org/projects/1844832) | No documented point-in-time cutoffs; [Tongyi-Finance-14B trails its general base Qwen-14B on CFLUE](https://benchmarklist.com/benchmarks/cflue/), so domain tuning is not automatically a win |
| Chinese benchmarks: [CFLUE](https://aclanthology.org/2024.findings-acl.337/) (Alibaba; 38K exam questions + 16K NLP task instances; [code](https://github.com/aliyun/cflue)), [FinEval, CFinBench, CFBenchmark](https://arxiv.org/pdf/2407.02301) | Knowledge and NLP-task evaluation in Chinese | Static exams and tasks; none measures look-ahead leakage or trading value |

**Project: Leakage Probe + TinyChrono**
- Unique: per-(entity, date) memorisation heat-map for the exact backtest window, written to S6 as a leakage flag; bilingual probe (English + Chinese, extensible to Russian) run on both Western and Chinese open-weight models, since memorisation of A-share or MOEX outcomes has not been measured by any of the analogs above; TinyChrono, 50M-300M decoder models with quarterly cutoffs 2020Q1-2026Q3 on time-stamped news, filings and crypto text (from I3); "bias budget" report decomposing LLM-strategy returns into memorisation, distraction and residual.
- Covers the requested Tiny LLM and LLM fine-tuning themes with a real research purpose.
- Deliverable: `llm-leakage-probe`, `tinychrono` model cards, report.
