# Project overview

## What Tradeq is

Tradeq is a quant trading platform for the Moscow Exchange (MOEX), built as a portfolio of independent
repositories. It does not compete on engines or models. It builds the **validity layer** that every strategy
of a human, a trading robot or an LLM agent must pass before it gets real money:

1. every trial is counted, and Sharpe is deflated by the effective number of trials (no overfitting by search);
2. data is served only "as known at T" (no look-ahead, no restated data);
3. fills are checked against real order books with a queue model (no ideal or sandbox fills);
4. LLM backtests are audited for memorised outcomes (no leakage through model memory);
5. agents trade through the same budgets and pre-trade checks as humans (MCP gateway).

Pitch line used in the hackathon: "Проверка стратегий и AI-агентов до выхода на реальный счет". Together the
modules form an **incubator for AI agents**: a strategy is tested, admitted by a formal criterion and only
then deployed.

**Admission criterion** (research ledger gate): DSR ≥ 0.95 with N_eff and HAC standard errors, PBO ≤ 0.2
(CSCV, 16 blocks), track record T ≥ MinTRL, zero leakage flags. All metrics are computed after the 0.25%
commission and after the queue execution model.

## Workspace

- Root: `/Users/alexasadullin/PycharmProjects/Tradeq` (umbrella repo, public:
  https://github.com/AlexAsadullin/Tradeq). It holds the spec, prompts, constraints, docs and scripts. The
  project folders are separate git repos and are gitignored by the umbrella.
- Specification: `quant_platform_plan_full.md` (science track S1–S12, infrastructure track I1–I10,
  architecture, section 1.3 status table, section 5.4 real-time RL loop).
- `PLAN-moex.md`: the checklist of the MOEX pivot (2026-10-29) and the 2026-11-05/06 pass.
- `prompts/`: the brief each repo was built from; `00-platform-conventions.md` defines shared rules, ports and
  HTTP/file contracts (section 6). `11-readme-and-research-report-standards.md` defines doc standards.
- `docs/moex-sources.md`: T-Bank Invest API and MOEX AlgoPack/ISS summary; `docs/tinvest-contracts/*.proto`.
- `scripts/download-all.sh`: downloads all MOEX history into I2 (see data-and-tbank.md).
- `docs/hackathon/`: T-Bank hackathon materials (Russian); `docs/hackathon/src/` their build sources.
- `data/` (gitignored, about 3.6 GB on 2026-11-07): the shared data root `TRADEQ_DATA_DIR`.
- `../tbank_rl` (outside the workspace): an older RL skeleton, not part of Tradeq yet.

## The 11 repositories

All under https://github.com/AlexAsadullin/<repo>. All public except `research-terminal` (private; the user
must switch it to public manually, the tool was not allowed to create a public repo).

| ID | Repo | Port | Package | What it does | Offline tests |
|---|---|---|---|---|---|
| S6 | research-ledger | 8601 | research_ledger | Counts every trial, DSR/PSR/PBO/MinTRL, N_eff, promotion gate, audit log (DuckDB) | 89 |
| I1 | market-tape-recorder | 8602 | tape_recorder | Records MOEX data (T-Bank stream with SPKI pinning, ISS), certificates per instrument-day, bulk history | 138 |
| I2 | point-in-time-store | 8603 | pit_store | Bitemporal store (valid time + knowledge time), leakage guard, market slice + stream, macro vintages; the hub | 92 |
| S1 | tsfm-arena | 8604 | tsfm_arena | Cutoff-aware benchmark of time-series foundation models on decision metrics; rank-tuned PatchTST | 71 |
| S7 | llm-leakage-probe | 8605 | leakage_probe | Measures LLM memorisation per (entity, date); TinyChrono point-in-time tiny LMs | 66 |
| I5 | backtest-orchestrator | 8606 | bt_orchestrator | Fidelity ladder over vectorbt, NautilusTrader, hftbacktest and S3; calibrated fills; parity checks | 88 + 1 integration |
| S8 | agent-arena | 8607 | agent_arena | Statistical leaderboard for LLM agents and baselines trading through I9 | 88 + 1 integration |
| I9 | risk-gated-mcp-gateway | 8608 | mcp_gateway | MCP server for agents: session clock, trial logging, budgets, pre-trade checks, local mirror sandbox | 107 + 1 integration |
| S3 | reactive-lob-sim | 8609 | reactive_lob_sim | Reactive MOEX order-book simulator (lots, ticks, bands, auctions, halts), impact κ, sim-to-real gap G | 55 |
| I6 | shadow-exchange | 8610 | shadow_exchange | Shadow fills on real MOEX books, queue position, impact, latency; offline T-Bank sandbox rules as baseline | 145 |
| I8 | research-terminal | 8611 | research_terminal | TradingView-style web UI (React, lightweight-charts) + FastAPI BFF; mock world; RL placeholder `rl/v1` | 31 + 11 UI |

Env prefixes: LEDGER_, TAPE_, PIT_, TSFM_, LEAKAGE_, BT_, ARENA_, GATEWAY_, SIM_, SHADOW_, TERMINAL_.

Status (section 1.3 of the spec, 2026-11-06): S6, S1 v0.1; S7 partly done; I5, S8, I9, S3, I6 v0.2 MOEX; I1,
I2 v0.3 on real data; I8 v0.1. Not started: S4 (RL agent), S2, S5, S9–S12, I3, I4, I7, I10. Research results
in module reports are synthetic unless stated otherwise.

## How the pieces connect

```
I1 tape ──► I2 as-known-at store ──► S1 forecasts / S3 simulator / I5 backtests ──► S6 ledger (gate)
                    ▲                                                                   │
                    │                    S7 leakage audit ─────────────────────────────►│
   agents ──► I9 MCP gateway ──► I6 shadow exchange (fills ──► I5 calibration, S3 gap)   ▼
   S8 arena ──┘                                                            promotion to live (I7, later)
```

I8 reads every service. S4, the future RL agent, will observe the I2 market slice and trade in the I9 mirror
sandbox through the `rl/v1` contract (defined in research-terminal `docs/rl-api-contract.md`). Repos never
import each other's code; each ships typed clients and offline fallbacks. Opt-in integration tests: I9 against
real I2, I5, S6; I5 against real I2, S6; S8 against real I9.

## Stack

Python 3.13 (newest with NautilusTrader wheels), uv, per-repo `.venv`, FastAPI, pydantic-settings, DuckDB,
Polars, PyArrow, NumPy/SciPy, scikit-learn, Numba, PyTorch, transformers, chronos-forecasting, peft, vectorbt,
NautilusTrader, hftbacktest, MCP SDK, structlog, typer; React + lightweight-charts for the terminal. Shared
pins in `constraints.txt` (resolved from `constraints.in`).
