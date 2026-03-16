# 持仓与盈亏（Position & P&L）深度调研

> 美港股券商交易引擎 -- Position Management & Profit/Loss Calculation
> 最后更新: 2026-03-16

---

## 1. 业务概述

### 1.1 持仓的定义与本质

持仓（Position）是用户在某一证券上的持有状态，是交易系统中连接"订单成交"与"资产展示"的核心数据实体。每一笔成交（Execution）都会改变持仓的状态，而持仓的实时市值又直接影响用户的购买力（Buying Power）、保证金要求（Margin Requirement）和风控决策。

在我们的系统中，持仓由 `(account_id, symbol, market)` 三元组唯一标识，即一个账户在一个市场的一只证券上只有一条持仓记录。这是一种 **net position** 模型，与 **gross position**（每笔交易独立记录）模型不同。

#### 持仓方向

| 方向 | Quantity 值 | 含义 | 适用场景 |
|------|------------|------|---------|
| 多头（Long） | > 0 | 持有证券，期望价格上涨 | 普通买入 |
| 空头（Short） | < 0 | 借入并卖出证券，期望价格下跌 | 融券卖空（需要 Reg SHO locate） |
| 平仓（Flat） | = 0 | 不持有该证券 | 全部卖出或空头回补 |

#### 已结算与未结算数量

这是持仓管理中最容易被忽视但最关键的维度之一。

| 字段 | 含义 | 约束 |
|------|------|------|
| `settled_qty` | 已完成资金/证券交割的数量 | 可以自由卖出、转移 |
| `unsettled_qty` | 交易已成交但交割未完成的数量 | 美股 T+1，港股 T+2 |
| `quantity` | 总持仓数量 | = `settled_qty` + `unsettled_qty` |

**为什么要分开追踪？**

1. **Free-riding Violation 防范**：现金账户（Cash Account）用户卖出未结算的股票所得不能立即用于购买新股票（Good Faith Violation）。如果用户用未结算资金买入并在结算前卖出，构成 free-riding，FINRA 可能冻结账户 90 天。
2. **可提取余额计算**：只有已结算资金才能发起出金（withdrawal），`unsettled_qty` 对应的资金不可出金。
3. **融券卖出限制**：融券卖出的 locate 要求只对已结算证券有效。

### 1.2 盈亏的分类

盈亏（P&L, Profit and Loss）是用户最关心的核心数据，必须做到**实时、准确、可审计**。系统中存在三种不同维度的盈亏：

| P&L 类型 | 计算依据 | 更新频率 | 持久化 |
|----------|---------|---------|--------|
| 未实现盈亏（Unrealized P&L） | 当前市价 vs 持仓成本 | 每次行情变动（实时） | 不持久化，实时计算 |
| 已实现盈亏（Realized P&L） | 卖出价格 vs 买入成本 | 每次卖出成交 | 持久化到 positions 表 |
| 日内盈亏（Day P&L） | 当前市价 vs 昨日收盘价 | 每次行情变动（实时） | 不持久化，实时计算 |

### 1.3 业务流程概览

```
成交回报（ExecutionReport）
    │
    ├─── 买入成交 ──────► 增加持仓数量，更新加权平均成本
    │                     增加 unsettled_qty
    │                     扣减现金余额（含手续费）
    │
    ├─── 卖出成交 ──────► 减少持仓数量，计算已实现盈亏
    │                     减少 settled_qty（优先）或 unsettled_qty
    │                     增加现金余额（扣除手续费）
    │
    └─── 结算完成 ──────► unsettled_qty 转为 settled_qty
                          更新资金结算状态
```

### 1.4 与其他子域的关系

```
┌──────────────┐     成交回报      ┌──────────────────┐
│  Order OMS   │ ──────────────► │  Position Engine  │
└──────────────┘                  └────────┬─────────┘
                                           │
                     ┌─────────────────────┼──────────────────────┐
                     │                     │                      │
                     ▼                     ▼                      ▼
              ┌─────────────┐      ┌──────────────┐      ┌──────────────┐
              │ Risk Engine │      │Margin Engine │      │ Fund Transfer│
              │ (购买力计算) │      │ (保证金计算)  │      │ (出入金余额)  │
              └─────────────┘      └──────────────┘      └──────────────┘
                                           │
                                           ▼
                                   ┌──────────────┐
                                   │   Mobile UI  │
                                   │ (持仓/P&L展示)│
                                   └──────────────┘
```

---

## 2. 监管与合规要求

### 2.1 美国市场（SEC / FINRA）

#### 2.1.1 SEC Rule 15c3-1 (Net Capital Rule)

券商必须准确记录所有客户持仓和对应的市值。持仓数据是计算净资本要求的基础。

#### 2.1.2 SEC Rule 17a-3 / 17a-4 (记录保留)

- **17a-3**: 要求券商保留每个客户账户的完整持仓记录，包括每笔交易的详细信息。
- **17a-4**: 所有记录必须保留至少 **6 年**（前两年可随时调取），以 WORM（Write Once Read Many）格式存储。
- 持仓变更必须有可追溯的审计记录，包括时间戳、变更原因、操作人。

#### 2.1.3 FINRA Rule 4511 (账簿和记录)

- 所有客户持仓变更必须在 **交易日当天** 记录。
- 持仓记录必须包含：账户号、证券标识、数量、成本基准、市值。

#### 2.1.4 Reg SHO (卖空规则)

- 卖空前必须有 locate（借券确认）。
- 持仓系统必须准确区分多头和空头持仓。
- Fail-to-deliver（未能按时交割）超过 T+4 必须强制回补（close-out）。

#### 2.1.5 Reg T (保证金交易)

- 持仓市值直接影响保证金计算。
- 现金账户用户卖出后，资金需要 T+1 才能结算。
- 在结算前使用未结算资金构成 Good Faith Violation。

#### 2.1.6 税务报告 (IRS Form 1099-B)

- 年终必须向 IRS 申报所有已实现盈亏。
- 必须记录每笔交易的 **cost basis**（成本基准）。
- 默认使用 **FIFO** 方法计算 cost basis。
- Wash Sale Rule：30 天内买回实质相同证券，不能确认亏损。

### 2.2 香港市场（SFC / HKEX）

#### 2.2.1 SFC Code of Conduct

- 持牌中介人必须保留完整的客户持仓记录。
- 必须定期向客户发送持仓报告（至少每月一次）。
- 持仓和成交记录保留至少 **7 年**。

#### 2.2.2 SFO (Securities and Futures Ordinance)

- 大额持仓披露：持有上市公司 5% 以上须向 SFC 申报。
- 内幕交易监控：需要追踪特定账户的持仓变化模式。

#### 2.2.3 CCASS (Central Clearing and Settlement System)

- 港股通过 CCASS 进行集中清算和结算。
- T+2 结算周期。
- 持仓以"手"（Board Lot）为单位，碎股（Odd Lot）需要在专门的碎股市场交易。

#### 2.2.4 港股印花税与费用

卖出成交时需要扣除印花税（Stamp Duty），这会影响已实现盈亏的计算：
- 印花税：成交金额的 0.13%（取整到最近的港元，最低 1 港元）
- 交易征费（Trading Levy）：0.0027%
- 交易费（Trading Fee）：0.00565%

### 2.3 合规对系统设计的影响

| 合规要求 | 系统设计影响 |
|---------|------------|
| 持仓记录 7 年保留 | 使用 Event Sourcing，所有变更 append-only |
| FIFO cost basis 追踪 | 需要维护每笔买入的 lot 级别记录 |
| Wash Sale 检测 | 需要 30 天滑动窗口，追踪同一证券的买卖模式 |
| 已结算/未结算分离 | positions 表分开存储 settled_qty 和 unsettled_qty |
| 大额持仓披露 | 持仓变更时检查是否触及 5% 阈值 |
| 碎股处理（HK） | Board Lot 校验，碎股单独标记 |

---

## 3. 市场差异（US vs HK）

### 3.1 结算周期

| 维度 | 美股 (US) | 港股 (HK) |
|------|----------|----------|
| 结算周期 | T+1（2024年5月28日起） | T+2 |
| 结算系统 | DTCC / NSCC | CCASS (HKSCC) |
| 结算货币 | USD | HKD |
| 结算时间 | 当日 ET 16:00 后 | 次次日 HKT 16:00 后 |
| 假日影响 | 美国联邦假日不结算 | 香港公众假期不结算 |

**跨市场结算日历的复杂性**：系统必须维护两套独立的结算日历（US Calendar + HK Calendar），准确计算每笔交易的结算日期。例如：
- 周五成交的美股在下周一结算（T+1，跳过周末）
- 周四成交的港股在下周一结算（T+2，跳过周末）
- 如果遇到假日，顺延到下一个工作日

### 3.2 交易单位

| 维度 | 美股 (US) | 港股 (HK) |
|------|----------|----------|
| 最小交易单位 | 1 股 | Board Lot（因股票而异） |
| 碎股交易 | 部分券商支持（fractional shares） | 碎股市场（Odd Lot Market） |
| 常见 Board Lot | N/A | 100股、200股、400股、500股、1000股等 |
| 碎股限制 | 无 | 碎股只能卖出，不能买入（除配股等特殊情况） |

**对持仓系统的影响**：
- 美股：`quantity` 以单股为单位，无需 board lot 校验。
- 港股：买入时需要校验是否为 board lot 的整数倍；持仓中可能存在碎股（来自拆股、配股等企业行动）。

### 3.3 价格精度

| 维度 | 美股 (US) | 港股 (HK) |
|------|----------|----------|
| 最小变动单位 | $0.01（Sub-penny 用于暗池） | 依据价格区间变动（Tick Size Table） |
| 价格精度 | 4 位小数 | 3 位小数 |
| 币种 | USD | HKD |

港股 Tick Size Table（部分）：

| 价格区间 (HKD) | 最小变动单位 |
|---------------|------------|
| 0.01 - 0.25 | 0.001 |
| 0.25 - 0.50 | 0.005 |
| 0.50 - 10.00 | 0.010 |
| 10.00 - 20.00 | 0.020 |
| 20.00 - 100.00 | 0.050 |
| 100.00 - 200.00 | 0.100 |
| 200.00 - 500.00 | 0.200 |
| 500.00 - 1000.00 | 0.500 |
| 1000.00 - 2000.00 | 1.000 |
| 2000.00 - 5000.00 | 2.000 |
| > 5000.00 | 5.000 |

**对 P&L 计算的影响**：所有价格和金额必须使用 `shopspring/decimal`，不得使用 `float64`。不同市场的精度配置需要参数化。

### 3.4 手续费结构

美股费用（按每笔成交）：

| 费用项 | 类型 | 费率 | 适用方向 |
|-------|------|------|---------|
| 佣金（Commission） | Per Share | $0.005/股 | 买卖 |
| SEC Fee | Percentage | 0.00278% | 仅卖出 |
| FINRA TAF | Per Share | $0.000166/股 | 仅卖出 |
| Exchange Fee | Per Share | $0.003/股 | 买卖 |

港股费用（按每笔成交）：

| 费用项 | 类型 | 费率 | 最低收费 |
|-------|------|------|---------|
| 佣金（Commission） | Percentage | 0.03% | HK$3.00 |
| 印花税（Stamp Duty） | Percentage | 0.13% | HK$1.00 |
| 交易征费（Trading Levy） | Percentage | 0.0027% | 无 |
| 交易费（Trading Fee） | Percentage | 0.00565% | 无 |
| 平台费（Platform Fee） | Flat | HK$0.50 | N/A |

**费用对已实现盈亏的影响**：卖出时的净收入 = 成交金额 - 所有卖出费用。买入时的总成本 = 成交金额 + 所有买入费用。已实现盈亏 = 净卖出收入 - 总买入成本。

### 3.5 企业行动差异

| 企业行动 | 美股处理方式 | 港股处理方式 |
|---------|------------|------------|
| 现金股息 | Ex-Date 前持仓者获得，Pay Date 到账 | 与美股相同 |
| 股票拆分 | 自动调整数量和成本，DTCC 通知 | 自动调整，CCASS 通知 |
| 配股（Rights Issue） | 较少见 | 常见，需处理碎股权利 |
| 合并（Merger） | 现金/股票/混合对价 | 与美股类似 |
| 红股（Bonus Issue） | 较少见 | 常见于港股 |

### 3.6 税务差异

| 维度 | 美股 | 港股 |
|------|------|------|
| 资本利得税 | 短期（持有<1年）按普通收入税率，长期按优惠税率 | 香港不征资本利得税 |
| 股息税 | 美国非居民预扣 30%（条约可减免） | 无预扣税（但中国大陆投资者通过港股通需缴纳 20% 股息税） |
| Cost Basis 报告 | IRS 要求券商报告 (1099-B) | 无强制要求 |
| Wash Sale Rule | 30 天内同证券买卖需调整 cost basis | 不适用 |

---

## 4. 技术架构

### 4.1 核心数据模型

#### 4.1.1 Position（持仓）

基于代码库中的 `src/internal/position/position.go`：

```go
type Position struct {
    UserID       int64
    AccountID    int64
    Symbol       string
    Market       string            // "US" / "HK"
    Quantity     int64             // 正=多头, 负=空头
    AvgCostBasis decimal.Decimal   // 加权平均成本（含买入手续费）
    RealizedPnL  decimal.Decimal   // 累计已实现盈亏
    SettledQty   int64             // 已结算数量
    UnsettledQty int64             // 未结算数量
    FirstTradeAt int64             // 首笔交易时间 (Unix nanos)
    LastTradeAt  int64             // 最近交易时间 (Unix nanos)
    Version      int               // 乐观锁版本号
}
```

**设计要点**：
- `Quantity = SettledQty + UnsettledQty`，系统中任何时刻都必须保持这个不变量。
- `AvgCostBasis` 包含买入时的手续费分摊，即 `(成交价 * 数量 + 手续费) / 数量`。
- `RealizedPnL` 是累计值，每次卖出成交时追加。
- `Version` 用于乐观锁（Optimistic Locking），防止并发更新冲突。

#### 4.1.2 PnLSnapshot（盈亏快照）

```go
type PnLSnapshot struct {
    Symbol        string
    Market        string
    Quantity      int64
    AvgCostBasis  decimal.Decimal
    MarketPrice   decimal.Decimal   // 当前市价（来自 Market Data）
    MarketValue   decimal.Decimal   // abs(Quantity) * MarketPrice
    CostValue     decimal.Decimal   // abs(Quantity) * AvgCostBasis
    UnrealizedPnL decimal.Decimal   // MarketValue - CostValue（考虑方向）
    UnrealizedPct decimal.Decimal   // UnrealizedPnL / CostValue * 100
    RealizedPnL   decimal.Decimal   // 来自 Position.RealizedPnL
    DayPnL        decimal.Decimal   // 基于昨日收盘价计算
}
```

**注意**：`PnLSnapshot` 是**实时计算**的，不持久化到数据库。它由 `Position`（数据库）+ 当前市价（Market Data 服务）组合而成。

#### 4.1.3 PortfolioSummary（组合摘要）

```go
type PortfolioSummary struct {
    AccountID        int64
    TotalEquity      decimal.Decimal // 总净值 = CashBalance + TotalMarketValue
    TotalMarketValue decimal.Decimal // 所有持仓市值之和
    CashBalance      decimal.Decimal // 现金余额（来自 Fund Transfer 服务）
    TotalUnrealized  decimal.Decimal // 所有持仓未实现盈亏之和
    TotalRealized    decimal.Decimal // 所有持仓已实现盈亏之和
    TotalDayPnL      decimal.Decimal // 所有持仓日内盈亏之和
    BuyingPower      decimal.Decimal // 购买力
    PositionCount    int
    Positions        []*PnLSnapshot
}
```

### 4.2 核心公式

#### 4.2.1 平均成本计算

**买入时更新平均成本（Weighted Average Cost）**：

```
新平均成本 = (原成本 * 原数量 + 新成交价 * 新数量 + 买入手续费) / (原数量 + 新数量)
```

Go 实现伪码：

```go
func updateAvgCost(pos *Position, fillQty int64, fillPrice, fees decimal.Decimal) {
    oldCost := pos.AvgCostBasis.Mul(decimal.NewFromInt(pos.Quantity))
    newCost := fillPrice.Mul(decimal.NewFromInt(fillQty)).Add(fees)
    totalQty := decimal.NewFromInt(pos.Quantity + fillQty)

    pos.AvgCostBasis = oldCost.Add(newCost).Div(totalQty)
    pos.Quantity += fillQty
    pos.UnsettledQty += fillQty
}
```

**卖出时不改变平均成本**（仅减少数量，计算已实现盈亏）。

#### 4.2.2 未实现盈亏

```
未实现盈亏 = (当前市价 - 平均成本) * 持仓数量
```

对于多头：
```
UnrealizedPnL = (MarketPrice - AvgCostBasis) * Quantity
```

对于空头（Quantity < 0）：
```
UnrealizedPnL = (AvgCostBasis - MarketPrice) * abs(Quantity)
// 等价于 (MarketPrice - AvgCostBasis) * Quantity （因为 Quantity 为负）
```

**百分比**：
```
UnrealizedPct = UnrealizedPnL / CostValue * 100
CostValue = abs(Quantity) * AvgCostBasis
```

#### 4.2.3 已实现盈亏

**加权平均成本法**（系统默认，用于实时展示）：

```
已实现盈亏 += (成交价 - 加权平均成本) * 成交数量 - 卖出手续费
```

**FIFO 法**（用于税务报告）：

```
对于每一笔卖出成交：
    按时间顺序匹配最早的买入 lot：
        已实现盈亏 += (卖出价 - 该 lot 的买入价) * 匹配数量
    直到卖出数量全部匹配完毕
```

FIFO 需要额外的 `tax_lots` 表来追踪每笔买入的 lot：

```sql
CREATE TABLE tax_lots (
    id              BIGSERIAL PRIMARY KEY,
    account_id      BIGINT NOT NULL,
    symbol          TEXT NOT NULL,
    market          TEXT NOT NULL,
    buy_execution_id UUID NOT NULL,
    quantity        BIGINT NOT NULL,        -- 该 lot 剩余未卖出数量
    original_qty    BIGINT NOT NULL,        -- 该 lot 原始买入数量
    cost_per_share  NUMERIC(20, 8) NOT NULL,-- 每股成本（含手续费分摊）
    bought_at       TIMESTAMPTZ NOT NULL,
    wash_sale_adj   NUMERIC(20, 8) DEFAULT 0, -- Wash Sale 调整
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    INDEX idx_lots_account (account_id, symbol, market, bought_at)
);
```

#### 4.2.4 日内盈亏（Day P&L）

```
日内盈亏 = (当前市价 - 昨日收盘价) * 持仓数量 + 日内已实现盈亏
```

其中 `昨日收盘价`（Previous Close）来自 Market Data 服务。

**特殊情况**：
- **今日新开仓**：没有昨日收盘价，使用开仓成本作为基准。
- **今日部分平仓**：对剩余持仓使用昨收，已平仓部分计入日内已实现盈亏。
- **盘前/盘后交易**：Day P&L 的基准仍然是上一个常规交易日的收盘价。

Go 实现伪码：

```go
func calcDayPnL(pos *Position, marketPrice, prevClose decimal.Decimal, dayRealizedPnL decimal.Decimal) decimal.Decimal {
    qty := decimal.NewFromInt(pos.Quantity)

    if prevClose.IsZero() {
        // 今日新开仓，使用成本作为基准
        return marketPrice.Sub(pos.AvgCostBasis).Mul(qty).Add(dayRealizedPnL)
    }

    return marketPrice.Sub(prevClose).Mul(qty).Add(dayRealizedPnL)
}
```

#### 4.2.5 组合净值

```
组合净值 = 现金余额 + SUM(持仓数量 * 当前市价)
         = CashBalance + TotalMarketValue
```

### 4.3 成交处理流程（核心写入路径）

成交处理是持仓系统中最关键的写入操作，必须保证**原子性**（Atomicity）。

```
ExecutionReport 到达
    │
    ├─── 1. 幂等检查 ──► execution_id 是否已处理过？
    │        │               是 → 跳过，返回成功
    │        │               否 → 继续
    │        ▼
    ├─── 2. 开启数据库事务 (BEGIN)
    │        │
    │        ▼
    ├─── 3. 锁定持仓记录 (SELECT ... FOR UPDATE)
    │        │     WHERE account_id = ? AND symbol = ? AND market = ?
    │        │     如果记录不存在，插入初始记录（quantity=0）
    │        ▼
    ├─── 4. 更新持仓
    │        │
    │        ├── 买入: quantity += fill_qty
    │        │         avg_cost_basis 重新计算
    │        │         unsettled_qty += fill_qty
    │        │
    │        └── 卖出: quantity -= fill_qty
    │                  realized_pnl += (fill_price - avg_cost) * fill_qty - fees
    │                  settled_qty -= min(fill_qty, settled_qty)
    │                  unsettled_qty -= remainder if any
    │        ▼
    ├─── 5. 版本号检查 (Optimistic Lock)
    │        │     UPDATE positions SET ... WHERE version = ? AND id = ?
    │        │     affected_rows == 0 → 并发冲突，重试
    │        ▼
    ├─── 6. 写入成交记录 (INSERT INTO executions)
    │        ▼
    ├─── 7. 写入台账分录 (INSERT INTO ledger_entries)
    │        │     双笔分录：
    │        │     买入: DR 证券持仓, CR 现金
    │        │     卖出: DR 现金, CR 证券持仓
    │        ▼
    ├─── 8. 写入订单事件 (INSERT INTO order_events)
    │        ▼
    ├─── 9. 提交事务 (COMMIT)
    │        ▼
    └─── 10. 发布 Kafka 事件 (position.updated)
              │     通知下游：Mobile UI / Margin Engine / Risk Engine
              ▼
         11. 更新 Redis 缓存
              │     刷新热路径数据
              ▼
         完成
```

#### 4.3.1 原子性保证

在单个 PostgreSQL 事务中完成以下操作（步骤 2-9）：
1. 持仓更新（positions）
2. 成交记录写入（executions）
3. 台账分录写入（ledger_entries）
4. 订单事件写入（order_events）

**如果任何一步失败，整个事务回滚**。这保证了数据一致性——不会出现"持仓更新了但台账没写"这种中间状态。

#### 4.3.2 乐观锁实现

```go
func (r *repository) Upsert(ctx context.Context, pos *Position) error {
    result, err := r.db.ExecContext(ctx, `
        UPDATE positions
        SET quantity = $1, avg_cost_basis = $2, realized_pnl = $3,
            settled_qty = $4, unsettled_qty = $5, last_trade_at = $6,
            version = version + 1, updated_at = NOW()
        WHERE account_id = $7 AND symbol = $8 AND market = $9 AND version = $10
    `, pos.Quantity, pos.AvgCostBasis, pos.RealizedPnL,
       pos.SettledQty, pos.UnsettledQty, pos.LastTradeAt,
       pos.AccountID, pos.Symbol, pos.Market, pos.Version)

    if err != nil {
        return fmt.Errorf("update position %s/%s for account %d: %w",
            pos.Symbol, pos.Market, pos.AccountID, err)
    }

    rows, _ := result.RowsAffected()
    if rows == 0 {
        return ErrOptimisticLockConflict
    }
    return nil
}
```

当检测到 `ErrOptimisticLockConflict` 时，调用方应重新读取最新版本并重试（最多 3 次）。

#### 4.3.3 SELECT FOR UPDATE vs 乐观锁

系统同时使用两种机制：

| 机制 | 使用场景 | 原因 |
|------|---------|------|
| SELECT FOR UPDATE | ProcessExecution 事务内 | 防止同一持仓被两个并发成交同时修改 |
| Optimistic Lock (version) | ProcessExecution 的最终 UPDATE | 作为第二道防线，万一事务隔离级别不足 |

### 4.4 Redis 热路径（实时 P&L 缓存）

#### 4.4.1 为什么需要 Redis 缓存？

P&L 更新的性能目标是 **< 1ms p99**（每次市价变动）。如果每次行情变动都从 PostgreSQL 读取持仓数据再计算，延迟远超目标。因此我们使用 Redis 作为持仓的 materialized view。

#### 4.4.2 Redis 数据结构

```
# 单个持仓（Hash）
position:{account_id}:{symbol}:{market}
    quantity      -> "100"
    avg_cost      -> "150.25000000"
    realized_pnl  -> "1200.50000000"
    settled_qty   -> "100"
    unsettled_qty -> "0"
    version       -> "5"

# 账户持仓列表（Set）
account_positions:{account_id}
    -> "AAPL:US"
    -> "0700.HK:HK"
    -> "TSLA:US"

# 实时 P&L（Hash，每次行情更新时刷新）
pnl:{account_id}:{symbol}:{market}
    market_price    -> "155.30000000"
    market_value    -> "15530.00000000"
    unrealized_pnl  -> "505.00000000"
    unrealized_pct  -> "3.36"
    day_pnl         -> "120.00000000"
    updated_at      -> "1710600000000000000"  # Unix nanos

# 组合汇总（Hash）
portfolio:{account_id}
    total_equity      -> "50000.00000000"
    total_market_value -> "35000.00000000"
    cash_balance       -> "15000.00000000"
    total_unrealized   -> "2500.00000000"
    total_day_pnl      -> "500.00000000"
    buying_power       -> "25000.00000000"
    position_count     -> "5"
```

#### 4.4.3 缓存更新策略

**写入路径（成交处理后）**：
1. PostgreSQL 事务提交成功后，同步更新 Redis。
2. 使用 Redis Pipeline 批量更新，减少网络往返。
3. 如果 Redis 更新失败，不回滚 PostgreSQL（Redis 是缓存，不是 source of truth）。
4. 通过后台定时任务（每 5 分钟）对账 Redis 与 PostgreSQL 的一致性。

**读取路径（行情驱动 P&L 刷新）**：
1. 收到 Market Data 行情推送（price tick）。
2. 从 Redis 读取 `position:{account_id}:{symbol}:{market}` 的 `quantity` 和 `avg_cost`。
3. 用新价格计算 P&L。
4. 写回 `pnl:{account_id}:{symbol}:{market}`。
5. 更新 `portfolio:{account_id}` 的汇总数据。

**缓存失效**：
- TTL: 24 小时（兜底失效）。
- 主动失效: 成交处理后立即更新。
- 全量重建: 盘前（Market Open 前 30 分钟）执行一次全量 PostgreSQL -> Redis 同步。

#### 4.4.4 Redis 与 PostgreSQL 的一致性

```
写入链路：ExecutionReport → PostgreSQL (COMMIT) → Redis (BEST EFFORT) → Kafka

如果 Redis 更新失败：
  1. 记录错误日志（包含 account_id, symbol, market, version）
  2. 将 account_id 加入 "dirty set"（Redis Set: dirty_positions）
  3. 后台 reconciler 每 30 秒扫描 dirty set，从 PostgreSQL 重建缓存
```

### 4.5 Kafka 事件流

#### 4.5.1 事件定义

Topic: `position.updated`

```json
{
  "event_id": "uuid-v4",
  "event_type": "POSITION_UPDATED",
  "timestamp": "2026-03-16T09:30:05.123Z",
  "account_id": 12345,
  "symbol": "AAPL",
  "market": "US",
  "data": {
    "quantity": 100,
    "avg_cost_basis": "150.25000000",
    "realized_pnl": "1200.50000000",
    "settled_qty": 100,
    "unsettled_qty": 0,
    "trigger": "EXECUTION",
    "execution_id": "exec-uuid",
    "version": 5
  }
}
```

事件类型：

| Event Type | 触发条件 | 消费者 |
|-----------|---------|--------|
| POSITION_UPDATED | 成交处理后 | Mobile (推送), Margin Engine, Risk Engine |
| POSITION_SETTLED | 结算完成后 | Fund Transfer (更新可提余额) |
| POSITION_CORPORATE_ACTION | 企业行动处理后 | Mobile (通知), Tax Lot 追踪 |
| PORTFOLIO_SNAPSHOT | 定时快照 | Data Warehouse, Compliance |

#### 4.5.2 Outbox Pattern

为保证 PostgreSQL 和 Kafka 的最终一致性，使用 Outbox Pattern：

```sql
CREATE TABLE outbox (
    id          BIGSERIAL PRIMARY KEY,
    topic       TEXT NOT NULL,
    key         TEXT NOT NULL,       -- Kafka partition key (account_id)
    payload     JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published   BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMPTZ
);
```

1. 在 ProcessExecution 事务中，将 Kafka 事件写入 outbox 表。
2. 独立的 Outbox Publisher goroutine 轮询 outbox 表，将未发布的事件推送到 Kafka。
3. 发布成功后标记 `published = TRUE`。
4. 定期清理已发布的旧记录。

### 4.6 Market Data 订阅与 P&L 刷新

#### 4.6.1 行情订阅机制

Position Engine 需要订阅 Market Data 服务的行情推送，以实时刷新 P&L。

```
Market Data Service
    │
    │ (gRPC Stream / Kafka topic: quote.realtime)
    │
    ▼
Position P&L Updater (goroutine pool)
    │
    ├── 1. 收到行情: {symbol: "AAPL", market: "US", price: "155.30", prev_close: "154.00"}
    │
    ├── 2. 查询受影响的账户（从 Redis Set: symbol_subscribers:AAPL:US）
    │
    ├── 3. 对每个账户，计算新的 P&L
    │       │
    │       ├── 读取 Redis: position:{account_id}:AAPL:US
    │       ├── 计算: unrealized_pnl = (155.30 - 150.25) * 100 = 505.00
    │       ├── 计算: day_pnl = (155.30 - 154.00) * 100 = 130.00
    │       └── 写入 Redis: pnl:{account_id}:AAPL:US
    │
    └── 4. 更新 portfolio:{account_id} 汇总
```

#### 4.6.2 性能优化

- **批量处理**：同一 symbol 的行情变动，批量计算所有受影响账户的 P&L。
- **Goroutine Pool**：使用固定大小的 worker pool（如 32 workers）处理行情，避免 goroutine 爆炸。
- **限流**：如果行情变动过于频繁（如每秒 100+ ticks），合并处理（取最新价格）。
- **仅更新非零持仓**：通过 `symbol_subscribers` Redis Set 快速定位有该证券持仓的账户。

#### 4.6.3 行情延迟对 P&L 的影响

| 场景 | P&L 准确性 | 处理方式 |
|------|-----------|---------|
| 实时行情正常 | 精确 | 正常计算 |
| 行情延迟 > 5s | 标记为 "delayed" | 在 API 响应中增加 `delayed: true` 标记 |
| 行情中断 > 30s | 使用最后已知价格 | 前端显示 "数据可能延迟" 警告 |
| 盘后/非交易时段 | 使用收盘价 | 固定为收盘价，不再刷新 |

### 4.7 结算处理

#### 4.7.1 每日结算批处理

```
盘后结算 Job (每日运行)
    │
    ├── 1. 查询今日需要结算的成交
    │       SELECT * FROM executions
    │       WHERE settlement_date = CURRENT_DATE AND settled = FALSE
    │
    ├── 2. 按 account_id 分组处理
    │
    ├── 3. 对每个成交：
    │       │
    │       ├── 标记成交为已结算 (settled = TRUE)
    │       │
    │       ├── 更新持仓:
    │       │     买入: settled_qty += quantity, unsettled_qty -= quantity
    │       │     卖出: settled cash available for withdrawal
    │       │
    │       └── 写入结算事件 (Kafka: settlement.completed)
    │
    └── 4. 通知 Fund Transfer 服务更新可提余额
```

#### 4.7.2 结算日期计算

```go
func CalculateSettlementDate(tradeDate time.Time, market string, calendar *MarketCalendar) time.Time {
    var businessDaysToAdd int
    switch market {
    case "US":
        businessDaysToAdd = 1 // T+1
    case "HK":
        businessDaysToAdd = 2 // T+2
    default:
        businessDaysToAdd = 2 // 保守默认
    }

    settlementDate := tradeDate
    for i := 0; i < businessDaysToAdd; {
        settlementDate = settlementDate.AddDate(0, 0, 1)
        if calendar.IsBusinessDay(settlementDate, market) {
            i++
        }
    }
    return settlementDate
}
```

### 4.8 企业行动处理

#### 4.8.1 现金股息（Cash Dividend）

```
Ex-Date 到达
    │
    ├── 1. 查询 Record Date 持仓快照
    │       (系统需要在 Record Date 收盘后生成持仓快照)
    │
    ├── 2. 计算股息金额
    │       dividend_amount = position_quantity * dividend_per_share
    │
    ├── 3. Pay Date 处理:
    │       ├── 增加现金余额 (Credit: Dividend Receivable)
    │       ├── 写入台账分录 (DR Cash, CR Dividend Income)
    │       └── 不改变持仓数量和成本
    │
    └── 4. 税务处理:
            ├── US: 预扣税 (withholding tax)
            └── HK: 一般无预扣 (大陆投资者除外)
```

**注意**：现金股息**不改变** `avg_cost_basis`。但在某些税务框架下，Return of Capital 类型的分配需要减少 cost basis。

#### 4.8.2 股票拆分（Stock Split）

```
Ex-Date 到达
    │
    ├── 1. 查询所有持有该证券的账户
    │
    ├── 2. 拆分比例: 例如 4:1 (split_ratio = 4)
    │       新数量 = 原数量 * split_ratio
    │       新平均成本 = 原平均成本 / split_ratio
    │
    ├── 3. 更新持仓:
    │       UPDATE positions
    │       SET quantity = quantity * 4,
    │           avg_cost_basis = avg_cost_basis / 4,
    │           settled_qty = settled_qty * 4,
    │           unsettled_qty = unsettled_qty * 4,
    │           version = version + 1
    │       WHERE symbol = 'AAPL' AND market = 'US'
    │
    ├── 4. 更新 Tax Lots:
    │       UPDATE tax_lots
    │       SET quantity = quantity * 4,
    │           original_qty = original_qty * 4,
    │           cost_per_share = cost_per_share / 4
    │       WHERE symbol = 'AAPL' AND market = 'US'
    │
    └── 5. 写入审计记录和事件通知
```

**关键不变量**：拆分前后，`quantity * avg_cost_basis`（总成本）不变。

#### 4.8.3 配股（Rights Issue）

港股常见的企业行动，需要特殊处理：

```
公告配股方案
    │
    ├── 1. Ex-Date 确定现有股东的配股权利
    │       配股比例: 例如每 10 股配 1 股
    │       配股价: 通常低于市价
    │
    ├── 2. 通知用户:
    │       ├── 发送 Kafka 事件 (corporate_action.rights_issue)
    │       ├── Mobile Push Notification
    │       └── 用户选择: 认购 / 放弃 / 出售权利
    │
    ├── 3. 用户认购:
    │       ├── 冻结认购资金
    │       ├── 在配股到账日:
    │       │     quantity += rights_shares
    │       │     avg_cost_basis 重新计算（加入新股成本）
    │       └── 写入台账分录
    │
    └── 4. 用户放弃/超期:
            └── 权利失效，不做处理
```

#### 4.8.4 合并/收购（Merger & Acquisition）

```
合并生效日
    │
    ├── 现金合并:
    │     ├── 移除原持仓 (quantity -> 0)
    │     ├── 增加现金 (merger_price * quantity)
    │     ├── 计算已实现盈亏 (merger_price - avg_cost) * quantity
    │     └── 关闭 Tax Lots
    │
    ├── 股票合并:
    │     ├── 移除原持仓
    │     ├── 创建新持仓 (new_symbol, new_quantity by ratio)
    │     ├── 转移 cost basis
    │     └── 调整 Tax Lots
    │
    └── 混合合并:
          ├── 现金部分: 同现金合并
          └── 股票部分: 同股票合并
```

---

## 5. 性能要求与设计决策

### 5.1 性能目标

| 指标 | 目标值 | 实测基准 | 瓶颈分析 |
|------|--------|---------|---------|
| 成交处理 (ProcessExecution) | < 3ms p99 | ~2.1ms | PostgreSQL 事务 + 乐观锁 |
| P&L 实时更新 | < 1ms p99 | ~0.3ms | Redis 读写 |
| 获取持仓列表 | < 5ms p99 | ~1.2ms | Redis 热路径 |
| 获取组合摘要 | < 10ms p99 | ~3.5ms | 多持仓聚合计算 |
| 结算批处理 | < 30s | ~12s | 批量 UPDATE + 事件发布 |

### 5.2 关键设计决策

#### 决策 1: Net Position vs Gross Position

**选择: Net Position（净持仓）**

| 方案 | 优势 | 劣势 |
|------|------|------|
| Net Position | 简单，一行一个持仓；查询快 | 丢失单笔交易粒度 |
| Gross Position | 每笔交易独立记录，更灵活 | 查询复杂，聚合开销大 |

选择 Net Position 的原因：
1. 性能目标要求 < 1ms 读取持仓，Net Position 只需一次 key lookup。
2. 单笔交易粒度通过 `executions` 表和 `tax_lots` 表保留。
3. 大部分零售券商（Robinhood, Webull, Tiger）都使用 Net Position 模型。

#### 决策 2: 实时 P&L 不持久化

**选择: P&L 实时计算，不写入数据库**

理由：
1. 市价变动频率极高（美股每秒数百次 tick），如果每次都写数据库，PostgreSQL 会成为瓶颈。
2. P&L 是 `Position (DB) + MarketPrice (Market Data)` 的派生数据，不需要独立持久化。
3. Redis 缓存满足实时查询需求。
4. 历史 P&L 通过定时快照（每日收盘后）保存到 `portfolio_snapshots` 表。

#### 决策 3: 加权平均成本为主，FIFO 为辅

**选择: 实时展示用 Weighted Average Cost，税务报告用 FIFO**

理由：
1. Weighted Average Cost 计算简单，O(1)，适合实时更新。
2. FIFO 需要遍历 tax lots，O(N)，不适合每次行情变动都计算。
3. IRS 要求的 cost basis 报告（年度 1099-B）可以在盘后批量计算。
4. 两种方法的 `avg_cost_basis` 差异通常很小，不影响用户体验。

#### 决策 4: Optimistic Lock + SELECT FOR UPDATE 双保险

**选择: 双重并发控制**

理由：
1. `SELECT FOR UPDATE` 防止同一持仓被两个事务同时修改（写-写冲突）。
2. `version` 字段作为第二道防线，防止网络分区或事务超时导致的脏写。
3. 成交处理的并发度不高（同一证券的成交通常是顺序到达的），所以乐观锁冲突率很低。

#### 决策 5: Outbox Pattern 保证事件一致性

**选择: Transactional Outbox（而非 CDC）**

理由：
1. CDC（Change Data Capture）对 PostgreSQL 有额外的性能影响（WAL 解析）。
2. Outbox Pattern 实现简单，与业务事务天然一致。
3. 我们只需要为特定的业务事件（position.updated）发布 Kafka 消息，不需要捕获所有数据库变更。

### 5.3 容量规划

| 维度 | 估算 | 备注 |
|------|------|------|
| 活跃持仓数 | ~500K | 10万用户 * 平均5个持仓 |
| 日均成交数 | ~200K | 10万用户 * 平均2笔成交 |
| P&L 刷新频率 | ~500K/s | 500K 持仓 * 每秒1次行情（峰值） |
| Redis 内存 | ~2GB | 500K 持仓 * 4KB/持仓 |
| PostgreSQL 写入 | ~200K TXN/day | 成交处理 |

---

## 6. 接口设计（gRPC / REST / Kafka Events）

### 6.1 gRPC 接口

基于代码库中的 `docs/specs/api/grpc/trading.proto`：

#### 6.1.1 PositionService

```proto
service PositionService {
  // 获取单个持仓（含实时 P&L）
  rpc GetPosition(GetPositionRequest) returns (GetPositionResponse);

  // 获取账户所有持仓（含实时 P&L）
  rpc ListPositions(ListPositionsRequest) returns (ListPositionsResponse);

  // 获取组合摘要（总净值、总 P&L、所有持仓快照）
  rpc GetPortfolioSummary(GetPortfolioSummaryRequest) returns (PortfolioSummary);
}
```

#### 6.1.2 GetPosition 详细说明

请求：
```proto
message GetPositionRequest {
  int64  account_id = 1;  // 必填
  string symbol = 2;      // 必填，如 "AAPL" 或 "0700.HK"
  Market market = 3;      // 必填，MARKET_US 或 MARKET_HK
}
```

响应：
```proto
message GetPositionResponse {
  Position position = 1;
  // Position 中已包含实时 P&L 字段:
  // market_price, market_value, unrealized_pnl, unrealized_pct, realized_pnl, day_pnl
}
```

实现要求：
1. 优先从 Redis 读取（热路径）。
2. Redis miss 时 fallback 到 PostgreSQL + Market Data 实时计算。
3. 如果持仓不存在，返回 gRPC NOT_FOUND 错误。

#### 6.1.3 ListPositions 详细说明

请求：
```proto
message ListPositionsRequest {
  int64  account_id = 1;       // 必填
  Market market_filter = 2;    // 可选，筛选市场
}
```

响应：
```proto
message ListPositionsResponse {
  repeated Position positions = 1;        // 所有非零持仓
  string total_market_value = 2;          // 所有持仓市值之和
  string total_unrealized_pnl = 3;        // 所有持仓未实现盈亏之和
  string total_day_pnl = 4;              // 所有持仓日内盈亏之和
}
```

实现要求：
1. 仅返回 `quantity != 0` 的持仓。
2. 按 `market_value` 降序排列（最大持仓在前）。
3. 所有金额字段使用 string 类型（Protobuf 不支持 decimal）。

#### 6.1.4 GetPortfolioSummary 详细说明

```proto
message PortfolioSummary {
  int64  account_id = 1;
  string total_equity = 2;          // 总净值 = cash + market_value
  string total_market_value = 3;    // 持仓总市值
  string cash_balance = 4;          // 现金余额（来自 Fund Transfer）
  string total_unrealized_pnl = 5;  // 总未实现盈亏
  string total_realized_pnl = 6;    // 总已实现盈亏
  string total_day_pnl = 7;         // 总日内盈亏
  string buying_power = 8;          // 购买力
  int32  position_count = 9;        // 持仓数量
  repeated Position positions = 10; // 所有持仓快照
  MarginRequirement margin = 11;    // 保证金状态（仅 Margin Account）
}
```

### 6.2 REST 接口（通过 API Gateway 暴露）

#### 6.2.1 GET /v1/positions

面向客户端的 RESTful 接口，API Gateway 将 REST 请求转换为 gRPC 调用。

```http
GET /v1/positions?market=US
Authorization: Bearer <jwt>
X-Device-ID: <device_id>
```

响应：
```json
{
  "positions": [
    {
      "symbol": "AAPL",
      "market": "US",
      "quantity": 100,
      "avg_cost_basis": "150.25",
      "market_price": "155.30",
      "market_value": "15530.00",
      "unrealized_pnl": "505.00",
      "unrealized_pct": "3.36",
      "realized_pnl": "1200.50",
      "day_pnl": "130.00",
      "settled_qty": 100,
      "unsettled_qty": 0
    }
  ],
  "total_market_value": "15530.00",
  "total_unrealized_pnl": "505.00",
  "total_day_pnl": "130.00"
}
```

#### 6.2.2 GET /v1/portfolio

```http
GET /v1/portfolio
Authorization: Bearer <jwt>
```

响应：
```json
{
  "account_id": 12345,
  "total_equity": "50000.00",
  "total_market_value": "35000.00",
  "cash_balance": "15000.00",
  "total_unrealized_pnl": "2500.00",
  "total_realized_pnl": "3200.00",
  "total_day_pnl": "500.00",
  "buying_power": "25000.00",
  "position_count": 5,
  "positions": [ ... ],
  "margin": {
    "total_equity": "50000.00",
    "initial_margin": "17500.00",
    "maintenance_margin": "8750.00",
    "available_margin": "32500.00",
    "margin_usage_pct": "35.00",
    "margin_call_amount": "0"
  }
}
```

### 6.3 Kafka Events

#### 6.3.1 position.updated

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_type": "POSITION_UPDATED",
  "timestamp": "2026-03-16T09:30:05.123456Z",
  "account_id": 12345,
  "user_id": 67890,
  "symbol": "AAPL",
  "market": "US",
  "data": {
    "quantity": 100,
    "prev_quantity": 50,
    "avg_cost_basis": "150.25",
    "realized_pnl": "1200.50",
    "settled_qty": 50,
    "unsettled_qty": 50,
    "version": 5,
    "trigger": "EXECUTION",
    "execution_id": "exec-uuid-here",
    "side": "BUY",
    "fill_qty": 50,
    "fill_price": "155.30"
  }
}
```

消费者：
- **Mobile Push Service**: 向用户推送持仓变更通知
- **Margin Engine**: 重新计算保证金要求
- **Risk Engine**: 更新购买力缓存
- **Data Warehouse**: 持仓变更归档

#### 6.3.2 position.settled

```json
{
  "event_id": "...",
  "event_type": "POSITION_SETTLED",
  "timestamp": "2026-03-17T16:30:00.000Z",
  "account_id": 12345,
  "data": {
    "executions_settled": [
      {
        "execution_id": "exec-1",
        "symbol": "AAPL",
        "market": "US",
        "quantity": 50,
        "net_amount": "7765.00",
        "side": "BUY"
      }
    ],
    "new_settled_qty": 100,
    "new_unsettled_qty": 0
  }
}
```

消费者：
- **Fund Transfer**: 更新可提取余额

#### 6.3.3 portfolio.snapshot

每日收盘后生成的组合快照，用于历史追踪和合规报告。

```json
{
  "event_id": "...",
  "event_type": "PORTFOLIO_SNAPSHOT",
  "timestamp": "2026-03-16T21:00:00.000Z",
  "account_id": 12345,
  "data": {
    "snapshot_date": "2026-03-16",
    "total_equity": "50000.00",
    "total_market_value": "35000.00",
    "cash_balance": "15000.00",
    "total_unrealized_pnl": "2500.00",
    "total_realized_pnl": "3200.00",
    "positions": [
      {
        "symbol": "AAPL",
        "market": "US",
        "quantity": 100,
        "avg_cost_basis": "150.25",
        "closing_price": "155.30",
        "market_value": "15530.00",
        "unrealized_pnl": "505.00"
      }
    ]
  }
}
```

---

## 7. 开源参考实现

### 7.1 相关开源项目

| 项目 | 语言 | 相关性 | 参考价值 |
|------|------|--------|---------|
| [Quickfix/Go](https://github.com/quickfixgo/quickfix) | Go | FIX 协议 | ExecutionReport 解析，成交处理入口 |
| [Matching Engine (Go)](https://github.com/mzusman/matching-engine) | Go | 撮合引擎 | 订单簿和成交生成的参考 |
| [Shopspring/decimal](https://github.com/shopspring/decimal) | Go | 精确计算 | 所有金额计算必用 |
| [Alpaca Markets API](https://github.com/alpacahq/alpaca-trade-api-go) | Go | 券商 API | Position 和 Portfolio API 设计参考 |
| [Lemon Markets SDK](https://github.com/lemon-markets) | Multi | 券商 API | 持仓和盈亏展示的 API 设计 |
| [GoCryptoTrader](https://github.com/thrasher-corp/gocryptotrader) | Go | 交易系统 | Position tracking, P&L 计算参考 |

### 7.2 行业 API 参考

#### 7.2.1 Interactive Brokers (IBKR)

IBKR 的 Position 数据模型是行业标杆：

```
Position Fields:
- conid (Contract ID)
- position (quantity)
- mktPrice (market price)
- mktValue (market value)
- avgCost (average cost)
- unrealizedPnl
- realizedPnl
- currency
```

#### 7.2.2 Alpaca Markets

```json
{
  "asset_id": "...",
  "symbol": "AAPL",
  "qty": "100",
  "avg_entry_price": "150.25",
  "market_value": "15530.00",
  "cost_basis": "15025.00",
  "unrealized_pl": "505.00",
  "unrealized_plpc": "0.0336",
  "current_price": "155.30",
  "lastday_price": "154.00",
  "change_today": "0.00844"
}
```

#### 7.2.3 Webull

```json
{
  "ticker": { "symbol": "AAPL", "exchangeCode": "NSQ" },
  "position": "100",
  "costPrice": "150.25",
  "lastPrice": "155.30",
  "marketValue": "15530.00",
  "unrealizedProfitLoss": "505.00",
  "unrealizedProfitLossRate": "0.0336"
}
```

### 7.3 值得借鉴的模式

1. **Alpaca 的 `cost_basis` 字段**：直接暴露总成本（而非单价），方便前端计算百分比。
2. **IBKR 的 `currency` 字段**：多币种支持（我们的系统也需要，USD vs HKD）。
3. **Webull 的 `unrealizedProfitLossRate`**：直接返回百分比，减少前端计算。
4. **Alpaca 的 `lastday_price` + `change_today`**：Day P&L 计算的数据基础。

---

## 8. PRD Review 检查清单

### 8.1 功能完整性

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 多头/空头持仓正确显示 | -- | 空头 quantity < 0 |
| 2 | 买入成交更新平均成本 | -- | 加权平均，含手续费 |
| 3 | 卖出成交计算已实现盈亏 | -- | 默认加权平均法 |
| 4 | 未实现盈亏实时更新 | -- | 行情变动触发 |
| 5 | 日内盈亏基于昨日收盘 | -- | prev_close 来自 Market Data |
| 6 | 组合净值正确计算 | -- | 现金 + 持仓市值 |
| 7 | 已结算/未结算数量分开展示 | -- | settled_qty / unsettled_qty |
| 8 | 现金股息正确到账 | -- | Pay Date 入账，不影响 cost basis |
| 9 | 股票拆分正确调整 | -- | 数量 * ratio, 成本 / ratio |
| 10 | 配股处理（港股） | -- | 用户选择认购/放弃 |
| 11 | 合并/收购处理 | -- | 现金/股票/混合 |
| 12 | FIFO tax lot 追踪 | -- | 税务报告用 |
| 13 | Wash Sale 检测 | -- | 30 天窗口 |
| 14 | 碎股处理（港股） | -- | Board Lot 校验 |

### 8.2 数据准确性

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 所有金额使用 shopspring/decimal | -- | 绝不使用 float64 |
| 2 | 成交处理原子事务 | -- | 持仓+台账+事件 |
| 3 | 乐观锁防并发冲突 | -- | version 字段 |
| 4 | quantity = settled + unsettled | -- | 不变量检查 |
| 5 | 拆分前后总成本不变 | -- | qty * avg_cost 不变 |
| 6 | 已实现盈亏 = 累计卖出净收入 - 累计买入总成本 | -- | 跨生命周期验证 |

### 8.3 合规要求

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 所有持仓变更有审计记录 | -- | order_events + 台账 |
| 2 | 记录保留 7 年 | -- | append-only, WORM |
| 3 | 大额持仓披露（HK 5%） | -- | 持仓变更时检查 |
| 4 | Free-riding violation 防范 | -- | 现金账户结算校验 |
| 5 | Reg SHO 卖空追踪 | -- | 空头持仓标记 |
| 6 | Cost basis 税务报告 | -- | FIFO, Wash Sale |

### 8.4 性能要求

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 成交处理 < 3ms p99 | -- | PostgreSQL 事务 |
| 2 | P&L 更新 < 1ms p99 | -- | Redis 热路径 |
| 3 | 持仓列表 < 5ms p99 | -- | Redis 缓存 |
| 4 | 组合摘要 < 10ms p99 | -- | 聚合计算 |
| 5 | 500K 并发持仓 | -- | Redis 内存 ~2GB |

### 8.5 异常场景

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 重复成交回报处理 | -- | execution_id 幂等检查 |
| 2 | 乐观锁冲突重试 | -- | 最多 3 次 |
| 3 | Redis 不可用时 fallback | -- | 降级到 PostgreSQL |
| 4 | Market Data 中断 | -- | 使用最后已知价格 |
| 5 | 企业行动处理失败 | -- | 人工审核 + 重试机制 |
| 6 | 结算批处理失败 | -- | 幂等重试，报警通知 |

---

## 9. 工程落地注意事项

### 9.1 实现优先级

| 阶段 | 功能 | 复杂度 | 依赖 |
|------|------|--------|------|
| P0 (MVP) | 基本买卖持仓更新 | 中 | Order OMS, PostgreSQL |
| P0 (MVP) | 加权平均成本计算 | 低 | shopspring/decimal |
| P0 (MVP) | 未实现盈亏计算 | 低 | Market Data 接口 |
| P0 (MVP) | 已实现盈亏计算（加权平均） | 中 | 成交处理事务 |
| P0 (MVP) | 组合净值和购买力 | 中 | Fund Transfer (现金余额) |
| P1 | 日内盈亏 | 低 | prev_close 数据 |
| P1 | Redis 缓存层 | 中 | Redis 部署 |
| P1 | Kafka 事件发布 | 中 | Kafka 部署, Outbox |
| P1 | 结算处理（T+1/T+2） | 高 | 市场日历，批处理框架 |
| P2 | FIFO Tax Lot 追踪 | 高 | tax_lots 表 |
| P2 | Wash Sale 检测 | 高 | 30 天滑动窗口 |
| P2 | 企业行动处理 | 很高 | 外部数据源, 各类型适配 |
| P3 | 碎股处理（港股） | 中 | Board Lot 配置 |
| P3 | 历史 P&L 快照 | 低 | 定时任务 |

### 9.2 关键代码路径的测试策略

#### 9.2.1 单元测试

```go
// 必须覆盖的测试场景
func TestProcessExecution_BuyNewPosition(t *testing.T)      {} // 首次买入
func TestProcessExecution_BuyExisting(t *testing.T)          {} // 加仓
func TestProcessExecution_SellPartial(t *testing.T)          {} // 部分卖出
func TestProcessExecution_SellAll(t *testing.T)              {} // 清仓
func TestProcessExecution_SellShort(t *testing.T)            {} // 卖空
func TestProcessExecution_Duplicate(t *testing.T)            {} // 重复成交（幂等）
func TestProcessExecution_OptimisticLockConflict(t *testing.T) {} // 并发冲突

func TestAvgCostBasis_SimpleBuy(t *testing.T)               {}
func TestAvgCostBasis_MultipleBuysAtDifferentPrices(t *testing.T) {}
func TestAvgCostBasis_BuyWithFees(t *testing.T)              {}
func TestAvgCostBasis_SellDoesNotChangeAvgCost(t *testing.T) {}

func TestRealizedPnL_SellAtProfit(t *testing.T)             {}
func TestRealizedPnL_SellAtLoss(t *testing.T)               {}
func TestRealizedPnL_PartialSellCumulative(t *testing.T)    {}
func TestRealizedPnL_IncludesFees(t *testing.T)             {}

func TestDayPnL_WithPrevClose(t *testing.T)                 {}
func TestDayPnL_NewPositionNoPrevClose(t *testing.T)        {}

func TestSettlement_USMarketTPlus1(t *testing.T)            {}
func TestSettlement_HKMarketTPlus2(t *testing.T)            {}
func TestSettlement_SkipsWeekends(t *testing.T)             {}
func TestSettlement_SkipsHolidays(t *testing.T)             {}

func TestCorporateAction_CashDividend(t *testing.T)         {}
func TestCorporateAction_StockSplit(t *testing.T)           {}
func TestCorporateAction_StockSplit_PreservedTotalCost(t *testing.T) {} // 不变量
```

#### 9.2.2 集成测试

```go
// PostgreSQL + Redis 集成测试
func TestProcessExecution_FullPipeline(t *testing.T) {
    // 1. 创建测试账户和初始持仓
    // 2. 模拟买入成交
    // 3. 验证 PostgreSQL 持仓记录
    // 4. 验证 Redis 缓存一致
    // 5. 验证 Outbox 事件写入
    // 6. 模拟卖出成交
    // 7. 验证已实现盈亏
    // 8. 验证台账分录（双笔借贷）
}

func TestConcurrentExecution_SamePosition(t *testing.T) {
    // 1. 初始化持仓
    // 2. 并发发送 10 笔成交
    // 3. 验证最终持仓数量正确
    // 4. 验证乐观锁重试日志
}
```

#### 9.2.3 对账验证

```go
// 每日运行的不变量检查
func ReconcilePositions() {
    // 1. quantity == settled_qty + unsettled_qty (所有持仓)
    // 2. sum(executions) 与 positions.quantity 一致
    // 3. Redis 缓存与 PostgreSQL 一致
    // 4. sum(realized_pnl) 与台账记录一致
    // 5. sum(user_balances) == custodian_balance (三方对账)
}
```

### 9.3 监控和告警

#### 9.3.1 Prometheus Metrics

```go
// 成交处理延迟
trading_execution_processing_duration_seconds (histogram)
    labels: market, side, outcome (success/failure/retry)

// 持仓更新计数
trading_position_updates_total (counter)
    labels: market, side, trigger (execution/settlement/corporate_action)

// 乐观锁冲突
trading_position_optimistic_lock_conflicts_total (counter)
    labels: market

// P&L 计算延迟
trading_pnl_calculation_duration_seconds (histogram)
    labels: market, source (redis/postgres)

// Redis 缓存命中率
trading_position_cache_hits_total (counter)
trading_position_cache_misses_total (counter)

// 结算处理
trading_settlement_processed_total (counter)
    labels: market, outcome

// 不变量违规（严重告警）
trading_position_invariant_violations_total (counter)
    labels: type (qty_mismatch/cost_mismatch/balance_mismatch)
```

#### 9.3.2 告警规则

| 告警 | 条件 | 严重级别 | 处理方式 |
|------|------|---------|---------|
| 成交处理超时 | p99 > 10ms 持续 5 分钟 | P1 | 排查 PostgreSQL 锁等待 |
| 乐观锁冲突过多 | > 100 次/分钟 | P2 | 排查并发热点 |
| Redis 缓存不一致 | dirty_positions set > 100 | P2 | 触发全量对账 |
| 不变量违规 | 任何一次 | P0 | 立即人工介入 |
| P&L 行情延迟 | 最新行情 > 30s ago | P2 | 检查 Market Data 连接 |
| 结算批处理失败 | 任何一次 | P1 | 排查并重试 |

### 9.4 常见踩坑点

#### 9.4.1 decimal 精度丢失

```go
// 错误: 中间结果可能丢失精度
avgCost := totalCost.Div(totalQty) // Div 默认精度可能不够

// 正确: 指定精度和 rounding mode
avgCost := totalCost.DivRound(totalQty, 8) // 8 位小数，四舍五入
```

#### 9.4.2 零数量除法

```go
// 危险: 清仓后 quantity = 0，计算百分比会除零
unrealizedPct := unrealizedPnL.Div(costValue) // costValue = 0 !

// 正确: 先检查
if costValue.IsZero() {
    unrealizedPct = decimal.Zero
} else {
    unrealizedPct = unrealizedPnL.Div(costValue).Mul(decimal.NewFromInt(100))
}
```

#### 9.4.3 时区处理

```go
// 错误: 使用本地时间计算结算日
settlementDate := time.Now().AddDate(0, 0, 1)

// 正确: 使用交易所时区的交易日
tradeDate := time.Now().In(exchangeTZ) // ET for US, HKT for HK
businessDate := toBusinessDate(tradeDate, market)
settlementDate := addBusinessDays(businessDate, settlementDays, market)
```

#### 9.4.4 并发成交处理顺序

```go
// 问题: 同一订单的两笔部分成交几乎同时到达
// 如果不序列化处理，avg_cost_basis 可能计算错误

// 解决: 使用 Redis 分布式锁（per account+symbol+market）
lockKey := fmt.Sprintf("position_lock:%d:%s:%s", accountID, symbol, market)
lock := redisLock.Obtain(lockKey, 5*time.Second)
defer lock.Release()

// 或者: 使用 Kafka partition by account_id 保证同一账户的成交顺序到达
```

#### 9.4.5 Day P&L 跨日重置

```go
// 问题: 如果用户持仓跨日，Day P&L 需要在新交易日开始时重置
// 但 "新交易日" 的定义因市场而异

// US: 新交易日从 04:00 ET 开始（盘前）
// HK: 新交易日从 09:00 HKT 开始（开市竞价）

// 实现: 在盘前同步 prev_close，Day P&L 自动重置
```

### 9.5 数据迁移注意事项

如果从旧系统迁移：

1. **历史持仓导入**: 必须同时导入 `avg_cost_basis` 和 `realized_pnl`。
2. **Tax Lot 重建**: 如果旧系统不支持 FIFO，需要从历史成交记录重建 tax lots。
3. **Version 初始化**: 迁移的持仓 version 从 1 开始。
4. **Redis 预热**: 迁移完成后执行一次全量 PostgreSQL -> Redis 同步。
5. **不变量验证**: 迁移后运行完整的对账检查。

### 9.6 灾难恢复

| 场景 | 恢复策略 | RTO | RPO |
|------|---------|-----|-----|
| Redis 全部丢失 | 从 PostgreSQL 全量重建 | < 5 分钟 | 0（PostgreSQL 是 source of truth） |
| PostgreSQL 主库宕机 | 切换到从库 | < 30 秒 | < 1 秒 |
| Kafka 不可用 | 事件暂存 outbox 表，恢复后重放 | 0（不影响写入） | 0 |
| 成交处理中间失败 | 事务回滚，ExecutionReport 重新投递 | 自动 | 0 |
| 结算批处理中断 | 幂等重跑 | < 5 分钟 | 0 |

---

## 附录 A: 数据库表设计

### positions 表

```sql
CREATE TABLE positions (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    account_id      BIGINT NOT NULL,
    symbol          TEXT NOT NULL,
    market          TEXT NOT NULL,         -- 'US' / 'HK'
    quantity        BIGINT NOT NULL DEFAULT 0,
    avg_cost_basis  NUMERIC(20, 8) NOT NULL DEFAULT 0,
    realized_pnl    NUMERIC(20, 8) NOT NULL DEFAULT 0,
    settled_qty     BIGINT NOT NULL DEFAULT 0,
    unsettled_qty   BIGINT NOT NULL DEFAULT 0,
    first_trade_at  TIMESTAMPTZ,
    last_trade_at   TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version         INT NOT NULL DEFAULT 0,
    UNIQUE (account_id, symbol, market)
);

CREATE INDEX idx_positions_user ON positions (user_id);
CREATE INDEX idx_positions_symbol ON positions (symbol, market);
CREATE INDEX idx_positions_nonzero ON positions (account_id) WHERE quantity != 0;
```

### tax_lots 表（FIFO 追踪）

```sql
CREATE TABLE tax_lots (
    id               BIGSERIAL PRIMARY KEY,
    account_id       BIGINT NOT NULL,
    symbol           TEXT NOT NULL,
    market           TEXT NOT NULL,
    buy_execution_id UUID NOT NULL,
    quantity         BIGINT NOT NULL,         -- 剩余未卖出数量
    original_qty     BIGINT NOT NULL,         -- 原始买入数量
    cost_per_share   NUMERIC(20, 8) NOT NULL, -- 每股成本（含手续费分摊）
    bought_at        TIMESTAMPTZ NOT NULL,
    wash_sale_adj    NUMERIC(20, 8) NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lots_account ON tax_lots (account_id, symbol, market, bought_at);
CREATE INDEX idx_lots_open ON tax_lots (account_id, symbol, market)
    WHERE quantity > 0;
```

### portfolio_snapshots 表（每日快照）

```sql
CREATE TABLE portfolio_snapshots (
    id                  BIGSERIAL PRIMARY KEY,
    account_id          BIGINT NOT NULL,
    snapshot_date       DATE NOT NULL,
    total_equity        NUMERIC(20, 8) NOT NULL,
    total_market_value  NUMERIC(20, 8) NOT NULL,
    cash_balance        NUMERIC(20, 8) NOT NULL,
    total_unrealized    NUMERIC(20, 8) NOT NULL,
    total_realized      NUMERIC(20, 8) NOT NULL,
    positions_json      JSONB NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (account_id, snapshot_date)
);

CREATE INDEX idx_portfolio_snap ON portfolio_snapshots (account_id, snapshot_date DESC);
```

---

## 附录 B: 完整计算示例

### 场景: 美股 AAPL 交易全过程

**初始状态**: 空仓，现金 $50,000

**第 1 笔: 买入 100 股 @ $150.00，佣金 $0.50**
```
quantity:       0 → 100
avg_cost_basis: 0 → (150.00 * 100 + 0.50) / 100 = $150.005
settled_qty:    0
unsettled_qty:  0 → 100
cash_balance:   $50,000 → $50,000 - $15,000 - $0.50 = $34,999.50
```

**第 2 笔: 买入 50 股 @ $155.00，佣金 $0.25**
```
quantity:       100 → 150
avg_cost_basis: (150.005 * 100 + 155.00 * 50 + 0.25) / 150 = $151.67
settled_qty:    0 (T+1 尚未到)
unsettled_qty:  100 → 150
cash_balance:   $34,999.50 - $7,750 - $0.25 = $27,249.25
```

**T+1 结算第 1 笔**:
```
settled_qty:    0 → 100
unsettled_qty:  150 → 50
quantity:       150 (不变)
```

**行情: AAPL 涨到 $160.00，昨收 $155.50**
```
market_value:    150 * $160.00 = $24,000.00
cost_value:      150 * $151.67 = $22,750.50
unrealized_pnl:  $24,000.00 - $22,750.50 = $1,249.50
unrealized_pct:  $1,249.50 / $22,750.50 * 100 = 5.49%
day_pnl:         (160.00 - 155.50) * 150 = $675.00

portfolio_equity: $27,249.25 + $24,000.00 = $51,249.25
```

**第 3 笔: 卖出 80 股 @ $160.00，佣金 $0.40，SEC Fee $0.36**
```
quantity:        150 → 70
avg_cost_basis:  $151.67 (卖出不变)
realized_pnl:    0 → (160.00 - 151.67) * 80 - 0.40 - 0.36 = $665.64
settled_qty:     100 → 20 (优先减已结算)
unsettled_qty:   50 (不变)
cash_balance:    $27,249.25 + $12,800 - $0.40 - $0.36 = $40,048.49
```

**验证不变量**:
```
quantity = settled_qty + unsettled_qty → 70 = 20 + 50 ✓
总投入 = 150 * 151.67 = $22,750.50
总收回 = 80 * 160.00 - 0.76 = $12,799.24
剩余成本 = 70 * 151.67 = $10,616.90
差额 = $22,750.50 - $12,799.24 - $10,616.90 = -$665.64 (= 已实现盈亏的相反数，但手续费已包含) ✓
```
