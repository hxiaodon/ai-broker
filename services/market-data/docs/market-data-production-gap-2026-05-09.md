# 行情服务生产化分析与开源参考全景图

**日期**: 2026-05-09
**来源**: 与 Claude 的设计讨论会话整理
**目的**: 沉淀对"行情服务从 PoC 到生产"差距的完整认识，作为后续迭代规划的参考文档
**关联**:
- 上游：[`code-review-2026-05-08.md`](./code-review-2026-05-08.md) — 4 P0 + 6 P1 + 5 P2 + 3 P3 具体 bug 清单
- 平级：[`active-features.yaml`](./active-features.yaml) — 功能跟踪
- 下游：尚未创建的迭代规划

---

## 0. TL;DR

| 维度 | 结论 |
|------|------|
| 当前代码量 | 4,500 行真业务逻辑（去注释/空行/swagger） |
| 直觉目标 | 50K+ 行（用户提出，与行业 baseline 一致） |
| 差距倍数 | ~10× |
| 差距性质 | **横向 18 个核心模块完全缺失** + **纵向 8 个已有模块只到骨架** |
| 关键发现 | 行业大型开源项目（Lean）713K 行，但**90% 不解决你们的问题**（Lean 是消费侧，你们要建生产侧） |
| 架构决策 | 存数据**不是为了备份 Polygon**，而是为了合规/业务计算/故障隔离 — 决策维度是"业务产出物 vs 原料副本" |

---

## 1. 当前代码量基线

### 1.1 数字事实（2026-05-08 测量）

```
总代码（含测试）:       10,530 行
生产代码（raw）:         6,900 行
生产代码（去注释/空行）: 5,327 行
  - 生成的 swagger.docs.go:  -820 行（非业务）
  - 真正的业务逻辑:          ~4,500 行
测试代码:                3,630 行
```

### 1.2 按 subdomain 分布（生产代码 raw）

```
internal/quote:       1,682  ████████████████
internal/server:        794  ████████
internal/kline:         684  ███████
internal/kafka:         474  █████
internal/watchlist:     449  █████
internal/search:        438  █████
internal/feed:          359  ████
internal/conf:          107  █
pkg/observability:      145  ██
pkg/middleware:          93  █
pkg/polygon:            112  █  (stub)
pkg/hkex:               104  █  (stub)
```

### 1.3 实际功能完成度

- **REST endpoint**: 7/11 实现，4 个返 501（movers / stocks/{symbol} / news / financials）
- **Polygon client**: 112 行 stub，注释明写"domain engineers will implement"
- **HKEX feed**: 104 行 stub，feed worker 硬编码 `MarketUS`
- **WebSocket**: 372 行单文件骨架
- **K-line**: 8 个时间周期，但 1W/1M 已知未实现
- **TA 指标**: 0 行
- **公司行为复权**: 字段存在，逻辑 0 行
- **Order Book / L2**: 仅 top-of-book Bid/Ask 字段，无订单簿
- **Migrations**: 7 张表

---

## 2. 横向缺口（整块功能模块"不存在"）

| 模块 | 现状 | 行业典型量级 |
|------|-----|-----------|
| TA 技术指标（MACD/RSI/KDJ/BOLL…50+） | 完全没有 | 5-10K |
| 公司行为流水线（拆股/分红/合并/分拆/退市/复权） | 字段有，逻辑零 | 3-5K |
| Order Book / Level 2 / NBBO | 只有 top-of-book | 5-10K |
| 逐笔成交（Trade Tape） | 没有 | 1-2K |
| 期权链 / 期货 / 指数 | 没有 | 5-10K |
| 行业/板块/ETF 持仓/热力图 | 没有 | 2-3K |
| 新闻聚合（多源） | 路由 501 | 2-3K |
| 财务数据（财报/估值/财务比率） | 路由 501 | 2-3K |
| Movers（涨跌幅榜/活跃榜） | 路由 501 | 1-2K |
| 股票详情页（基本信息/概况） | 路由 501 | 1-2K |
| 交易日历（节假日/半日/盘前盘后/熔断/停牌） | 没有 | 2-3K |
| Symbology 映射（CUSIP/ISIN/FIGI/多上市） | 没有 | 1-2K |
| FX / 汇率（HKD/USD 显示换算） | 没有 | 0.5-1K |
| Tick 历史存储 / 回放 | 没有（仅 latest snapshot） | 3-5K（见 §4） |
| 冷启动 backfill / gap recovery | spec 有，代码 0 | 1-2K |
| 多 feed 交叉校验 / 自动 failover | 没有 | 1-2K |
| Entitlement / 数据 license 服务 | 仅 userType 字段 | 2-3K |
| HKEX feed 完整接入 | stub | 3-5K |

**横向小计**：缺 18 个模块，按 mid 估算 **~40-70K 行**。

---

## 3. 纵向缺口（已有模块"骨架很薄"）

| 现有模块 | 当前 | 生产 | 缺什么 |
|---------|------|------|-------|
| Polygon client | 112 行 stub | 3-5K | 实数据拉取/断线重连/gap detection/多 endpoint 协调 |
| Massive WebSocket feed | 359 行（仅 Aggs） | 3-5K | Trades/Quotes/L2/Imbalance 频道 + 序号校验 + 降级 |
| WebSocket gateway | 372 行 | 3-5K | 订阅分片 / per-client coalesce / backpressure / diff push / binary frame / 10K+ 连接扩展性 |
| K-line 聚合 | 684 行（仅时间 bar） | 2-3K | 复权回填 / volume-bar / dollar-bar / range-bar / 跨 session 边界 |
| Quote pipeline | 1,682 行 | 5-10K | 跨 feed stale 比较 / 心跳监控 / 异常值过滤 / license 标注 |
| Search | 438 行 | 2-3K | 多语言/拼音/模糊/排名权重/最近浏览/推荐 |
| Watchlist | 449 行 | 1-2K | 分组/置顶/共享/多端同步/排序记忆 |
| Migrations | 7 张表 | 30-50 张 | 公司行为/财务/新闻/期权/日历/符号映射/license/订阅 |

**纵向小计**：现有 4.5K 行 → 该到 **~25-35K 行** 才到 prod 标准。

---

## 4. 行数估算的方法学（避免"拍脑袋"）

> 用户在 tick 存储 3-5K 行的估算上提出过质疑。第一次给数没有拆分过程，是行业经验拍数。下面是**自下而上**重估的标准方法，未来引用任何模块行数前都该走一遍。

### 方法：把模块拆成不可再分的子组件，每项给 mid 区间

以 **tick 历史存储/回放** 为例：

| 子组件 | 职责 | 行数（mid） |
|--------|------|----------|
| 1. Tick ingestion writer | 订阅 feed、批量缓冲、schema 编码、写存储 | 300-500 |
| 2. Storage backend client | ClickHouse/Timescale/Parquet+S3 包装、建表/分区/压缩 | 400-800 |
| 3. Partition/索引管理 | 按日期+symbol 分区、manifest、catalog、retention | 200-400 |
| 4. Query API | 时间范围查询 + symbol 过滤 + cursor 分页 + 聚合下推 | 300-500 |
| 5. Replay engine | 按原时戳或 N 倍速回放、订阅会话、断点续放 | 300-600 |
| 6. Compaction/retention | 每日 raw→bar 压缩 + 5 年冷归档 + 重编码 | 300-500 |
| 7. Hot ring buffer | 内存最近 N 条 tick，给 backfill / 短查询 | 200-400 |
| 8. Backfill/cold-start | WS 重连补丢失 tick + 冷启动 warmup latest 1h | 200-400 |
| 9. 测试（bench/并发/roundtrip） | 1M ticks/s 写入压测 + 并发正确性 | 500-800 |
| **合计** | | **~3,800（区间 2.7K-5.0K）** |

### 关键变量影响估算

- 用现成 ClickHouse/Timescale + 简单包装 → 偏 2.5-3.5K
- 自研 Parquet/Arrow 列存（HFT 团队选这个） → 偏 5-8K
- 用 kdb+（大量逻辑在 q 脚本） → Go 这边反而偏小 1.5-2.5K

### 横向 + 纵向总表的可信度分级

- ✅ **可信**：基于上述子组件法重估过的（目前只有 tick 存储）
- ⚠️ **行业经验**：其他 17 个横向模块 + 8 个纵向模块都是行业 mid 估算
- 🚫 **不可拿去汇报**：把所有数字直接相加得出"~50K 行"虽然量级对，但每项的精度都是 ±50%

**建议**：要驱动 headcount/排期前，对每个模块走一遍子组件法。半天可完成全部。

---

## 5. 开源参考全景图（含真实状态核查）

### 5.1 直接可用 / 高价值

| 项目 | 语言 | 状态 | 用途 |
|------|------|------|------|
| [polygon-io/client-go](https://github.com/polygon-io/client-go) | Go | 活跃，官方 | Polygon WS 订阅/重连/gap detection 标准实现，**直接参考** |
| [cinar/indicator](https://github.com/cinar/indicator) | Go | 活跃 | 50+ TA 指标，可直接集成（注意内部用 float64，需外层 decimal 包装） |
| [QuantConnect/Lean](https://github.com/QuantConnect/Lean) `Common/Data/Auxiliary/` | C# | 活跃 | 公司行为/复权因子（FactorFile.cs/CorporateFactorProvider.cs，3,436 行），翻译成 Go |
| [QuantConnect/Lean](https://github.com/QuantConnect/Lean) `Indicators/` | C# | 活跃 | 166 个 TA 指标参考实现，~31K 行 |
| [QuantConnect/Lean](https://github.com/QuantConnect/Lean) `Common/Data/Market/Tick.cs` | C# | 活跃 | Tick 数据类型设计参考（855 行，含 TickType 枚举体系） |

### 5.2 不要直接依赖（已死或定位不符）

| 项目 | 状态 | 原因 |
|------|------|------|
| [alpacahq/marketstore](https://github.com/alpacahq/marketstore) | **404 已删除** | 原始仓库已不存在 |
| [mypmc/marketstore](https://github.com/mypmc/marketstore) | 1 star fork，无人维护 | 仅作架构思路参考，不可集成 |
| [alpacahq/alpaca-trade-api-go](https://github.com/alpacahq/alpaca-trade-api-go) | 活跃但是客户端 SDK | 不是行情服务实现，是调他们 API 的客户端 |

### 5.3 关于 Alpaca / Lean 的认知澄清

**Alpaca**：API-first 持牌券商（SEC + FINRA），商业模式是 **Brokerage-as-a-Service**——把清算/托管/交易能力打包成 API 卖给其他 fintech。和 Tiger/Futu 是同一定位的不同打法。

**它的开源仓库以 SDK 为主**，因为核心 OMS / 行情系统 / 清算引擎是商业产品，不开源。`marketstore` 曾是少有的服务端开源代码，现已删除。

**Lean**：算法**回测/执行引擎**，定位是数据**消费侧**——读历史数据回测策略 / 接 broker live 执行。和你们要建的"生产侧行情服务器"是两个不同的物种。

| Lean 包含 | Lean 不包含 |
|----------|----------|
| ✅ TA 指标（166 个，31K 行） | ❌ 实际 feed 接入实现（在独立 broker 仓库） |
| ✅ 复权因子计算（FactorFile，3.4K 行） | ❌ Redis 行情缓存 |
| ✅ Tick/QuoteBar/TradeBar 数据类型 | ❌ WebSocket 推送给 C 端 |
| ✅ 财务数据字段体系（113K 行，多为生成代码） | ❌ Kafka 分发 |
| ✅ L2 OrderBook 骨架（240 行） | ❌ 延迟行情 ring buffer |
| | ❌ 用户自选股 / 搜索 / 热搜 |

**结论**：Lean 总量 713K 行很吓人，但实际可参考的部分只有 ~35K 行（Indicators + Auxiliary + Market types），约 5%。整体架构没有参考意义。

### 5.4 可作为 baseline 量级参考

如果你需要回答"行情服务到底要多大"，**Lean 的 Engine + Common/Data + Indicators + ToolBox 加起来 ~200K C# 行**，作为"完整的回测+实时+TA"系统的 baseline。其中**与你们直接对应的部分（生产侧）大约 30-50K 行**——这正是你直觉中的 50K 数字的来源。

---

## 6. 架构决策框架

### 6.1 为什么有了 Polygon 还要自己存（4 个真实理由）

| 理由 | 说明 |
|------|------|
| 1. **Polygon 历史查询有限速** | REST `/v3/trades/{symbol}` 免费版 5 req/min，付费也有上限。WS 重连时需补齐断线期，多 symbol 并发会被限流 → 自存毫秒级、无限流 |
| 2. **License 不允许透传** | 标准 Polygon API key 禁止 redistribution，必须升级 Poly.feed+ 才合规分发。升级前你**不能直接转发** Polygon 数据给 C 端 → 必须存一份在内部消费 |
| 3. **Polygon 没有你的业务数据** | `change`/`change_pct` 基于前收盘计算（前收盘要存）、`is_stale` 标记（你的 stale 阈值）、复权 K 线（复权逻辑是你的）、T-15min delayed 快照（Polygon 没切片）、用户自选股（业务数据） |
| 4. **故障隔离** | Polygon 断线/故障时，自存最近一份能撑住短暂断线，返回 `is_stale: true` 而不是 500 |

### 6.2 必须存 vs 可以不存

| 数据 | 决策 | 理由 |
|------|------|------|
| 实时 quote 快照（latest） | ✅ 必须存（Redis） | 客户端查询 + WS 初始 snapshot |
| T-15min delayed 快照 | ✅ 必须存（Redis sorted set） | Guest 合规 |
| K 线（1min-1D 等） | ✅ 必须存（MySQL） | 聚合逻辑是你的 |
| 前收盘价 | ✅ 必须存（MySQL kline 表足够） | change/change_pct 计算基准 |
| **逐笔 tick 历史（5 年）** | ⚠️ **可以不存** | 直接透传 Polygon `/v3/trades`，除非有限流问题或离线分析需求 |

### 6.3 关键洞察：业务产出物 vs 原料副本

> 不是"再存一份 Polygon 的数据"，是"存你自己的业务数据"。
> Polygon 给的是**原料**，你的服务在原料上加了合规处理 / 业务计算 / 故障隔离，存的是**产出物**。

如果某项"存储"只是 Polygon 数据的副本（无业务增值），就该重新审视——可能压根不需要存。

---

## 7. 现实主义视角：什么是"生产"

> 这一节是会话讨论之外的补充，但我认为对规划至关重要。

### 7.1 "生产" 是相对的

不同业务模型对应**不同的生产标准**：

| 业务模型 | 行情服务标准 |
|---------|-----------|
| **持牌券商**（Tiger/Futu/IBKR） | 全套：feed/Order Book/复权/期权/财务/新闻/L2 — 50K+ 行起步 |
| **券商前端**（用 Apex/Alpaca 清算） | 中等：feed 透传 + 业务计算层 — 15-25K 行 |
| **图表/分析工具**（TradingView 早期） | 中等偏下：feed + TA 指标 + K线 — 10-20K 行 |
| **量化平台**（QuantConnect/Backtrader） | 重历史轻实时：tick 存储 + 回放 + 指标 — 30K+ 行 |

你们目前的定位（**跨境券商 App 的行情服务**）落在第二档，目标 **15-25K 行业务代码** 是更现实的"MVP 上线" 标准；50K 是"成熟产品"标准。

### 7.2 License 是架构驱动力

数据 license **不是合规章节里的脚注，是架构骨架**。

- 标准 Polygon key 禁分发 → 你不可能是"透明代理"，必须存储+加工
- Index 数据（S&P 500/NASDAQ）需独立 license → Phase 1 用 ETF 代理（SPY/QQQ）→ UI 标注 "ETF tracking XXX"
- Guest delayed-15min → 不是给数据加个 flag，是**真的得有 T-15min 时间切片**

很多团队把 license 当合规问题处理，结果到产品上线前才发现整个架构的某些假设不成立——这是行业常见返工。

### 7.3 用户可见性 vs 实现复杂度倒挂

最复杂的部分用户感知最弱：

| 模块 | 用户可见度 | 实现复杂度 | 是否可延后 |
|------|---------|---------|----------|
| 行情数字显示 | 🔴 高 | 🟢 低 | 否 |
| K 线图 | 🔴 高 | 🟡 中 | 否 |
| 自选股 | 🔴 高 | 🟢 低 | 否 |
| 搜索 | 🔴 高 | 🟢 低 | 否 |
| TA 指标（MACD 等） | 🟡 中 | 🟡 中 | **可分期** — 用 cinar/indicator 可省 80% |
| 公司行为复权 | 🟢 低（用户只看到 K 线连续） | 🔴 高 | 否（错了 K 线就难看） |
| L2 Order Book | 🟢 低（散户基本不看） | 🔴 高 | **零售场景可砍** |
| Tick 历史存储 | 🟢 低 | 🔴 高 | **可砍**（透传 Polygon） |
| Cross-feed 校验 | 🟢 零（运维才知道） | 🔴 高 | **可分期**（多 feed 才需要） |

**优先级排序应该按"用户感知 × 不可替代性"排，而不是按"看起来高大上"排**。这能砍掉横向 18 模块中的 5-7 个，省 10-20K 行。

### 7.4 阶段性扩容路径

| 阶段 | 用户量 | 行情服务关注点 | 行数估算 |
|------|--------|------------|---------|
| MVP | < 1K MAU | 基本 quote + K 线 + 自选股，单实例 | 8-12K |
| 早期增长 | 10K MAU | 加 search + delayed + 故障容错 | 12-18K |
| 规模化 | 100K MAU | WS 分片 + 复权 + 公司行为 + 多 feed | 20-30K |
| 成熟产品 | 1M+ MAU | 全套 + 期权 + 财务 + 新闻 + L2（如需要） | 40-60K |

**当前 4.5K 行连 MVP 都不到**——这个判断比"距离 50K 还差 45K"更可操作。

### 7.5 不要被开源大项目吓到

Lean 713K 行 / QuestDB 200K+ 行这些数字会让人焦虑，但它们解决的是**不同的问题**：
- Lean 是单进程算法引擎（不需要分布式 / 不需要 C 端推送 / 不需要合规切片）
- QuestDB 是通用时序数据库（你们最多用它，不需要重新造）
- Bloomberg Terminal 内核是 30+ 年 C++ 代码（完全不可比）

**真正可比的是其他持牌券商的内部行情服务**——这些**全部不开源**。所以 50K 这个数字本质上是个"行业经验值"，不是从开源项目数出来的。

---

## 8. 推荐迭代顺序（优先级排序）

### Wave 1：止血（已识别 P0，不修不能用）
来源：[`code-review-2026-05-08.md`](./code-review-2026-05-08.md)

1. P0-1 + P0-2: DB schema 不一致（migration v2）
2. P0-3: Guest 走 delayed 路径（合规阻塞）
3. P0-4: feed 浮点精度

### Wave 2：合 MVP 真正可用
1. P1-6: app.Stop() WaitGroup（防止滚动发布丢数据）
2. P1-5: Prometheus 指标真正 emit（运维可见）
3. P1-9 + P1-10: watchlist 认证警告 + cache 错误告警
4. P0 区域之外：补齐 4 个 501 endpoint（movers/stocks/news/financials）至少返回真实数据
5. HKEX feed 真正接入（解硬编码）

### Wave 3：到达"早期增长"标准
1. 公司行为复权流水线（3-5K 行）
2. JWT RS256 接 AMS 公钥
3. WS Protobuf binary frame
4. 1W/1M K-line 聚合

### Wave 4：到达"规模化"标准
1. TA 指标（集成 cinar/indicator + decimal 包装）
2. 跨 feed 交叉校验
3. WS 订阅分片 + per-client coalesce
4. Migration v3+：补齐财务/新闻/日历/符号映射表

### 暂不投入
- L2 Order Book（零售场景需求弱）
- Tick 历史存储（透传 Polygon 即可）
- 期权 / 期货 / 指数（业务上线再评估）

---

## 9. 待解决的开放问题

| 问题 | 影响 | 谁来决定 |
|------|------|--------|
| 数据 license 升级时间表（Polygon 标准 → Poly.feed+） | 直接影响能否上 prod | 商务 + 法务 |
| 是否做量化回测产品 | 决定 tick 存储是否需要 | 产品 |
| 期权业务上线时间 | 决定期权链模块优先级 | 产品 |
| HK 市场 license 提供商最终选型 | 影响 HK feed 实现工作量 | 商务 |
| L2 Order Book 是否纳入 v1 | 决定整个数据模型设计 | 产品 + 技术 |
| Index 数据 license（S&P/NASDAQ） vs ETF 代理是否长期方案 | 决定指数组件工作 | 商务 + 法务 |

---

## 附录：本文档与其他文档的关系

```
docs/
├── code-review-2026-03-25.md     ← 上一轮 review（Wave 1-7 修复记录）
├── code-review-2026-05-08.md     ← 当前 review（4 P0/6 P1/5 P2/3 P3）
├── market-data-production-gap-2026-05-09.md  ← 本文档（生产化分析 + 参考全景）
├── active-features.yaml          ← 功能跟踪
├── patches.yaml                  ← Patch 注册
└── specs/                        ← 技术规范
    ├── market-data-system.md     ← System spec v2.1
    ├── market-api-spec.md        ← REST API spec
    ├── websocket-spec.md         ← WS protocol spec
    └── data-flow.md              ← Feed → Cache → WS 数据流
```

本文档定位：**横切性的现实主义评估**，给规划/架构决策提供基线，不替代具体的技术 spec 或 review。下一份类似文档建议 3 个月后写，对比代码量增长曲线和优先级偏离度。
