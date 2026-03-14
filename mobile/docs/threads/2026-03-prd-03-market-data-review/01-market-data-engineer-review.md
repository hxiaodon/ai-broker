---
seq: 01
author_role: market-data-engineer
date: 2026-03-14T10:00+08:00
action: RAISE_ISSUE
---

# Market Data Engineer 技术评审意见

> 对象: PRD-03 行情模块 v1.1 (2026-03-13)
> 评审人: market-data-engineer
> 参照: financial-coding-standards, security-compliance, market-data service CLAUDE.md

---

## CRITICAL

### C1: 访客延迟行情实现方案有严重内存风险

**位置**: PRD Section 6.3

**问题**: PRD 描述"行情推送在服务端延迟 15 分钟后发送"。如果实现为"hold 住实时消息 15 分钟后再推给 guest 连接"，则：
- 每个 guest 连接需要在服务端维护一个 15 分钟的消息缓冲队列
- 目标 10 万并发连接中，假设 50% 为访客 = 5 万个队列
- 每个 symbol 每秒 1-5 条 tick，假设 guest 订阅 10 只股票 → 每连接约 45,000 条/15min
- 总内存消耗估算：5 万 × 45,000 × ~200bytes ≈ **420GB**，完全不可行

**建议**: 改为以下架构（不影响 PRD 产品逻辑，只调整实现描述）：
1. 服务端维护一份**全局**的"15 分钟前行情快照"（Ring Buffer 或 Redis Sorted Set，按时间索引）
2. Guest 连接订阅时，从 T-15min 的快照中读取数据推送
3. 推送频率降低为每 **5-10 秒** 一次（而非实时 tick），因为延迟行情无需 sub-second 更新
4. 全局共享一份历史数据，内存开销从 O(连接数 × 消息量) 降到 O(symbol 数 × 15min 数据量)

**PRD 修改建议**: Section 6.3 第二行改为：
> ~~行情推送在服务端延迟 15 分钟后发送~~
> 服务端从 15 分钟前的行情快照缓存中读取数据推送给访客连接，推送频率为每 5 秒一次

---

### C2: Watchlist 数量上限三处描述矛盾

**位置**: PRD Section 5.1 / Section 7.5 / Section 9.1

**问题**: 三处对自选股上限的描述不一致：

| 位置 | 描述 |
|------|------|
| Section 5.1 功能规格 | "最大数量: 200 只（Phase 1 暂不设上限，后续评估）" |
| Section 7.5 Watchlist API | "每用户最多 **100** 支自选股，超出返回 400 WATCHLIST_FULL" |
| Section 9.1 数据模型 | "约束：每用户上限 **100** 条，应用层检查" |

**影响**: 前端显示的上限提示和后端校验不一致，会导致用户在第 101 只时被后端拒绝但前端未提示。

**建议**: 统一为 **100 只**（与数据模型和 API 约束一致）。Section 5.1 改为：
> 最大数量: 100 只（Phase 2 可评估扩展）

---

## HIGH

### H1: 分钟 K 线"当日全量返回"可能超过 500 条限制

**位置**: PRD Section 7.2 分页规则

**问题**:
- 规则："分钟级（period=1min 且含 date 参数）不支持 cursor，直接返回当日全量"
- 但 limit 最大 500 条
- 美股盘前 04:00 ~ 盘后 20:00 = 960 分钟 > 500
- 即使只算常规交易时段 09:30-16:00 = 390 分钟（可以）
- PRD-04 允许盘前/盘后交易，用户可能需要查看含盘前盘后的分钟线

**建议**: 明确"当日全量"范围：
- **方案 A**: 分钟线仅包含常规交易时段 (09:30-16:00)，约 390 条，不超限 ✅
- **方案 B**: 分钟线包含盘前盘后 (04:00-20:00)，需取消 cursor 限制或改用 cursor 分页
- 推荐 **方案 A**，盘前盘后价格数据仍通过 WebSocket 实时展示，不必入 K 线

---

### H2: 盘口深度 (Order Book / Level 2) 接口未定义

**位置**: PRD 整体

**问题**:
- PRD-04 交易模块依赖 NBBO (National Best Bid and Offer) 数据做市价单 Collar 计算
- PRD-03 Section 3.2 股票详情页有 bid/ask 字段
- PRD-03 Section 6.2 WebSocket 推送也含 bid/ask
- 但 PRD-03 **没有定义独立的盘口深度 REST API 或 WebSocket depth 订阅协议**
- 如果 Phase 1 只需要 Level 1 (最佳买一/卖一)，当前 quote 推送已包含 bid/ask，足够
- 但如果将来需要 5 档/10 档盘口，需要独立接口

**建议**:
- PM 确认 Phase 1 是否只需 Level 1 (bid/ask 在 quote 中即可)
- 如果 Phase 1 不需要深度盘口，建议在 PRD 中明确标注："Phase 1 仅提供 Level 1 报价（最佳买一/卖一），Level 2 深度盘口 Phase 2 规划"
- 保留 bid/ask 在 quote 推送和 REST 响应中即可

---

### H3: 换手率 (turnover rate) 字段定义缺失

**位置**: PRD Section 3.2 价格英雄区

**问题**:
- 价格英雄区字段列表中包含"换手率"
- 但 Section 7.1 的 quotes API 响应示例中没有 `turnover_rate` 字段
- Polygon API 不直接提供换手率，需要计算：`turnover_rate = volume / shares_outstanding`
- `shares_outstanding`（流通股数）属于基本面数据，非实时更新

**建议**:
1. 在 Section 7.1 quotes 响应中补充 `"turnover_rate": "1.62"` 字段（百分比字符串）
2. 明确计算公式和精度：`turnover_rate = (volume / shares_outstanding) × 100`，保留 2 位小数
3. `shares_outstanding` 每日更新即可（来自基本面数据源）

---

### H4: 新闻数据源 Phase 1 方案"待定"

**位置**: PRD Section 3.5

**问题**: "数据源: Polygon.io 新闻 API / Finnhub（Phase 1 方案待定）"。数据源未确认将影响：
- 接口响应字段设计（不同源返回字段不同）
- 开发排期（需要适配 SDK）
- 成本预算

**建议**: PM 尽快确认。从技术角度建议：
- **Polygon.io 新闻 API**: 若行情已用 Polygon，新闻复用同一 SDK，集成成本最低
- Finnhub: 需额外 API Key 和适配工作

---

### H5: WebSocket 缺少 unsubscribe 和心跳协议

**位置**: PRD Section 6.2

**问题**:
1. **unsubscribe 未定义**: 用户离开股票详情页或切换 Tab 时需要取消订阅，否则服务端持续推送无用数据。缺少 `{"action": "unsubscribe", "symbols": [...]}` 的协议定义。
2. **心跳未定义**: Section 6.2 只定义了 auth/subscribe/quote 消息，没有 ping/pong 心跳协议。WebSocket 长连接需要心跳保活，否则中间设备（NAT、LB）可能超时断开。

**建议**: 在 Section 6.2 中补充：

```json
// 取消订阅
{ "action": "unsubscribe", "symbols": ["AAPL"] }

// 心跳（客户端每 30 秒发送）
{ "action": "ping" }
// 服务端响应
{ "type": "pong", "timestamp": "2026-03-13T14:30:00Z" }
```

同时明确：
- 客户端心跳间隔：30 秒
- 服务端无心跳超时：60 秒自动断开
- 断开后客户端自动重连（指数退避，最长 30 秒间隔，与 PRD-07 Section 9.1 一致）

---

### H6: market_status 枚举缺少 HALTED 状态

**位置**: PRD Section 7.1 quotes API 响应 / Section 8 交易时段规则

**问题**:
- Section 7.1: `"market_status": "REGULAR" | "PRE_MARKET" | "AFTER_HOURS" | "CLOSED"`
- 但 PRD-07 Section 9.2 明确定义了交易暂停 (Trading Halt) 场景
- PRD-03 Section 8 没有 Halt 行
- 交易暂停时股票不可买卖（PRD-04 Section 9 ERR_TRADING_HALTED），但 market_status 没有对应值

**建议**: 在枚举中增加 `"HALTED"` 状态：

```
"market_status": "REGULAR" | "PRE_MARKET" | "AFTER_HOURS" | "CLOSED" | "HALTED"
```

同时在 Section 8 交易时段表中增加 Halt 行：

| 时段 | ET 时间 | 显示标签 | 可买卖 |
|------|--------|---------|-------|
| 交易暂停 | 交易所通知 | "暂停交易" 红色标签 | ❌ |

---

## MEDIUM

### M1: 数据模型 DDL 使用 PostgreSQL 语法，项目用 MySQL

**位置**: PRD Section 9.1

**问题**:
- 使用了 `UUID` 类型 — MySQL 无原生 UUID 类型
- 使用了 `TIMESTAMPTZ` — MySQL 无此类型（应为 `TIMESTAMP` 或 `DATETIME`）
- 使用了 `REFERENCES users(id)` — MySQL InnoDB 支持外键但语法不同
- 使用了 `NOW()` — MySQL 中建议用 `CURRENT_TIMESTAMP`
- 项目 `services/market-data/CLAUDE.md` 明确声明 **MySQL 8.0+**

**建议**: 将 DDL 调整为 MySQL 方言。注意：这是 Surface PRD 中的示意性数据模型，最终 DDL 以 market-data 域的 `scripts/init_db.sql` 为准。但为避免开发误解，建议至少改正类型名。

---

### M2: 搜索 debounce 策略和拼音搜索性能

**位置**: PRD Section 4.2 / Section 7.3

**问题**:
- PRD 要求搜索响应 < 300ms，但未提到客户端 debounce 策略
- 用户快速输入时每个字符都触发搜索请求，会产生大量无效请求
- 拼音首字母搜索（"pg" → 苹果）需要后端维护拼音索引，搜索复杂度较高

**建议**:
1. PRD 补充：客户端输入 debounce 间隔 **300ms**（即停止输入 300ms 后才发起搜索）
2. 拼音搜索：在股票元数据表中预存 `pinyin_initials` 字段（如 "pg" 对应 "苹果"），避免运行时计算
3. 搜索最少输入 **1 个字符**（代码搜索）或 **2 个字符**（中文/拼音搜索），减少无效查询

---

### M3: Redis 访客延迟行情缓存策略语义不清

**位置**: PRD Section 9.2

**问题**:
- 描述："延迟行情（访客）：1200s（15min 对应）"
- 语义不清：1200s TTL 意味着这个 key 15 分钟后过期，但延迟行情应该是"15 分钟前的实时行情"
- 正确的语义是：维护一份 T-15min 的行情快照数据，而非简单设置 15 分钟 TTL

**建议**: 与 C1 联动调整，改为：
```
quote:delayed:{symbol}     // Hash，15分钟前的行情数据
TTL = 60s（每分钟从历史数据中刷新一次 T-15min 快照）
```

---

### M4: 美股 Tab 子分类切换交互未明确

**位置**: PRD Section 2.1 / Section 2.4

**问题**:
- 美股 Tab 下有三种数据：热门 / 涨幅榜 / 跌幅榜
- PRD 未明确这三者的 UI 交互形式（子 Tab？分段控件？下拉选择？）
- 原型 `market.html` 也未实现此功能

**建议**: PM 与 ui-designer 确认交互形式，补充到 PRD Section 2.1。建议使用**分段控件 (SegmentedControl)**：`热门 | 涨幅 | 跌幅`

---

### M5: API 响应是否需要统一包装格式

**位置**: PRD Section 7 全部接口

**问题**:
- PRD 中的 API 响应直接返回业务数据，如 `{"quotes": {...}}`
- 通常生产 API 会有统一包装格式：`{"code": 0, "message": "success", "data": {...}}`
- 统一包装便于前端统一错误处理、版本管理

**建议**: PM 确认全局 API 响应格式规范。如果其他域（AMS、Trading Engine）已有约定，行情服务应保持一致。此项应由**跨域契约** (`docs/contracts/`) 统一定义。

---

## LOW（原型差异）

### L1: stock-detail.html 原型缺少关键显示元素

**位置**: `mobile/prototypes/stock-detail.html`

与 PRD Section 3.1-3.2 对比，原型缺少：
- [ ] 交易时段标识（盘前/盘后/休市标签）— PRD Section 3.7 要求
- [ ] 昨收（前一日收盘价）字段 — PRD Section 3.2 "昨收"
- [ ] 成交额（当日成交额）字段 — PRD Section 3.2 "成交额"
- [ ] 换手率 — PRD Section 3.2 "换手率"
- [ ] 价格精度：原型显示 2 位小数 (`$175.23`)，PRD 要求美股 **4 位小数**

---

### L2: market.html 颜色方案与 PRD 默认设置不一致

**位置**: `mobile/prototypes/market.html`

- 原型硬编码 **绿涨红跌** (`.price-up { color: #10B981 }`)
- PRD Section 2.2：默认 +86 用户 **红涨绿跌**，默认 +852 用户 绿涨红跌
- 原型应至少注释说明颜色设置来自用户偏好

---

### L3: search.html 空状态提示不完整

**位置**: `mobile/prototypes/search.html`

- 原型：`"未找到相关股票"`
- PRD Section 4.6：`"未找到 'XXXXX' 相关股票"` + 提示 `"美股代码由 1-5 位字母组成"`
- 访客模式下搜索结果应显示 `delayed` 标识（与行情列表一致）

---

## 需要回复方

- [ ] **product-manager**: 回复 C1、C2、H1-H6、M1-M5（共 13 项）
- [ ] **ui-designer**: 回复 M4、L1-L3（共 4 项）
