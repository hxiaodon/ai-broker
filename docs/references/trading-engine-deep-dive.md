# Trading Engine 深度剖析
## 面向零售美港股券商系统的参考文档

> **文档定位**: 以 NautilusTrader 源码为一手参考，结合零售券商业务场景，深入剖析领域模型、执行引擎、数据引擎三个核心模块的设计原理与关键实现，供券商 Trading Engine 服务的架构设计与工程实现参考。
>
> **适用读者**: 交易引擎后端工程师、架构师、技术 PM
>
> **源码基准**: NautilusTrader v1.225.0 (`develop` branch)

---

## 目录

1. [系统全局架构](#1-系统全局架构)
2. [领域模型层](#2-领域模型层)
   - 2.1 核心值类型：Price / Quantity / Money
   - 2.2 金融工具模型
   - 2.3 订单类型体系
   - 2.4 订单状态机（最核心）
   - 2.5 订单事件体系
   - 2.6 持仓模型
3. [执行引擎层](#3-执行引擎层)
   - 3.1 整体架构
   - 3.2 风控引擎（Pre-Trade）
   - 3.3 订单管理系统（OMS）
   - 3.4 执行客户端（ExecClient）
   - 3.5 关键流程：下单全链路
   - 3.6 关键流程：撤单竞态处理
4. [数据引擎层](#4-数据引擎层)
   - 4.1 整体架构
   - 4.2 行情数据类型
   - 4.3 订单簿维护
   - 4.4 K 线聚合
   - 4.5 Cache：系统状态中枢
5. [MessageBus：系统解耦的核心](#5-messagebus系统解耦的核心)
6. [券商适配要点](#6-券商适配要点)

---

## 1. 系统全局架构

NautilusTrader 采用**单进程事件驱动架构**，所有组件通过 `MessageBus` 解耦通信，不存在直接方法调用跨越模块边界。

```mermaid
graph TD
    subgraph "外部世界"
        EX[交易所/Broker<br/>NYSE/HKEX/IB]
        MD[行情源<br/>Polygon/HKEX OMD]
    end

    subgraph "NautilusTrader 核心"
        direction TB
        DC[DataClient<br/>数据接入适配器]
        DE[DataEngine<br/>数据引擎]
        MB[MessageBus<br/>消息总线]
        RE[RiskEngine<br/>风控引擎]
        EE[ExecutionEngine<br/>执行引擎]
        EC[ExecutionClient<br/>执行适配器]
        CA[Cache<br/>状态中枢]
        PF[Portfolio<br/>组合/持仓]
        ST[Strategy / Actor<br/>策略/业务逻辑]
    end

    MD --> DC --> DE
    DE --> MB
    MB --> ST
    ST --> MB
    MB --> RE
    RE --> EE
    EE --> EC --> EX
    EX --> EC --> MB
    MB --> CA
    MB --> PF
    CA <-.-> DE
    CA <-.-> EE
```

**关键设计原则**：
- `RiskEngine` 在 `ExecutionEngine` 上游 —— 命令必须先过风控才能发到交易所
- `Cache` 是全局只写一次的真相来源（Source of Truth），所有查询走 Cache
- `MessageBus` 是唯一通信通道，订阅/发布模式，组件间零直接依赖

> **源码入口**:
> - 消息体系: `crates/common/src/messages/mod.rs`
> - MessageBus: `crates/common/src/msgbus/mod.rs`
> - Cache: `crates/common/src/cache/mod.rs`

---

## 2. 领域模型层

### 2.1 核心值类型：Price / Quantity / Money

这是整个交易系统最底层的基石，设计上有三个关键决策：

#### 决策一：固定精度整数，禁止浮点数

```
Price 内部表示:
  标准模式:  i64  (64位整数)
  高精度模式: i128 (128位整数，feature = "high-precision")

例: 价格 $123.45，precision=2
  内部存储: 12345 (i64)
  FIXED_SCALAR: 1_000_000_000 (10^9)
  实际内部值: 12345 * 10^9 = 12_345_000_000_000
```

> **源码**: `crates/model/src/types/price.rs:1-80`
> **源码**: `crates/model/src/types/fixed.rs` — `FIXED_PRECISION`, `FIXED_SCALAR`

**为什么不用浮点**：`0.1 + 0.2 = 0.30000000000000004`，在金融系统中会导致撮合错误、保证金计算偏差。NautilusTrader 全程整数运算，Python API 层用 `str` 传递，与你的接口契约 **"所有金额字段使用 string 编码的 decimal，禁止浮点数"** 完全一致。

#### 决策二：不可变值类型（Immutable Value Types）

```rust
// Price / Quantity / Money 均为 Copy 类型
// 算术运算返回新实例，不修改原值
let p1 = Price::new(100.50, 2);
let p2 = Price::new(0.01, 2);
let p3 = p1 + p2;  // 返回新 Price(100.51)，p1 不变
```

#### 决策三：三种类型各司其职

| 类型 | 用途 | 正负 | 精度来源 |
|---|---|---|---|
| `Price` | 市场报价、订单价格 | 可为负（期差/基差） | 交易所规格 |
| `Quantity` | 数量、手数 | 恒正 | 交易所规格 |
| `Money` | 金额（含货币） | 可为负（亏损） | 货币精度 |

> **源码**: `crates/model/src/types/` 目录下各文件

---

### 2.2 金融工具模型

```mermaid
classDiagram
    class InstrumentAny {
        <<enum>>
        Equity
        FuturesContract
        OptionContract
        CurrencyPair
        CryptoPerpetual
        ...共14种
    }

    class Equity {
        +InstrumentId id
        +Symbol raw_symbol
        +Option~Ustr~ isin
        +Currency currency
        +u8 price_precision
        +Price price_increment
        +Decimal maker_fee
        +Decimal taker_fee
        +Option~Quantity~ lot_size
        +Option~Quantity~ min_quantity
        +Option~Price~ min_price
    }

    class FuturesContract {
        +InstrumentId id
        +AssetClass asset_class
        +Price price_increment
        +Quantity multiplier
        +UnixNanos expiry_date
    }

    class InstrumentId {
        +Symbol symbol
        +Venue venue
        toString() "AAPL.XNAS"
    }

    InstrumentAny --> Equity
    InstrumentAny --> FuturesContract
    Equity --> InstrumentId
```

**对券商的关键字段**：

| 字段 | 用途 | 券商场景 |
|---|---|---|
| `price_increment` | 最小报价单位（Tick Size） | 港股 0.01/0.001，美股 $0.01 |
| `lot_size` | 最小交易单位 | 港股 100/200/500 手，美股 1 股 |
| `min_quantity` | 最小下单量 | 碎股支持时设为 1 |
| `maker_fee / taker_fee` | 费率 | 计算预估手续费 |
| `margin_init / margin_maint` | 保证金比例 | 融资融券业务 |

> **源码**: `crates/model/src/instruments/equity.rs`
> **源码**: `crates/model/src/instruments/futures_contract.rs`

---

### 2.3 订单类型体系

```mermaid
graph TD
    subgraph "基础订单类型"
        MO[MarketOrder<br/>市价单]
        LO[LimitOrder<br/>限价单]
        SM[StopMarket<br/>止损市价单]
        SL[StopLimit<br/>止损限价单]
        MTL[MarketToLimit<br/>市转限]
    end

    subgraph "条件触发订单"
        MIT[MarketIfTouched<br/>触碰市价单]
        LIT[LimitIfTouched<br/>触碰限价单]
        TSM[TrailingStopMarket<br/>追踪止损市价]
        TSL[TrailingStopLimit<br/>追踪止损限价]
    end

    subgraph "组合订单（ContingencyType）"
        OCO[OCO<br/>One-Cancels-Other]
        OTO[OTO<br/>One-Triggers-Other]
        OUO[OUO<br/>One-Updates-Other]
    end

    OL[OrderList<br/>订单组合容器] --> OCO
    OL --> OTO
    OL --> OUO
```

**零售券商常用订单类型**（美港股场景）：

| 订单类型 | 美股 | 港股 | 说明 |
|---|---|---|---|
| `MarketOrder` | ✓ | ✓ | 即时以最优价成交 |
| `LimitOrder` | ✓ | ✓ | 指定价格或更优价成交 |
| `StopMarket` | ✓ | 部分 | 触发后转市价单，常用于止损 |
| `StopLimit` | ✓ | 部分 | 触发后转限价单 |
| `TrailingStopMarket` | ✓ | ✗ | 追踪止损，价格跟随市场 |

**每个订单的完整字段**（以 LimitOrder 为例）：

```rust
// crates/model/src/orders/limit.rs
pub struct LimitOrder {
    // 身份
    pub trader_id: TraderId,
    pub strategy_id: StrategyId,
    pub instrument_id: InstrumentId,
    pub client_order_id: ClientOrderId,   // 客户端生成的唯一ID
    pub venue_order_id: Option<VenueOrderId>, // 交易所返回的ID

    // 订单参数
    pub order_side: OrderSide,      // Buy / Sell
    pub quantity: Quantity,          // 委托数量
    pub price: Price,                // 限价

    // 执行指令
    pub time_in_force: TimeInForce,  // GTC/DAY/IOC/FOK/GTD
    pub expire_time: Option<UnixNanos>,  // GTD 过期时间
    pub post_only: bool,             // 只做 Maker（拒绝 Taker）
    pub reduce_only: bool,           // 只减仓（期货场景）
    pub display_qty: Option<Quantity>, // 冰山单显示量

    // 状态追踪
    pub status: OrderStatus,
    pub filled_qty: Quantity,        // 已成交数量
    pub avg_px: Option<f64>,         // 平均成交价
    pub events: Vec<OrderEventAny>,  // 完整事件历史

    // 时间戳（纳秒）
    pub ts_init: UnixNanos,
    pub ts_last: UnixNanos,
}
```

> **TimeInForce 枚举**:
> - `GTC` — Good Till Cancelled，撤销前有效
> - `DAY` — 当日有效，收盘自动撤销
> - `IOC` — Immediate Or Cancel，立即成交剩余撤销
> - `FOK` — Fill Or Kill，全部成交或全部撤销
> - `GTD` — Good Till Date，指定日期前有效
> - `AT_THE_OPEN` / `AT_THE_CLOSE` — 开盘/收盘集合竞价

---

### 2.4 订单状态机（最核心）

这是整个交易系统正确性的基础，NautilusTrader 对每一个状态转换都做了严格的合法性验证。

```mermaid
stateDiagram-v2
    [*] --> Initialized : 订单创建

    Initialized --> Denied : 风控拒绝
    Initialized --> Emulated : 本地模拟执行
    Initialized --> Submitted : 提交到交易所
    Initialized --> Rejected : 外部订单直接拒绝

    Emulated --> Released : 触发条件满足
    Emulated --> Canceled : 用户撤销
    Emulated --> Expired : GTD到期

    Released --> Submitted : 提交到交易所
    Released --> Denied : 提交前风控拒绝

    Submitted --> Accepted : 交易所确认接收
    Submitted --> Rejected : 交易所拒绝
    Submitted --> Canceled : FOK/IOC未成交撤销
    Submitted --> Filled : 直接全部成交

    Accepted --> PendingUpdate : 发送改单请求
    Accepted --> PendingCancel : 发送撤单请求
    Accepted --> Triggered : 条件单触发
    Accepted --> PartiallyFilled : 部分成交
    Accepted --> Filled : 全部成交
    Accepted --> Canceled : 撤单成功
    Accepted --> Expired : GTD到期

    PendingUpdate --> Accepted : 改单成功/改单失败恢复
    PendingUpdate --> PendingCancel : 继续撤单
    PendingUpdate --> Filled : 改单过程中成交

    PendingCancel --> Canceled : 撤单成功
    PendingCancel --> Accepted : 撤单失败(竞态)
    PendingCancel --> Filled : 撤单过程中成交⚡

    PartiallyFilled --> PendingUpdate : 发送改单
    PartiallyFilled --> PendingCancel : 发送撤单
    PartiallyFilled --> Filled : 剩余全部成交
    PartiallyFilled --> Canceled : 剩余撤销

    Triggered --> PendingCancel : 撤销
    Triggered --> Filled : 成交

    Canceled --> Filled : ⚡竞态：撤单后仍收到成交回报

    Denied --> [*]
    Rejected --> [*]
    Filled --> [*]
    Canceled --> [*]
    Expired --> [*]
```

> ⚡ **竞态场景**（Real-world possibility）: 已标注为源码注释，`Canceled → Filled` 和 `PendingCancel → Filled` 是真实市场中存在的情况，NautilusTrader 专门处理了这个状态转换。

> **源码**: `crates/model/src/orders/mod.rs` — `impl OrderStatus { fn transition(...) }`

**状态分组**：

```rust
// is_open() —— 订单仍在交易所挂单中
Submitted | Accepted | Triggered | PendingUpdate | PendingCancel | PartiallyFilled

// is_closed() —— 终态，不可再变更
Denied | Rejected | Canceled | Expired | Filled

// is_cancellable() —— 可以发送撤单请求
Accepted | Triggered | PendingUpdate | PartiallyFilled
// 注意：PendingCancel 不在此列，防止重复撤单
```

---

### 2.5 订单事件体系

订单的每一次状态变化都由一个**不可变事件**驱动，事件永久记录在 `order.events` 列表中，形成完整的审计日志。

```mermaid
graph LR
    subgraph "命令 → 事件 映射"
        direction TB
        CMD1[SubmitOrder] --> EVT1[OrderSubmitted]
        EVT1 --> EVT2[OrderAccepted / OrderRejected]
        CMD2[ModifyOrder] --> EVT3[OrderPendingUpdate]
        EVT3 --> EVT4[OrderUpdated / OrderModifyRejected]
        CMD3[CancelOrder] --> EVT5[OrderPendingCancel]
        EVT5 --> EVT6[OrderCanceled / OrderCancelRejected]
        EX[交易所回报] --> EVT7[OrderFilled / OrderPartiallyFilled]
    end
```

**完整事件列表**：

| 事件 | 触发方 | 说明 |
|---|---|---|
| `OrderInitialized` | 客户端 | 订单对象创建 |
| `OrderDenied` | 风控引擎 | Pre-trade 风控拒绝 |
| `OrderSubmitted` | 执行引擎 | 已提交给交易所 |
| `OrderAccepted` | 交易所 | 交易所确认接收 |
| `OrderRejected` | 交易所 | 交易所拒绝（含原因） |
| `OrderPendingUpdate` | 执行引擎 | 发出改单请求 |
| `OrderUpdated` | 交易所 | 改单成功 |
| `OrderModifyRejected` | 交易所 | 改单被拒 |
| `OrderPendingCancel` | 执行引擎 | 发出撤单请求 |
| `OrderCanceled` | 交易所 | 撤单成功 |
| `OrderCancelRejected` | 交易所 | 撤单被拒 |
| `OrderExpired` | 交易所 | GTD/DAY 到期 |
| `OrderTriggered` | 交易所 | 条件单触发 |
| `OrderFilled` | 交易所 | 成交（含成交价/量/手续费） |

> **源码**: `crates/model/src/events/order/mod.rs`
> **完整事件**: `OrderFilled` 含 `last_px`, `last_qty`, `commission`, `liquidity_side(Maker/Taker)`, `trade_id`

---

### 2.6 持仓模型

```mermaid
classDiagram
    class Position {
        +PositionId id
        +InstrumentId instrument_id
        +AccountId account_id
        +PositionSide side  ← LONG/SHORT/FLAT
        +Quantity quantity
        +f64 avg_px_open    ← 持仓均价
        +f64 avg_px_close
        +f64 realized_pnl   ← 已实现盈亏
        +f64 unrealized_pnl(last_px) ← 未实现盈亏
        +Money commission   ← 累计手续费
        +List~TradeId~ trade_ids ← 关联成交流水
        +apply(OrderFilled)
        +is_open() bool
        +is_closed() bool
    }

    class PositionSide {
        <<enum>>
        NoPositionSide
        Long
        Short
        Flat
    }

    Position --> PositionSide
```

**持仓均价计算**（加权平均）：
```
新增买入：
  avg_px = (old_qty * old_avg_px + fill_qty * fill_px) / (old_qty + fill_qty)

减仓卖出：
  realized_pnl += (fill_px - avg_px_open) * fill_qty - commission
  quantity -= fill_qty
```

> **源码**: `crates/model/src/position.rs`

---

## 3. 执行引擎层

### 3.1 整体架构

```mermaid
graph TD
    subgraph "命令流（向下）"
        ST[Strategy/Actor<br/>发出 TradingCommand] --> MB[MessageBus]
        MB --> RE[RiskEngine<br/>风控引擎]
        RE -- "通过" --> EE[ExecutionEngine<br/>订单路由/OMS]
        RE -- "拒绝" --> DENY[OrderDenied 事件]
        EE --> OM[OrderManager<br/>OMS 状态追踪]
        EE --> EC[ExecutionClient<br/>交易所适配器]
        EC --> EX[交易所/IB]
    end

    subgraph "回报流（向上）"
        EX2[交易所/IB] --> EC2[ExecutionClient]
        EC2 --> MB2[MessageBus]
        MB2 --> EE2[ExecutionEngine.process]
        EE2 --> OM2[OMS 更新订单状态]
        EE2 --> CA[Cache 更新]
        EE2 --> PF[Portfolio 更新持仓]
        MB2 --> ST2[Strategy 收到事件]
    end
```

> **源码**: `crates/execution/src/engine/mod.rs`

---

### 3.2 风控引擎（Pre-Trade）

风控引擎是订单进入交易所之前的最后一道门，**同步执行**，通过则放行，拒绝则立即产生 `OrderDenied` 事件。

```mermaid
flowchart TD
    CMD[TradingCommand 到达] --> TS{交易状态?}
    TS -- "HALTED" --> DENY1[全部拒绝]
    TS -- "REDUCING" --> CHK1{是否减仓单?}
    CHK1 -- "否" --> DENY2[拒绝非减仓单]
    CHK1 -- "是" --> NEXT
    TS -- "ACTIVE" --> NEXT

    NEXT --> CHK2{订单价格检查}
    CHK2 -- "超出涨跌停/合理范围" --> DENY3[价格异常拒绝]
    CHK2 -- "通过" --> CHK3

    CHK3{订单数量检查}
    CHK3 -- "< min_quantity 或 > max_quantity" --> DENY4[数量异常拒绝]
    CHK3 -- "通过" --> CHK4

    CHK4{名义金额检查}
    CHK4 -- "> max_notional_per_order" --> DENY5[超过单笔限额]
    CHK4 -- "通过" --> CHK5

    CHK5{账户余额/保证金检查}
    CHK5 -- "余额不足" --> DENY6[余额不足拒绝]
    CHK5 -- "通过" --> PASS[放行 → ExecutionEngine]
```

**风控配置参数** (`RiskEngineConfig`):

```rust
pub struct RiskEngineConfig {
    pub bypass: bool,                    // 是否跳过风控（仅测试用）
    pub max_order_submit_rate: Option<RateLimit>,    // 下单频率限制
    pub max_order_modify_rate: Option<RateLimit>,    // 改单频率限制
    pub max_notional_per_order: HashMap<InstrumentId, Decimal>, // 单笔名义额限制
}

// TradingState 枚举
pub enum TradingState {
    Active,    // 正常交易
    Halted,    // 完全暂停（紧急情况）
    Reducing,  // 只允许减仓
}
```

> **源码**: `crates/risk/src/engine/mod.rs` — `check_order()`, `check_order_price()`, `check_order_quantity()`, `check_orders_risk()`

**对零售券商的补充风控**（NautilusTrader 未包含，需自行实现）：

| 风控项 | 说明 | 实现位置建议 |
|---|---|---|
| PDT 规则 | 美股 Pattern Day Trader 检测 | AMS 或 RiskEngine 扩展 |
| 涨跌停板 | 港股价格限制 | RiskEngine price_check |
| 客户交易权限 | KYC 等级对应可交易品种 | AMS → Trading Engine gRPC |
| T+0/T+1 限制 | 港股当日买入不可当日卖出 | Position 检查 |
| 融资融券比例 | 按账户 margin tier | Account 模块 |

---

### 3.3 订单管理系统（OMS）

OMS 负责**跟踪每一笔订单的完整生命周期**，是整个执行引擎的状态核心。

```mermaid
sequenceDiagram
    participant S as Strategy
    participant RE as RiskEngine
    participant EE as ExecutionEngine
    participant OM as OrderManager
    participant CA as Cache
    participant EC as ExecClient(IB)

    S->>RE: SubmitOrder(order)
    RE->>RE: pre-trade 检查
    RE->>EE: SubmitOrder (通过)

    EE->>OM: handle_submit_order()
    OM->>CA: add_order(INITIALIZED)
    EE->>EC: submit_order(order)
    EC->>CA: update_order(SUBMITTED)

    Note over EC: 网络延迟 ~50-200ms

    EC-->>EE: OrderAccepted(venue_order_id)
    EE->>OM: process(OrderAccepted)
    OM->>CA: update_order(ACCEPTED)
    EE-->>S: 广播 OrderAccepted 事件

    EC-->>EE: OrderFilled(fill_px, fill_qty)
    EE->>OM: process(OrderFilled)
    OM->>CA: update_order(FILLED)
    OM->>CA: update_position()
    EE-->>S: 广播 OrderFilled 事件
```

**OMS 核心职责**：

```rust
// crates/execution/src/order_manager/manager.rs 关键方法：

// 1. 注册新订单（提交时）
fn handle_submit_order(order: &OrderAny) {
    cache.add_order(order, INITIALIZED);
}

// 2. 处理交易所回报，驱动状态机
fn process_event(event: &OrderEventAny) {
    let order = cache.get_order(event.client_order_id);
    order.apply(event);          // 触发状态机 transition()
    cache.update_order(order);   // 持久化新状态
    // 若事件是 OrderFilled，同步更新 Position
}

// 3. 对账：系统重启后与交易所同步状态
fn reconcile_order_status_report(report: &OrderStatusReport) {
    // 比对本地状态 vs 交易所状态
    // 生成补偿事件使两者一致
}
```

> **源码**: `crates/execution/src/order_manager/manager.rs`
> **源码**: `crates/execution/src/reconciliation.rs`

---

### 3.4 执行客户端（ExecClient）

每个交易所/Broker 对应一个 `ExecutionClient` 实现，对外暴露统一接口：

```rust
// crates/common/src/clients.rs — ExecutionClient trait
pub trait ExecutionClient {
    async fn submit_order(&mut self, command: &SubmitOrder) -> anyhow::Result<()>;
    async fn modify_order(&mut self, command: &ModifyOrder) -> anyhow::Result<()>;
    async fn cancel_order(&mut self, command: &CancelOrder) -> anyhow::Result<()>;
    async fn cancel_all_orders(&mut self, command: &CancelAllOrders) -> anyhow::Result<()>;
    async fn generate_mass_status(&mut self, ...) -> anyhow::Result<()>;
}
```

对于零售券商，`ExecutionClient` 就是对 IB (Interactive Brokers) TWS API 的封装。它负责：
1. 将内部 `SubmitOrder` 命令转换为 IB 的 `placeOrder()` 调用
2. 将 IB 回调（`orderStatus`, `execDetails`）转换为内部 `OrderFilled` 等事件
3. 管理连接断线重连

---

### 3.5 关键流程：下单全链路

```mermaid
sequenceDiagram
    participant App as 移动端 App
    participant API as Trading Engine API
    participant AMS as AMS (gRPC)
    participant RE as RiskEngine
    participant EE as ExecutionEngine
    participant CA as Cache
    participant IB as Interactive Brokers

    App->>API: POST /api/v1/orders<br/>{symbol,side,qty,price,type}
    API->>API: JWT验证 + HMAC签名校验

    API->>AMS: VerifySession(token)
    AMS-->>API: AccountStatus{可交易, PDT=false}

    API->>CA: 查询买入力（available_balance）
    CA-->>API: 可用资金 $10,000

    API->>API: 构造 LimitOrder 对象<br/>assign client_order_id (UUID)
    API->>RE: SubmitOrder(order)

    RE->>RE: check_price() ← 价格合理性
    RE->>RE: check_quantity() ← 数量合法
    RE->>RE: check_notional() ← 不超单笔限额
    RE->>RE: check_balance() ← 资金充足

    alt 风控通过
        RE->>EE: SubmitOrder
        EE->>CA: add_order(INITIALIZED→SUBMITTED)
        EE->>IB: placeOrder(contract, ibOrder)
        EE-->>API: OrderSubmitted 事件
        API-->>App: HTTP 200 {order_id, status:"SUBMITTED"}

        IB-->>EE: orderStatus(orderId, "Submitted")
        EE->>CA: update(ACCEPTED)
        EE->>App: WebSocket push {status:"ACCEPTED"}

        IB-->>EE: execDetails(fill)
        EE->>CA: update(FILLED), update_position()
        EE->>App: WebSocket push {status:"FILLED", fill_px, fill_qty}
    else 风控拒绝
        RE-->>API: OrderDenied(reason)
        API-->>App: HTTP 400 {error:"ORDER_DENIED", reason}
    end
```

---

### 3.6 关键流程：撤单竞态处理

这是交易系统中最容易出 bug 的场景：**用户撤单的同时，交易所正好成交了**。

```mermaid
sequenceDiagram
    participant App as 移动端
    participant API as Trading Engine
    participant EE as ExecutionEngine
    participant CA as Cache
    participant IB as IB

    App->>API: DELETE /api/v1/orders/{id}
    API->>EE: CancelOrder(client_order_id)
    EE->>CA: update(ACCEPTED → PENDING_CANCEL)
    EE->>IB: cancelOrder(ibOrderId)

    Note over IB: 网络传输中...

    par 并发竞态
        IB-->>EE: execDetails(FILLED) ← 成交先到达
    and
        IB-->>EE: orderStatus(Cancelled) ← 撤单确认
    end

    Note over EE: 关键！先处理 FILLED

    EE->>EE: process(OrderFilled)
    Note over EE: PENDING_CANCEL → FILLED ✓ 合法转换
    EE->>CA: update(FILLED), create_position()
    EE->>App: WebSocket push {status:"FILLED"}

    Note over EE: 丢弃后到的 Cancelled 事件
    Note over EE: （或：Canceled → Filled 也是合法转换）

    App->>API: GET /api/v1/orders/{id}
    API-->>App: {status:"FILLED", fill_px:..., fill_qty:...}
```

**状态机的竞态保护**（源码中的注释）：
```rust
// crates/model/src/orders/mod.rs
(Self::Canceled, OrderEventAny::Filled(_)) => Self::Filled,
// "Real world possibility" —— 已撤单后收到成交回报，合法转换

(Self::PendingCancel, OrderEventAny::Filled(_)) => Self::Filled,
// 撤单进行中收到成交回报，优先处理成交

(Self::PendingCancel, OrderEventAny::Accepted(_)) => Self::Accepted,
// 撤单请求失败，恢复为 Accepted，订单仍在场上
```

---

## 4. 数据引擎层

### 4.1 整体架构

```mermaid
graph TD
    subgraph "数据源"
        PG[Polygon API<br/>美股行情]
        HK[HKEX OMD<br/>港股行情]
    end

    subgraph "DataEngine"
        DC1[DataClient<br/>Polygon Adapter]
        DC2[DataClient<br/>HKEX Adapter]

        DC1 --> DE[DataEngine Core]
        DC2 --> DE

        DE --> OB[OrderBook<br/>订单簿维护]
        DE --> BA[BarAggregator<br/>K线聚合]
        DE --> CA2[Cache<br/>行情快照存储]
        DE --> MB3[MessageBus<br/>推送给订阅者]
    end

    subgraph "消费者"
        ST3[Strategy<br/>策略信号]
        WS[WebSocket Server<br/>推送给移动端]
        RE3[RiskEngine<br/>价格合理性检查]
    end

    PG --> DC1
    HK --> DC2
    MB3 --> ST3
    MB3 --> WS
    MB3 --> RE3
```

> **源码**: `crates/data/src/engine/mod.rs`

---

### 4.2 行情数据类型

NautilusTrader 定义了**完整的行情数据类型层次**：

```mermaid
classDiagram
    class QuoteTick {
        +InstrumentId instrument_id
        +Price bid_price      ← 买一价
        +Price ask_price      ← 卖一价
        +Quantity bid_size    ← 买一量
        +Quantity ask_size    ← 卖一量
        +UnixNanos ts_event   ← 交易所时间
        +UnixNanos ts_init    ← 接收时间
    }

    class TradeTick {
        +InstrumentId instrument_id
        +Price price          ← 成交价
        +Quantity size        ← 成交量
        +AggressorSide aggressor_side  ← 主动方 Buy/Sell
        +TradeId trade_id
        +UnixNanos ts_event
    }

    class Bar {
        +BarType bar_type     ← 含 symbol+周期+价格类型
        +Price open
        +Price high
        +Price low
        +Price close
        +Quantity volume
        +UnixNanos ts_event   ← Bar 结束时间
    }

    class OrderBookDelta {
        +InstrumentId instrument_id
        +BookAction action    ← ADD/UPDATE/DELETE/CLEAR
        +BookOrder order      ← price + size + side + order_id
        +UnixNanos ts_event
    }
```

**BarType 的设计**（非常精巧）：

```
BarType = InstrumentId + BarSpecification + AggregationSource

BarSpecification = step + aggregation + price_type
例如:
  "AAPL.XNAS-1-MINUTE-LAST-EXTERNAL"   ← 1分钟K线，用最新价，来自外部
  "AAPL.XNAS-5-MINUTE-BID-INTERNAL"    ← 5分钟K线，用买价，内部聚合
  "AAPL.XNAS-1-VOLUME-MID-INTERNAL"    ← 按成交量聚合，1手一根K线
```

`AggregationSource` 区分了两种 K 线来源：
- `EXTERNAL` — 从数据源直接获取（如 Polygon 推送现成的 1min Bar）
- `INTERNAL` — 从 Tick 数据在本地聚合计算

> **源码**: `crates/model/src/data/bar.rs`

---

### 4.3 订单簿维护

```mermaid
graph LR
    subgraph "订单簿更新流"
        D[OrderBookDelta 增量] --> OB[OrderBook]
        SNAP[OrderBookSnapshot 快照] --> OB
        DEPTH[OrderBookDepth10 十档] --> OB
    end

    subgraph "OrderBook 内部"
        OB --> BIDS[Bids 买方挂单<br/>价格降序]
        OB --> ASKS[Asks 卖方挂单<br/>价格升序]
    end

    subgraph "输出"
        BIDS --> Q[最优买卖价<br/>spread 计算]
        ASKS --> Q
        BIDS --> MID[中间价<br/>mark price]
        ASKS --> MID
    end
```

NautilusTrader 支持三种订单簿精度：
- `L1_MBP` — 仅 Top of Book（买一/卖一）
- `L2_MBP` — 多档聚合（按价位）
- `L3_MBO` — 逐单订单簿（机构级别）

零售券商通常使用 `L1_MBP` 或 `L2_MBP`（十档盘口）。

> **源码**: `crates/model/src/orderbook/`

---

### 4.4 K 线聚合

内部聚合是 NautilusTrader 的一个亮点：从 Tick 流实时生成任意周期 K 线。

```mermaid
sequenceDiagram
    participant DC as DataClient(Polygon)
    participant DE as DataEngine
    participant BA as BarAggregator
    participant CA as Cache
    participant MB as MessageBus

    DC->>DE: QuoteTick(AAPL, bid=150.01, ask=150.02)
    DE->>BA: update(tick)

    BA->>BA: 检查是否达到聚合条件
    Note over BA: 时间聚合：已过1分钟？<br/>成交量聚合：已满X手？<br/>Tick聚合：已满N笔？

    alt 未达到聚合条件
        BA->>BA: 更新 open/high/low/close/volume
    else 达到聚合条件，Bar完成
        BA->>MB: publish(Bar{AAPL.1min})
        MB->>CA: 存储最新Bar
        MB-->>WS: 推送Bar到WebSocket订阅者
        BA->>BA: 重置，开始下一根
    end
```

> **源码**: `crates/data/src/aggregation.rs`

---

### 4.5 Cache：系统状态中枢

`Cache` 是整个系统的**内存状态中枢**，所有查询操作不走数据库，直接从 Cache 读取，保证低延迟。

**Cache 存储的内容**：

```
行情数据:
  quotes[instrument_id] → 最新 QuoteTick
  trades[instrument_id] → 最新 TradeTick
  bars[bar_type]        → 最新 N 根 Bar
  order_books[instrument_id] → 实时订单簿

交易数据:
  orders[client_order_id]     → 所有订单（含历史）
  positions[position_id]      → 所有持仓
  accounts[account_id]        → 账户余额

金融工具:
  instruments[instrument_id]  → 合约规格
  currencies[code]            → 货币信息
```

**Cache 的写入规则**：
- 只有 `ExecutionEngine` 和 `DataEngine` 可以写入 Cache
- 策略/业务逻辑只能读取 Cache
- 每次写入同时可选持久化到 Redis / PostgreSQL

> **源码**: `crates/common/src/cache/mod.rs`
> **关键查询方法**: `client_order_ids_open()`, `positions_open()`, `calculate_unrealized_pnl()`

---

## 5. MessageBus：系统解耦的核心

```mermaid
graph LR
    subgraph "发布者"
        EE4[ExecutionEngine]
        DE4[DataEngine]
        EC4[ExecClient]
    end

    subgraph "MessageBus"
        MB4[主题路由表<br/>topic → [handlers]]
    end

    subgraph "订阅者"
        ST4[Strategy]
        RE4[RiskEngine]
        PF4[Portfolio]
        CA4[Cache]
        WS4[WebSocket推送层]
    end

    EE4 -- "publish('execution.OrderFilled')" --> MB4
    DE4 -- "publish('data.QuoteTick.AAPL')" --> MB4
    EC4 -- "publish('execution.OrderAccepted')" --> MB4

    MB4 -- "dispatch" --> ST4
    MB4 -- "dispatch" --> RE4
    MB4 -- "dispatch" --> PF4
    MB4 -- "dispatch" --> CA4
    MB4 -- "dispatch" --> WS4
```

**主题命名规范**（NautilusTrader 的约定）：
```
数据主题:
  data.QuoteTick.{instrument_id}
  data.TradeTick.{instrument_id}
  data.Bar.{bar_type}

执行主题:
  execution.{EventType}          ← 所有执行事件
  execution.OrderFilled          ← 特定事件
```

**对券商 WebSocket 推送的启示**：
可以在 MessageBus 上挂一个 `WebSocketBroadcaster`，订阅相关主题，将事件翻译为 JSON 推送给移动端，实现**执行引擎与推送层完全解耦**。

---

## 6. 券商适配要点

### 6.1 你的系统 vs NautilusTrader 覆盖范围

```mermaid
graph LR
    subgraph "NautilusTrader 覆盖"
        A1[领域模型<br/>Order/Position/Price]
        A2[执行引擎<br/>OMS + 状态机]
        A3[风控引擎<br/>Pre-trade]
        A4[数据引擎<br/>行情 + K线]
        A5[Cache<br/>状态中枢]
    end

    subgraph "你需要额外实现"
        B1[用户认证层<br/>JWT + Biometric + HMAC]
        B2[AMS 集成<br/>账户状态/权限查询]
        B3[REST API 层<br/>HTTP接口封装]
        B4[WebSocket 推送层<br/>订单/行情实时推送]
        B5[Fund Transfer 集成<br/>资金结算]
        B6[合规层<br/>PDT/T+1/涨跌停]
        B7[管理后台<br/>风控配置/人工干预]
    end

    A2 --> B3
    A3 --> B6
    A4 --> B4
    A5 --> B3
```

### 6.2 关键设计建议

#### 建议一：直接复用订单状态机设计

将 NautilusTrader 的 14 个状态和完整状态转换表直接移植到你的 Go/Java 实现中，不要自己简化。少一个状态（如 `PendingCancel`）就会在竞态场景下埋下 bug。

#### 建议二：Price/Quantity 用 int64 存储

```go
// Go 参考实现
type Price struct {
    raw       int64  // 内部整数表示
    precision uint8  // 小数精度
}

func (p Price) String() string {
    // 转换为 "150.01" 格式
}

// 禁止:
type WrongPrice struct {
    value float64  // ❌ 永远不要这样做
}
```

#### 建议三：订单事件要持久化为事件日志

每一个 `OrderEvent` 都应该写入数据库（PostgreSQL），而不只是更新订单状态字段。这既是审计要求，也是系统崩溃后恢复状态的基础。

#### 建议四：Cache 层要与数据库双写

```
OrderFilled 到来时:
  1. 更新内存 Cache（同步，< 1ms）
  2. 异步写入 PostgreSQL（用 Kafka/队列）
  3. 返回 HTTP 响应（基于内存状态）

查询接口:
  GET /positions → 读 Cache（< 1ms）
  GET /orders/history → 读 PostgreSQL（历史数据）
```

#### 建议五：与 IB (Interactive Brokers) 的集成参考

NautilusTrader 有完整的 IB 适配器实现（`nautilus_trader/adapters/interactive_brokers/`），你的 `ExecutionClient` 实现可以直接参考其：
- TWS API 连接管理和重连策略
- 订单字段到 IB Contract/Order 的映射
- `orderStatus` / `execDetails` 回调处理
- 账户余额同步（`AccountSummary`）

---

## 附录：源码路径速查

| 模块 | 路径 |
|---|---|
| 订单状态机 | `crates/model/src/orders/mod.rs` |
| 订单状态枚举 | `crates/model/src/enums.rs` |
| 订单事件体系 | `crates/model/src/events/order/mod.rs` |
| Price 类型 | `crates/model/src/types/price.rs` |
| Quantity 类型 | `crates/model/src/types/quantity.rs` |
| 股票合约模型 | `crates/model/src/instruments/equity.rs` |
| 期货合约模型 | `crates/model/src/instruments/futures_contract.rs` |
| 持仓模型 | `crates/model/src/position.rs` |
| 执行引擎 | `crates/execution/src/engine/mod.rs` |
| 订单管理器 | `crates/execution/src/order_manager/manager.rs` |
| 对账逻辑 | `crates/execution/src/reconciliation.rs` |
| 风控引擎 | `crates/risk/src/engine/mod.rs` |
| 数据引擎 | `crates/data/src/engine/mod.rs` |
| K线聚合 | `crates/data/src/aggregation.rs` |
| Cache | `crates/common/src/cache/mod.rs` |
| MessageBus | `crates/common/src/msgbus/mod.rs` |
| 消息类型 | `crates/common/src/messages/mod.rs` |
| IB 适配器 | `nautilus_trader/adapters/interactive_brokers/` |
