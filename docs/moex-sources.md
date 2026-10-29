# MOEX data and broker sources

One summary of the two external APIs that the platform uses, read from the official docs on 2026-10-29. Every
repository codes against this file, so a change in an API is fixed here first. Endpoints, hosts, symbols and
limits still live in each repository's `config/settings.yaml`; this file only records what the vendors document.

The platform targets the MOEX stock market (engine `stock`, market `shares`, main board `TQBR`) first.
Futures (FORTS) and currency (CETS) are documented by both vendors and can be added later through config.

## 1. T-Bank Invest API (first source; free token, free sandbox)

Source: https://developer.tbank.ru/invest/ (the site uses a Russian CA certificate, so the built-in browser
refuses it; read it in Chrome). Protobuf contracts, which define every message and field:
https://github.com/RussianInvestments/investAPI/tree/main/src/docs/contracts (a copy is in
`docs/tinvest-contracts/`, package `tinkoff.public.invest.api.contract.v1`).

### 1.1 Endpoints

| Protocol | Production | Sandbox |
|---|---|---|
| gRPC | `invest-public-api.tbank.ru:443` | `sandbox-invest-public-api.tbank.ru:443` |
| REST proxy | `https://invest-public-api.tbank.ru/rest/` | `https://sandbox-invest-public-api.tbank.ru/rest/` |
| WebSocket (gRPC streams as JSON) | `wss://invest-public-api.tbank.ru/ws/` | not documented; the platform treats it as config |

REST call form: `POST {base}/rest/tinkoff.public.invest.api.contract.v1.<Service>/<Method>` with a JSON body
in proto3 JSON (lowerCamelCase field names, int64 as strings, enums as names, timestamps as RFC 3339).
Auth: `Authorization: Bearer <token>` on every call. The token comes only from the environment.

WebSocket: connect with the subprotocol `json-proto` (field names as in the proto contracts) or `json`, and the
bearer token in the `Authorization` header (or `Web-Socket-Protocol: json, <token>`). The server sends
`{"ping": {"time": ..., "streamId": ...}}` keep-alives.

### 1.2 Instrument identifiers

Market-data methods accept `instrument_id` as a FIGI, an `instrument_uid`, or `<ticker>_<class_code>` (for
example `SBER_TQBR`). Order methods accept only a FIGI or an `instrument_uid`, so the adapter resolves the uid once
through `InstrumentsService/ShareBy` with `idType: INSTRUMENT_ID_TYPE_TICKER`, `classCode: TQBR`, `id: SBER`.
`Share` carries `lot` (shares per lot), `minPriceIncrement` (tick, a Quotation), `uid`, `figi`, `currency`
and `tradingStatus`.

Number types: `Quotation {units: int64, nano: int32}` is the value units + nano / 1e9 (both carry the sign).
`MoneyValue` is a Quotation plus an ISO `currency`.

### 1.3 Market data used by the platform

| Need | Method | Notes |
|---|---|---|
| Order book snapshot | `MarketDataService/GetOrderBook` `{instrumentId, depth}` | depth 1..50; bids, asks, `limitUp`, `limitDown`, `lastPrice`, `orderbookTs` |
| Recent trades | `MarketDataService/GetLastTrades` `{instrumentId, from, to}` | anonymous trades, at most the last hour |
| Historical candles | `MarketDataService/GetCandles` `{instrumentId, from, to, interval, limit}` | intervals from 5 s to 1 month (`CANDLE_INTERVAL_*`) |
| Trading status | `MarketDataService/GetTradingStatus` | `SECURITY_TRADING_STATUS_*` |
| Live stream | `MarketDataStreamService/MarketDataStream` (WebSocket) | requests `subscribeOrderBookRequest`, `subscribeTradesRequest`, `subscribeCandlesRequest`, `subscribeInfoRequest`, `subscribeLastPriceRequest`; responses `orderbook`, `trade`, `candle`, `tradingStatus`, `lastPrice`, `ping` |

Stream messages: `orderbook {figi, depth, isConsistent, bids[{price, quantity}], asks[...], time, limitUp,
limitDown, instrumentUid, orderBookType, ticker, classCode}`; each message is a full depth-N snapshot, not a
delta. `trade {figi, direction (TRADE_DIRECTION_BUY|SELL), price, quantity, time, instrumentUid, tradeSource,
ticker, classCode}`; trades carry no trade id or sequence number. `quantity` is in lots.

### 1.4 Sandbox

Same methods as production at the sandbox host, plus `SandboxService`: `OpenSandboxAccount`, `SandboxPayIn`
(roubles only, at most 30,000,000 per pay-in), `CloseSandboxAccount`, `PostSandboxOrder`, `CancelSandboxOrder`,
`GetSandboxOrderState`, `GetSandboxPositions`, `GetSandboxPortfolio`, `GetSandboxOperations`. Accounts are kept
for 3 months after last use.

Documented sandbox fill rules, which are the reason the platform does not use the sandbox as its fill model:
1. A market order fills at the last trade price, whatever its size.
2. A limit order fills in full at the best opposite price if at least one lot is available there.
3. A resting limit order does not enter the book and does not affect the market.
4. The commission is 0.05% of the trade value for every instrument.

`PostOrderRequest {quantity (lots), price?, direction, accountId, orderType (ORDER_TYPE_LIMIT|MARKET|BESTPRICE),
orderId (idempotency key, uuid), instrumentId, timeInForce (TIME_IN_FORCE_DAY|FILL_AND_KILL|FILL_OR_KILL)}`.
`PostOrderResponse` and `OrderState` report `executionReportStatus` (`EXECUTION_REPORT_STATUS_FILL`,
`REJECTED`, `CANCELLED`, `NEW`, `PARTIALLYFILL`), `lotsRequested`, `lotsExecuted`, `executedOrderPrice`,
`executedCommission`, and `stages[{price, quantity, tradeId, executionTime}]`.

### 1.5 Limits

Unary requests per minute: market data 600, instruments 200 (Shares and similar listings 15), orders 100,
`PostOrder` 15 per second, sandbox 200. The documented guideline is at most 50 requests per second per IP over all
tokens. Streams: at most 32 market-data streams, 300 subscriptions (candles, order books and trades together)
per stream, and 100 subscription requests per minute.

## 2. MOEX AlgoPack and ISS (second source; paid token)

Source: https://moexalgo.github.io/docs/api/ (REST, OpenAPI pages; examples sit behind an "Example" tab),
https://moexalgo.github.io/docs/websocket/websocket (ISS+ WebSocket). Python SDK: `moexalgo` on GitHub.

### 2.1 REST

Base `https://apim.moex.com` with `Authorization: Bearer <APIKEY>`. Without a token the same paths on
`https://iss.moex.com` return 15-minute delayed data (trades, candles, statistics) or nothing (order book,
Super Candles). Every response is ISS JSON: each table is `{metadata, columns, data}` with rows as arrays.
Long answers page through `start=<offset>`; Super Candles report the page in the `data.cursor` table
(`INDEX`, `TOTAL`, `PAGESIZE`).

| Need | Path (stock, TQBR) | Notes |
|---|---|---|
| Order book | `/iss/engines/stock/markets/shares/boards/tqbr/securities/{ticker}/orderbook.json` | 20 levels per side; table `orderbook`: `BOARDID, SECID, BUYSELL (B/S), PRICE, QUANTITY (lots), SEQNUM, UPDATETIME, DECIMALS`; table `dataversion`: `data_version, seqnum, trade_date, trade_session_date` |
| Trades | `/iss/engines/stock/markets/shares/boards/tqbr/securities/{ticker}/trades.json?tradeno=<n>` | today's trades from trade number n; `TRADENO, TRADETIME, BOARDID, SECID, PRICE, QUANTITY, VALUE, PERIOD, TRADETIME_GRP, SYSTIME, BUYSELL (aggressor), DECIMALS, TRADINGSESSION, TRADEDATE, TRADE_SESSION_DATE` |
| Candles | `/iss/engines/stock/markets/shares/boards/tqbr/securities/{ticker}/candles.json?from&till&interval` | interval 1, 10, 60, 24 (day), 7, 31, 4; `open, close, high, low, value, volume, begin, end` (Moscow time) |
| Security and market data | `/iss/engines/stock/markets/shares/boards/tqbr/securities/{ticker}.json` | tables `securities` (`LOTSIZE`, `MINSTEP`, `DECIMALS`, `PREVPRICE`, ...) and `marketdata` (`BID`, `OFFER`, `LAST`, `VOLTODAY`, `TRADINGSTATUS`, ...) |
| Super Candles tradestats | `/iss/datashop/algopack/eq/tradestats/{ticker}.json?from&till&latest` | 5-minute bars from the trade stream: `pr_open..pr_close, pr_std, vol, val, trades, pr_vwap, pr_change, trades_b/s, val_b/s, vol_b/s, disb, pr_vwap_b/s, SYSTIME` |
| Super Candles orderstats | `/iss/datashop/algopack/eq/orderstats/{ticker}.json` | 5-minute order-flow stats: `put_orders_b/s, put_val_b/s, put_vol_b/s, put_vwap_b/s, cancel_*` |
| Super Candles obstats | `/iss/datashop/algopack/eq/obstats/{ticker}.json` | 5-minute book stats: `spread_bbo, spread_lv10, spread_1mio, levels_b/s, vol_b/s, val_b/s, imbalance_vol_bbo, imbalance_val_bbo, imbalance_vol, imbalance_val, vwap_b/s, vwap_b/s_1mio` |
| Trading schedule | `/iss/calendars/stock/session.json` | table `session_schedule`: `tradedate, tradingsession (0 morning, 1 main, 2 evening, 5 weekend), boardid, secid, type, time_from, time_till` |
| Non-trading days | `/iss/calendars/stock.json?from&till` | table `off_days`: `tradedate, is_traded, trade_session_date, reason` |

Super Candles update every 5 minutes, and `SYSTIME` is the publication time, so the platform uses it as the
knowledge time of the bar. All MOEX times are Moscow time (UTC+3, no daylight saving).

### 2.2 ISS+ WebSocket (STOMP)

URL `wss://iss.moex.com/infocx/v3/websocket`, subprotocol `STOMP`. Send `CONNECT` with headers `domain`
(`passport` for subscribers, `DEMO` for guests), `login`, `passcode`; expect `CONNECTED` (or `ERROR`).
Subscribe with `SUBSCRIBE` headers `id`, `destination`, `selector`:

| destination | selector | fields |
|---|---|---|
| `MXSE.orderbooks` | `TICKER="MXSE.TQBR.SBER"` | `BUYSELL, PRICE, QUANTITY` |
| `MXSE.securities` | `TICKER="MXSE.TQBR.SBER"` | `LAST, BID, OFFER, VOLTODAY, VALTODAY, NUMTRADES, TRADINGSTATUS, TIME, ...` |
| `MXSE.candles` | `ticker="MXSE.TQBR.SBER" and interval="M1"` | `FROM, TILL, OPEN, HIGH, LOW, CLOSE, VALUE, VOLUME` |

Each `MESSAGE` body is JSON with `properties` (type, sequence number, timestamps), `columns` and `data`.
`properties.type` is `snapshot` (replace everything), `updates` (upsert by key fields) or `removal`. The STOMP
body ends with a NUL byte.

### 2.3 Trading statuses (MXSE)

`N` not traded, `O` opening period, `C` closed, `F` closing period, `B` break, `T` main session, `L` closing
auction, `D` dark pool, `I` discrete auction, `E` closing-auction-price trading, `S` opening auction, `A`, `a`,
`b`, `p` auction phases.

## 3. What the platform derives from these facts

1. T-Bank streams full order-book snapshots without sequence numbers, so the I1 certificate checks snapshot
   staleness, crossed books and coverage for T-Bank, and sequence gaps only where a source has them (AlgoPack
   `SEQNUM`, `TRADENO`).
2. Quantities are in lots in both sources. The tape stores `size` in shares (lots times lot size) and keeps
   the lot size per instrument in config, so every downstream project sees one unit.
3. The T-Bank sandbox is an execution venue with idealised fills, which makes it the first "testnet-style"
   baseline for I6 and the first external broker for I9; it is not a fill model.
