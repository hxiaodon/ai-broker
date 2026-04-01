---
name: position-pnl
description: 持仓管理、成本基础方法、已实现/未实现 P&L、Wash Sale 规则
type: domain-prd
surface_prd: mobile/docs/prd/06-portfolio.md (§六.1 成本计算、§七 Wash Sale)
version: 1
status: DRAFT
created: 2026-03-30T00:00+08:00
last_updated: 2026-03-30T00:00+08:00
revisions:
  - rev: 1
    date: 2026-03-30T00:00+08:00
    author: trading-engineer
    summary: "初始版本：从 Surface PRD 提取成本基础方法、P&L 定义、Wash Sale 识别逻辑"
---

# 持仓与盈亏管理 (Position & P&L Management) — Domain PRD

> **对应 Surface PRD**：`mobile/docs/prd/06-portfolio.md` §六.1（成本计算）、§七（Wash Sale）
> **依赖 Spec**：`services/trading-engine/docs/specs/domains/05-position-pnl.md`
> **相关规定**：IRS Wash Sale Rule、美国报税要求（1099-B）

---

## 1. 成本基础方法（Cost Basis Method）

### 1.1 确定方案：加权均价法

> **PM 决策**（2026-03-30）：
> 本系统采用**加权均价法（Weighted Average Cost）**计算成本基础。
> 该方案适用于 Phase 1（美股）和 Phase 2（港股）。

**业务依据：**
- **实现简洁** — 仅维护单个均价值，无需复杂批次链表管理，符合 MVP 快速交付要求
- **税务合规** — IRS 明确允许加权均价法用于美国报税，无额外税务复杂性
- **用户体验** — 用户理解直观，持仓均价即实际均价
- **美港股统一** — Phase 2 港股也采用同一方法，避免用户困惑

### 1.2 加权均价法（当前实现）

**定义**：所有持仓取单一平均成本价，卖出时不区分购买批次。

```
新均价 = (原持仓 × 原均价 + 新买数量 × 成交价) / 新总持仓数量
```

**示例**：
```
初始状态：0 股

Execution 1: 买入 100 股 AAPL @ $180.00
  → 总股数 = 100，均价 = $180.00，成本基础 = $18,000

Execution 2: 买入 50 股 AAPL @ $190.00
  → 新均价 = (100×$180 + 50×$190) / 150 = $183.33
  → 总股数 = 150，成本基础 = $27,500

Execution 3: 卖出 30 股 AAPL @ $200.00
  → 已实现 P&L = 30 × ($200 - $183.33) = $500
  → 剩余 120 股，均价仍为 $183.33（加权均价）
```

**优点**：
- 计算简单，只需维护单个均价值
- IRS 允许，无额外税务复杂性

**缺点**：
- 不区分购买批次，无法追踪个别批次的成本
- 无法精确执行 Wash Sale 规则（需要批次信息）

### 1.3 替代方案：FIFO（先进先出）

**定义**：每次卖出时，按照购买顺序匹配最早的批次。

```
示例（使用 FIFO）：
Execution 1: 买入 100 股 @ $180 → 批次 A
Execution 2: 买入 50 股 @ $190 → 批次 B
Execution 3: 卖出 30 股 @ $200

FIFO 匹配：优先卖出批次 A 的 30 股 @ $180 成本
  → 已实现 P&L = 30 × ($200 - $180) = $600

剩余：批次 A 70 股 @ $180，批次 B 50 股 @ $190
```

**优点**：
- 更容易精确追踪 Wash Sale（知道每批次的购买日期）
- 更接近实际交易流程

**缺点**：
- 需要维护批次链表，计算复杂度高
- 库存管理复杂

### 1.4 PM 决策说明（已确认）

**采用加权均价法的关键理由：**

1. **Phase 1 MVP 优先** — 加权均价法无需维护复杂的批次链表，实现速度快，符合快速上市要求
2. **税务完全合规** — IRS 明确允许加权均价法用于美国报税；Wash Sale 规则在 Phase 1 采用"标记+提示"模式，用户可咨询税务顾问
3. **一致性** — Phase 1 和 Phase 2 都采用相同方法，避免用户切换市场时的困惑
4. **用户友好** — 均价直观理解，不需要批次管理的复杂概念

**未来升级路径：** 如 Phase 2 需要更精细的成本管理或用户要求个性化选择，可考虑在 Phase 3 支持 FIFO 或用户自选（工作量约 20-25 人天）

---

## 2. 盈亏（P&L）的三种维度

### 2.1 未实现盈亏（Unrealized P&L）

**定义**：持仓在当前市价下的浮动盈亏。

```
Unrealized P&L = 当前市价 - 成本基础价格
               × 持仓数量（仅已结算部分计算）

示例：
  持仓 100 股 AAPL
  成本均价 = $150
  当前市价 = $160
  浮动盈亏 = ($160 - $150) × 100 = $1,000
```

**特性**：
- 实时更新（每次行情变动）
- 不持久化（实时计算，无需存储）
- 用户可见（持仓页展示）

### 2.2 已实现盈亏（Realized P&L）

**定义**：卖出时锁定的盈亏。

```
Realized P&L = (卖出价 - 成本基础价) × 成交量

示例：
  卖出 100 股 AAPL @ $160
  成本基础 = $150
  已实现 P&L = ($160 - $150) × 100 = $1,000
```

**特性**：
- 在成交时一次性确定，不再改变
- 持久化存储（`executions.realized_pnl`）
- 用于报税（1099-B）
- 需要考虑 Wash Sale 税务影响

### 2.3 日内盈亏（Day P&L）

**定义**：当前市价相比上一个交易日收盘价的变化。

```
Day P&L = (当前市价 - 上一交易日收盘价) × 持仓数量

示例：
  昨日收盘价 = $150
  当前市价 = $155
  持仓 100 股
  日内 P&L = ($155 - $150) × 100 = $500
```

**特性**：
- 仅在交易时段内更新
- 用于用户直观了解当日涨跌

---

## 3. 平均成本价的维护与更新

### 3.1 购买时更新

```python
def update_avg_cost_on_buy(position, execution):
    """
    position: {symbol, settled_qty, avg_cost, ...}
    execution: {executed_qty, executed_price, ...}
    """
    old_qty = position.settled_qty
    old_avg = position.avg_cost

    new_qty = old_qty + execution.executed_qty
    new_avg = (old_qty * old_avg + execution.executed_qty * execution.executed_price) / new_qty

    position.settled_qty = new_qty
    position.avg_cost = new_avg
    position.cost_basis = new_qty * new_avg  # 总成本基础

    return position
```

### 3.2 卖出时保持不变

```python
def on_sell_execution(position, execution):
    """
    卖出时，均价不变；仅成交数量减少
    """
    position.settled_qty -= execution.executed_qty
    # avg_cost 保持不变
    # 新的 cost_basis = settled_qty * avg_cost

    # 已实现 P&L 在 execution 表中单独记录
    execution.realized_pnl = execution.executed_qty * (execution.executed_price - position.avg_cost)
```

### 3.3 公司行动调整（Phase 1 人工 + Phase 2 自动化）

**Phase 1 处理方案：人工触发**

Phase 1 仅支持以下常见公司行动，由 Compliance 团队人工确认和触发：

| 公司行动 | Phase 1 | 处理方式 |
|---------|--------|--------|
| 现金分红（Cash Dividend） | ✅ | 自动或半自动处理 |
| 股票分红（Stock Dividend） | ✅ | 人工触发后台工具 |
| 股票拆分（Stock Split） | ✅ | 人工触发后台工具 |
| 反向拆分（Reverse Split） | ❌ | Phase 2 |
| 配股（Rights Offering） | ❌ | Phase 2 |
| 并购（Merger） | ❌ | Phase 2 |

**Phase 1 人工处理流程：**
```
1. Compliance 团队监控交易所公司行动公告
2. 识别影响用户持仓的事件（如 AAPL 3:1 拆分）
3. PM 评估和确认
4. 后台工具（Admin Panel）手动触发调整：
   - 更新 positions 表的 qty 和 avg_cost
   - 记录 position_adjustments 审计日志
5. 推送用户通知："AAPL 发生 3:1 拆分，您的持仓已自动调整"
6. Compliance 确认调整正确性
```

**股票拆分调整公式：**
```
拆分比例 = 3:1 (3 股变 1 股)

Before: 100 股 @ $180 均价
After: 300 股 @ $60 均价

调整：
  qty = qty * split_ratio
  avg_cost = avg_cost / split_ratio
```

**Phase 2 自动化方案：**

计划在 Phase 2 启动时设计完整的自动化流程：
1. 对接公司行动数据源（Bloomberg/FactSet API）
2. 自动识别持仓涉及的事件
3. 按规则自动计算调整并应用
4. Compliance Officer 事后审核

预计工作量：20-25 人天；数据源成本：月度 $3-5K

---

## 4. Wash Sale 规则识别与标记

### 4.1 Wash Sale 的定义

**IRS Wash Sale Rule**：
```
如果用户卖出证券产生亏损，
然后在卖出日前 30 天至后 30 天（共 61 天窗口）内买入相同证券，
则原卖出的亏损不可用于当年报税（税基延后至新购买的持仓）。

卖出日 ± 30 天 = 不可用于报税的亏损窗口
```

### 4.2 识别算法

```python
def check_wash_sale(sell_execution):
    """
    sell_execution: {account_id, symbol, executed_date, realized_pnl, ...}

    Return: {is_wash_sale: bool, disallowed_loss: decimal, notes: str}
    """

    # 如果卖出没有产生亏损，不适用 Wash Sale
    if sell_execution.realized_pnl >= 0:
        return {"is_wash_sale": False}

    symbol = sell_execution.symbol
    sell_date = sell_execution.executed_date
    window_start = sell_date - 30 days
    window_end = sell_date + 30 days

    # 查询同一账户的同一证券，在 60 天窗口内的所有买入
    subsequent_buys = query_executions(
        account_id=sell_execution.account_id,
        symbol=symbol,
        side="BUY",
        executed_date_range=(window_start, window_end)
    )

    if len(subsequent_buys) > 0:
        # 买入数量需要 >= 卖出数量，才算完全冲销
        total_buy_qty = sum(b.executed_qty for b in subsequent_buys)

        if total_buy_qty >= sell_execution.executed_qty:
            return {
                "is_wash_sale": True,
                "disallowed_loss": sell_execution.realized_pnl,  # 负数
                "wash_sale_dates": [(b.executed_date) for b in subsequent_buys]
            }

    return {"is_wash_sale": False}
```

### 4.3 前端标记与展示

在"已实现盈亏"记录中，如果检测到 Wash Sale：

```
[已实现盈亏列表]

卖出 100 股 AAPL @ $140（买入均价 $150）
亏损：-$1,000
⚠️ Wash Sale 标记：
   该笔交易产生的亏损可能不符合税务抵扣条件。
   请咨询税务专业人士了解详情。

相关买入：2026-04-05 买入 100 股 @ $145
```

### 4.4 税务处理（Phase 2）

```
在生成 1099-B 报表时：
  1. 计算所有卖出的已实现 P&L
  2. 识别 Wash Sale 卖出
  3. 将 Wash Sale 的亏损金额转移到对应的买入持仓的成本基础
  4. 调整后的成本基础用于报税计算
```

---

## 5. 持仓市值与占比计算

### 5.1 持仓市值

```
Position Market Value = settled_qty × current_market_price
```

**实时更新**：
- 行情推送时实时计算
- 如果市价断连，使用最后已知价格

### 5.2 总持仓市值

```
Total Position Value = Σ(symbol: Position Market Value)
```

### 5.3 占比

```
Position Ratio = Position Market Value / Total Position Value

触发警告阈值：
  if Position Ratio > 30%
    → 显示 ⚠️ 集中度警告横幅
```

---

## 6. REST API 响应定义

所有持仓相关 API 端点的返回格式在本章定义。**所有金额字段使用 string decimal；所有时间戳使用 ISO 8601 UTC。**

### 6.1 GET /api/v1/positions — 200 OK

列表查询所有持仓，按市值从大到小排序。

**响应 200 OK**：
```json
{
  "positions": [
    {
      // 基本信息
      "symbol": "AAPL",
      "market": "US",                    // US | HK
      "company_name": "Apple Inc.",      // 公司名称

      // 持仓数量（来自 settlement.md §2）
      "quantity": 200,                   // 总持仓 = settled_qty + unsettled_qty
      "settled_qty": 100,                // 已结算数量（可卖出）
      "unsettled_qty": 100,              // 未结算数量（不可卖出）
      "settlement_date": "2026-04-01T00:00:00Z",  // 未结算部分的结算日期

      // 成本基础（来自 position-pnl.md §1 — 加权均价法）
      "avg_cost": "148.3200",            // 加权均价（string decimal）
      "cost_basis": "29664.00",          // 总成本 = quantity × avg_cost

      // 实时市价（来自 Market Data 的行情）
      "current_price": "150.2500",       // 最新市价（string decimal）
      "market_value": "30045.00",        // 持仓市值 = quantity × current_price

      // P&L（来自 position-pnl.md §2）
      "unrealized_pnl": "381.00",        // 未实现盈亏 = market_value - cost_basis
      "unrealized_pnl_pct": "1.29",      // 未实现盈亏率（百分比，已乘以 100）
      "today_pnl": "125.30",             // 当日浮动盈亏（仅当日变化）
      "today_pnl_pct": "0.42",           // 当日盈亏率（百分比）

      // 风险指标
      "account_ratio": "0.2134",         // 占账户总资产比例（用于集中度预警 > 30%）

      // 时间戳
      "first_buy_date": "2026-03-15T00:00:00Z",  // 首次买入日期
      "updated_at": "2026-03-31T09:45:00.000Z"   // 最后更新时间（行情变动时）
    },
    {
      "symbol": "MSFT",
      "market": "US",
      "company_name": "Microsoft Corporation",
      "quantity": 150,
      "settled_qty": 150,
      "unsettled_qty": 0,
      "settlement_date": null,
      "avg_cost": "380.5000",
      "cost_basis": "57075.00",
      "current_price": "418.7500",
      "market_value": "62812.50",
      "unrealized_pnl": "5737.50",
      "unrealized_pnl_pct": "10.05",
      "today_pnl": "456.25",
      "today_pnl_pct": "0.73",
      "account_ratio": "0.3215",
      "first_buy_date": "2026-02-10T00:00:00Z",
      "updated_at": "2026-03-31T09:45:00.000Z"
    }
  ],

  // 整体汇总
  "summary": {
    "total_market_value": "92857.50",    // 全部持仓市值
    "total_cost_basis": "86739.00",      // 全部持仓成本
    "total_unrealized_pnl": "6118.50",   // 全部持仓未实现盈亏
    "total_unrealized_pnl_pct": "7.05",  // 全部持仓盈亏率
    "updated_at": "2026-03-31T09:45:00.000Z"
  }
}
```

---

### 6.2 GET /api/v1/positions/:symbol — 200 OK

单只持仓详情，包含完整成交历史和已实现盈亏。

**响应 200 OK**：
```json
{
  // 持仓基本信息（与列表相同的字段）
  "symbol": "AAPL",
  "market": "US",
  "company_name": "Apple Inc.",
  "quantity": 200,
  "settled_qty": 100,
  "unsettled_qty": 100,
  "settlement_date": "2026-04-01T00:00:00Z",
  "avg_cost": "148.3200",
  "cost_basis": "29664.00",
  "current_price": "150.2500",
  "market_value": "30045.00",
  "unrealized_pnl": "381.00",
  "unrealized_pnl_pct": "1.29",
  "today_pnl": "125.30",
  "today_pnl_pct": "0.42",
  "first_buy_date": "2026-03-15T00:00:00Z",
  "updated_at": "2026-03-31T09:45:00.000Z",

  // 成交历史（按日期排序）
  "trades": [
    {
      "trade_id": "trade-001",
      "trade_date": "2026-03-15T00:00:00Z",
      "side": "BUY",
      "quantity": 100,
      "price": "147.5000",               // string decimal
      "gross_amount": "14750.00",        // 成交额（数量 × 价格）
      "fees": "0.30",                    // 总费用
      "net_amount": "14750.30",          // 净成本（成交额 + 费用）
      "venue": "NASDAQ",
      "status": "SETTLED",               // SETTLED | UNSETTLED
      "settlement_date": "2026-03-16T00:00:00Z"
    },
    {
      "trade_id": "trade-002",
      "trade_date": "2026-03-20T00:00:00Z",
      "side": "BUY",
      "quantity": 100,
      "price": "149.1400",
      "gross_amount": "14914.00",
      "fees": "0.30",
      "net_amount": "14914.30",
      "venue": "NYSE",
      "status": "SETTLED",
      "settlement_date": "2026-03-21T00:00:00Z"
    }
  ],

  // 已实现盈亏（仅卖出才会产生）
  "realized_trades": [
    {
      "sell_trade_id": "trade-003",
      "sell_date": "2026-03-25T00:00:00Z",
      "sell_price": "155.0000",
      "sell_qty": 50,
      "cost_basis": "7416.00",           // 对应买入的成本（加权均价 × 数量）
      "gross_proceeds": "7750.00",       // 卖出金额
      "fees": "2.45",                    // 卖出费用（交易所、SEC、FINRA）
      "realized_pnl": "333.55",          // 已实现盈亏（卖出 - 成本 - 费用）
      "realized_pnl_pct": "4.50",        // 已实现盈亏率
      "venue": "NASDAQ",
      "status": "SETTLED",
      "settlement_date": "2026-03-26T00:00:00Z",
      "wash_sale_flag": false,           // 是否涉及 Wash Sale（见§4）
      "wash_sale_note": null             // Wash Sale 说明（如有）
    }
  ],

  // 累计统计
  "cumulative": {
    "total_cost_basis": "29664.00",     // 全部买入的总成本
    "total_realized_pnl": "333.55",     // 已卖出部分的累计已实现盈亏
    "total_unrealized_pnl": "381.00",   // 当前持仓的未实现盈亏
    "total_pnl": "714.55"               // 累计总盈亏（已实现 + 未实现）
  }
}
```

---

### 6.3 WebSocket position.updated 消息

推送时机：该持仓的市价变动时（通常每秒或行情更新时）。

**消息格式**：
```json
{
  "channel": "position.updated",
  "data": {
    // 基本信息
    "symbol": "AAPL",
    "market": "US",

    // 数量信息（来自 settlement.md §2）
    "quantity": 200,
    "settled_qty": 100,
    "unsettled_qty": 100,
    "settlement_date": "2026-04-01T00:00:00Z",

    // 成本（来自 position-pnl.md §1）
    "avg_cost": "148.3200",
    "cost_basis": "29664.00",

    // 市价和 P&L（来自 position-pnl.md §2）
    "current_price": "150.2500",
    "market_value": "30045.00",
    "unrealized_pnl": "381.00",
    "unrealized_pnl_pct": "1.29",

    // 时间戳
    "updated_at": "2026-03-31T09:45:00.123Z"
  }
}
```

---

## 7. 与其他 Domain PRD 的关系

- **order-lifecycle.md**：成交（FILLED）后触发持仓更新
- **settlement.md**：已结算数量和未结算数量的分离（见§2）
- **risk-rules.md**：持仓市值用于集中度检查（见 §1 第 5 项）和保证金计算
- **type-definitions.md**：decimal、timestamp 的序列化规则
- **mobile/docs/prd/06-portfolio.md**：前端展示持仓均价、未实现/已实现 P&L

---

## 8. 实现清单

### Domain PRD 完成标志

- [ ] PM 确认成本基础方法（FIFO vs 加权均价）
- [ ] 在 `mobile/docs/prd/06-portfolio.md §6.1` 中补充澄清说明
- [ ] 数据库 schema：`positions` 和 `executions` 表设计
- [ ] 成本基础更新逻辑实现
- [ ] Wash Sale 识别算法实现和测试
- [ ] 公司行动自动化（Phase 2）
- [ ] 1099-B 报表生成（Phase 2）

### 与 Surface PRD 的同步

- [ ] `mobile/docs/prd/06-portfolio.md §6.1` 中移除"FIFO 原则"标题歧义
- [ ] `mobile/docs/prd/06-portfolio.md §6.1` 中补充对 Domain PRD 的引用
