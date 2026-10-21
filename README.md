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

## Project repositories (priority-A wave)

The first wave is the top ten projects of the specification table (section 1.3). Each one is an independent git
repository in a subfolder of this workspace.

| ID | Project | Repository | Prompt | Port |
|---|---|---|---|---|
| S6 | Research Ledger: trial accounting, DSR/PBO gate | [research-ledger/](research-ledger/) | [01](prompts/01-research-ledger.md) | 8601 |
| I1 | Market Tape Recorder: crypto CEX/DEX + MOEX, quality-certified | [market-tape-recorder/](market-tape-recorder/) | [02](prompts/02-market-tape-recorder.md) | 8602 |
| I2 | Point-in-time Store: bitemporal "as-known-at" | [point-in-time-store/](point-in-time-store/) | [03](prompts/03-point-in-time-store.md) | 8603 |
| S1 | TSFM Arena + rank-tuned finance FM | [tsfm-arena/](tsfm-arena/) | [04](prompts/04-tsfm-arena.md) | 8604 |
| S7 | LLM leakage probe + TinyChrono | [llm-leakage-probe/](llm-leakage-probe/) | [05](prompts/05-llm-leakage-probe.md) | 8605 |
| I5 | Multi-fidelity backtest orchestrator | [backtest-orchestrator/](backtest-orchestrator/) | [06](prompts/06-backtest-orchestrator.md) | 8606 |
| S8 | Agent Arena | [agent-arena/](agent-arena/) | [07](prompts/07-agent-arena.md) | 8607 |
| I9 | Risk-gated MCP agent gateway | [risk-gated-mcp-gateway/](risk-gated-mcp-gateway/) | [08](prompts/08-risk-gated-mcp-gateway.md) | 8608 |
| S3 | Reactive crypto LOB simulator + sim-to-real gap score | [reactive-lob-sim/](reactive-lob-sim/) | [09](prompts/09-reactive-lob-sim.md) | 8609 |
| I6 | Shadow Exchange sandbox with micro/macro scenarios | [shadow-exchange/](shadow-exchange/) | [10](prompts/10-shadow-exchange.md) | 8610 |

## How the pieces connect

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
