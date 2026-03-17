# 开源项目全景图

> 零售美港股券商平台相关开源项目的系统性调研，覆盖交易引擎、行情存储、资金账务、AML 合规、基础设施各层

**调研日期**: 2026-03-16
**调研方法**: 基于已有 references 文档中引用的项目列表，系统补查遗漏领域，重点关注 Go/Rust/Java 语言、2024-2026 年有活跃维护、stars > 100 或具有历史参考价值的项目。

---

## 已收录项目（之前 references 中已引用）

| 项目 | 领域 | 语言 |
|------|------|------|
| quickfixgo/quickfix | FIX 协议库 | Go |
| cyanly/gotrade | OMS PoC | Go |
| robaho/go-trader | 撮合引擎 | Go |
| tolyo/open-outcry | 撮合引擎 | Go |
| gsitgithub/SubMicroTrading | 机构 OMS + FIX | Java |
| thrasher-corp/gocryptotrader | 多交易所框架 | Go |
| QuantConnect/Lean | 算法交易平台 | C# |
| nautechsystems/nautilus_trader | 生产交易引擎 | Rust+Python |
| ettec/open-trading-platform | 多服务平台 | Go+Java |
| QuantLib / OpenSourceRisk | 金融数学 | C++ |
| vnpy/vnpy | Python 交易框架 | Python |
| alpacahq/* | Broker API | Go |
| apache/fineract | 银行核心 | Java |
| ballerine-io/ballerine | KYC 流程 | TypeScript |

---

## 新发现项目（本次补查）

### 一、撮合引擎

#### exchange-core/exchange-core
- **链接**: https://github.com/exchange-core/exchange-core
- **规模**: ~2,400 stars，Java
- **覆盖**: 基于 LMAX Disruptor + Real Logic Agrona + OpenHFT 的超高性能撮合引擎。全 Order Book 管理、风控、事件溯源、Journal Replay。无浮点数设计（全整数/定点数）。性能：5M ops/秒（十年前硬件）。
- **对我们的价值**: 目前最完善的生产级开源撮合引擎。核心设计模式——事件溯源 + 同 Ring Buffer 内的原子风控——直接对应我们 OMS 的灾难恢复和审计追踪需求。**研究其 Journal Replay 设计**是理解 SEC 17a-4 合规审计实现的最好参考。
- **关键洞察**: `MatchingEngineRouter` 按 symbol→shard→processor 路由的设计，可借鉴到我们的 OMS 分区策略；无浮点设计与我们 `shopspring/decimal` 规则完全一致。

#### i25959341/orderbook
- **链接**: https://github.com/i25959341/orderbook
- **规模**: ~539 stars，Go
- **覆盖**: 纯 Go 限价 Order Book 库，价格时间优先，支持市价/限价/取消，300k+ trades/秒，零外部依赖。
- **对我们的价值**: 最被引用的生产级 Go Order Book 库，可直接嵌入 trading-engine。比 exchange-core 轻得多——适合作为 OMS 的核心数据结构，而非独立系统。
- **关键洞察**: 使用红黑树（O(log n) best bid/ask），避免朴素 Map 实现的 O(n) 扫描。JSON 序列化支持使状态快照/恢复轻松实现。

#### Quod-Financial/quantreplay
- **链接**: https://github.com/Quod-Financial/quantreplay
- **规模**: 2025 年 7 月发布，来自生产交易软件商 Quod Financial，Java/FIX
- **覆盖**: 完整 FIX 多资产市场模拟器——撮合引擎、行情发布、连续/竞价模式，支持文件回放和 GAN 合成订单生成（可基于真实 tick 数据训练）。
- **对我们的价值**: **直接解决 FIX 集成测试的核心痛点**——在不花钱申请真实交易所连接的情况下，端到端测试我们的 SOR 路由、FIX 消息处理、ExecutionReport 解析。可在 CI pipeline 中部署为 FIX Acceptor。
- **关键洞察**: GAN 订单生成意味着可以基于真实 HKEX/NYSE tick 数据训练后，产生统计特征一致的合成行情——这对测试 PDT 检测和 Margin Call 触发场景极有价值。

---

### 二、行情存储与时序数据库

#### questdb/questdb
- **链接**: https://github.com/questdb/questdb
- **规模**: 16,500+ stars，Java+C++
- **覆盖**: 高性能时序数据库，纳秒级时间戳，专为金融场景设计的 SQL 扩展——`ASOF JOIN`（按时间最近匹配）、`LATEST ON`（每个 symbol 的最新报价）、`SAMPLE BY`（K 线聚合）、`HORIZON JOIN`（时间序列前瞻分析）。4.3M rows/秒写入。
- **对我们的价值**: **market-data 服务的首选 tick 存储**。`ASOF JOIN` 解决"按成交时刻的有效价格"查询——P&L 计算和 TCA 分析的核心需求；`LATEST ON` 替代 `GROUP BY + MAX(timestamp)` 的 symbol 最新价查询——风控实时价格检查的热路径。Tier 1 投行生产使用。
- **关键洞察**: `HORIZON JOIN`（2025 年新增）是 Best Execution 分析（Reg NMS 合规举证）的专用工具——衡量订单发出后 N 秒内价格变化。`time_bucket_gapfill()` 自动填充无成交时段的空白 K 线，无需应用层逻辑。

#### timescale/timescaledb
- **链接**: https://github.com/timescale/timescaledb
- **规模**: 22,000+ stars，C（PostgreSQL 扩展）
- **覆盖**: PostgreSQL 时序扩展——Hypertable、Continuous Aggregate、列式压缩（90%+ 压缩率）、自动数据分层（→S3）、`time_bucket()`、`first()`/`last()` 聚合。
- **对我们的价值**: 如果团队已熟悉 PostgreSQL，这是最低摩擦的 tick 存储选择——集成到现有 Postgres 集群，无需额外学习成本。Continuous Aggregate 可在 tick 写入时自动维护实时 OHLC K 线，免去流处理 job。7 年 SEC 17a-4 保留要求可直接映射到其 tiering→S3 策略。
- **关键洞察**: `add_retention_policy()` + `add_tiering_policy()` 组合实现热→温→Parquet 的全自动数据生命周期管理——compliance 团队要求的"7 年可检索"无需定制开发。

---

### 三、资金账务与清算

#### tigerbeetle/tigerbeetle
- **链接**: https://github.com/tigerbeetle/tigerbeetle
- **规模**: ~10,000 stars，Zig（有 Go/Java/Node.js 客户端）
- **覆盖**: 专为金融交易设计的数据库——双记账原语（账户+转账）内置于存储层，严格可串行化，Append-Only 不可变，Viewstamped Replication 集群共识，**2025 年 6 月通过 Jepsen 验证**。
- **对我们的价值**: fund-transfer ledger 和 trading P&L ledger 的最正确架构选择。数据库层面强制双记账——不能创建没有对应借贷账户的 Transfer，不能透支低于设定下限。消除了整类账务完整性 bug。
- **关键洞察**: **两阶段转账**（`pending` + `post/void`）直接对应我们的"资金已冻结但未结算"模型——ACH 提款发起时 pending，银行确认后 post，超时未确认则 void。这是我们 fund-transfer 合规规则 Rule 10（资金操作错误处理）最优雅的实现方式。

#### blnkfinance/blnk
- **链接**: https://github.com/blnkfinance/blnk
- **规模**: 87 stars，Go
- **覆盖**: Go 原生金融账务核心——双记账、多币种余额、Inflight（待确认）交易、余额快照、超额支出支持、批量交易、对外部银行记录的对账、PII Token 化、实时交易监控 DSL（"Blnk Watch"）。
- **对我们的价值**: **目前唯一为金融科技产品设计的 Go 原生双记账账本**（其他都是个人财务或会计软件）。其 `ledger`、`balance`、`transaction`、`identity` 分层原语直接映射到我们 fund-transfer 的领域模型。"Blnk Watch" DSL 支持 AML 合规规则 2 的 CTR/STR 监控。
- **关键洞察**: Inflight 交易模式（`inflight: true`）对应 ACH 存款"已收到但未清算"的中间状态；余额快照解决了 `SELECT SUM(amount) FROM transactions` 随历史增长的性能退化——用快照 + 增量 SUM 替代全量扫描。

#### GrandmasterTash/OpenRec
- **链接**: https://github.com/GrandmasterTash/OpenRec
- **规模**: 小众但独特（目前找到的唯一专用开源对账引擎），Rust
- **覆盖**: 可配置对账引擎——YAML Charter 配置 + Lua 脚本定义字段推导和匹配规则，外部归并排序处理数百万记录（<100MB RAM），100-200 万交易/分钟。
- **对我们的价值**: 我们 fund-transfer 合规规则 6（三向对账：内部台账 ↔ 银行 ↔ 托管账户）的直接参考实现。Lua 脚本式字段推导解决了银行对账单格式不一致的现实问题（"USD 1,234.56" vs "$1234.56" 的标准化）。
- **关键洞察**: YAML Charter 而非代码来配置匹配规则意味着对账规则变更无需重新部署——这对应对不同银行的格式差异至关重要。

---

### 四、AML / 制裁筛查 / 交易监控

#### moov-io/watchman
- **链接**: https://github.com/moov-io/watchman
- **规模**: 439 stars，Go，最新提交 2026 年 3 月
- **覆盖**: HTTP 服务 + Go 库，覆盖 OFAC SDN、EU 制裁、UN 制裁、FinCEN 311 Special Measures、OpenSanctions 名单。Jaro-Winkler 距离模糊名称匹配（与 OFAC 官方算法一致）。自动每日刷新名单。MySQL/PostgreSQL 支持多实例并发。
- **对我们的价值**: **fund-transfer AML 合规管道的直接可用组件**（合规规则 2：每笔转账必须筛查 OFAC SDN/制裁名单）。Go 原生，Docker 镜像开箱即用，2024 年 4 月新增 FinCEN 311 覆盖。**这是唯一需要直接评估是否采用的项目**。
- **关键洞察**: Watchman 是无状态筛查服务（不存储客户数据），架构正确——fund-transfer 在提交任何提款前同步调用，响应映射到审批工作流：MATCH→阻断+升级合规官；REVIEW→人工审核队列；PASS→继续。

#### checkmarble/marble
- **链接**: https://github.com/checkmarble/marble
- **规模**: 455 stars，Go（后端）+ React（前端），100+ 金融科技公司使用
- **覆盖**: 实时交易监控 + AML 决策引擎——无代码规则构建器、案件管理（含审计追踪）、制裁+PEP 筛查（集成 OpenSanctions）、速率检查、拆分交易检测（Structuring Detection）、AI 辅助规则描述。自托管。
- **对我们的价值**: 覆盖合规规则 2 中规则引擎部分——速率检查（Velocity Check）、聚合检测（CTR 阈值）、异常模式（Structuring）。"持续监控"功能（v0.59.0）在名单更新时自动重新筛查已有客户，覆盖银行账号绑定后的持续合规需求。
- **关键洞察**: "ongoing monitoring"（持续监控）解决了我们一个具体场景：用户绑定银行账号 3 天后，其姓名出现在新更新的制裁名单上——Marble 会自动触发重筛并创建案件。

#### opensanctions/opensanctions
- **链接**: https://github.com/opensanctions/opensanctions + `yente` API
- **规模**: 数据管道仓库，Python
- **覆盖**: 聚合 331 个全球制裁名单——OFAC SDN、EU 综合名单、UN、**HK JFIU 指定人员名单**、PEP 名单、犯罪数据库。`yente` 子项目提供自托管实体匹配 REST API。
- **对我们的价值**: 是 Watchman 和 Marble 的数据层来源。对港股合规**特别重要**：JFIU（联合财富情报组）指定名单覆盖直接对应 AMLO 筛查要求。`yente` API 返回匹配分数并说明哪个来源名单触发了匹配——这是合规官升级流程（需要展示"该客户命中 OFAC SDN 条目 #XXXX"）的必要信息。
- **关键洞察**: 非商业免费使用；生产商业部署需授权，但数据管道代码 MIT 协议开源，可自建数据刷新流水线。

---

### 五、FIX 工具（QuickFIX 之外）

#### fix8/fix8
- **链接**: https://github.com/fix8/fix8
- **规模**: 462 stars，C++
- **覆盖**: Schema 驱动的 C++ FIX 4.x–5.x 框架，编解码速度 3× 于 QuickFIX，SSL、无锁队列、Redis/BerkeleyDB 持久化、异步日志。
- **对我们的价值**: 若 quickfixgo 在延迟上成为瓶颈的参考替代。更实际的用途：其"metadata-aware 测试框架"直接从 FIX Spec Schema 生成测试用例——研究此方法，用于验证我们 quickfixgo 适配层的消息处理正确性，无需手工编写每个测试。

#### jamesdbrock/hffix
- **链接**: https://github.com/jamesdbrock/hffix
- **规模**: 适中，C++98 header-only
- **覆盖**: 零分配 FIX 消息解析/序列化，直接操作 I/O 缓冲区，无线程/无 I/O/无 OOP，STL 风格前向迭代器接口。
- **对我们的价值**: ExecutionReport 解析热路径的参考实现——零分配意味着在数据从内核接收缓冲区复制前即可完成解析，为延迟增加零字节。研究其设计以指导 Go FIX 解析层的内存复用策略。

---

### 六、出入金基础设施

#### moov-io/ach
- **链接**: https://github.com/moov-io/ach
- **规模**: 521 stars，Go
- **覆盖**: 完整 ACH NACHA 标准文件读写和校验。支持所有 SEC 代码（PPD、CCD、**WEB**、TEL 等），Docker 镜像，REST API。配套的 `achgateway` 处理批处理、提交窗口调度和 Return/NOC 文件接收。
- **对我们的价值**: **美股用户 ACH 存取款的生产参考实现**。NACHA 文件格式有大量 edge case 和附加记录类型，这个库已经处理好了。`WEB` SEC 代码是互联网发起的零售 ACH——正是我们的用户存款场景。
- **关键洞察**: `achgateway` 的事件驱动文件提交架构（含 ACH 固定截止时间窗口的调度）是 ACH 结算状态机设计的最佳参考——ACH 的截止时间（美东时间 17:00 等）直接影响"存款几天后可交易"的用户体验。

#### moov-io/wire
- **链接**: https://github.com/moov-io/wire
- **规模**: 92 stars，Go
- **覆盖**: FedWire RTGS 文件解析/生成——大额实时结算电汇，覆盖所有 Business Function 代码，含 IMAD/OMAD 参考号、TypeSubtype 代码、CHIPS 相关字段。
- **对我们的价值**: 对超过人工审核阈值（$50,000+）的大额提款，Wire 是标准渠道。这是目前找到的**唯一 Go 原生 FedWire 文件构造库**，避免从 Fed 发布的 PDF 规范逆向工程（SWIFT MT103 的 FedWire 变体格式极难手工实现）。

---

### 七、低延迟基础设施

#### smarty-prototypes/go-disruptor
- **链接**: https://github.com/smarty-prototypes/go-disruptor
- **规模**: ~300 stars，Go
- **覆盖**: LMAX Disruptor Ring Buffer 的 Go 移植——无锁、无竞争的 goroutine 间通信。同硬件下 225M msg/秒 vs Go 原生 channel 的 15M msg/秒（15× 吞吐提升）。
- **对我们的价值**: 理解 exchange-core 为何如此高性能的底层原理。若需要将 `FIX 接收→解码→风控→Order Book 更新→成交事件→持仓更新` 组成零拷贝、零锁管道，go-disruptor 是工具。**即使不直接部署，研究 Ring Buffer 模式可指导 OMS 事件管道的架构设计**。
- **关键洞察**: LMAX 论文的核心洞察：Disruptor 的性能来自缓存局部性（连续 Ring Buffer 适合 L3 Cache）和机械共情（无锁→无 CPU 核间 cache line 失效）。我们的下单热路径（提交→风控→路由→确认）天然适合 3 阶段 Disruptor 管道。

---

### 八、亚洲市场参考

#### koreainvestment/open-trading-api
- **链接**: https://github.com/koreainvestment/open-trading-api
- **规模**: 韩国投资证券（Korea Investment & Securities）官方仓库，Python 样例
- **覆盖**: 官方开放交易 API 文档和样例——覆盖 KOSPI/KOSDAQ 国内订单**以及海外市场包括 NYSE、NASDAQ、AMEX 和 HKEX**。含实时 WebSocket 行情、下单、账户查询、结算查询。
- **对我们的价值**: **目前找到的与我们最相似的零售券商 API 参考**。韩国 KRX 监管环境与香港 SFC 结构相近（T+2 结算、严格保证金和卖空规定、亚洲营业时间惯例）。重点研究：①如何将 HK 订单路由与国内订单并存；②WebSocket 在 HKEX 交易时段内的重连/订阅模式；③海外账户与国内账户的端点分离设计。
- **关键洞察**: 其 API 设计将 HK 股票订单归类为"海外订单"（`/trading/v1/overseas-stock/...`），与国内订单完全分离——这种隔离模式值得在我们 OMS 路由层采用，以保持 HKEX FIX Session 管理与 NYSE/NASDAQ Session 相互隔离。

---

## 综合评估矩阵

| 项目 | 领域 | Stars | 可直接采用 | 研究价值 | 优先级 |
|------|------|-------|----------|---------|--------|
| **moov-io/watchman** | AML/OFAC 筛查 | 439 | ✅ 是 | 高 | **P0** |
| **moov-io/ach** | ACH 出入金 | 521 | ✅ 是 | 高 | **P0** |
| **questdb/questdb** | Tick 存储 | 16.5k | ✅ 是 | 高 | **P0** |
| **tigerbeetle/tigerbeetle** | 账务账本 | ~10k | 评估中 | 极高 | **P1** |
| **exchange-core/exchange-core** | OMS 架构参考 | 2.4k | ❌ Java | 极高 | **P1** |
| **checkmarble/marble** | 交易监控 | 455 | 评估中 | 高 | **P1** |
| **i25959341/orderbook** | Go Order Book | 539 | ✅ 是 | 高 | **P1** |
| **moov-io/wire** | Wire 电汇 | 92 | ✅ 是 | 中 | **P2** |
| **timescale/timescaledb** | Tick 存储（Postgres 方案）| 22k | 按场景 | 高 | **P2** |
| **blnkfinance/blnk** | Go 账本 | 87 | 评估中 | 中 | **P2** |
| **opensanctions/opensanctions** | 制裁数据 | 数据库 | 数据层 | 中 | **P2** |
| **Quod-Financial/quantreplay** | FIX 测试模拟 | 新项目 | ✅ CI | 高 | **P2** |
| **GrandmasterTash/OpenRec** | 对账引擎 | 小众 | 评估中 | 中 | **P3** |
| **go-disruptor** | 低延迟管道 | ~300 | 架构参考 | 中 | **P3** |
| **koreainvestment/open-trading-api** | 亚洲券商参考 | 官方 | 参考 | 中 | **P3** |
| **fix8/fix8** | FIX 备选 | 462 | ❌ C++ | 中 | **P3** |
| **hffix** | FIX 零分配解析 | 适中 | ❌ C++ | 中 | **P3** |
| **OpenSourceRisk/Engine** | 风险分析 | 658 | ❌ C++ | 中 | **P3** |

---

## 五个立即建议评估的项目

### 1. moov-io/watchman — 可直接集成到 fund-transfer

**理由**: 唯一 Go 原生、生产级、覆盖 OFAC+EU+JFIU 的制裁筛查服务。2026 年 3 月仍有提交。合规规则 2 的筛查要求零容忍错误，自研不如用经过验证的库。

建议调研问题：
- JFIU 名单的刷新频率和延迟是否满足 SFC 要求？
- Jaro-Winkler 中文姓名匹配效果是否足够？（中文客户名需要额外验证）

### 2. moov-io/ach — 美股 ACH 存取款的基础

**理由**: NACHA 格式极其复杂（各银行的 Return Code 解读、addenda 记录格式、文件批次规则），这个库已经处理了所有 edge case。521 stars + Go 原生 + 持续维护。避免自研节省 2-4 周工程时间。

### 3. questdb/questdb — market-data 服务的 tick 存储选型

**理由**: `ASOF JOIN` 和 `LATEST ON` 是行情服务的杀手级特性。16.5k stars 和 Tier 1 投行生产使用背书。与 InfluxDB/Prometheus 相比，SQL 接口对团队摩擦最小。

注意：QuestDB 的 SQL 方言不完全兼容 PostgreSQL，迁移成本需评估。

### 4. tigerbeetle/tigerbeetle — fund-transfer ledger 的架构决策

**理由**: 双记账由数据库层强制（而非应用层），消除了整类账务 bug。Jepsen 验证（2025 年 6 月）是目前所有分布式金融数据库中最高的可靠性背书。Go 客户端可用。

注意：Zig 编写，不是 Go/Java，运维需要额外学习成本；社区相对 MySQL 小很多；需要评估生产事故时的 Debug 能力。

### 5. checkmarble/marble + opensanctions/yente — AML 工作流引擎

**理由**: Watchman 处理名单筛查，Marble 处理规则引擎和案件管理——两者组合覆盖我们合规规则 2 的全部要求（筛查 + 监控 + 上报工作流）。100+ 金融科技公司使用 Marble 提供了一定的生产验证。

注意：Marble 是相对新的项目（87 stars），需要评估稳定性和 SLA。

---

## 参考链接

- https://github.com/exchange-core/exchange-core
- https://github.com/i25959341/orderbook
- https://github.com/Quod-Financial/quantreplay
- https://github.com/questdb/questdb
- https://github.com/timescale/timescaledb
- https://github.com/OpenSourceRisk/Engine
- https://github.com/tigerbeetle/tigerbeetle
- https://github.com/GrandmasterTash/OpenRec
- https://github.com/blnkfinance/blnk
- https://github.com/moov-io/watchman
- https://github.com/checkmarble/marble
- https://github.com/opensanctions/opensanctions
- https://github.com/fix8/fix8
- https://github.com/jamesdbrock/hffix
- https://github.com/moov-io/ach
- https://github.com/moov-io/wire
- https://github.com/smarty-prototypes/go-disruptor
- https://github.com/koreainvestment/open-trading-api
