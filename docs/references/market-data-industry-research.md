---
type: industry-research
domain: market-data
date: 2026-03-15
author: market-data-engineer
status: ACTIVE
affects_specs:
  - services/market-data/docs/specs/market-data-system.md
  - services/market-data/docs/specs/market-api-spec.md
  - services/market-data/docs/specs/websocket-spec.md
  - services/market-data/docs/specs/data-flow.md
---

# 行情系统业界调研报告

> 本文档记录行情系统设计的业界实践研究，作为技术规范的知识来源和决策依据。
> 调研时间：2026-03-15

---

## 1. 行情数据授权与合规（Market Data Licensing）

### 1.1 核心法规框架

| 法规/协议 | 管辖范围 | 关键条款 |
|---------|---------|---------|
| **SEC Regulation NMS（2005）** | 全美国股票市场 | Rule 611：Order Protection Rule（NBBO 保护）；Rule 603：行情数据访问和分发要求 |
| **CTA Plan（Consolidated Tape Association）** | NYSE 上市股票（Tape A/B） | 管理 CQS/CTS 数据分发，向 Distributor 授权 |
| **UTP Plan（Unlisted Trading Privileges）** | Nasdaq 上市股票（Tape C） | 管理 UQDF/UTDF 数据分发 |

**参考资料：**
- [SEC Regulation NMS Rule 611 Memo](https://www.sec.gov/spotlight/emsac/memo-rule-611-regulation-nms.pdf)
- [NYSE Market Data Complete Policy Package](https://www.nyse.com/publicdocs/nyse/data/NYSE_Market_Data_Complete_Policy_Package.pdf)
- [UTP Data Policies](https://www.utpplan.com/DOC/datapolicies.pdf)

### 1.2 Non-Professional 用户的法律定义

**来源：** [NYSE Non-Professional Subscriber Policy](https://www.nyse.com/publicdocs/nyse/data/Policy-Non-ProfessionalSubscribers_PDP.pdf)

Non-Professional 是指满足**所有**以下条件的自然人：
1. 行情数据**仅用于个人、非商业目的**
2. 未作为《投资顾问法》§202(a)(11) 定义的"投资顾问"执业（无论是否注册）
3. 未受雇于银行或豁免注册机构，执行通常需要注册的职能
4. 未在 SEC、CFTC 及州证券监管机构注册

**合规责任**：Distributor（券商 App）负责核实用户状态，错误分类将承担溯及既往的费用差额。

### 1.3 Polygon.io 数据授权条款

**来源：** [Polygon.io Market Data Terms of Service](https://polygon.io/legal/market-data-terms-of-service)

| 计划 | 是否可向终端用户展示 | 说明 |
|------|-------------------|------|
| 标准 API Key | ❌ **明确禁止** | 仅限个人、非商业使用；禁止向第三方用户展示、分发、重新传播 |
| **Poly.feed+** | ✅ 允许 | 专为 Display 场景设计；无限终端用户；无需对用户做 Pro/Non-Pro 分类；无需向交易所月度报告 |

**结论：互联网券商 App 必须升级至 Poly.feed+，或直接与 NYSE/Nasdaq 签署 Vendor Agreement。**

### 1.4 大盘指数的授权特殊性

| 指数 | 数据版权方 | 授权要求 |
|------|----------|---------|
| S&P 500 | S&P Global | 需单独签署 S&P Indices 数据分发协议 |
| 道琼斯（DJIA）| S&P/Dow Jones Indices | 同上 |
| Nasdaq Composite | Nasdaq | 需 Nasdaq 授权 |
| 恒生指数 | 恒生指数公司 | 需单独授权 |

**Phase 1 合规替代方案（无额外授权成本）**：
- S&P 500 → **SPY ETF**（SPDR S&P 500 ETF，标注"追踪 S&P 500"）
- Nasdaq 100 → **QQQ ETF**（Invesco QQQ）
- 道琼斯 → **DIA ETF**（SPDR DJIA ETF）
- 恒生指数 → **2800.HK ETF**（盈富基金，Phase 2）

---

## 2. 复权处理（Corporate Actions & Price Adjustment）

### 2.1 业界标准

**后复权（Backward Adjustment）是业界主流做法**：保持最新价格等于市场实际交易价，将历史价格向过去调整。

来源：
- [StockCharts Price Data Adjustments](https://help.stockcharts.com/data-and-ticker-symbols/data-availability/price-data-adjustments)
- [CRSP Price Calculations PDF (University of Michigan)](https://leiq.bus.umich.edu/docs/crsp_calculations_splits.pdf)
- [Nasdaq Data Blog - Comprehensive Guide](https://blog.data.nasdaq.com/the-comprehensive-guide-to-stock-price-calculation)

### 2.2 股票拆分（Split）调整公式

```
调整系数 = 拆分前股数 / 拆分后股数

4:1 正向拆股（最常见，如 AAPL、TSLA 历史上均有）：
  调整系数 = 1/4 = 0.25
  pre_split_price_adjusted  = raw_price  × 0.25
  pre_split_volume_adjusted = raw_volume × 4

累积系数（多次拆股叠加）：
  先 2:1 再 4:1 → 累积系数 = 1/2 × 1/4 = 0.125
```

### 2.3 股息（Dividend）除权调整公式

**Yahoo Finance / CRSP 标准公式：**
```
调整系数 = (P_prev - D) / P_prev = 1 - D/P_prev

P_prev = 除息日前一日收盘价
D      = 每股现金分红金额

示例：P_prev=$40，D=$2
  系数 = (40-2)/40 = 0.95
  除息日之前所有历史价格 × 0.95
```

来源：[Yahoo Finance Adjusted Close Explained](https://help.yahoo.com/kb/SLN28256.html)

### 2.4 Polygon.io 复权支持范围

来源：[Polygon.io - Is Data Adjusted for Splits?](https://polygon.io/knowledge-base/article/is-polygons-stock-data-adjusted-for-splits-or-dividends)

```
GET /v2/aggs/ticker/{ticker}/range/{multiplier}/{timespan}/{from}/{to}
    ?adjusted=true   # 默认，仅处理 Split
    ?adjusted=false  # 原始价格

⚠️ Polygon adjusted=true 只处理 Split，不处理 Dividend
   Dividend 调整需应用层自行计算（从 /v3/reference/dividends 获取分红历史）
```

### 2.5 本项目复权策略决策

| 场景 | 复权策略 |
|------|---------|
| 日/周/月线（历史图表） | Split + Dividend 全复权（后复权） |
| 分时图（当日内） | 不复权，使用实时原始价格 |
| 涨跌幅 change/change_pct | 不复权，以前一日 Regular Close（16:00 ET）为基准 |
| 成交量 | 与价格同步调整（Split 时成交量反向乘以拆股倍数） |

---

## 3. NBBO 与最优执行（Best Execution）

### 3.1 NBBO 的法律定义

来源：[Wikipedia - NBBO](https://en.wikipedia.org/wiki/National_best_bid_and_offer)、[SEC Rule 611 Memo](https://www.sec.gov/spotlight/emsac/memo-rule-611-regulation-nms.pdf)

**NBBO = 全国所有交易所中最高买价（Best Bid）+ 最低卖价（Best Ask/Offer）**

计算主体为 SIP（Securities Information Processor）：
- **CTA SIP**（Mahwah, NJ）→ 计算 Tape A/B（NYSE 上市股票）NBBO
- **UTP SIP**（Carteret, NJ）→ 计算 Tape C（Nasdaq 上市股票）NBBO

**Reg NMS Rule 611（Trade-Through Rule）：** 交易所必须保护显示于 NBBO 的报价，执行价格不得穿越当时 NBBO。

### 3.2 SIP vs 直接交易所 Feed

来源：[Alpaca - Understanding Stock Market Data](https://alpaca.markets/learn/understanding-stock-market-data)、[Exchange-to-SIP Latency Study 2024](https://microstructure.exchange/slides/Latency_TME_2024_JW.pdf)

| 维度 | SIP 合并数据 | Direct Exchange Feed |
|------|------------|---------------------|
| 覆盖 | 全部交易所 Top-of-Book | 单一交易所（含 L2） |
| 延迟 | ~61µs（Quote）/ ~64µs（Trade）| 纳秒级（co-location）|
| 合规地位 | NBBO 计算基础，Reg NMS 要求 | 不直接构成 NBBO |
| 适用场景 | 零售券商、合规展示、预交易风控 | HFT、做市商 |
| 成本 | 相对较低 | 较高（各交易所分别订阅）|

**结论：零售券商使用 SIP Level 1 数据（通过 Polygon 获取）完全合规。** 通过 Polygon 获取的 bid/ask 即为 SIP 聚合的 NBBO，可直接用于市价单 Collar 计算。

### 3.3 Collar 计算中行情系统的责任边界

行情系统向交易引擎提供：
```json
{
  "symbol": "AAPL",
  "bid": "182.51",
  "ask": "182.53",
  "last": "182.52",
  "is_stale": false,
  "timestamp": "2026-03-13T14:30:00.123Z"
}
```

交易引擎使用 `(bid + ask) / 2` 作为 Collar 基准价（NBBO 中间价），行情系统只需保证数据实时性和 `is_stale` 字段正确性。

---

## 4. 数据质量与 Stale Quote 处理

### 4.1 阈值标准

来源：[Data Intellect - Measuring Stale Data](https://dataintellect.com/blog/stale-data-measuring-what-isnt-there/)、[QuestDB - Feed Handlers Glossary](https://questdb.com/glossary/market-data-feed-handlers/)

**无统一监管规定，业界实践如下：**

| 场景 | Stale 阈值 |
|------|----------|
| 预交易风控（Pre-Trade Risk） | > 500ms ~ 1s |
| 行情展示警告 | > 5s |
| LULD 参考价计算 | 基于过去 5 分钟均价 |
| Feed 级中断告警 | > 42ms 无新消息（高频 Feed）|
| 系统熔断 | Feed 中断 > 30s |

### 4.2 假新鲜数据检测

某些低质量数据源会为陈旧价格附加新时间戳（Fake Refresh）。检测方法：
- 监控"价格变动频率"：若同一 symbol 超过 60s 价格完全不变但 timestamp 持续更新，标记为可疑
- 同时监控 Feed 级消息统计：若总消息量正常但特定 symbol 长时间无更新，可能是 symbol 级别的陈旧

来源：[TraderMade - Understanding Good Quality Tick Data](https://tradermade.com/blog/understanding-good-quality-fx-tick-data)

---

## 5. 高质量开源参考项目

### 5.1 MarketStore（Alpaca 出品，最推荐）

- **GitHub**: [alpacahq/marketstore](https://github.com/alpacahq/marketstore)
- **语言**: Go
- **定位**: 专为金融时序数据设计的 DataFrame 服务端数据库
- **特点**:
  - 列式存储，针对 OHLCV K 线优化
  - 支持 Tick 级别数据（全部美股历史 Tick）
  - 插件式数据摄入层（支持 Polygon、GDAX 等）
  - 已在 Alpaca 生产环境验证
- **适合本项目的借鉴点**: K 线历史存储设计、数据摄入插件架构

### 5.2 QuickFIX/Go

- **GitHub**: [quickfix/quickfix](https://github.com/quickfix/quickfix)
- **语言**: C++/Java/Go（多语言）
- **定位**: FIX 协议消息引擎
- **适合本项目**: 与上游经纪商/交易所通过 FIX 协议交互（Trading Engine 侧）

---

## 6. 互联网券商行情系统实践

### 6.1 Robinhood 架构要点

来源：[Robinhood System Design Handbook](https://www.systemdesignhandbook.com/guides/design-robinhood/)、[Quastor - Robinhood Tech Stack](https://blog.quastor.org/p/robinhoods-tech-stack)

| 组件 | 技术选择 |
|------|---------|
| 行情摄入 | 直连交易所原始 Feed，格式标准化 |
| 消息分发 | Kafka / Pulsar（顺序保证）|
| 热缓存 | Redis（亚毫秒查询）|
| 客户端推送 | WebSocket Gateway（横向扩展）|
| 后端 | Python (Django) → Go（迁移中）|
| 数据库 | PostgreSQL + pgbouncer |
| 扩展策略 | 物理分片（sharding）+ 独立负载熔断 |

### 6.2 百万级 WebSocket 并发方案

来源：[Scaling 1M WebSocket Connections](https://arizawan.com/2025/02/how-we-scaled-1-million-websocket-connections-real-world-engineering-insights/)、[Ably - Scaling Pub/Sub with WebSockets](https://ably.com/blog/scaling-pub-sub-with-websockets-and-redis)

**五层架构：**
```
Load Balancer（IP Hash 粘性）
  → WebSocket Gateway 集群（无状态，横向扩展）
  → Redis Pub/Sub（跨节点消息路由）
    Channel: market.us.AAPL → fan-out 到所有订阅此 symbol 的连接
  → Kafka（上游行情入口）
  + OS 调优：fs.file-max、net.core.somaxconn、TCP keepalive
```

**进阶方案**：NATS JetStream 替代 Redis Pub/Sub，提供更低延迟和原生通配符路由（`market.data.us.*`），更适合金融场景。

### 6.3 Alpaca 行情系统参考

来源：[Alpaca Market Data API Docs](https://docs.alpaca.markets/docs/about-market-data-api)

- Basic 计划：IEX 交易所数据（~2-3% 市场成交量）
- Algo Trader Plus：完整 SIP 数据（全市场）
- WebSocket：认证后 10 秒完成认证，支持 trades/quotes/bars 订阅
- 每用户默认 1 个活跃连接

---

## 7. K 线历史数据回填

### 7.1 Polygon.io 历史 API 约束

来源：[Polygon.io Aggregates API Docs](https://polygon.io/docs)、[Polygon.io Aggregates FAQ](https://polygon.io/knowledge-base/categories/aggregates)

| 约束 | 值 |
|------|---|
| 单次返回上限 | 50,000 根 K 线 |
| 调整参数 | `adjusted=true`（默认，仅 Split）；`adjusted=false`（原始）|
| 无交易 K 线 | 不生成，Holiday/Halt 期间为空白 |
| 参考端点 | `/v3/reference/splits`、`/v3/reference/dividends` |

### 7.2 分级回填策略

```
第一阶段（全市场日线，部署时）：
  P0: TOP 100 热门股票 → 约 30 秒（付费计划）
  P1: 全市场 ~8000 只  → 约 4 分钟（100 req/min）

第二阶段（分钟线，用户触发）：
  用户访问股票详情页 → 触发当日分钟线按需加载

第三阶段（盘中实时续接）：
  订阅 Polygon WebSocket AM.* 事件，追加写入 MySQL
```

### 7.3 数据缺口处理

Polygon 不生成无交易的 K 线，因此：
- **节假日**：跳过，不 forward-fill，K 线图显示空白
- **停牌（Halt）**：停牌期间标记 `halted=true`，不填充
- **新股**：从上市日开始，无历史数据
- **盘前盘后分钟线**：不回填，仅通过实时 WebSocket 展示

---

## 8. 知识盲区记录（待深入研究）

| 编号 | 主题 | 优先级 | 说明 |
|------|------|--------|------|
| X1 | **LULD 熔断机制** | 🔴 高 | Limit Up Limit Down 是最常见的 Trading Halt 原因，需正确处理状态推送 |
| X2 | **Odd Lot 成交处理** | 🟡 中 | < 100 股交易不计入 NBBO，影响成交量和分时图展示 |
| X3 | **Consolidated Tape 分类** | 🟡 中 | Tape A/B/C 的股票分类规则，为何同一股票可能出现报价差异 |
| X4 | **港股 HKEX OMD-C 协议** | 🟡 中 | Phase 2 需要，届时深入研究午休期处理、委手数逻辑 |
| X5 | **Non-Professional 声明技术实现** | 🟡 中 | 若走 Vendor Agreement 路径，需与 AMS 工程师协作 |

---

## 9. 参考资料完整索引

### 监管合规

| 资料 | URL | 关键内容 |
|------|-----|---------|
| SEC Regulation NMS Rule 611 | https://www.sec.gov/spotlight/emsac/memo-rule-611-regulation-nms.pdf | NBBO 法律依据、Trade-Through Rule |
| NYSE Non-Professional Subscriber Policy | https://www.nyse.com/publicdocs/nyse/data/Policy-Non-ProfessionalSubscribers_PDP.pdf | Non-Pro 用户法律定义 |
| NYSE Market Data Policy Package | https://www.nyse.com/publicdocs/nyse/data/NYSE_Market_Data_Complete_Policy_Package.pdf | CTA 完整授权政策 |
| UTP Data Policies | https://www.utpplan.com/DOC/datapolicies.pdf | UTP（Nasdaq）授权政策 |
| Polygon.io Terms of Service | https://polygon.io/legal/market-data-terms-of-service | Polygon 数据使用限制 |

### 复权计算

| 资料 | URL | 关键内容 |
|------|-----|---------|
| CRSP Price Calculations (U of Michigan) | https://leiq.bus.umich.edu/docs/crsp_calculations_splits.pdf | 学术标准复权公式 |
| Yahoo Finance Adjusted Close | https://help.yahoo.com/kb/SLN28256.html | 股息复权计算说明 |
| Nasdaq Data Blog | https://blog.data.nasdaq.com/the-comprehensive-guide-to-stock-price-calculation | 综合复权计算指南 |
| Polygon Adjusted Data FAQ | https://polygon.io/knowledge-base/article/is-polygons-stock-data-adjusted-for-splits-or-dividends | Polygon 复权范围说明 |
| StockCharts Adjustments | https://help.stockcharts.com/data-and-ticker-symbols/data-availability/price-data-adjustments | 图表平台复权实践 |

### 系统架构

| 资料 | URL | 关键内容 |
|------|-----|---------|
| Exchange-to-SIP Latency Study 2024 | https://microstructure.exchange/slides/Latency_TME_2024_JW.pdf | SIP vs Direct Feed 实测延迟数据 |
| Alpaca - Understanding Data Feeds | https://alpaca.markets/learn/understanding-stock-market-data | SIP vs IEX 对比、数据分层说明 |
| Scaling 1M WebSocket Connections | https://arizawan.com/2025/02/how-we-scaled-1-million-websocket-connections-real-world-engineering-insights/ | 百万并发 WebSocket 工程实践 |
| Ably - Pub/Sub with WebSockets | https://ably.com/blog/scaling-pub-sub-with-websockets-and-redis | Redis Pub/Sub 扩展方案 |
| Robinhood Tech Stack (Quastor) | https://blog.quastor.org/p/robinhoods-tech-stack | Robinhood 技术选型 |

### 数据质量

| 资料 | URL | 关键内容 |
|------|-----|---------|
| Data Intellect - Stale Data | https://dataintellect.com/blog/stale-data-measuring-what-isnt-there/ | Stale 检测概率统计方法 |
| QuestDB - Feed Handlers | https://questdb.com/glossary/market-data-feed-handlers/ | Feed Handler 必备能力清单 |
| TraderMade - Tick Data Quality | https://tradermade.com/blog/understanding-good-quality-fx-tick-data | 假新鲜数据识别 |

### 开源项目

| 项目 | URL | 语言 | 适用场景 |
|------|-----|------|---------|
| alpacahq/marketstore | https://github.com/alpacahq/marketstore | Go | K 线历史存储、数据摄入架构 |
| quickfix/quickfix | https://github.com/quickfix/quickfix | Go/C++/Java | FIX 协议引擎 |
| Alpaca Market Data API | https://docs.alpaca.markets/docs/about-market-data-api | - | WebSocket 协议参考 |
