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
repository in a subfolder of this workspace. Each repository has:

- a v0.1 that runs end to end;
- `docs/report.md`, a research report whose numbers `make report` reproduces;
- `.claude/HANDOVER.md`, with its goal, architecture, state and the mistakes made.

All results so far come from synthetic data, because no recorded market data exists yet.

| ID | Project | Repository | Prompt | Tests | Headline result (synthetic data, 95% CI unless stated) |
|---|---|---|---|---|---|
| S6 | Research Ledger: trial accounting, DSR/PBO gate | [research-ledger/](research-ledger/) | [01](prompts/01-research-ledger.md) | 89 | Best of 200 noise strategies promoted in 8.0% (5.4 to 11.6) of runs by single-test PSR, 0.0% (0.0 to 1.3) by the ledger gate |
| I1 | Market Tape Recorder: crypto CEX/DEX + MOEX, quality-certified | [market-tape-recorder/](market-tape-recorder/) | [02](prompts/02-market-tape-recorder.md) | 83 | Certificates caught 600 of 600 injected faults per type with 0 false alarms in 600 clean runs; overlapping reconnects lost 0 trades against 75 for naive ones |
| I2 | Point-in-time Store: bitemporal "as-known-at" | [point-in-time-store/](point-in-time-store/) | [03](prompts/03-point-in-time-store.md) | 72 | A naive "latest data" backtest overstates the Sharpe ratio by 0.71 (0.67 to 0.76); 1484 of 1484 leaking queries refused |
| S1 | TSFM Arena + rank-tuned finance FM | [tsfm-arena/](tsfm-arena/) | [04](prompts/04-tsfm-arena.md) | 71 | Rank IC after the model cutoff: ridge on 10 lags 0.057, Chronos-Bolt zero-shot 0.037, rank-tuned PatchTST 0.028 (90% CI) |
| S7 | LLM leakage probe + TinyChrono | [llm-leakage-probe/](llm-leakage-probe/) | [05](prompts/05-llm-leakage-probe.md) | 66 | Combined probe precision 0.894 (0.833 to 0.935) and recall 0.882 (0.819 to 0.925) on planted leakage; anonymisation alone recalls 0.375 |
| I5 | Multi-fidelity backtest orchestrator | [backtest-orchestrator/](backtest-orchestrator/) | [06](prompts/06-backtest-orchestrator.md) | 76 | Calibrated fill-probability error 0.021 against 0.752 for touch fills; parity check found 64 of 64 planted engine bugs |
| S8 | Agent Arena | [agent-arena/](agent-arena/) | [07](prompts/07-agent-arena.md) | 81 | One run per agent named the wrong winner in 51.7% (46.0 to 57.3) of seasons; the arena protocol in 0.0% (0.0 to 1.3) |
| I9 | Risk-gated MCP agent gateway | [risk-gated-mcp-gateway/](risk-gated-mcp-gateway/) | [08](prompts/08-risk-gated-mcp-gateway.md) | 73 | Blocked 1225 of 1225 adversarial violations with 0 of 2686 false refusals; an unguarded wrapper blocked none |
| S3 | Reactive crypto LOB simulator + sim-to-real gap score | [reactive-lob-sim/](reactive-lob-sim/) | [09](prompts/09-reactive-lob-sim.md) | 43 | Gap score of tape replay 0.115 (0.075 to 0.191) against 0.285 to 0.383 for the generative and agent-based simulators |
| I6 | Shadow Exchange sandbox with micro/macro scenarios | [shadow-exchange/](shadow-exchange/) | [10](prompts/10-shadow-exchange.md) | 84 | Testnet-style ideal fills credit a market maker with 3137 USDT/day against 865 for queue-aware fills; 15 ms latency turns this into a loss of 900 |

Ports are listed in [prompts/00-platform-conventions.md](prompts/00-platform-conventions.md), section 4.

**Real-service integration.** Opt-in tests start the sibling services from their own `.venv` and check these
links:
- I9 against the real I2 and S6;
- I5 against the real I2 and S6;
- S8 against the real I9.

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
