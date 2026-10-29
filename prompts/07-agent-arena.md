---
id: S8
title: Agent Arena
repository: agent-arena
path: ./agent-arena
package: agent_arena
track: Science
priority: A
default_port: 8607
depends_on: [I9, S6, S7]
used_by: [I8 (leaderboard), reports]
contracts_produced: "leaderboard artefacts"
contracts_consumed: "6.1, 6.5 (leakage), 6.6"
spec_section: "quant_platform_plan_full.md, project S8"
conventions: ./00-platform-conventions.md
version: 2.0
date: 2026-10-29
---

# S8 - Agent Arena

You are the sole developer of the `agent-arena` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Evaluate LLM trading agents with statistics that hold up: deflated, bootstrapped, net-of-intelligence-cost, through the same risk path as humans.

## Revision 2 (2026-10-29): MOEX scope

Agents trade MOEX stocks through I9, whose default broker is the mirror sandbox (contract 6.8). The arena's main use is strategy against strategy (quant baselines, RL policies, scripted agents); real LLM agents are optional and capped by a token budget, because every bar of every run would otherwise be an LLM call. See `../docs/moex-sources.md` and section 5.4 of the spec.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/agent-arena/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/agent-arena/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `agent_arena`. Contracts you produce: leaderboard artefacts. Contracts you consume: 6.1, 6.5 (leakage), 6.6.

- Arena runner: seasons -> episodes -> steps. It drives the I9 gateway as an MCP client (contract 6.6) and uses
  the admin HTTP API to create sessions and advance the clock. A complete in-process fake gateway implementing
  the same MCP tool contract (built with the `mcp` SDK, in-memory transport) is used in tests and the offline
  demo.
- Agents behind one protocol: LLM agents (provider adapters for an OpenAI-compatible endpoint and the
  Anthropic API; model ids, prices and endpoints all in config), prompt variants from config templates, and quant
  baselines (buy-and-hold, time-series momentum, mean reversion, random) competing under the same rules. A
  deterministic scripted LLM double drives the tests.
- Accounting: net-of-intelligence-cost PnL. Token costs come from the configured price table; latency is charged
  through a configurable delay/slippage model. Budgets are respected via the gateway.
- Statistical leaderboard: deflated Sharpe (via the S6 verdict, with a clearly labelled local fallback),
  bootstrap CIs across seeds x prompt variants x episodes, pairwise win probabilities (bootstrap and
  Bradley-Terry), and significance against baselines.
- Behavioural diagnostics: over-trading (turnover vs baseline), consistency (decision agreement across seeds
  and prompt variants), sizing discipline (limit hits, concentration, martingale patterns) and refusal/error
  rate.
- Every agent run logged to S6; S7 leakage report requested per LLM agent (contract 6.5 client, offline
  fallback that marks "not audited").
- Output: Markdown + static HTML leaderboard under the data root; CLI `arena run-season | leaderboard | report`.
- `make reproduce`: a synthetic season with 3 scripted "LLM" agents of different behaviour, plus the baselines,
  across seeds and prompt variants against the fake gateway, producing the full leaderboard.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### S8. LLM trading agents and live evaluation

[TradingAgents](https://github.com/TauricResearch/TradingAgents) ([paper](https://arxiv.org/html/2412.20138v4)) simulates a trading firm with analysts, bull/bear debate, trader and risk manager; [a third-party review](https://x-cmd.com/install/tradingagents) notes costs scale with agents and advises skipping it if you need reproducible decisions. [LiveTradeBench](https://arxiv.org/html/2511.03628v1) ran 50-day live evaluations of 21 LLMs and found [high LMArena scores do not imply better trading](https://huggingface.co/papers/2511.03628). [FinBen](https://nips.cc/virtual/2024/poster/97525) includes stock-trading and agent tasks. In [Alpha Arena Season 1](https://forklog.com/en/four-out-of-six-ai-models-suffer-losses-in-trading-tournament/), four of six models lost money and the organiser noted LLMs handle numeric time series poorly; commentators stressed [results are regime-dependent and not statistically significant](https://www.innobu.com/en/articles/ai-trading-competition-chinese-llms-investors.html). Later seasons on US tech stocks lost about a third overall, with [only 6 of 32 runs profitable and trade counts varying from 158 to 1,418 under identical prompts](https://wallstreetcn.com/articles/3771681).

| Analog | Can | Cannot / limits |
|---|---|---|
| TradingAgents | Role-based multi-agent decisions | Non-deterministic, costly, daily, backtests exposed to look-ahead |
| LiveTradeBench | Live leak-free evaluation | Fixed agent template, no cost/latency economics |
| Alpha Arena | Real-money public test | Few runs, no significance |
| [OpenQuant](https://github.com/mitchellbernstein/openquant) | Agents + paper trading + MCP | Proof of concept; no statistical evaluation |

**Project: Agent Arena**
- Unique: statistical leaderboard (deflated Sharpe, bootstrap CIs across seeds and prompt variants, pairwise win probabilities); net-of-intelligence-cost PnL (tokens and latency charged); agents connect through I9 with the same risk path as humans; behavioural diagnostics (over-trading, consistency, sizing discipline); quant baselines compete under the same rules; automatic S7 leakage report.
- Deliverable: `agent-arena` + quarterly report.
