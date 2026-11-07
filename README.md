# Tradeq

Tradeq is a full-cycle quant trading platform built as a portfolio of independent repositories. Most
open-source quant tooling competes on engines and models. Tradeq builds the validity and reality layer that
every human strategy, AI agent and trading robot must pass through:

- every trial is counted and deflated;
- data is served only "as known at T";
- fills are checked against real order books;
- agents share the same risk path as humans.

This repository is the umbrella. It holds the specification, the prompts each project was built from, the
shared dependency constraints, and links to the project repositories.

## Contents

| Path | What it is |
|---|---|
| [quant_platform_plan_full.md](quant_platform_plan_full.md) | The full specification (science track S1-S12, infrastructure track I1-I10, architecture, timeline) |
| [prompts/](prompts/) | Briefs given to each project's developer agent; each starts with a YAML header |
| [prompts/00-platform-conventions.md](prompts/00-platform-conventions.md) | Engineering rules and the cross-project contracts (HTTP and file) that all projects share |
| [constraints.txt](constraints.txt) | Newest mutually compatible library versions for the platform (Python 3.13), resolved from [constraints.in](constraints.in) |
| `data/` | The single data root (`TRADEQ_DATA_DIR`), shared by all projects, not versioned |

**Hackathon materials (in Russian):** [docs/hackathon/](docs/hackathon/README.md): architecture diagram, prototype with screenshots, calculations, research (docx), presentation (PDF); their build sources are in `docs/hackathon/src/`.

**Context for AI assistants:** [CLAUDE.md](CLAUDE.md) and [docs/claude/](docs/claude/README.md) hold the long-term memory of this workspace.

## Repository index

Each project subfolder is its own git repository; this umbrella repository ignores them and links them here.

| Folder | Repository | What it is |
|---|---|---|
| `research-ledger/` | [https://github.com/AlexAsadullin/research-ledger](https://github.com/AlexAsadullin/research-ledger) | S6: counts every trial on the platform, deflates Sharpe (DSR, PSR, PBO, MinTRL) and gates promotion to live |
| `market-tape-recorder/` | [https://github.com/AlexAsadullin/market-tape-recorder](https://github.com/AlexAsadullin/market-tape-recorder) | I1: records MOEX market data (T-Bank stream with key pinning, public ISS) with quality certificates per instrument-day; bulk history downloader |
| `point-in-time-store/` | [https://github.com/AlexAsadullin/point-in-time-store](https://github.com/AlexAsadullin/point-in-time-store) | I2: bitemporal "as known at T" store, the platform hub; leakage guard, market slice and its stream, Russian macro vintages |
| `tsfm-arena/` | [https://github.com/AlexAsadullin/tsfm-arena](https://github.com/AlexAsadullin/tsfm-arena) | S1: cutoff-aware benchmark of time-series foundation models on decision metrics, with rank-tuned fine-tuning |
| `llm-leakage-probe/` | [https://github.com/AlexAsadullin/llm-leakage-probe](https://github.com/AlexAsadullin/llm-leakage-probe) | S7: measures LLM look-ahead memorisation per entity and date; TinyChrono point-in-time language models |
| `backtest-orchestrator/` | [https://github.com/AlexAsadullin/backtest-orchestrator](https://github.com/AlexAsadullin/backtest-orchestrator) | I5: fidelity ladder over vectorbt, NautilusTrader, hftbacktest and the S3 simulator, with calibrated fills and parity checks |
| `agent-arena/` | [https://github.com/AlexAsadullin/agent-arena](https://github.com/AlexAsadullin/agent-arena) | S8: statistical leaderboard for LLM agents and quant baselines trading through the gateway |
| `risk-gated-mcp-gateway/` | [https://github.com/AlexAsadullin/risk-gated-mcp-gateway](https://github.com/AlexAsadullin/risk-gated-mcp-gateway) | I9: MCP server for AI agents with time-travel data, trial logging, budgets, pre-trade checks and the local mirror sandbox |
| `reactive-lob-sim/` | [https://github.com/AlexAsadullin/reactive-lob-sim](https://github.com/AlexAsadullin/reactive-lob-sim) | S3: reactive MOEX order-book simulator (auctions, bands, sessions) with a calibrated impact coupling and a sim-to-real gap score |
| `shadow-exchange/` | [https://github.com/AlexAsadullin/shadow-exchange](https://github.com/AlexAsadullin/shadow-exchange) | I6: shadow fills on real MOEX books with queue position and impact, micro and macro scenarios, T-Bank sandbox rules as a baseline |
| `research-terminal/` | [https://github.com/AlexAsadullin/research-terminal](https://github.com/AlexAsadullin/research-terminal) (private) | I8: TradingView-style web terminal for the whole platform (BFF on port 8611) |

Folders that belong to this umbrella repository:

| Folder | What it is |
|---|---|
| `prompts/` | the brief each project was built from; `00-platform-conventions.md` holds the shared rules, ports and contracts |
| `docs/` | `moex-sources.md` (T-Bank Invest API and MOEX AlgoPack/ISS summary), T-Invest contract notes, `hackathon/` materials, `claude/` context for AI assistants |
| `scripts/` | `download-all.sh`: downloads all MOEX history and loads it into I2 |
| `data/` | the shared data root (`TRADEQ_DATA_DIR`), not versioned |

## Project repositories

Each project is an independent git repository in a subfolder of this workspace, with a `README.md` and a
`.claude/HANDOVER.md` that hold its current state. The platform targets the Moscow Exchange (MOEX). T-Bank is
used for market data only, reached through key pinning; trading is local, in I9's mirror sandbox, at the
T-Invest commission (0.25% per fill, 0% for T-Capital funds). Crypto features are kept as optional modules
that are off.

| ID | Project | Repository | Tests (offline) | State and headline result (2026-11-06) |
|---|---|---|---|---|
| S6 | Research Ledger: trial accounting, DSR/PBO gate | [research-ledger/](research-ledger/) | 89 | Best of 200 noise strategies promoted in 100% of runs by single-test PSR, 0.0% by the ledger gate (synthetic) |
| I1 | Market Tape Recorder: MOEX via T-Bank (pinned) and ISS | [market-tape-recorder/](market-tape-recorder/) | 138 | Real captures since 2026-11-05; bulk history for 282 instruments: 829,744 day rows and 28.6 million 1-minute rows (12 months), 0 failed requests |
| I2 | Point-in-time Store: bitemporal "as-known-at", market slice | [point-in-time-store/](point-in-time-store/) | 92 | Real tape and candles ingested; slice p95 20 ms at the live edge; CBR key rate and CPI vintages |
| S1 | TSFM Arena + rank-tuned finance FM | [tsfm-arena/](tsfm-arena/) | 71 | Rank IC after cutoff: ridge 0.057, Chronos-Bolt 0.037, rank-tuned PatchTST 0.028 (synthetic) |
| S7 | LLM leakage probe + TinyChrono | [llm-leakage-probe/](llm-leakage-probe/) | 66 | Probe precision 0.894, recall 0.882 on planted leakage (synthetic) |
| I5 | Multi-fidelity backtest orchestrator | [backtest-orchestrator/](backtest-orchestrator/) | 88 + 1 integration | MOEX market: calibrated fill-probability error 0.015 vs 0.764 for touch fills; parity found 64/64 planted bugs |
| S8 | Agent Arena | [agent-arena/](agent-arena/) | 88 + 1 integration | One run per agent named the wrong winner in 51.7% of seasons, the arena protocol in 0.0% |
| I9 | Risk-gated MCP agent gateway | [risk-gated-mcp-gateway/](risk-gated-mcp-gateway/) | 107 + 1 integration | MOEX fakes: blocked 1,181/1,181 violations, 0/2,730 false refusals |
| S3 | Reactive MOEX LOB simulator + sim-to-real gap score | [reactive-lob-sim/](reactive-lob-sim/) | 55 | MOEX world: gap score of tape replay 0.133 (0.090 to 0.223) vs 0.328 to 0.523 for reactive simulators |
| I6 | Shadow Exchange sandbox (MOEX, offline T-Bank sandbox baseline) | [shadow-exchange/](shadow-exchange/) | 145 | Real T-Bank books: market-maker fill rate 0.517 queue-aware vs 0.238 under T-Bank sandbox rules; 10,000-lot LKOH order 26.84 bps vs 0.00 |
| I8 | Research terminal: TradingView-style web UI | [research-terminal/](research-terminal/) | 31 + 11 (UI) | v0.1: market, time travel, data health, integrity, agents, sandbox, RL placeholder (`rl/v1`) |

Research results are synthetic unless the row says otherwise. Not started: S4 (the RL agent; a separate
skeleton, `../tbank_rl`, exists outside this workspace), I3, I4, I7, I10, S2, S5, S9 to S12.

## Data

`scripts/download-all.sh` downloads all the history the platform needs and loads it into I2: the universe (TQBR
shares and MOEX-listed T-Capital funds), daily candles for the full history, 1-minute candles for the last 12
months, certificates, I2 ingest. It is resumable; `--smoke` runs three instruments. `cd point-in-time-store &&
.venv/bin/pit fetch-macro` adds the CBR key rate and CPI vintages. The T-Bank token lives only in the root and
`market-tape-recorder` `.env` files (both gitignored).

## Terminal

```bash
cd research-terminal && make setup && make reproduce   # UI on a mock world: http://127.0.0.1:8611
make serve                                             # the same UI against the running services
```

Ports are listed in [prompts/00-platform-conventions.md](prompts/00-platform-conventions.md), section 4 (I8 is 8611).

**Real-service integration.** Opt-in tests start the sibling services from their own `.venv` and check these
links:
- I9 against the real I2, I5 and S6;
- I5 against the real I2 and S6;
- S8 against the real I9.

## How the pieces connect

(I8, the terminal, reads every service below; S4, the RL agent, will observe the I2 slice and trade in the I9
mirror sandbox.)

```
I1 tape ──► I2 as-known-at store ──► S1 forecasts / S3 simulator / I5 backtests ──► S6 ledger (gate)
                    ▲                                                                   │
                    │                    S7 leakage audit ─────────────────────────────►│
   agents ──► I9 MCP gateway ──► I6 shadow exchange (fills ──► I5 calibration, S3 gap)   ▼
   S8 arena ──┘                                                            promotion to live (I7, later)
```

The contracts behind these arrows are defined once, in
[prompts/00-platform-conventions.md](prompts/00-platform-conventions.md) (section 6). The projects never import
each other's code. Each one ships typed clients and offline fallbacks, so it builds and tests on its own.

## Shared rules

- **Python 3.13 in a per-repository `.venv`** (created with `uv`). It is the newest Python that NautilusTrader
  supports with binary wheels.
- **One version set.** Each repository pins overlapping packages to exactly the versions in
  [constraints.txt](constraints.txt).
- **One data root.** All data goes under `TRADEQ_DATA_DIR`, in `data/<repository>/`. Copy `.env.example` to
  `.env` and set it.
- **No hardcoding.** Settings come from `config/settings.yaml` and environment variables; secrets come only from
  the environment.
- **Standard targets.** Every repository has `make setup lint typecheck test reproduce`; tests run offline.

## Working with a project

```bash
cd research-ledger        # any project folder
cp .env.example .env      # set TRADEQ_DATA_DIR to this workspace's data/ folder
make setup                # creates .venv and installs the locked dependencies
make test                 # offline test suite
make reproduce            # end-to-end demo; outputs go to $TRADEQ_DATA_DIR/<repository>/
```

## Updating the platform constraints

```bash
uv venv --python 3.13 .venv
VIRTUAL_ENV=.venv uv pip compile constraints.in --only-binary :all: -o constraints.txt
```

After that, bump the pins in each affected repository and run its tests.
