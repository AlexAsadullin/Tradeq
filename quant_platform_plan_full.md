# Full-Cycle Quant Trading Platform: GitHub Portfolio and Development Plan

Unified document: Part 1 (science track) + Part 2 (trading infrastructure track) + Eastern ecosystem review (section 2.1). October 2026.

Goal: a portfolio of GitHub projects that supports a smooth move from data science to quant trading, and that together form one platform with access for humans, AI agents and trading robots.

**Revision of 2026-10-29: MOEX focus and the real-time RL loop.** The platform now targets one market, the Moscow Exchange (stocks on the TQBR board first). Crypto venues are out of scope until further notice; crypto-specific parts of the sections below (Binance/Bybit/OKX/Hyperliquid capture, funding and liquidations, on-chain wallets, crypto options) are deferred, not deleted. Market data comes from two sources: the T-Bank Invest API (free token, free sandbox, real-time streams; used first) and MOEX AlgoPack (paid token; 20-level order books, all trades, Super Candles). Their documented interfaces are summarised in [docs/moex-sources.md](docs/moex-sources.md). The repositories stay independent blocks that any project can reuse, and together they form a real-time reinforcement-learning system: it records the live market, stores it "as known at T", trains an RL trading agent on history and on live data, and tests the agent on both, in a sandbox that mirrors the real market before any external broker. The Point-in-time Store (I2) is the central module, and it also feeds a real-time terminal with a slice of every metric at one moment. Computing priority goes to data collection first. Section 5.4 describes the loop.

---

## Contents

1. Executive summary
2. Method and rules
3. Part 1 - Science track (S1-S12)
4. Part 2 - Infrastructure track (I1-I10)
5. Platform architecture and user experience (5.4: the real-time RL loop)
6. Unified timeline
7. Prioritisation and career angle

Rule used throughout: a "unique feature" must contain at least one substantive differentiator (a new method, metric, guarantee, data domain, or a capability no analog has). "Faster", "all in one place" and "better UI" appear only as secondary benefits.

---

## 1. Executive summary

### 1.1 Main finding of the research

In both tracks the open-source landscape is crowded with engines, models and collectors, but almost nothing enforces validity: whether a result is real, whether the data was known at the time, whether a simulated fill would have happened, whether an agent's idea is one of 500 tried.

Evidence from the science track:

- Off-the-shelf time-series foundation models [perform poorly zero-shot on daily excess returns, while models pre-trained from scratch on financial data show real gains](https://arxiv.org/abs/2511.18578v1); a 2026 benchmark found [improvements over a random walk small and sparse](https://arxiv.org/pdf/2606.27100); and [per-series metrics hide a collapse of cross-sectional structure](https://www.alphaxiv.org/abs/2608.14106).
- LLM backtests are contaminated by memorised outcomes: [FinCAD](https://arxiv.org/abs/2605.24564) calls it parametric look-ahead bias, and [Look-Ahead-Bench](https://hedgefundalpha.com/education/your-llms-alpha-might-be-mere-memorization/) shows severe bias in commercial LLMs.
- Live LLM trading tests ([LiveTradeBench](https://arxiv.org/html/2511.03628v1), [nof1 Alpha Arena](https://forklog.com/en/four-out-of-six-ai-models-suffer-losses-in-trading-tournament/)) show general reasoning scores do not translate into trading results.
- RL studies show simulators that ignore market impact are over-optimistic ([survey](https://arxiv.org/pdf/2109.13851)) and deep RL can need [the equivalent of ~8,000 years of daily prices](https://arxiv.org/abs/2307.07694v3).

Evidence from the infrastructure track:

- Exchange testnets give [ideal fills with no slippage or liquidity risk and intermittent downtime](https://medadsabz.com/2024/10/1884.html); testnet books can be so thin that [market orders simply expire unfilled](https://datawookie.dev/blog/2021/11/binance-spot-trading-liquidity/).
- The best historical crypto tick archive, [Tardis.dev, costs $350-6,000/month](https://docs.ccxt.com/docs/comparisons/ccxt-vs-tardis), and even it has a [300-3,000 ms gap per day during WebSocket re-subscription](https://docs.tardis.dev/historical-data-details/overview).
- Backtesters differ in fill semantics so much that [the same logic produces different PnL in event-driven vs vectorised engines](https://pypi.org/project/manifoldbt/).
- Smart-money trackers mostly show raw disclosures; [congressional amounts are legal ranges, and disclosures can be late, amended or wrong](https://www.luxalgo.com/market-trackers.md).
- Trading MCP servers for AI agents exist, but some [have no built-in risk management or trade validation](https://enterprisedna.co/directories/mcp/laukikk-alpaca-mcp).

### 1.2 Strategy

Do not compete on "yet another engine or model". Build the validity and reality layer that every human strategy, AI agent and robot must pass through, reuse the best open-source engines underneath (NautilusTrader, hftbacktest, QuestDB/ArcticDB, OpenBB components), and publish honest research results on top.

Since 2026-10-29 the first market is MOEX, reached through the T-Bank Invest API and MOEX AlgoPack, and the first end-to-end goal is the real-time RL loop of section 5.4: collect, store as known at T, train, test in a sandbox that mirrors the market, then promote.

### 1.3 All projects at a glance

Status values: **v0.1 done** (base and unique features work end to end on synthetic or fixture data, tests pass, report written); **v0.2 MOEX** (adapted to MOEX, offline tests pass); **v0.3** (running on real MOEX data); **not started**. Real data exists since 2026-11-05/06 (T-Bank and ISS captures, the bulk candle history); research results in the reports are still synthetic. Tests are the default offline suite (`make test`). Status column updated 2026-11-06.

| ID | Project | Track | Priority | Status (2026-11-06) |
|---|---|---|---|---|
| S6 | Research Ledger (trial accounting, DSR/PBO gate) | Science core | A | v0.1 done; 89 tests; market-independent |
| I1 | Market Tape Recorder (MOEX via T-Bank and AlgoPack, quality-certified) | Infra core | A | v0.3 live: T-Bank via SPKI key pinning (no Russian CA trusted), read-only allowlist, first real captures (T-Bank, ISS); bulk history downloaded (282 TQBR shares + T-Capital funds: 829,744 day rows, 28.6M 1-minute rows over 12 months) and `scripts/download-all.sh`; zero-fee fund list; 138 tests; AlgoPack awaits a token |
| I2 | Point-in-time Store (bitemporal "as-known-at"; central hub; market slice for the terminal) | Infra core | A | v0.3: real T-Bank/ISS tape and bulk candles ingested; live-edge slice cache (p95 20 ms); CBR key rate and CPI vintages (`pit fetch-macro`); 92 tests |
| S1 | TSFM Arena + rank-tuned finance foundation model | Science | A | v0.1 done; 71 tests; synthetic panel, to be pointed at MOEX stocks via I2 |
| S7 | LLM leakage probe + TinyChrono point-in-time tiny LMs | Science | A | Partly done: probe framework v0.1 (66 tests); TinyChrono only toy-sized; no real LLM probed |
| I5 | Multi-fidelity backtest orchestrator with reality-calibrated fills | Infra | A | v0.2 MOEX: MOEX default market, T-Invest commission (0.25%, 0% T-Capital funds), report rerun; 88 tests; crypto as optional profile |
| S8 | Agent Arena (agents and strategies against each other) | Science | A | v0.2 MOEX: MOEX demo season and fees matching I9, report rerun; 88 tests; no real LLM run |
| I9 | Risk-gated MCP agent gateway (exchange-agnostic, with a market-mirroring sandbox) | Infra | A | v0.2 MOEX: broker-adapter boundary, local mirror sandbox with T-Invest commission; T-Bank sandbox broker disabled (trading local only); report rerun; 107 tests |
| S3 | Reactive LOB simulator for MOEX stocks + sim-to-real gap score | Science | A | v0.2 MOEX (2026-11-06): lots, ticks, price bands, auctions and uncross, halts, MOEX sessions, MOEX scenarios, T-Invest fees; crypto optional; report rerun; 55 tests; real calibration needs a longer T-Bank capture |
| I6 | Shadow Exchange sandbox (MOEX books via T-Bank/AlgoPack; T-Bank sandbox as baseline) | Infra | B | v0.2 MOEX (2026-11-06): lots/ticks/bands, calendar and halts, T-Invest commission (matches I9 on 5,640 fills), tape-tail and slice-stream live feeds, offline T-Bank sandbox rules as baseline (no orders to T-Bank), MOEX and macro scenarios; report rerun on real T-Bank books; 145 tests |
| I3 | Latency-stamped text and filings parsers | Infra | B | not started |
| I4 | Copyability tracker for insiders, Congress, funds, on-chain whales | Infra | B | not started (MOEX-relevant part: issuer disclosures) |
| I7 | Unified execution and risk engine (robots runtime) | Infra | B | not started |
| S2 | LOB forecast-to-fill benchmark | Science | B | not started |
| S4 | Robust RL execution and market making (the RL agent of the loop) | Science | B | v0.2 (2026-11-08): `robust-mm-rl`; execution agent (night run: 1.39 bps [0.36, 2.42] cheaper than TWAP on validation, bar-level model); fund-trading agent on 14 T-Capital funds (0% commission) with research-based point-in-time inputs (prices, liquidity, iNAV premium, macro, CBR/dividend/report calendar, live order book), offline PPO + locked test + hourly live fine-tuning; dashboard with training history; 42 tests |
| S5 | Honest Alpha Factory | Science | B | not started |
| S9 | Time-to-signal benchmark + distilled tiny market-text models | Science | B | not started |
| I8 | Research-integrity terminal (real-time market slice) | Infra | B | v0.1 (2026-11-06): `research-terminal`, TradingView-style web UI (React, lightweight-charts) + BFF on 8611; market, time travel, data health, integrity, agents, sandbox, RL placeholder (`rl/v1`); mock world; 42 tests |
| I10 | Strategy observability and drift alerts | Infra | C | not started |
| S10 | Online conformal risk + regime sizing | Science | C | not started |
| S11 | Cost-aware decision-focused allocator | Science | C | not started |
| S12 | Crypto Vol Lab (rough-vol calibration, deep hedging) | Science | C | not started; deferred (crypto); a MOEX options variant is possible later |

---

## 2. Method

- Sources: arXiv/alphaXiv, ICML/AAAI/ICAIF/EACL proceedings, RePEc, Springer, GitHub READMEs, PyPI, Hugging Face, vendor docs and pricing pages, independent comparisons, and press coverage for live competitions.
- For each direction: (1) find the disputed or unsolved problem, (2) find as many open-source or free analogs as possible, (3) record what they can and cannot do, preferably from their own docs or limitations sections, (4) define a project in the gap.
- All sources used were publicly accessible; no login-gated pages were needed. If later you want commercial terminals (Bloomberg, Bookmap, TradingView paid tiers) compared in detail, that is the point where the Chrome extension with your sign-ins would help.
- Caveat: "cannot do" describes each analog as documented when researched. Re-check before making comparative claims in a README.

### 2.1 Eastern (Chinese) ecosystem review

A second research pass covered Chinese open-source frameworks, data interfaces, financial LLMs, preprint servers and on-chain tools. Findings are merged into the affected sections below (S2, S4, S5, S7, S9, I1, I3, I4, I5, I7). Several starting assumptions did not hold up and are corrected here:

| Assumption | What the sources show |
|---|---|
| vn.py has MOEX connectors | Not found. [VeighNa's published gateways](https://pypi.org/user/vnpyproject/) cover CTP and many Chinese brokers, IB, and crypto; MOEX would still need our own gateway. |
| Hikyuu is an execution/data base layer | It is a [C++/Python research and backtest framework deeply adapted to A-share data](https://pypi.org/project/hikyuu/), not a broker or exchange gateway layer. Useful in I5, not I7 or I1. |
| AkShare can replace the tape recorder | No. [AkShare scrapes authoritative websites, so interfaces get updated or deprecated](https://getclawkit.com/skills/official-anyjohn-akshare-zh), and [some Sina sources ban IPs on high call rates](https://clawhub.ai/zhengr/akshare-stock-pro). It is a breadth supplement for I3/I4 and Chinese futures, not a tick archive. Its crypto coverage is thin; [the Rust port lists only Bitcoin and major crypto spot data](https://docs.rs/akshare). Macro vintages were not found. |
| ModelScope hosts "Qwen-Finance", "Baichuan-Finance", "FinMA" | The verified open-weight Chinese financial models are [Tongyi-Finance-14B](https://proginn.com/w/1545171) (Qwen-14B based, on ModelScope) and [DISC-FinLLM](https://arxiv.org/abs/2310.15205v1) (Baichuan-13B based); [XuanYuan](https://arxiv.org/pdf/2308.09975) and CFGPT also exist. FinMA is from the English PIXIU/FinBen line, [evaluated in CFinBench](https://arxiv.org/pdf/2407.02301), not a ModelScope Chinese model. "FinQA-zh" could not be verified; the established Chinese benchmarks are CFLUE, FinEval, CFinBench and CFBenchmark. |
| JoinQuant/RiceQuant publish high-frequency alpha-mining frameworks | JoinQuant's open source is mainly [jqdatasdk](https://pypi.org/project/jqdatasdk/1.8.2), a data SDK requiring an account, which also serves Alpha101/Alpha191 factor data, plus [jqfactor_analyzer](https://docsearch.algolia.com/mcp/docs/repo/joinquant/jqfactor_analyzer). RiceQuant publishes [RQAlpha](https://www.skillsdirectory.com/skills/dvcrn-rqalpha), an event-driven A-share/futures backtester. Neither is an HF alpha-mining framework. |
| ChinaXiv is a source of LOB/RL-execution preprints | [ChinaXiv's subject list](https://www.chinaxiv.org/home.htm) has no finance or economics category (closest are management, statistics, computer science), and keyword searches found no LOB or execution preprints there. Chinese LOB work appears in journals instead, for example [Liu & Yang 2024 in 计量经济学报](https://cjoe.cjoe.ac.cn/CN/10.12012/CJoE2024-0158), and the [national preprint platform mirrors arXiv](https://sinoxiv.napstic.cn/article/24653605). ChinaXiv links to a separate [philosophy and social sciences preprint server](https://zsyyb.cn) where economics papers are more likely. |
| Asian security firms publish open-source copy-trading/DEX tools | SlowMist publishes [an open-source MistTrack MCP server](https://github.com/slowmist/MistTrackMCP) and [agent skills](https://kyt.slowmist.com/blog/misttrack-skills-released-empowering-ai-agents-with-on-chain-aml-risk-analysis-c/), but the data behind them is a paid AML/risk API, not a copyability tool. No open-source PeckShield trading tooling was verified. The best-known Asian smart-money product, [GMGN](https://madeonsol.com/compare/gmgn-vs-solana-tracker), is a closed freemium platform. |

---

## 3. Part 1 - Science track

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

---

### S2. LOB representation learning and short-horizon forecasting

**Disputed question.** Do deep LOB models generalise and are their predictions tradable?

[DeepLOB](https://arxiv.org/pdf/1808.03668.pdf) claimed stable out-of-sample accuracy and transfer to unseen instruments. [LOBCAST](https://arxiv.org/pdf/2308.01915) re-examined 15 models for robustness and generalisability (some papers report >88% F1 in simulated settings). [LOBFrame](https://arxiv.org/html/2403.09267v2) argues that traditional ML metrics fail to assess LOB forecast quality and the field lacks standard protocols. [LOBench](https://arxiv.org/pdf/2505.02139v1.pdf) standardises LOB representation learning on A-shares.

| Analog | Can | Cannot / limits |
|---|---|---|
| [LOBCAST](https://github.com/matteoprata/LOBCAST) | 15 models, preprocessing, training, simple profit analysis | Equity datasets; no queue position or latency in profit analysis |
| [LOBFrame](https://arxiv.org/html/2403.09267v2) | Large-scale NASDAQ LOB processing | Equities only; no execution simulation |
| [LOBench](https://arxiv.org/pdf/2505.02139v1.pdf) ([code](https://github.com/financial-simulation-lab/LOBench)) | Representation-learning benchmark | A-shares; not trading-oriented |
| [Image-CNN on LOB (Ye, Yang, Chen, IJF 2023)](https://ma.x-mol.com/paper/1721401906566025216) | Converts LOB into 2D images; reports CNN beating raw-LOB deep models | Accuracy-based; Chinese-team baseline worth including in the zoo |
| [Liu & Yang 2024, 计量经济学报](https://cjoe.cjoe.ac.cn/CN/10.12012/CJoE2024-0158) | Information content of the LOB from a deep-learning view, Chinese journal | Chinese-language only; no public code found |
| [Crypto LOB: "better inputs matter more than another hidden layer"](https://sinoxiv.napstic.cn/article/24767811) | On Bybit BTC/USDT at 100 ms, preprocessing lets logistic regression/XGBoost match or beat DeepLOB | Directly supports our fill-aware, simple-baseline-first protocol |
| [NTU thesis: DeepLOB on Binance BTC futures](https://tdr.lib.ntu.edu.tw/handle/123456789/88514) | DeepLOB with a robust LOB representation beats linear models on Binance | Accuracy only, one venue |

**Gap.** No benchmark converts a LOB forecast into fills with queue position, latency and fees; crypto multi-venue data (free, 24/7) is nearly absent, which blocks cross-venue transfer studies.

**Project: LOB Forecast-to-Fill Bench**
- Base: LOB ingestion, multi-horizon labels, model zoo (DeepLOB, TransLOB, BiN-CTABL, MLPLOB), F1.
- Unique: fill-aware evaluation through a queue/latency backtester ([hftbacktest](https://hftbacktest.readthedocs.io/en/latest/tutorials/examples.html)); cross-venue and cross-period transfer protocol on our own crypto data (I1); "signal half-life vs latency" curve from 1 ms to 1 s.
- Platform: `lob-signal-service` feeding S4 and robots.
- Deliverable: `lob-fill-bench` + report.

---

### S3. Generative and agent-based market simulation

**Disputed question.** Can simulators be realistic and reactive enough to train and stress-test strategies, and how is realism measured?

[JAX-LOB](https://arxiv.org/pdf/2308.13289) is the first GPU LOB simulator, processing thousands of books in parallel with [up to 75x faster per-message processing](https://ora.ox.ac.uk/objects/uuid:eafe039c-38eb-4845-8252-05def202b71a). [LOB-Bench (ICML 2025)](https://arxiv.org/pdf/2502.09172) provides realism metrics including market-impact response functions and finds autoregressive state-space generators beat GAN and parametric baselines. [TRADES](https://www.arxiv.org/abs/2502.07071) is a transformer diffusion engine, released with [DeepMarket, described as the first open-source Python framework for deep-learning LOB simulation](https://api.crossref.org/works/10.3233%2FFAIA251249). [DiffLOB](https://arxiv.org/pdf/2602.03776) adds regime-conditioned counterfactuals. [LOB-ID (2026)](https://arxiv.org/pdf/2608.13082) proposes inception-distance evaluation and notes that judging realism remains a central challenge. For LLM-agent markets, a 2026 replication found [fat tails appear only when price-impact coupling is strong enough](https://arxiv.org/pdf/2608.11215): the mechanism, not the agent, determines realism; other work finds [LLM-agent markets often look "too rational"](https://arxiv.org/pdf/2602.07023.pdf), and [small prompt changes toward trade aversion can stop trading altogether](https://arxiv.org/html/2503.00320v2).

| Analog | Can | Cannot / limits |
|---|---|---|
| [ABIDES](https://github.com/jpmorganchase/abides-jpmc-public) | Agent-based discrete-event market, RL gym | CPU; hand-crafted agents; manual calibration |
| [JAX-LOB](https://arxiv.org/pdf/2308.13289) | GPU parallel books + RL | Reactive realism not benchmarked |
| [TRADES / DeepMarket](https://www.arxiv.org/abs/2502.07071) | Diffusion order flow reacting to an experimental agent | Two equity stocks; realism via predictive score and plots |
| [LOB-Bench](https://github.com/peernagy/lob_bench) | Rigorous realism metrics | Benchmark separate from strategy testing; equity LOBSTER data |
| [DiffLOB](https://arxiv.org/pdf/2602.03776) | Counterfactual regimes | Level-2 snapshots, not messages |
| [Lopez-Lira LLM market sim](https://arxiv.org/pdf/2504.10789) | Open-source LLM trading agents in a market | Expensive, small scale |

**Gap.** Nobody closes the loop generator -> realism -> strategy trained in sim -> live paper trading -> measured degradation. Missing quantity: a sim-to-real gap score. No open generator trained on crypto message data with funding and liquidation events.

**Project: Reactive MOEX Stock Simulator + Sim-to-Real Gap Score** (adapted from the crypto design on 2026-10-29)
- Base: replay, matching engine, zero-intelligence/Hawkes agents, generative order flow, stylised-fact checks.
- Unique: sim-to-real gap score (same strategies in replay, ABM, generative sim and I6 shadow exchange; simulators ranked by how well they predict live results); hybrid engine with an explicit calibrated impact coupling; MOEX equity microstructure (orders in lots, price tick per security, daily price bands, opening and closing auctions, the main and evening sessions, T+1 settlement, no funding or liquidations); counterfactual stress library for MOEX (opening-auction imbalance, dividend gap, liquidity withdrawal, CBR key-rate surprise, trading halt). The crypto conditioning (funding, liquidations, open interest) stays in the code as an optional module for a later crypto return.
- Platform: `sim-service` used by S4 (RL training), I6, I9's sandbox and terminal stress tests.
- Deliverable: `reactive-lob-sim` + LOB-Bench-compatible scores on MOEX tape.

---

### S4. RL for execution and market making

**Disputed question.** Does RL beat closed-form control (Almgren-Chriss, Avellaneda-Stoikov, GLFT) under realistic frictions?

Surveys note [market impact is ignored and historical-only simulation is not enough](https://arxiv.org/pdf/2109.13851); a 2026 forex RL paper notes [engines abstract away financing and liquidation, so gains may come from permissive simulators](https://arxiv.org/pdf/2604.00031); a deep-RL portfolio study needed [more than 2m steps in the simplest setting](https://arxiv.org/abs/2307.07694v3). [FinFlowRL](https://arxiv.org/pdf/2510.15883) tables show vanilla PPO below GLFT on Sharpe in several regimes. [Market-making RL work](https://arxiv.org/pdf/2507.18680) recommends domain randomisation and mixing simulated and real experience. [Robust RL with elliptic uncertainty sets](https://arxiv.org/pdf/2510.19950) models impact uncertainty but notes its own simulation is an approximation at extreme volumes.

| Analog | Can | Cannot / limits |
|---|---|---|
| [FinRL](https://github.com/AI4Finance-Foundation/FinRL) | Easy DRL pipelines | [Execution abstractions too permissive; reward to frictions unclear](https://arxiv.org/pdf/2604.00031); [market impact ignored](https://ojs.aaai.org/index.php/AAAI/article/view/41493/45454) |
| [mbt_gym](https://github.com/JJJerome/mbt_gym) ([paper](https://ar5iv.arxiv.org/html/2209.07823)) | Vectorised model-based gyms for MM and execution | Model-based dynamics only, no data replay |
| [hftbacktest](https://www.mintlify.com/nkaz001/hftbacktest/introduction) | Queue-position and latency-aware tick backtests; L2/L3; Rust live trading | Backtester, not RL env; no learned market response |
| [TensorTrade](https://github.com/tensortrade-org/tensortrade) | Simple trading envs | Toy frictions |
| [Qlib RL order execution](https://gitcode.com/hejinlin/qlib/blob/main/examples/rl_order_execution/README.md) (Microsoft Research Asia + SJTU) | PPO and [Oracle Policy Distillation (AAAI 2021)](https://arxiv.org/pdf/2103.10860): a student policy imitates a teacher with perfect information to improve sample efficiency | On 5-minute CSI300 bars; [its own docs note backtest assumptions where any order amount can be completely executed](https://gitcode.com/hejinlin/qlib/blob/main/examples/rl_order_execution/README.md) |

**Project: Robust RL Execution and Market Making**
- Base: gym API, PPO/SAC, inventory penalties.
- Unique: "beat the formula" protocol (every result vs closed-form optimum under identical frictions, with CIs); residual RL on top of GLFT quotes to cut sample complexity, compared head-to-head with Qlib's OPD as the strongest open sample-efficiency baseline, but rerun under queue-aware fills where OPD's "always fully executed" assumption is removed; training against impact uncertainty and S3 domain randomisation; three-stage validation sim -> hftbacktest replay -> I6 shadow exchange.
- Deliverable: `robust-mm-rl` + report.

---

### S5. Alpha mining (formulaic, RL, LLM-guided)

**Disputed question.** Do automated miners find real alpha or mine noise and crowd?

[Qlib](https://github.com/microsoft/qlib) supplies Alpha158/360; [RD-Agent](https://github.com/microsoft/RD-Agent) runs an LLM factor loop; [AlphaGen](https://github.com/RL-MLDM/alphagen) uses RL. [AlphaAgent](https://arxiv.org/pdf/2502.16789) reports RD-Agent's candidates are homogeneous, leading to crowding and faster decay. [AlphaJungle](https://arxiv.org/html/2505.11122v3) uses LLM + MCTS; [CogAlpha](https://arxiv.org/html/2511.18850v1) argues most LLM miners stay in shallow regions of formulaic space; [FactorEngine (2026)](https://arxiv.org/html/2603.16365) evolves programs with knowledge from reports. None of these deflate reported metrics by the number of formulas the search tried.

| Analog | Can | Cannot / limits |
|---|---|---|
| Qlib + RD-Agent | Full pipeline, LLM loop | China A-share defaults; homogeneous candidates; no trial deflation |
| AlphaGen | RL generation + LLM routines | IC-only reward; Qlib-tied data |
| AlphaAgent, AlphaJungle, CogAlpha, FactorEngine | Diversity and originality controls | Research code; CSI300/500; no live decay tracking |
| [vnpy.alpha (VeighNa 4.0)](https://github.com/Vixob/vnpy) | Qlib-inspired factor engine with Alpha158, Lasso and LightGBM models, connected to vn.py live trading | Handcrafted factor sets and standard ML; no search or deflation |
| [JoinQuant jqdatasdk](https://pypi.org/project/jqdatasdk/1.8.2) + [jqfactor_analyzer](https://docsearch.algolia.com/mcp/docs/repo/joinquant/jqfactor_analyzer) | Precomputed WorldQuant Alpha101 and short-horizon Alpha191 factor data; single-factor and attribution analysis | Requires a JoinQuant account; A-shares; factor library, not a miner |

**Project: Honest Alpha Factory**
- Base: expression DSL, operators, IC/RankIC/ICIR, GP/RL/LLM generators; Alpha101/Alpha158/Alpha191 imported as the "known factor" reference set for crowding scores.
- Unique: multiple-testing-aware search (every candidate logged in S6, deflated IC/Sharpe, effective number of independent trials); live decay and crowding monitor; crypto-native operators (funding, basis, OI, liquidations); hypothesis gate tested on a held-out market.
- Deliverable: `honest-alpha` + report "How much LLM-mined alpha survives deflation?"

---

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

---

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

---

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

---

### S9. Tiny and fast LLMs for market text

A 2026 engineering paper reports [general LLM agents at 1-5 s latency vs a FinBERT-LSTM pipeline at 250-470 ms](https://submission-hk.aconf.org/hk/2026/03/paper_1167512_w2kqsaffbbeilagq_v1.pdf). Fine-tuned [Qwen3 8B and Llama3 8B beat FinBERT on most datasets even with 5% of the training data](https://arxiv.org/abs/2512.00946v1). [FinLoRA](https://arxiv.org/html/2505.19819v1) benchmarks LoRA, QLoRA, DoRA, rsLoRA and federated LoRA; [FinGPT](https://github.com/AI4Finance-Foundation/FinGPT) provides LoRA/QLoRA pipelines and RAG. Speculative decoding gives [roughly 1.5-2x speedups](https://arxiv.org/pdf/2404.14294), but for 1-2B models [drafting overhead is the bottleneck and retrieval-based drafting gives consistent gains (EACL 2026)](https://aclanthology.org/2026.eacl-long.255/).

| Analog | Can | Cannot / limits |
|---|---|---|
| [FinBERT](https://github.com/ProsusAI/finBERT) | Fast sentiment | Three classes, dated, weak on crypto/social text |
| FinGPT, FinLoRA | Fine-tuning recipes | Accuracy only, no time-to-trade |
| [llama.cpp](https://github.com/ggml-org/llama.cpp), [vLLM](https://github.com/vllm-project/vllm) | Fast generic inference | No finance metric |
| Tongyi-Finance-14B-Chat-Int4 via ModelScope/ms-swift | [4-bit quantised Chinese finance model with native ms-swift support](https://skywork.ai/blog/?p=48706) | No latency-to-signal measurement; 14B is too large for the fastest tier |
| Chinese open-weight frontier models (GLM, Kimi, DeepSeek, Qwen) | [Kimi K2.6 ranks third in accuracy on Financial Touchstone (2026)](https://arxiv.org/pdf/2608.08634) | [Geopolitical content filters sometimes refuse legitimate financial questions, depending on access route](https://ideas.repec.org/p/arx/papers/2608.08634.html), a reliability risk for automated pipelines |

**Project: Time-to-Signal Bench + distilled models**
- Unique: end-to-end headline-to-order latency and alpha-decay-per-100 ms measured on live crypto news and exchange announcements (from I3), with a Chinese-language track (CFLUE classification subset for accuracy, Chinese exchange and crypto announcements for latency) and a refusal-rate column, because silent refusals by a model are a failure mode for robots; distillation chain large -> 8B LoRA -> 0.5-1B -> encoder on an accuracy/latency/cost Pareto front; retrieval drafting from a cache of recent headlines; structured output (event, entity, direction, confidence, half-life) for robots.
- Deliverable: `time-to-signal` + model cards + report.

---

### S10. Uncertainty quantification and regime detection

Conformal guarantees assume exchangeability, which returns violate; [Temporal Conformal Prediction](https://arxiv.org/html/2507.05470v5), a [2025 review of conformal forecasting](https://arxiv.org/html/2511.13608v1) and [2026 conformal VaR/ES bounds under non-exchangeability](https://publikationen.bibliothek.kit.edu/1000196356) address this. Regime tools: [ruptures](https://github.com/deepcharles/ruptures) and R changepoint are [offline and non-Bayesian, while RegimeChange adds online BOCPD](https://github.com/IsadoreNabi/RegimeChange/wiki); many [HMM hobby repos](https://github.com/Sakeeb91/market-regime-detection) exist. [MAPIE](https://github.com/scikit-learn-contrib/MAPIE) provides conformal intervals.

**Gap.** None turns calibrated uncertainty and regime probabilities into position sizes evaluated by drawdown avoided after costs.

**Project: Risk-Aware Sizing Service.** Unique: online adaptive conformal intervals for any S1/S2 model with live coverage monitoring; strictly filtering BOCPD + HMM ensemble (no smoothing look-ahead); evaluation by "drawdown avoided per unit of return given up"; conformal VaR/ES limits fed into I7. Deliverable: `conformal-risk`.

---

### S11. Portfolio construction and decision-focused learning

[Riskfolio-Lib](https://riskfolio-lib.readthedocs.io/), [skfolio](https://arxiv.org/abs/2507.04176v1) and [PyPortfolioOpt](https://github.com/robertmartin8/PyPortfolioOpt) cover classical optimisation. 2026 papers propose [decision-focused sparse tangent portfolios with a differentiable convex layer](https://arxiv.org/abs/2607.00581) and [differentiable Sharpe/Omega/CVaR surrogates](https://arxiv.org/pdf/2605.28853).

**Project: Cost-Aware DFL Allocator.** Unique: transaction costs, funding and turnover inside the differentiable layer; identical-CV comparison with skfolio/Riskfolio through S6; regime-conditioned risk aversion from S10; crypto perps + equities + MOEX. Deliverable: `dfl-allocator`.

---

### S12. Mathematical modelling: deep calibration and deep hedging

[Horvath, Muguruza and Tomas](https://ideas.repec.org/a/taf/quantf/v21y2021i1p11-27.html) calibrate (rough) volatility surfaces in milliseconds; [rough_volatility](https://github.com/sigurdroemer/rough_volatility) computes a full surface in about 1 ms; [CaNN](https://pypi.org/project/calibration-nn/) ships pretrained Heston and rough Heston surrogates; [Bayer & Stemper code](https://github.com/yonch/deep_rough_calibration); [GPU calibration with jumps](https://arxiv.org/pdf/2510.19126). [Deep Hedging](https://www.arxiv.org/abs/1802.03042) handles frictions; [PFHedge](https://www.preferred.jp/en/blog/tech/deep-hedging) adds the no-transaction band network; a 2025 paper shows [good hedges from only 256 trajectories in GBM](https://econpapers.repec.org/paper/arxpapers/2505.22836.htm). See also [Awesome Deep Hedging](https://github.com/guijinSON/Awesome-Deep-Hedging).

**Gap.** Mostly SPX/VIX, offline, synthetic markets. Little open work on live crypto option surfaces with perps as hedges and real fee and funding schedules.

**Project: Crypto Vol Lab.** Unique: per-minute neural calibration of rough Bergomi/Heston to BTC/ETH option surfaces; deep hedging with perps + options and real costs; realised hedging P&L vs delta and Leland hedges on live data; calibrated surface published as a factor to I6. Deliverable: `crypto-vol-lab`.

### Science backlog (folded into the above)

KAN and state-space (Mamba/S5) architectures as model options in S1/S2; GNNs for cross-asset relations in S1; causal factor attribution in S5; Hawkes and TimeGAN/QuantGAN baselines in S3; prediction markets as an optional S8 market.

---

## 4. Part 2 - Infrastructure track

### I1. Market Tape Recorder (data collection: order books, trades, funding, liquidations)

**Problem.** Tick-level history is expensive and every self-built collector silently loses data.

| Analog | Can | Cannot / limits |
|---|---|---|
| [Tardis.dev](https://tardis.dev/) + [tardis-node / tardis-machine](https://docs.ccxt.com/docs/comparisons/ccxt-vs-tardis) | Full-depth L2, trades, funding, OI, liquidations, options chains back to 2019; order book reconstruction; open-source clients | [Data is paid ($350-6,000/month)](https://docs.ccxt.com/docs/comparisons/ccxt-vs-tardis); [daily 300-3,000 ms gap at re-subscription](https://docs.tardis.dev/historical-data-details/overview); [historical L3 only for Bitfinex, Coinbase, Bitstamp](https://docs.tardis.dev/faq/order-books) |
| [cryptofeed](https://github.com/bmoscon/cryptofeed) | [Normalised multi-exchange feeds, L2/L3 books and deltas via callbacks](https://pypi.org/project/cryptofeed/0.22.2/) | Feed handler only: no storage, no gap auditing, no archive |
| [CCXT](https://github.com/ccxt/ccxt) | Free unified REST/WS API across exchanges | [Live API client; not a tick archive](https://docs.ccxt.com/docs/comparisons/ccxt-vs-tardis) |
| [data.binance.vision](https://data.binance.vision) | Free bulk files | [Daily bulk only, no intraday](https://www.github.com/akenshaw/flowsurface); one venue |
| MOEX [ISS](https://iss.moex.com/iss/reference/) / [AlgoPack](https://moexalgo.github.io/), [moex-iss client](https://pypi.org/project/moex-iss/), [go-moex-iss](https://github.com/Ruvad39/go-moex-iss) | Free public ISS; AlgoPack analytics | [ISS order books are REST polling snapshots, not streaming; real-time needs Passport; AlgoPack is paid](https://docs.rs/crate/digdigdig3/latest/source/src/l2/free/moex/README.md) |
| [Hyperliquid public API](https://api.hyperliquid.xyz/info) | [No-auth public positions, fills and leaderboard](https://apify.com/zhorex/hyperliquid-scraper.md) | Raw API only |
| [vn.py data_recorder](https://gitee.com/AnyQuant/vnpy) | GUI-configured market data recording through any vn.py gateway, incl. CTP Chinese futures | Bar/tick recording into a database; no completeness certificates or multi-region timestamps |
| [AkShare](https://github.com/akfamily/akshare) | [1,062 credential-free interfaces in v1.18.94](https://apify.com/research_master/akshare-financial-data.md), including all six Chinese futures exchanges (CFFEX, SHFE, DCE, CZCE, GFEX, INE) | Scraped snapshots and history, not a streaming order-book recorder; interfaces change |

**Gap.** No open, self-hosted recorder that (a) proves completeness per day, (b) records both exchange and arrival timestamps from more than one region, (c) covers CEX, on-chain perp DEX and MOEX in one schema, and (d) publishes free archives with quality reports.

**Project: Market Tape Recorder** (MOEX only since 2026-10-29)
- Base: streaming subscription, REST polling, normalisation, snapshot + delta storage, reconnection.
- Sources, in order of use: (1) T-Bank Invest API: WebSocket market-data stream (order book up to 50 levels as full snapshots, anonymous trades, candles, trading status) plus REST for history (candles, recent trades); free token. (2) MOEX AlgoPack: REST order book (20 levels, `SEQNUM`), all trades with `TRADENO`, candles, Super Candles (tradestats, orderstats, obstats every 5 minutes), and the ISS+ STOMP WebSocket for order books; paid token. (3) Public ISS without a token as a delayed fallback. See [docs/moex-sources.md](docs/moex-sources.md).
- Unique:
  1. Data-quality certificate per instrument-day: sequence-gap detection where the source has sequence numbers (AlgoPack `SEQNUM`, `TRADENO`), crossed-book checks, snapshot staleness, cross-source consistency (T-Bank book against AlgoPack book), re-subscription gap measurement, all within the MOEX trading-session windows from the ISS calendar.
  2. Two independent sources for the same instrument (T-Bank and AlgoPack) play the role that two regions played for crypto: the merge keeps the earliest message, and the latency of each source is measured; latency data is reused in S2 and S9.
  3. Recorder first: collection has the highest computing priority on the host (bounded queues, writer never blocked by analytics, nice level for every other process), because data cannot be recollected later.
  4. One schema for both sources, so every downstream project reads one tape.
- Secondary: Python collectors, Parquet output.
- Deferred: crypto venues (Binance, Bybit, OKX, Hyperliquid); their adapters were removed from the code and can be restored from git history.
- Platform: feeds I2 (batch and live append); consumers are every other service.

---

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
- Central role (2026-10-29): I2 is the hub of the real-time RL loop. It takes the live tape from I1 continuously (tail of the finalised and staging tape, or a push endpoint), so the same store serves history and the live edge; it holds MOEX datasets (trades, order-book snapshots, candles, Super Candles, trading status, CBR key rate and CPI vintages); and it serves a **market slice**: every metric of every instrument as known at one moment T (best bid and ask, spread, depth and imbalance, last trade, VWAP, volume, Super Candle stats, trading status, data-quality state), both as a query (`GET /v1/slice?known_at=`) and as a live stream for the terminal (I8) and agents (I9). The same slice at historical T is the observation an RL agent sees in training, so training and live inference read one function.
- Platform: the only data path for I5, I6, S-track services, agents and the terminal.

---

### I3. Text, filings and announcement parsers (latency-stamped)

| Analog | Can | Cannot / limits |
|---|---|---|
| [edgartools](https://github.com/dgunning/edgartools) | [SEC filings back to 1994, XBRL statements, Form 4, 8-K items, latest filings](https://edgartools.readthedocs.io/); MIT; [MCP/skill for Claude](https://glama.ai/mcp/servers/sareegpt/edgartools-mcp) | No first-seen latency, no cross-asset entity mapping |
| CryptoPanic API + [scrapers](https://apify.com/solidcode/cryptopanic-news-scraper.md) | Headlines, coin tags, community votes, sentiment | Aggregator delay; paid scrapers; no latency measurement |
| [OpenBB](https://github.com/OpenBB-finance/OpenBB) | Unified access to many news and data providers | Provider-dependent; not latency-oriented |
| MOEX disclosure sources (ISS, issuer disclosure sites) | Official Russian market data | Scattered formats; few open parsers |
| [AkShare](https://docsearch.algolia.com/mcp/docs/repo/akfamily/akshare) | Free Chinese and global data incl. [financial news from multiple sources and banking regulatory data](https://docs.rs/akshare) | Scraping-based; no first-seen timestamps |
| [Tushare Pro](https://tushare.pro/) | Standardised A-share, futures, macro, financials API | [Freemium: interfaces gated by points earned through activity or payment](https://app.dealroom.co/companies/tushare); [free accounts limited to about 120 calls per minute](https://skillselion.com/skills/lzwme/finance-quant-skills/tushare) |
| [JoinQuant jqdatasdk](https://pypi.org/project/jqdatasdk/1.8.2) | A-share prices, macro, factor data; also an HTTP API | Account required; not latency-oriented |

**Project: Latency-stamped Event Parsers**
- Base: polling/streaming of news, exchange announcements (listings, delistings, maintenance), SEC filings, MOEX corporate events; deduplication.
- Unique: first-seen timestamp per source with clock-sync, so S9 can measure time-to-signal; entity resolution across tickers, crypto contracts and MOEX securities; novelty score (is this new information or a re-post); every item stored point-in-time in I2 and used to build TinyChrono training corpora (S7).

---

### I4. Copyability tracker for individuals' portfolios (insiders, Congress, funds, on-chain whales)

| Analog | Can | Cannot / limits |
|---|---|---|
| [Quiver Quantitative](https://www.quiverquant.com/news/Quiver+Quantitative+Is+Now+Available+in+the+Claude+Connector+Directory) | Congress, Form 4, 13F, lobbying, contracts; API, [MCP](https://glama.ai/mcp/servers/wru0penxe3), [Robinhood agents](https://www.webull.com/news/15666687646254080) | Paid API for most datasets; shows data, not copy profitability |
| [Capitol Trades](https://www.capitoltrades.com) | [Free clean UI](https://orthogonal.info/track-congressional-stock-trades-with-python-and-free-sec-data/) | No API, no evaluation |
| [Disclosed Capitol](https://www.disclosedcapitol.com/vs/quiverquant) | Free API tier, committee portfolios, alerts | Politics-focused |
| [LuxAlgo Market Trackers](https://www.luxalgo.com/market-trackers.md) | Free open data with source citations, intraday refresh of congress/insider | [Amounts are ranges; disclosures can be late or wrong](https://www.luxalgo.com/market-trackers.md) |
| [Arkolith](https://arkolith.com/data/congress) | Parsed PTRs, cross-source join (Congress + insiders + 13F) | Commercial; no copy simulation |
| [HoldingsIntel](https://www.holdingsintel.com/vs/quiver-quantitative) | 13F depth, single 0-100 score per stock with published forward test | Score per stock, not per person |
| Hyperliquid trackers ([Apify actors](https://apify.com/xtracto/hyperliquid-whales), [windyund/hyperliquid-analyse](https://github.com/windyund/hyperliquid-analyse)) | Live whale positions; the latter scores skill via drawdown, Sharpe, win rate, flags martingale and wash trading, and simulates copying with slippage | Single venue; skill not deflated for selection from thousands of wallets |
| China insider equivalents in [AkShare](https://docs.rs/crate/akshare/latest/source/src/stock/feature/gdzjc_em.rs) | Executive shareholding changes (高管持股变动), [shareholder increases/decreases, Dragon-Tiger list (龙虎榜) and active brokerage branches](https://clawhub.ai/zhengr/akshare-stock-pro) | Raw tables from Eastmoney; no person-level performance scoring |
| [GMGN](https://madeonsol.com/compare/gmgn-vs-solana-tracker) | Popular Asian smart-money wallet rankings and automated copy trading (mainly Solana memecoins) | Closed; [profitable wallets can become unprofitable, so copying is inherently risky](https://madeonsol.com/compare/gmgn-vs-solana-tracker); no selection-bias correction |
| [SlowMist MistTrack](https://slowmist.medium.com/misttrack-a-powerful-platform-for-blockchain-security-and-compliance-f2aca7a4d410) + [open-source MCP server](https://github.com/slowmist/MistTrackMCP) | Address labels across 17+ chains, including MEV bots and DeFi whales; AML risk score from entity, history and a malicious-address database | Paid OpenAPI plan for data; risk analytics, not trading performance |

**Gap.** Nobody answers the actual question: after disclosure lag, reporting ranges and costs, is following this person profitable, and is that skill or luck selected from thousands of candidates?

**Project: Copyability Tracker**
- Base: ingest Congress PTRs, Form 4, 13F, 13D, Hyperliquid wallets; normalise tickers and amounts; alerts.
- Unique:
  1. Copyability score = deflated skill (S6, correcting for selecting the best of N people/wallets) minus decay from disclosure lag minus execution cost; computed per person, not per stock.
  2. Default event studies: every alert comes with the historical post-disclosure return curve for that person and filing type.
  3. One identity graph across equities disclosures (US, plus Chinese executive and Dragon-Tiger data via AkShare) and on-chain perps.
  4. Risk-label filter: candidate wallets are screened with MistTrack-style labels (MEV bots, exchange wallets, flagged funds) before skill scoring, so the leaderboard does not reward wash trading or bots whose edge is not copyable.
  5. Exposed to agents via I9 (e.g. "which insiders are worth following in semis?").

---

### I5. Multi-fidelity backtest orchestrator

| Analog | Can | Cannot / limits |
|---|---|---|
| [backtrader](https://github.com/mementum/backtrader) | Flexible Python event-driven | [Slow at minute data over years](https://www.quantt.co.uk/resources/backtesting-platforms-comparison) |
| [zipline-reloaded](https://github.com/stefan-jansen/zipline-reloaded) | Classic equities research | Equities/daily focus |
| [LEAN](https://github.com/QuantConnect/Lean) | Production engine, multi-asset, live brokers | [Designed around QuantConnect's cloud](https://groundy.com/articles/nautilustrader-building-production-ready-algorithmic/); C# core |
| [NautilusTrader](https://github.com/nautechsystems/nautilus_trader) | [Rust core, event-driven, research-to-live parity, infrastructure-agnostic](https://groundy.com/articles/nautilustrader-building-production-ready-algorithmic/) | Fill models generic, not calibrated to your own fills |
| [vectorbt](https://github.com/polakowo/vectorbt) / [PRO](https://vectorbt.pro/) | [Fast vectorised sweeps, walk-forward](https://pypi.org/project/vectorbt/1.1.1/); PRO adds purged CV, limit orders, leverage | [Advanced features and fuller docs in paid PRO](https://www.stork.ai/en/vectorbt) |
| [backtesting.py](https://github.com/kernc/backtesting.py), [ManifoldBT](https://pypi.org/project/manifoldbt/), [ml4t-backtest](https://pypi.org/project/ml4t-backtest/0.1.0a11/), [DQengine](https://pypi.org/project/deployquant/) | Simple or very fast engines; ml4t-backtest offers presets to match vectorbt/backtrader/zipline fill semantics | Each claims speed or parity; none calibrates fills to reality |
| [hftbacktest](https://www.mintlify.com/nkaz001/hftbacktest/introduction) | Queue-position and latency fills | HFT scope |
| [Jesse](https://www.stork.ai/en/jesse), [Freqtrade](https://github.com/freqtrade/freqtrade) | Crypto research + live | Bar-level fills |
| [Hikyuu](https://docsearch.algolia.com/mcp/docs/repo/fasiondog/hikyuu) | Apache-2.0 C++ core with Python layer; [splits a trading system into seven swappable components (environment, condition, signal, stop-loss, money management, profit target, slippage)](https://pypi.org/project/hikyuu/1.2.3/) for fast combinatorial research | Deeply A-share oriented; optional plugins; the combinatorial design multiplies trials, which makes S6 deflation essential |
| [RQAlpha](https://github.com/gaoke966/rqalpha) (RiceQuant) | Modular event-driven backtester for A-shares and futures, [free daily A-share bundle, live trading via an rqalpha-mod-vnpy bridge](https://www.skillsdirectory.com/skills/dvcrn-rqalpha) | Daily-bar focus; no queue or impact modelling |
| [vn.py CTA backtester](https://github.com/snake3342/vnpy) | Backtesting integrated with live vn.py gateways | Bar-level fills |

**Gap.** Engines compete on speed. What is missing is (a) fill models calibrated from your own paper/live fills, (b) a promotion path from cheap to realistic fidelity, (c) automatic cross-engine parity checks, (d) automatic trial logging.

**Project: Multi-fidelity Backtest Orchestrator** (built on NautilusTrader + hftbacktest + vectorbt, not a new engine)
- Base: strategy API, sweeps, walk-forward, metrics, reports.
- Unique:
  1. Reality-calibrated slippage and fill probabilities learned from I6/I7 fills, updated continuously and versioned.
  2. Fidelity ladder: vectorised screen -> event-driven -> tick/queue -> S3 reactive sim; a strategy moves up only if it survives, and the drop in performance per level is reported.
  3. Cross-engine parity test: the same strategy in two engines; disagreements flag fill-semantics bugs (the issue [ManifoldBT documents for backtrader vs vectorbt](https://pypi.org/project/manifoldbt/)).
  4. Every run logged to S6 automatically, data read only through I2.

---

### I6. Shadow Exchange: sandbox with micro and macro factors

| Analog | Can | Cannot / limits |
|---|---|---|
| Exchange testnets ([Bybit, Binance futures](https://www.spark.money/glossary/paper-trading)) | Virtual balances, API practice | [Ideal fills, no slippage, testnet downtime](https://medadsabz.com/2024/10/1884.html); [thin books where orders expire unfilled](https://datawookie.dev/blog/2021/11/binance-spot-trading-liquidity/) |
| [Alpaca paper trading](https://alpaca.markets/agentic) | Equities/crypto paper accounts for agents | Simplified fills |
| [Rithmic paper trading](https://community.optimusfutures.com/t/is-rithmic-paper-trading-environment-realistic/2413) | Live-data exchange simulator | Futures only; separate servers, fill realism unclear |
| [fredapi/ALFRED](https://pypi.org/project/fredapi), [OpenBB](https://github.com/OpenBB-finance/OpenBB) | Macro data and vintages | No scenario engine |

**Gap.** A sandbox that trades against the live real order book (not a testnet), simulates queue-aware fills and impact, and lets you inject micro and macro scenarios with time-travel replay using vintage macro data.

**Project: Shadow Exchange** (MOEX and T-Bank since 2026-10-29)
- Base: virtual accounts, order API identical to I7, PnL accounting in roubles with MOEX lots, ticks and broker commission.
- Unique:
  1. Shadow fills on live MOEX books (T-Bank stream first, AlgoPack later, through I1) with queue position and S3-calibrated impact; fills feed I5's calibration.
  2. The T-Bank sandbox is the "testnet" baseline: its documented fill rules (market orders at the last price whatever their size, limit orders filled in full if one lot is available, resting orders outside the book, a flat 0.05% fee) are reproduced offline as an engine, and an optional mirror mode sends the same orders to the real T-Bank sandbox, so the gap between idealised and queue-aware fills is measured on MOEX.
  3. Micro scenarios: spread widening, liquidity withdrawal, opening-auction imbalance, trading halt, from S3 counterfactuals.
  4. Macro scenarios: CBR key-rate decision and CPI surprise replay with vintages, dividend gap, volatility shocks.
  5. Time-travel mode: replay any past day exactly as it was known (I2), including news timing (I3).
  6. The live end of the S3 sim-to-real gap score.

---

### I7. Unified execution and risk engine (trading robots runtime)

| Analog | Can | Cannot / limits |
|---|---|---|
| [Hummingbot](https://github.com/hummingbot/hummingbot) | [Market making and arbitrage across CEX and DEX, API server, dashboard](https://www.stork.ai/en/hummingbot) | [Most complex setup; market-making focus](https://gainium.io/compare/freqtrade-vs-hummingbot) |
| [Freqtrade](https://github.com/freqtrade/freqtrade) | [~50k stars, FreqUI, backtesting and live](https://www.pistack.xyz/posts/2026-04-27-freqtrade-vs-jesse-vs-hummingbot-self-hosted-algorithmic-trading-guide-2026/) | Crypto bar-level strategies |
| [Jesse](https://github.com/jesse-ai/jesse) | Research-first framework with live mode | Commercial UI for some features |
| NautilusTrader live | Same code in backtest and live | Risk policies are per-deployment |
| [OpenAlice](https://github.com/timFinn/OpenAlice) | Unified accounts across CCXT/Alpaca/IBKR, Trading-as-Git (stage, commit, push to execute), pre-execution guards | Early project; no statistical gate |
| MOEX connectors: [T-Invest, Alor, Finam, QUIK projects](https://github.com/topics/moex?l=python), [StockSharp MOEX ISS](https://nuget.stocksharp.com/packages/StockSharp.MoexISS) | Access to Russian brokers and data | Fragmented; StockSharp ISS adapter is data-only |
| [vn.py / VeighNa](https://pypi.org/project/vnpy/) (MIT) | De facto Chinese standard; [used by private funds, securities and futures firms](https://pypi.org/project/vnpy/); event engine, RPC for distributed deployment, database adapters; [gateways for CTP, many Chinese brokers, IB and crypto](https://pypi.org/user/vnpyproject/); [VeighNa Evo adds Binance, OKX, Bybit spot/perps/options and MT5](https://pypi.org/project/vnpy-evo); vnpy.alpha for ML strategies | No MOEX gateway found; risk management is per-app; community and docs mostly Chinese (WeChat/QQ) |
| [bt_api_py](https://pypi.org/project/bt-api-py/) | One interface for Binance, OKX, HTX, CTP, IB; connection-sharing gateway layer | [Only 4 exchanges fully supported; many others with known WebSocket gaps](https://pypi.org/project/bt-api-py/) |

**Base-layer decision after the Eastern review.** NautilusTrader stays the core runtime (Rust core, backtest-live parity). vn.py is adopted as an adapter source rather than a base: its gateway pattern (one gateway class per venue behind a uniform event interface) is the most battle-tested open design for Chinese venues, so CTP and Chinese brokers can be bridged through vn.py gateways when needed, and a MOEX gateway we write could be contributed back to the vn.py ecosystem as a visible open-source contribution. Hikyuu and RQAlpha belong to the research side (I5), not execution.

**Project: Unified Execution and Risk Engine**
- Base: order routing (crypto via CCXT/Nautilus adapters, MOEX via broker APIs, optional Chinese futures via vn.py CTP gateway), positions, PnL, pre-trade limits, kill switch.
- Unique:
  1. Single risk path for humans, agents and robots: every order passes the same pre-trade checks.
  2. Statistical promotion gate: a strategy can trade only within the capital tier its S6 verdict and I6 track record allow; automatic demotion when S5 decay or S10 coverage fails.
  3. Approval workflow for agents (stage -> human or rule approval -> execute), with every decision logged.
  4. Conformal VaR/ES limits from S10 rather than fixed caps.
  5. Crypto + MOEX in one book.

---

### I8. Research-integrity terminal (human interface)

| Analog | Can | Cannot / limits |
|---|---|---|
| [OpenBB](https://github.com/OpenBB-finance/OpenBB) | [Open-source platform; free web Workspace with AI copilot, premium in Pro](https://techcrunch.com/2024/10/07/fintech-openbb-aims-to-be-more-than-an-open-source-bloomberg-terminal/); [ODP under AGPL](https://us.fitgap.com/products/022551/openbb-terminal); [Workspace Lite $2,400/year](https://www.stork.ai/en/openbb) | [No SLA; users must validate data quality themselves](https://us.fitgap.com/products/openbb-terminal); research, not execution |
| [Flowsurface](https://www.github.com/akenshaw/flowsurface) / [Flowdepth](https://github.com/Niketion/flowdepth) | Native Rust order-flow charts: L2 heatmap, footprint, DOM, Time & Sales; Flowdepth adds Deribit GEX and iceberg detection | Visualisation only; Binance/Bybit focus |
| [quantick](https://github.com/milocaetano/quantick), [OrderFlowMap](https://github.com/Azhagesan-dev/OrderFlowMap) | Bookmap-style heatmaps; quantick feeds the same bars to backtests and bots | Small projects |
| TradingView, Bookmap, Bloomberg | Mature commercial terminals | Paid, closed |

**Project: Research-Integrity Terminal**
- Base: charts, order book heatmap, footprint, watchlists, positions, orders (reusing Flowsurface-style components or lightweight-charts).
- Unique:
  1. Every strategy card shows its S6 verdict (DSR, PBO, effective trials), S3 sim-to-real gap, live decay and coverage, which no analog shows.
  2. Model overlays on order flow: S1/S2 forecasts with S10 conformal bands drawn on the heatmap.
  3. Agent activity feed: what each agent proposed, its reasoning, ledger verdict, approve/veto buttons.
  4. Copyability alerts (I4) and latency-stamped events (I3) on the timeline.
  5. One terminal for crypto CEX/DEX and MOEX.

---

### I9. Risk-gated MCP agent gateway

| Analog | Can | Cannot / limits |
|---|---|---|
| [Alpaca MCP](https://alpaca.markets/blog/introducing-official-mcp-server-enabling-multi-market-trading-with-ai-interfaces/) | Equities, ETFs, crypto, options for agents; [toolset filtering and paper trading](https://alpaca.markets/agentic) | Broker-specific; no research validity |
| [laukikk/alpaca-mcp](https://enterprisedna.co/directories/mcp/laukikk-alpaca-mcp) | Lightweight Alpaca wrapper | No risk management or validation |
| [CPZAI MCP](https://github.com/CPZ-Lab/cpzai-mcp-server) | Strategies, backtests, multi-broker routing (Alpaca/IBKR/FIX), OAuth | Commercial backend |
| [OpenQuant](https://github.com/mitchellbernstein/openquant) | Agents + MCP + paper/Alpaca/Kalshi | Proof of concept |
| [Quiver MCP](https://glama.ai/mcp/servers/wru0penxe3), [EdgarTools MCP](https://glama.ai/mcp/servers/sareegpt/edgartools-mcp) | Data tools for agents | Read-only data |

**Project: Risk-gated MCP Gateway** (exchange-agnostic since 2026-10-29)
- Base: MCP tools for data, forecasts, backtests, orders.
- Unique:
  1. Time-travel enforcement: in research mode every data tool answers "as known at T" (I2), so agent backtests cannot leak the future.
  2. Every agent idea and backtest auto-logged as a trial in S6.
  3. Per-agent budgets for capital, drawdown, token spend and latency; orders go through I7 and start in I6.
  4. Leakage report (S7) attached to any LLM-driven strategy before promotion.
  5. Not bound to an exchange: every order and account call goes through a broker-adapter protocol (place, cancel, order state, positions, account, instrument rules such as lot size, tick and price band). Adapters are selected per venue in config, so terminals and brokers of other exchanges connect later without changes to the tools or the risk path.
  6. A built-in **mirror sandbox** is the first adapter: it duplicates the real market situation by matching agent orders against the live (or replayed) MOEX order book from I2, with queue-aware fills (I6 engine when it runs, a built-in book matcher otherwise), so agents and RL policies trade a copy of the real market with no broker. The T-Bank sandbox is the first external adapter; the I6 shadow exchange and the future I7 are the others.
  7. The market slice from I2 is exposed as an MCP tool, so an agent's observation equals the RL agent's observation and the terminal's view.

---

### I10. Strategy observability and drift alerts

Generic stacks (Prometheus, Grafana) cover system metrics. Unique layer: strategy-level health metrics (live vs backtest Sharpe gap, S5 factor decay, S10 coverage breaches, I1 data-quality incidents, fill-model drift from I5), with alerts to Telegram/email and automatic I7 demotion hooks.

---

## 5. Platform architecture and user experience

### 5.1 Services

| Layer | Services |
|---|---|
| Data | I1 Tape Recorder, I3 Event Parsers, I4 Copyability Tracker |
| Storage | I2 Point-in-time Store |
| Research | S1 forecast, S2 LOB signals, S3 simulator, S4 RL gym, S5 alpha factory, S7 LLM audit, S9 text signals, S10/S11 risk and allocation, S12 vol lab |
| Validity | S6 Research Ledger (gate), I5 Backtest Orchestrator |
| Trading | I6 Shadow Exchange, I7 Execution and Risk Engine |
| Access | I8 Terminal (humans), I9 MCP Gateway (agents), robots in I7 runtime, S8 Agent Arena |
| Ops | I10 Observability |

### 5.2 Three users, one path to market

1. Humans use the terminal to research, inspect integrity dashboards, run stress scenarios and approve promotions.
2. AI agents connect through MCP with time-travel-safe data tools and a single guarded order tool; every idea is a logged trial.
3. Robots (RL policies, factor portfolios, market makers) are deployed only after passing the gate, and demoted automatically on drift.

### 5.3 Core user journey

Idea (human or agent) -> data "as known at T" (I2) -> factor/model (S1/S2/S5) -> fidelity ladder backtests (I5) -> trials counted and deflated (S6) -> leakage audit if an LLM is involved (S7) -> shadow trading on live books with scenarios (I6) -> sim-to-real gap measured (S3) -> promotion to live within a capital tier (I7) -> live decay, coverage and data-quality monitoring (I10) -> automatic demotion if it fails.

The differentiator versus QuantConnect, Qlib, FinRL, Freqtrade/Hummingbot, OpenBB or TradingAgents is that this journey is enforced by design and is identical for humans, agents and robots.

### 5.4 The real-time RL loop (MOEX, from 2026-10-29)

Each repository stays an independent block with its own contracts, so any block can be reused in another project. Wired together they form one loop:

1. **Collect** (I1, highest computing priority): T-Bank stream and AlgoPack polling write the normalised tape and quality certificates.
2. **Store** (I2, the hub): the tape is appended live and kept bitemporal; history and the live edge are one store. The market slice (all metrics at moment T) is served as a query and as a stream.
3. **Observe**: the RL agent, LLM agents (I9) and the terminal (I8) read the same market slice, at historical T in training and at "now" in live.
4. **Train** (S4, with S3): the RL agent trains on replayed history from I2, on S3 simulators calibrated to MOEX tape, and keeps training on the live tape as it arrives.
5. **Test on history** (I5): the fidelity ladder, every run logged and deflated in S6.
6. **Test on live** (I9 mirror sandbox, I6): the agent trades a copy of the live market with queue-aware fills; the T-Bank sandbox gives the idealised-fill baseline; S3 measures the sim-to-real gap.
7. **Promote** (S6 gate, then I7 with a real broker): only after both tests pass; I10 watches for drift and demotes.

Computing priority on one host: I1 collectors first (they cannot replay a missed second), then I2 ingestion and the slice service, then live inference, and only then training, backtests and reports, which run at a lower OS priority and pause when the collector queue grows.

---

## 6. Unified timeline

Assumptions: one developer, about 20 hours/week, start November 2026. Infrastructure that produces data starts first because data needs time to accumulate. Each block ends with a public repo release and, for science projects, a short tech report.

| Month | Science | Infrastructure | Milestone |
|---|---|---|---|
| Nov 2026 | S6 ledger v0.1 | I1 recorder v0 (Binance/Bybit/OKX, Hyperliquid); I2 storage skeleton | Data starts accumulating |
| Dec 2026 | S6 SDK hooks; S1 design + baselines | I1 quality certificates, MOEX ISS; I5 orchestrator v0 with ledger hooks | |
| Jan 2027 | S1 arena v1 public | I2 as-known-at API v1; I3 parsers start (exchange announcements, SEC, news) | M1: first portfolio artefacts |
| Feb 2027 | S1 rank-tuning; S7 probe v1 | I3 v1 with first-seen stamps; I4 tracker start | |
| Mar 2027 | S7 corpus + TinyChrono training; S2 data + model zoo | I4 copyability score v1 | |
| Apr 2027 | S7 models + report; S2 fill-aware eval | I6 shadow exchange v0 | M2: Hugging Face models, leakage report |
| May 2027 | S2 report; S3 replay + ABM; S5 factory v1 | I6 micro scenarios; I5 fidelity ladder | |
| Jun 2027 | S3 generator; S5 decay monitor | I7 execution and risk engine v1 (crypto) | |
| Jul 2027 | S3 sim-to-real gap + report; S5 report; S4 env + baselines | I6 macro scenarios + time-travel; I5 reality-calibrated fills | M3: simulator and alpha factory |
| Aug 2027 | S4 residual RL; S9 latency bench | I7 promotion gate + MOEX connectors; I8 terminal v1 | |
| Sep 2027 | S4 three-stage validation; S9 distillation; S8 arena v1 | I9 MCP gateway v1 | |
| Oct 2027 | S4 report; S9 report; S8 season 1 | I8 terminal v2 (agent feed, integrity cards); I10 observability | M4: agents live in arena |
| Nov 2027 | S8 report; S10 sizing service | I10 drift alerts + auto-demotion | |
| Dec 2027 | S10 report; S11 allocator | Integration hardening, docs | |
| Jan-Mar 2028 | S11 report; S12 Crypto Vol Lab | Public platform release v1.0 | M5: full platform |

Job-search timing: start applying after M1 (January 2027) or M2 (April 2027), when the profile already shows original, well-validated work in both tracks.

---

## 7. Prioritisation and career angle

| Project | What it proves to a quant employer |
|---|---|
| S6 Research Ledger | Overfitting and multiple-testing discipline |
| I1 Tape Recorder | Market-data engineering, microstructure, data quality |
| I2 Point-in-time Store | Understanding of look-ahead and survivorship, data architecture |
| S1 TSFM Arena | Modern DL with correct financial evaluation |
| S7 Leakage + TinyChrono | LLM pretraining and fine-tuning; awareness of a hot open issue |
| I5 Orchestrator | Backtest realism, fill modelling |
| S3 Simulator | Generative modelling, microstructure, scale engineering |
| S8 + I9 Agent Arena and Gateway | Agentic AI with rigorous evaluation and risk control |
| S2, S4 | HFT-relevant evaluation, stochastic control, RL |
| S5 | Daily work of a quant researcher (factor research) |
| S9 | Low-latency ML engineering |
| I4 | Alternative data and event studies |
| I6, I7, I8, I10 | Production trading systems thinking |
| S10-S12 | Breadth: risk, portfolio construction, derivatives maths |

Minimum viable portfolio if time is short: S6 + I1 + I2 + S1 + S7 + S8/I9. These share infrastructure, take about 7-8 months, and each contains a defensible "the field disputes this, here is clean evidence" story.

For every repo: a one-paragraph claim at the top of the README, a reproducible `make reproduce` path, results with confidence intervals, a limitations section, and a short tech report. Honest negative results are valuable in this field and respected by quant interviewers.
