---
id: I9
title: Risk-gated MCP Agent Gateway
repository: risk-gated-mcp-gateway
path: ./risk-gated-mcp-gateway
package: mcp_gateway
track: Infra
priority: A
default_port: 8608
depends_on: [I2, S1, I5, S6, S7, I6, I7]
used_by: [S8, external agents]
contracts_produced: "6.6"
contracts_consumed: "6.1, 6.3, 6.4, 6.5"
spec_section: "quant_platform_plan_full.md, project I9"
conventions: ./00-platform-conventions.md
version: 1.0
date: 2026-10-21
---

# I9 - Risk-gated MCP Agent Gateway

You are the sole developer of the `risk-gated-mcp-gateway` repository, part of the Tradeq full-cycle quant trading platform.

**Mission.** Give AI agents one MCP door to the platform, with time-travel-safe data, every idea counted as a trial, per-agent budgets, and orders only through the shared risk path.

## Before you write code

1. Read `/Users/alexasadullin/PycharmProjects/Tradeq/prompts/00-platform-conventions.md` in full. It defines the
   engineering rules (Python 3.13, `.venv` via uv, pins from `constraints.txt`, the single data root
   `TRADEQ_DATA_DIR`, no hardcoding, testing, definition of done) and the cross-project contracts you must
   produce and consume.
2. Read sections 1 and 5 of `/Users/alexasadullin/PycharmProjects/Tradeq/quant_platform_plan_full.md` for how
   your project fits the platform. Your own section is quoted verbatim below.
3. Work only inside `/Users/alexasadullin/PycharmProjects/Tradeq/risk-gated-mcp-gateway/` (create it, `git init -b main`), plus
   your data subtree `$TRADEQ_DATA_DIR/risk-gated-mcp-gateway/`, with `TRADEQ_DATA_DIR=/Users/alexasadullin/PycharmProjects/Tradeq/data`.

## v0.1 scope (what to build now)

Package name: `mcp_gateway`. Contracts you produce: 6.6. Contracts you consume: 6.1, 6.3, 6.4, 6.5.

- MCP server (the `mcp` SDK) exposing exactly the contract 6.6 tools, with JSON-schema'd inputs and outputs,
  over streamable HTTP and stdio. Tool descriptions are written for LLMs: concise, with units.
- Sessions and modes: `research` (time travel: every data, feature, forecast and backtest call is pinned to the
  session's `known_at`; agents can never pass or advance it), `paper` (orders routed to I6), `live` (routed to
  I7; disabled unless config enables it and the S6 verdict passes and the S7 leakage report is clean).
- Admin HTTP API per contract (admin key from env; agent API keys stored hashed). Sessions persist under the
  data root.
- Budgets per agent: capital, max drawdown, max order notional, order rate, token spend (via `report_usage`)
  and latency. When a budget is breached, tools return structured refusals and the session freezes; all of
  this is config-driven.
- Every `run_backtest` and every order intent is logged as a trial/idea to S6 (inbox fallback). `verdict`
  proxies S6.
- Pre-trade checks before forwarding to I6/I7: instrument whitelist, notional, position limits and fat-finger
  price bands from config. Every decision is written to an append-only audit log.
- Typed downstream clients for I2, S1, I5, S6, S7, I6 and I7, all mocked with respx in tests.
- `make reproduce`: start the gateway against in-process fakes of the downstream services, run a scripted agent
  session, and show a time-travel refusal, a logged backtest trial, a budget breach that freezes the session,
  and a paper order reaching the fake I6. Print the audit log.

Prefer depth over breadth: each item above should really work and be tested. If something must be cut to keep
quality, cut the least central item, and list it under "Roadmap" in the README with the reason.

## Specification (verbatim from the platform plan)

### I9. Risk-gated MCP agent gateway

| Analog | Can | Cannot / limits |
|---|---|---|
| [Alpaca MCP](https://alpaca.markets/blog/introducing-official-mcp-server-enabling-multi-market-trading-with-ai-interfaces/) | Equities, ETFs, crypto, options for agents; [toolset filtering and paper trading](https://alpaca.markets/agentic) | Broker-specific; no research validity |
| [laukikk/alpaca-mcp](https://enterprisedna.co/directories/mcp/laukikk-alpaca-mcp) | Lightweight Alpaca wrapper | No risk management or validation |
| [CPZAI MCP](https://github.com/CPZ-Lab/cpzai-mcp-server) | Strategies, backtests, multi-broker routing (Alpaca/IBKR/FIX), OAuth | Commercial backend |
| [OpenQuant](https://github.com/mitchellbernstein/openquant) | Agents + MCP + paper/Alpaca/Kalshi | Proof of concept |
| [Quiver MCP](https://glama.ai/mcp/servers/wru0penxe3), [EdgarTools MCP](https://glama.ai/mcp/servers/sareegpt/edgartools-mcp) | Data tools for agents | Read-only data |

**Project: Risk-gated MCP Gateway**
- Base: MCP tools for data, forecasts, backtests, orders.
- Unique:
  1. Time-travel enforcement: in research mode every data tool answers "as known at T" (I2), so agent backtests cannot leak the future.
  2. Every agent idea and backtest auto-logged as a trial in S6.
  3. Per-agent budgets for capital, drawdown, token spend and latency; orders go through I7 and start in I6.
  4. Leakage report (S7) attached to any LLM-driven strategy before promotion.
