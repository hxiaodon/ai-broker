# 交易系统技术架构设计

> 美港股券商交易 APP — Trading System Architecture

## 1. 系统概述

交易系统是券商平台的核心引擎，负责接收用户下单指令，经过风控校验后路由至交易所执行，并实时跟踪订单状态、更新持仓和盈亏。系统需同时支持美股（NYSE/NASDAQ）和港股（HKEX）两个市场。

### 1.1 核心指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 订单验证+风控 | < 5ms (p99) | 从接收到风控决策 |
| 订单到交易所 | < 10ms (p99) | 从风控通过到 FIX 发出 |
| 成交处理 | < 3ms (p99) | 从收到 ExecutionReport 到持仓更新 |
| P&L 更新 | < 1ms (p99) | 每次行情变动时的持仓估值 |
| 系统吞吐 | 10,000+ orders/s | 峰值处理能力 |
| 可用性 | 99.99% | 盘中时段 |
| 资金准确率 | 100% | 零容差 |

### 1.2 支持的市场与交易时段

| 市场 | 交易所 | 常规交易 | 盘前 | 盘后 | 结算 |
|------|--------|----------|------|------|------|
| 美股 | NYSE | 09:30-16:00 ET | 04:00-09:30 ET | 16:00-20:00 ET | T+1 |
| 美股 | NASDAQ | 09:30-16:00 ET | 04:00-09:30 ET | 16:00-20:00 ET | T+1 |
| 港股 | HKEX | 09:30-12:00, 13:00-16:00 HKT | 09:00-09:30 | 16:00-16:10 (收市竞价) | T+2 |

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Trading System                                        │
│                                                                                 │
│  ┌─────────────┐     ┌──────────────────┐     ┌──────────────────────────────┐ │
│  │   Clients    │     │   API Gateway    │     │     Order Management        │ │
│  │              │     │                  │     │        System (OMS)          │ │
│  │ ┌─────────┐ │     │ ┌──────────────┐ │     │                              │ │
│  │ │ iOS App │─┼────▶│ │ REST / gRPC  │─┼────▶│ ┌────────────────────────┐  │ │
│  │ └─────────┘ │     │ │ Gateway      │ │     │ │   Order Validator      │  │ │
│  │ ┌─────────┐ │     │ └──────────────┘ │     │ │   (格式/规则校验)       │  │ │
│  │ │Android  │─┼────▶│ ┌──────────────┐ │     │ └──────────┬─────────────┘  │ │
│  │ └─────────┘ │     │ │ Auth + Rate  │ │     │            │                │ │
│  │ ┌─────────┐ │     │ │ Limiter      │ │     │ ┌──────────▼─────────────┐  │ │
│  │ │Web/API  │─┼────▶│ └──────────────┘ │     │ │   Risk Engine          │  │ │
│  │ └─────────┘ │     └──────────────────┘     │ │   (Pre-Trade 风控)     │  │ │
│  └─────────────┘                               │ └──────────┬─────────────┘  │ │
│                                                │            │                │ │
│                                                │ ┌──────────▼─────────────┐  │ │
│                                                │ │   Order State Machine  │  │ │
│                                                │ │   (订单状态管理)        │  │ │
│                                                │ └──────────┬─────────────┘  │ │
│                                                └────────────┼────────────────┘ │
│                                                             │                  │
│                          ┌──────────────────────────────────┤                  │
│                          │                                  │                  │
│                          ▼                                  ▼                  │
│              ┌──────────────────────┐         ┌──────────────────────┐         │
│              │  Smart Order Router  │         │    Event Bus         │         │
│              │       (SOR)          │         │    (Kafka)           │         │
│              │                      │         │                      │         │
│              │ ┌──────────────────┐ │         │  order.created       │         │
│              │ │ Best Execution   │ │         │  order.risk_approved │         │
│              │ │ Algorithm        │ │         │  order.submitted     │         │
│              │ └────────┬─────────┘ │         │  order.filled        │         │
│              │          │           │         │  order.cancelled     │         │
│              └──────────┼───────────┘         │  position.updated    │         │
│                         │                     │  margin.call         │         │
│              ┌──────────▼───────────┐         └──────────┬───────────┘         │
│              │   FIX Engine         │                    │                     │
│              │                      │                    ▼                     │
│              │ ┌──────────────────┐ │         ┌──────────────────────┐         │
│              │ │ NYSE Session     │ │         │  Post-Trade          │         │
│              │ ├──────────────────┤ │         │  Processing          │         │
│              │ │ NASDAQ Session   │ │         │                      │         │
│              │ ├──────────────────┤ │         │ ┌──────────────────┐ │         │
│              │ │ HKEX Session     │ │         │ │ Position Engine  │ │         │
│              │ └──────────────────┘ │         │ │ (持仓/P&L)       │ │         │
│              └──────────────────────┘         │ ├──────────────────┤ │         │
│                         │                     │ │ Margin Engine    │ │         │
│                         │ ExecutionReport     │ │ (保证金计算)     │ │         │
│                         ▼                     │ ├──────────────────┤ │         │
│              ┌──────────────────────┐         │ │ Settlement       │ │         │
│              │  Execution Handler   │────────▶│ │ (结算处理)       │ │         │
│              │  (成交处理)           │         │ ├──────────────────┤ │         │
│              └──────────────────────┘         │ │ Reconciliation   │ │         │
│                                               │ │ (对账)           │ │         │
│                                               │ └──────────────────┘ │         │
│                                               └──────────────────────┘         │
│                                                                                │
│  ┌──────────────────────────────────────────────────────────────────────────┐  │
│  │                        Data Layer                                        │  │
│  │                                                                          │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │  │
│  │  │ PostgreSQL   │  │ Redis        │  │ Kafka        │  │Elasticsearch│ │  │
│  │  │ (Orders,     │  │ (Cache,      │  │ (Events,     │  │(Audit Logs, │ │  │
│  │  │  Positions,  │  │  Locks,      │  │  Streaming)  │  │ Compliance) │ │  │
│  │  │  Ledger)     │  │  Session)    │  │              │  │             │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 订单管理系统 (OMS)

### 3.1 订单状态机

```
                          ┌─────────────────┐
                          │    CREATED       │
                          │  (订单已创建)     │
                          └────────┬────────┘
                                   │ validate()
                                   ▼
                          ┌─────────────────┐
                  ┌───────│    VALIDATED     │───────┐
                  │       │  (格式校验通过)   │       │
                  │       └────────┬────────┘       │
                  │                │ riskCheck()     │ reject()
                  │                ▼                 ▼
                  │       ┌─────────────────┐  ┌──────────┐
                  │       │  RISK_APPROVED   │  │ REJECTED │
                  │       │  (风控通过)       │  │ (被拒绝)  │
                  │       └────────┬────────┘  └──────────┘
                  │                │ submit()
                  │                ▼
                  │       ┌─────────────────┐
                  │       │    PENDING       │
                  │       │  (已发送交易所)   │
                  │       └────────┬────────┘
                  │                │ exchange_ack()
                  │                ▼
                  │       ┌─────────────────┐
                  │       │      OPEN        │◄──── partialFill() 循环
                  │       │  (交易所已确认)   │
                  │       └───┬────┬────┬───┘
                  │          │    │    │
                  │    fill() │    │    │ cancel()
                  │          ▼    │    ▼
                  │  ┌────────┐   │   ┌─────────────┐
                  │  │ FILLED │   │   │ CANCEL_SENT │
                  │  │(全部成交)│   │   │(取消请求已发)│
                  │  └────────┘   │   └──────┬──────┘
                  │               │          │ cancel_ack()
                  │               │          ▼
                  │               │   ┌───────────┐
                  │               │   │ CANCELLED │
                  │               │   │ (已取消)   │
                  │               │   └───────────┘
                  │               │
                  │          partialFill()
                  │               │
                  │               ▼
                  │       ┌─────────────────┐
                  │       │  PARTIAL_FILL   │───▶ 继续等待更多成交
                  │       │  (部分成交)      │     或转为 FILLED/CANCELLED
                  │       └─────────────────┘
                  │
                  │  exchange_reject()
                  │       ┌─────────────────┐
                  └──────▶│ EXCHANGE_REJECT │
                          │ (交易所拒绝)     │
                          └─────────────────┘

终态: FILLED, CANCELLED, REJECTED, EXCHANGE_REJECT
```

#### 状态转换规则 (严格执行)

```go
// 合法的状态转换定义
var validTransitions = map[OrderStatus][]OrderStatus{
    StatusCreated:       {StatusValidated, StatusRejected},
    StatusValidated:     {StatusRiskApproved, StatusRejected},
    StatusRiskApproved:  {StatusPending},
    StatusPending:       {StatusOpen, StatusExchangeReject, StatusRejected},
    StatusOpen:          {StatusPartialFill, StatusFilled, StatusCancelSent},
    StatusPartialFill:   {StatusPartialFill, StatusFilled, StatusCancelSent},
    StatusCancelSent:    {StatusCancelled, StatusFilled, StatusPartialFill},
    // 终态: 不允许任何转换
    StatusFilled:        {},
    StatusCancelled:     {},
    StatusRejected:      {},
    StatusExchangeReject:{},
}
```

### 3.2 支持的订单类型

| 订单类型 | 代码 | US | HK | 说明 |
|---------|------|----|----|------|
| 市价单 | MARKET | ✅ | ✅ | 以当前最优价格立即成交 |
| 限价单 | LIMIT | ✅ | ✅ | 指定价格或更优价格成交 |
| 止损单 | STOP | ✅ | ✅ | 触及止损价后转为市价单 |
| 止损限价单 | STOP_LIMIT | ✅ | ✅ | 触及止损价后转为限价单 |
| 追踪止损单 | TRAILING_STOP | ✅ | ❌ | 止损价跟随市场价格浮动 |
| 开盘市价单 | MOO | ✅ | ✅ | 在开盘集合竞价时以市价执行 |
| 收盘市价单 | MOC | ✅ | ✅ | 在收盘集合竞价时以市价执行 |
| 全额成交否则取消 | AON | ✅ | ❌ | 必须全部成交，否则全部取消 |
| 立即成交否则取消 | IOC | ✅ | ✅ | 立即尽量成交，剩余取消 |
| 有效至取消 | GTC | ✅ | ✅ | 持续有效直到成交或手动取消 (max 90天) |
| 当日有效 | DAY | ✅ | ✅ | 当日收盘前未成交自动取消 |

#### 订单类型 × 市场特殊规则

```go
// 港股特殊规则
type HKMarketRules struct {
    // 最小交易单位 (每手股数因标的而异)
    LotSizes map[string]int  // "0700.HK" -> 100, "9988.HK" -> 100

    // 价格最小变动单位 (Tick Size) 取决于价格区间
    // 0.01-0.25: tick=0.001
    // 0.25-0.50: tick=0.005
    // 0.50-10.00: tick=0.010
    // 10.00-20.00: tick=0.020
    // ... (完整的港交所 Tick Size 表)

    // 午休时段不接受新订单 (12:00-13:00 HKT)
    LunchBreak bool

    // 收市竞价时段 (16:00-16:10) 只接受竞价限价单
    ClosingAuction bool
}

// 美股特殊规则
type USMarketRules struct {
    // 碎股交易: 支持小数股 (如买 0.5 股 AAPL)
    FractionalShares bool

    // 盘前盘后: 仅支持限价单
    ExtendedHoursLimitOnly bool

    // Tick Size: $1 以上 = $0.01, $1 以下 = $0.0001
    TickSize func(price decimal.Decimal) decimal.Decimal

    // Short Sale: 需要 locate 确认
    ShortSaleLocateRequired bool
}
```

### 3.3 订单验证流程

```go
// OrderValidator 订单格式与业务规则校验
type OrderValidator struct {
    symbolService  SymbolService
    calendarService MarketCalendarService
}

func (v *OrderValidator) Validate(ctx context.Context, order *Order) error {
    // 1. 基础字段校验
    if order.Symbol == "" {
        return ErrMissingSymbol
    }
    if order.Quantity <= 0 {
        return ErrInvalidQuantity
    }
    if order.Side != SideBuy && order.Side != SideSell {
        return ErrInvalidSide
    }

    // 2. 标的校验
    symbol, err := v.symbolService.Get(ctx, order.Symbol, order.Market)
    if err != nil {
        return fmt.Errorf("symbol lookup %s: %w", order.Symbol, err)
    }
    if !symbol.Tradeable {
        return ErrSymbolNotTradeable
    }
    if symbol.Halted {
        return ErrSymbolHalted
    }

    // 3. 市场交易时段校验
    session := v.calendarService.CurrentSession(order.Market)
    if session == SessionClosed {
        return ErrMarketClosed
    }
    // 盘前盘后仅允许限价单
    if (session == SessionPre || session == SessionPost) && order.Type != OrderTypeLimit {
        return ErrExtendedHoursLimitOnly
    }

    // 4. 港股特殊校验
    if order.Market == MarketHK {
        // 碎股检查
        lotSize := symbol.LotSize
        if order.Quantity % int64(lotSize) != 0 {
            return fmt.Errorf("%w: must be multiple of %d", ErrInvalidLotSize, lotSize)
        }
        // Tick Size 检查
        if order.Type == OrderTypeLimit {
            if !isValidTickSize(order.Price, order.Market) {
                return ErrInvalidTickSize
            }
        }
        // 午休时段检查
        if session == SessionLunchBreak {
            return ErrLunchBreak
        }
    }

    // 5. 价格合理性检查 (限价单)
    if order.Type == OrderTypeLimit || order.Type == OrderTypeStopLimit {
        if order.Price.LessThanOrEqual(decimal.Zero) {
            return ErrInvalidPrice
        }
        // 价格偏离检查: 限价不能偏离市价超过 ±50%
        if lastPrice, ok := v.getLastPrice(ctx, order.Symbol); ok {
            deviation := order.Price.Sub(lastPrice).Div(lastPrice).Abs()
            if deviation.GreaterThan(decimal.NewFromFloat(0.5)) {
                return ErrPriceDeviation
            }
        }
    }

    // 6. 止损单校验
    if order.Type == OrderTypeStop || order.Type == OrderTypeStopLimit {
        if order.StopPrice.LessThanOrEqual(decimal.Zero) {
            return ErrInvalidStopPrice
        }
        // 买入止损: StopPrice > 市价; 卖出止损: StopPrice < 市价
        if lastPrice, ok := v.getLastPrice(ctx, order.Symbol); ok {
            if order.Side == SideBuy && order.StopPrice.LessThanOrEqual(lastPrice) {
                return ErrStopPriceBelowMarket
            }
            if order.Side == SideSell && order.StopPrice.GreaterThanOrEqual(lastPrice) {
                return ErrStopPriceAboveMarket
            }
        }
    }

    return nil
}
```

---

## 4. 风控引擎 (Risk Engine)

### 4.1 Pre-Trade 风控流水线

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Pre-Trade Risk Pipeline                           │
│                                                                     │
│  Order ──▶ [Account] ──▶ [Symbol] ──▶ [BuyingPower] ──▶ [Position] │
│               │              │              │                │      │
│               │              │              │                │      │
│            ──▶ [OrderRate] ──▶ [PDT] ──▶ [Margin] ──▶ [PostTrade]  │
│                   │            │           │              │         │
│                   │            │           │              │         │
│                   ▼            ▼           ▼              ▼         │
│               APPROVED or REJECTED (with specific reason)          │
│                                                                     │
│  每项检查独立执行，任一失败即终止流水线                                  │
│  全部通过: < 5ms (p99)                                               │
└─────────────────────────────────────────────────────────────────────┘
```

### 4.2 风控检查详情

#### Check 1: 账户状态检查

```go
type AccountCheck struct{}

func (c *AccountCheck) Check(ctx context.Context, order *Order, account *Account) *RiskResult {
    if account.Status != AccountActive {
        return Reject("account not active: %s", account.Status)
    }
    if !account.KYCVerified {
        return Reject("KYC not verified")
    }
    if account.Frozen {
        return Reject("account is frozen")
    }
    // 检查交易权限
    if order.Market == MarketUS && !account.Permissions.USTrading {
        return Reject("US trading not enabled")
    }
    if order.Market == MarketHK && !account.Permissions.HKTrading {
        return Reject("HK trading not enabled")
    }
    // 期权交易需要额外权限
    if order.AssetType == AssetTypeOption && !account.Permissions.OptionsTrading {
        return Reject("options trading not enabled")
    }
    return Approve()
}
```

#### Check 2: 购买力检查

```go
type BuyingPowerCheck struct {
    balanceService  BalanceService
    quoteCache      QuoteCache
    feeCalculator   FeeCalculator
}

func (c *BuyingPowerCheck) Check(ctx context.Context, order *Order, account *Account) *RiskResult {
    if order.Side == SideSell {
        // 卖出: 检查持仓数量
        return c.checkSellQuantity(ctx, order, account)
    }

    // 买入: 计算所需资金
    estimatedCost := c.estimateOrderCost(order)

    // 获取可用余额
    balance, err := c.balanceService.GetAvailable(ctx, account.ID, order.Currency())
    if err != nil {
        return Reject("balance lookup failed: %v", err)
    }

    // 计算已冻结的未成交买单金额
    pendingBuyValue, err := c.balanceService.GetPendingBuyOrders(ctx, account.ID, order.Currency())
    if err != nil {
        return Reject("pending orders lookup failed: %v", err)
    }

    // 可用购买力 = 可用余额 - 已冻结未成交订单
    buyingPower := balance.Sub(pendingBuyValue)

    if account.Type == AccountTypeMargin {
        // 保证金账户: 购买力 = 可用保证金 × 杠杆
        marginAvailable, _ := c.balanceService.GetMarginAvailable(ctx, account.ID)
        buyingPower = marginAvailable
    }

    if estimatedCost.GreaterThan(buyingPower) {
        return Reject("insufficient buying power: need %s, available %s",
            estimatedCost.StringFixed(2), buyingPower.StringFixed(2))
    }

    return Approve()
}

func (c *BuyingPowerCheck) estimateOrderCost(order *Order) decimal.Decimal {
    var price decimal.Decimal
    if order.Type == OrderTypeMarket {
        // 市价单: 使用当前卖一价 + 滑点缓冲 (2%)
        quote, _ := c.quoteCache.Get(order.Symbol)
        price = quote.AskPrice.Mul(decimal.NewFromFloat(1.02))
    } else {
        price = order.Price
    }

    // 订单金额
    orderValue := price.Mul(decimal.NewFromInt(order.Quantity))

    // 加上预估手续费
    fees := c.feeCalculator.Estimate(order)

    return orderValue.Add(fees)
}
```

#### Check 3: 持仓限额检查

```go
type PositionLimitCheck struct {
    positionService PositionService
    config          RiskConfig
}

func (c *PositionLimitCheck) Check(ctx context.Context, order *Order, account *Account) *RiskResult {
    if order.Side == SideSell {
        return Approve() // 卖出不检查持仓限额
    }

    // 当前持仓
    position, _ := c.positionService.Get(ctx, account.ID, order.Symbol, order.Market)
    currentQty := int64(0)
    if position != nil {
        currentQty = position.Quantity
    }

    // 加上未成交买单
    pendingBuyQty, _ := c.positionService.GetPendingBuyQuantity(ctx, account.ID, order.Symbol)
    totalAfterOrder := currentQty + pendingBuyQty + order.Quantity

    // 单标的最大持仓量
    maxPosition := c.config.MaxPositionPerSymbol
    if totalAfterOrder > maxPosition {
        return Reject("position limit exceeded: would hold %d, max %d", totalAfterOrder, maxPosition)
    }

    // 集中度检查: 单标的不超过总资产的 30%
    portfolioValue, _ := c.positionService.GetPortfolioValue(ctx, account.ID)
    if portfolioValue.GreaterThan(decimal.Zero) {
        quote, _ := c.quoteCache.Get(order.Symbol)
        positionValue := quote.LastPrice.Mul(decimal.NewFromInt(totalAfterOrder))
        concentration := positionValue.Div(portfolioValue)
        if concentration.GreaterThan(c.config.MaxConcentration) {
            return Reject("concentration limit: %.1f%% > %.1f%% max",
                concentration.Mul(decimal.NewFromInt(100)).InexactFloat64(),
                c.config.MaxConcentration.Mul(decimal.NewFromInt(100)).InexactFloat64())
        }
    }

    return Approve()
}
```

#### Check 4: PDT 检查 (Pattern Day Trader — 仅美股)

```go
type PDTCheck struct {
    tradeHistory TradeHistoryService
    balanceService BalanceService
}

func (c *PDTCheck) Check(ctx context.Context, order *Order, account *Account) *RiskResult {
    if order.Market != MarketUS {
        return Approve() // 仅适用于美股
    }
    if account.Type != AccountTypeMargin {
        return Approve() // 仅适用于保证金账户
    }

    // 检查账户净值是否 >= $25,000
    equity, _ := c.balanceService.GetAccountEquity(ctx, account.ID)
    if equity.GreaterThanOrEqual(decimal.NewFromInt(25000)) {
        return Approve() // 满足 PDT 豁免条件
    }

    // 统计过去 5 个工作日的日内交易次数
    // 日内交易 = 同一标的当天买入又卖出 (或卖出又买入)
    dayTradeCount, _ := c.tradeHistory.CountDayTrades(ctx, account.ID, 5)

    // 本次交易是否构成新的日内交易
    if c.wouldCreateDayTrade(ctx, order, account.ID) {
        dayTradeCount++
    }

    // PDT 规则: 5 个工作日内不超过 3 次日内交易
    if dayTradeCount >= 3 {
        return Reject("PDT restriction: %d day trades in past 5 business days (max 3 for accounts under $25,000)", dayTradeCount)
    }

    // 警告: 还剩 1 次机会
    if dayTradeCount == 2 {
        return ApproveWithWarning("PDT warning: this would be your 3rd day trade — next one will trigger PDT restriction")
    }

    return Approve()
}
```

#### Check 5: 保证金检查

```go
type MarginCheck struct {
    marginEngine MarginEngine
}

func (c *MarginCheck) Check(ctx context.Context, order *Order, account *Account) *RiskResult {
    if account.Type != AccountTypeMargin {
        return Approve() // 现金账户跳过
    }

    // 计算下单后的保证金要求
    marginReq, err := c.marginEngine.CalculateAfterOrder(ctx, account.ID, order)
    if err != nil {
        return Reject("margin calculation failed: %v", err)
    }

    // Reg T 初始保证金: 50%
    if marginReq.InitialMarginRequired.GreaterThan(marginReq.AvailableMargin) {
        return Reject("insufficient margin: need %s, available %s",
            marginReq.InitialMarginRequired.StringFixed(2),
            marginReq.AvailableMargin.StringFixed(2))
    }

    return Approve()
}
```

### 4.3 Post-Trade 风控

```go
// 成交后风控检查 (异步执行，不阻塞交易)
type PostTradeRiskMonitor struct {
    alertService AlertService
}

func (m *PostTradeRiskMonitor) Monitor(ctx context.Context, execution *Execution) {
    // 1. 大额成交预警
    if execution.NetAmount.GreaterThan(decimal.NewFromInt(100000)) {
        m.alertService.Send(AlertLargeExecution, execution)
    }

    // 2. 频繁交易检测 (Wash Trading 防范)
    if m.isWashTrade(ctx, execution) {
        m.alertService.Send(AlertWashTrade, execution)
    }

    // 3. 维持保证金检查
    marginStatus, _ := m.checkMaintenanceMargin(ctx, execution.AccountID)
    if marginStatus == MarginCallRequired {
        m.alertService.Send(AlertMarginCall, execution)
    }

    // 4. Wash Sale 规则检测 (税务合规)
    if m.isWashSale(ctx, execution) {
        m.alertService.Send(AlertWashSale, execution)
    }
}
```

---

## 5. 智能订单路由 (SOR)

### 5.1 路由决策流程

```
┌────────────────────────────────────────────────────┐
│               Smart Order Router                    │
│                                                    │
│  Order ──▶ [Market Detection] ──▶ [Venue Selection]│
│                                          │         │
│                                          ▼         │
│                                   ┌────────────┐   │
│                                   │ US Market  │   │
│                                   │            │   │
│                                   │ ┌────────┐ │   │
│                                   │ │ NBBO   │ │   │
│                                   │ │ Check  │ │   │
│                                   │ └───┬────┘ │   │
│                                   │     │      │   │
│                                   │     ▼      │   │
│                                   │ Best of:   │   │
│                                   │ • NYSE     │   │
│                                   │ • NASDAQ   │   │
│                                   │ • ARCA     │   │
│                                   │ • BATS     │   │
│                                   │ • IEX      │   │
│                                   └────────────┘   │
│                                                    │
│                                   ┌────────────┐   │
│                                   │ HK Market  │   │
│                                   │            │   │
│                                   │ Route to:  │   │
│                                   │ • HKEX     │   │
│                                   │ (单一交易所)│   │
│                                   └────────────┘   │
└────────────────────────────────────────────────────┘
```

### 5.2 Best Execution 算法

```go
type BestExecutionRouter struct {
    quoteCache    QuoteCache
    venueConfig   map[string]VenueConfig
    costModel     CostModel
}

type RoutingDecision struct {
    Venue         string          // 目标交易所
    Price         decimal.Decimal // 调整后价格 (tick size 对齐)
    Quantity      int64           // 可能拆单
    EstimatedCost decimal.Decimal // 预计总成本 (含手续费)
    Reason        string          // 路由原因 (审计用)
}

func (r *BestExecutionRouter) Route(ctx context.Context, order *Order) (*RoutingDecision, error) {
    if order.Market == MarketHK {
        // 港股: 单一交易所, 直接路由到 HKEX
        return &RoutingDecision{
            Venue:  "HKEX",
            Price:  r.alignTickSize(order.Price, MarketHK),
            Quantity: order.Quantity,
            Reason: "HK market: single venue",
        }, nil
    }

    // 美股: 多交易所最优执行
    venues := []string{"NYSE", "NASDAQ", "ARCA", "BATS", "IEX"}
    var bestDecision *RoutingDecision
    bestScore := decimal.NewFromFloat(-1)

    for _, venue := range venues {
        quote, err := r.quoteCache.GetVenueQuote(order.Symbol, venue)
        if err != nil {
            continue
        }

        // 计算综合评分
        score := r.calculateScore(order, venue, quote)
        if score.GreaterThan(bestScore) {
            bestScore = score
            bestDecision = &RoutingDecision{
                Venue:    venue,
                Price:    r.getExecutionPrice(order, quote),
                Quantity: order.Quantity,
                Reason: fmt.Sprintf("best execution: score=%.4f, price=%s, depth=%d",
                    score.InexactFloat64(), quote.BestPrice.String(), quote.Depth),
            }
        }
    }

    return bestDecision, nil
}

func (r *BestExecutionRouter) calculateScore(order *Order, venue string, quote *VenueQuote) decimal.Decimal {
    // 综合评分 = 价格因子 × 0.5 + 流动性因子 × 0.25 + 成本因子 × 0.15 + 延迟因子 × 0.10
    priceScore := r.priceScore(order, quote)           // 价格优势
    liquidityScore := r.liquidityScore(order, quote)   // 深度/成交量
    costScore := r.costScore(venue, order)              // 交易所费用/返佣
    latencyScore := r.latencyScore(venue)              // 网络延迟

    return priceScore.Mul(decimal.NewFromFloat(0.5)).
        Add(liquidityScore.Mul(decimal.NewFromFloat(0.25))).
        Add(costScore.Mul(decimal.NewFromFloat(0.15))).
        Add(latencyScore.Mul(decimal.NewFromFloat(0.10)))
}
```

---

## 6. FIX 协议引擎

### 6.1 FIX 会话管理

```
┌────────────────────────────────────────────────────────────┐
│                     FIX Engine                              │
│                                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ NYSE Session │  │NASDAQ Session│  │ HKEX Session │     │
│  │ FIX 4.2      │  │ FIX 4.2      │  │ FIX 4.4      │     │
│  │ Port: 9878   │  │ Port: 9879   │  │ Port: 9880   │     │
│  │ SSL/TLS      │  │ SSL/TLS      │  │ SSL/TLS      │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                  │                  │             │
│         ▼                  ▼                  ▼             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Session Manager                         │   │
│  │                                                     │   │
│  │  • 心跳管理 (HeartBeat interval: 30s)               │   │
│  │  • 序列号管理 (持久化到磁盘)                          │   │
│  │  • 自动重连 (exponential backoff)                    │   │
│  │  • 消息日志 (FIX message log, 合规留存)              │   │
│  │  • 消息恢复 (gap-fill on reconnect)                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Message Router                          │   │
│  │                                                     │   │
│  │  Outbound:                                          │   │
│  │  • NewOrderSingle (D)  → 新订单                      │   │
│  │  • OrderCancelRequest (F) → 取消订单                 │   │
│  │  • OrderCancelReplaceRequest (G) → 改单              │   │
│  │                                                     │   │
│  │  Inbound:                                           │   │
│  │  • ExecutionReport (8) → 成交/确认/拒绝回报          │   │
│  │  • OrderCancelReject (9) → 取消被拒                  │   │
│  │  • BusinessMessageReject (j) → 业务错误              │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

### 6.2 FIX 消息处理

```go
// FIX 消息处理核心接口
type FIXEngine interface {
    // 发送新订单 (MsgType=D NewOrderSingle)
    SendNewOrder(ctx context.Context, order *Order) error

    // 发送取消请求 (MsgType=F OrderCancelRequest)
    SendCancelOrder(ctx context.Context, orderID, origClOrdID string) error

    // 发送改单请求 (MsgType=G OrderCancelReplaceRequest)
    SendAmendOrder(ctx context.Context, order *Order, origClOrdID string) error

    // 注册执行报告处理器 (MsgType=8 ExecutionReport)
    OnExecutionReport(handler ExecutionReportHandler)

    // 会话状态
    SessionStatus(venue string) SessionStatus

    // 关闭
    Close() error
}

// ExecutionReport 交易所回报
type ExecutionReport struct {
    OrderID       string
    ClOrdID       string          // 客户订单ID
    ExecID        string          // 执行ID
    ExecType      ExecType        // NEW / PARTIAL_FILL / FILL / CANCELLED / REJECTED
    OrdStatus     OrderStatus
    Symbol        string
    Side          string
    LastQty       int64           // 本次成交数量
    LastPx        decimal.Decimal // 本次成交价格
    CumQty        int64           // 累计成交数量
    AvgPx         decimal.Decimal // 平均成交价格
    LeavesQty     int64           // 剩余未成交数量
    Commission    decimal.Decimal // 佣金
    TransactTime  time.Time       // 交易所成交时间
    Text          string          // 附加信息 (如拒绝原因)
}

// Execution Report 处理流程
func (h *ExecutionHandler) HandleReport(report *ExecutionReport) error {
    // 1. 幂等性检查 (ExecID 去重)
    if h.isDuplicate(report.ExecID) {
        return nil
    }

    // 2. 更新订单状态
    err := h.orderService.UpdateFromExecReport(ctx, report)
    if err != nil {
        return fmt.Errorf("update order from exec report: %w", err)
    }

    // 3. 如果有成交，更新持仓和余额
    if report.ExecType == ExecTypeFill || report.ExecType == ExecTypePartialFill {
        // 原子操作: 更新持仓 + 更新余额 + 记录台账
        err = h.positionService.ProcessExecution(ctx, report)
        if err != nil {
            return fmt.Errorf("process execution: %w", err)
        }
    }

    // 4. 发布事件到 Kafka
    h.eventBus.Publish("order.execution", report)

    // 5. Post-Trade 风控 (异步)
    go h.postTradeMonitor.Monitor(ctx, report)

    return nil
}
```

---

## 7. 持仓与 P&L 引擎

### 7.1 持仓更新逻辑

```go
// PositionEngine 持仓管理引擎
type PositionEngine struct {
    db          *pgx.Pool
    quoteCache  QuoteCache
    ledger      LedgerService
}

// ProcessExecution 处理成交，原子更新持仓+余额+台账
func (e *PositionEngine) ProcessExecution(ctx context.Context, exec *ExecutionReport) error {
    return e.db.BeginTxFunc(ctx, pgx.TxOptions{
        IsoLevel: pgx.Serializable,
    }, func(tx pgx.Tx) error {
        // 1. 获取当前持仓 (SELECT FOR UPDATE)
        pos, err := e.getPositionForUpdate(ctx, tx, exec.AccountID, exec.Symbol, exec.Market)
        if err != nil {
            return fmt.Errorf("get position: %w", err)
        }

        // 2. 计算新持仓
        if exec.Side == SideBuy {
            pos = e.applyBuy(pos, exec)
        } else {
            pos = e.applySell(pos, exec)
        }

        // 3. 更新持仓表 (乐观锁)
        err = e.updatePosition(ctx, tx, pos)
        if err != nil {
            return fmt.Errorf("update position: %w", err)
        }

        // 4. 更新账户余额
        err = e.updateBalance(ctx, tx, exec)
        if err != nil {
            return fmt.Errorf("update balance: %w", err)
        }

        // 5. 写入台账 (append-only)
        err = e.ledger.RecordExecution(ctx, tx, exec)
        if err != nil {
            return fmt.Errorf("record ledger: %w", err)
        }

        return nil
    })
}

// applyBuy 买入: 增加持仓，更新平均成本
func (e *PositionEngine) applyBuy(pos *Position, exec *ExecutionReport) *Position {
    // 新平均成本 = (原持仓数量 × 原成本 + 本次数量 × 本次价格) / 新总数量
    oldValue := pos.AvgCostBasis.Mul(decimal.NewFromInt(pos.Quantity))
    newValue := exec.LastPx.Mul(decimal.NewFromInt(exec.LastQty))
    newQuantity := pos.Quantity + exec.LastQty

    if newQuantity > 0 {
        pos.AvgCostBasis = oldValue.Add(newValue).Div(decimal.NewFromInt(newQuantity))
    }
    pos.Quantity = newQuantity
    pos.UnsettledQty += exec.LastQty
    pos.LastTradeAt = exec.TransactTime
    return pos
}

// applySell 卖出: 减少持仓，计算已实现盈亏 (FIFO)
func (e *PositionEngine) applySell(pos *Position, exec *ExecutionReport) *Position {
    // 已实现盈亏 = (卖出价 - 平均成本) × 卖出数量
    realizedPnL := exec.LastPx.Sub(pos.AvgCostBasis).Mul(decimal.NewFromInt(exec.LastQty))
    pos.RealizedPnL = pos.RealizedPnL.Add(realizedPnL)
    pos.Quantity -= exec.LastQty
    pos.LastTradeAt = exec.TransactTime

    // 清仓时重置成本基础
    if pos.Quantity == 0 {
        pos.AvgCostBasis = decimal.Zero
    }
    return pos
}
```

### 7.2 实时 P&L 计算

```go
// PnLCalculator 实时盈亏计算 (每次行情变动触发)
type PnLCalculator struct {
    quoteCache QuoteCache
}

type PnLSnapshot struct {
    Symbol        string
    Quantity      int64
    AvgCostBasis  decimal.Decimal
    MarketPrice   decimal.Decimal
    MarketValue   decimal.Decimal  // Quantity × MarketPrice
    CostValue     decimal.Decimal  // Quantity × AvgCostBasis
    UnrealizedPnL decimal.Decimal  // MarketValue - CostValue
    UnrealizedPct decimal.Decimal  // UnrealizedPnL / CostValue × 100
    RealizedPnL   decimal.Decimal
    DayPnL        decimal.Decimal  // 今日盈亏 (基于昨收)
}

func (c *PnLCalculator) Calculate(pos *Position) *PnLSnapshot {
    quote, ok := c.quoteCache.Get(pos.Symbol)
    if !ok {
        return nil
    }

    marketValue := quote.LastPrice.Mul(decimal.NewFromInt(pos.Quantity))
    costValue := pos.AvgCostBasis.Mul(decimal.NewFromInt(pos.Quantity))
    unrealizedPnL := marketValue.Sub(costValue)

    unrealizedPct := decimal.Zero
    if costValue.GreaterThan(decimal.Zero) {
        unrealizedPct = unrealizedPnL.Div(costValue).Mul(decimal.NewFromInt(100))
    }

    // 日内盈亏 = (现价 - 昨收) × 持仓量
    dayPnL := quote.LastPrice.Sub(quote.PrevClose).Mul(decimal.NewFromInt(pos.Quantity))

    return &PnLSnapshot{
        Symbol:        pos.Symbol,
        Quantity:      pos.Quantity,
        AvgCostBasis:  pos.AvgCostBasis,
        MarketPrice:   quote.LastPrice,
        MarketValue:   marketValue,
        CostValue:     costValue,
        UnrealizedPnL: unrealizedPnL,
        UnrealizedPct: unrealizedPct,
        RealizedPnL:   pos.RealizedPnL,
        DayPnL:        dayPnL,
    }
}
```

---

## 8. 保证金系统 (Margin Engine)

### 8.1 保证金规则

| 规则 | 美股 (Reg T) | 港股 (SFC) |
|------|-------------|------------|
| 初始保证金 | 50% (买入/卖空) | 按标的分级 (25%-100%) |
| 维持保证金 | 25% (FINRA) | 按标的分级 |
| Margin Call | 净值 < 维持保证金 | 净值 < 维持保证金 |
| 强制平仓线 | 净值 < 维持保证金且未补足 | 净值 < 强平线 |
| 日内交易保证金 | 25% (PDT豁免账户) | N/A |

### 8.2 保证金计算

```go
type MarginEngine struct {
    positionService PositionService
    quoteCache      QuoteCache
    marginRates     MarginRateService
}

type MarginRequirement struct {
    AccountID         int64
    TotalEquity       decimal.Decimal  // 总净值 = 现金 + 持仓市值
    InitialMargin     decimal.Decimal  // 初始保证金要求
    MaintenanceMargin decimal.Decimal  // 维持保证金要求
    AvailableMargin   decimal.Decimal  // 可用保证金
    MarginUsage       decimal.Decimal  // 保证金使用率
    MarginCallAmount  decimal.Decimal  // Margin Call 金额 (0=无)
}

func (e *MarginEngine) Calculate(ctx context.Context, accountID int64) (*MarginRequirement, error) {
    positions, err := e.positionService.ListByAccount(ctx, accountID)
    if err != nil {
        return nil, fmt.Errorf("list positions: %w", err)
    }

    var totalInitial, totalMaintenance decimal.Decimal

    for _, pos := range positions {
        quote, _ := e.quoteCache.Get(pos.Symbol)
        marketValue := quote.LastPrice.Mul(decimal.NewFromInt(abs(pos.Quantity)))

        // 获取该标的的保证金比例
        rate := e.marginRates.Get(pos.Symbol, pos.Market)

        // 初始保证金
        initial := marketValue.Mul(rate.InitialRate)
        totalInitial = totalInitial.Add(initial)

        // 维持保证金
        maintenance := marketValue.Mul(rate.MaintenanceRate)
        totalMaintenance = totalMaintenance.Add(maintenance)
    }

    equity := e.calculateEquity(ctx, accountID, positions)
    available := equity.Sub(totalInitial)
    marginCall := decimal.Zero
    if equity.LessThan(totalMaintenance) {
        marginCall = totalMaintenance.Sub(equity)
    }

    return &MarginRequirement{
        AccountID:         accountID,
        TotalEquity:       equity,
        InitialMargin:     totalInitial,
        MaintenanceMargin: totalMaintenance,
        AvailableMargin:   available,
        MarginUsage:       totalInitial.Div(equity).Mul(decimal.NewFromInt(100)),
        MarginCallAmount:  marginCall,
    }, nil
}
```

### 8.3 Margin Call 流程

```
┌──────────────────────────────────────────────────────────┐
│                  Margin Call Workflow                      │
│                                                          │
│  [定时检查: 每分钟] + [成交后实时检查]                      │
│         │                                                │
│         ▼                                                │
│  净值 < 维持保证金?                                       │
│    │ YES                                                 │
│    ▼                                                     │
│  ┌──────────────┐                                        │
│  │ 发出 Margin  │  通知用户: Push + SMS + Email           │
│  │ Call 通知    │  显示: 需补足金额、截止时间              │
│  └──────┬───────┘                                        │
│         │                                                │
│         ▼                                                │
│  等待用户响应 (T+2 工作日内)                               │
│    │                          │                          │
│    ▼ 补足保证金                ▼ 未补足                   │
│  ┌──────────────┐    ┌──────────────────┐                │
│  │ 解除 Margin  │    │ 强制平仓 (Forced │                │
│  │ Call 状态    │    │ Liquidation)     │                │
│  └──────────────┘    │                  │                │
│                      │ 按以下优先级平仓: │                │
│                      │ 1. 亏损最大的持仓 │                │
│                      │ 2. 波动率最高的   │                │
│                      │ 3. 流动性最好的   │                │
│                      └──────────────────┘                │
└──────────────────────────────────────────────────────────┘
```

---

## 9. 结算系统 (Settlement)

### 9.1 结算流程

```go
// SettlementEngine 结算引擎
type SettlementEngine struct {
    db              *pgx.Pool
    positionService PositionService
    balanceService  BalanceService
}

// ProcessSettlement 每日结算批处理
// 在交易所结算完成后运行 (US: T+1 晚间, HK: T+2 晚间)
func (e *SettlementEngine) ProcessSettlement(ctx context.Context, settlementDate time.Time) error {
    // 1. 查找所有待结算的成交
    executions, err := e.getUnsettledExecutions(ctx, settlementDate)
    if err != nil {
        return fmt.Errorf("get unsettled executions: %w", err)
    }

    for _, exec := range executions {
        err := e.db.BeginTxFunc(ctx, pgx.TxOptions{}, func(tx pgx.Tx) error {
            // 2. 更新成交记录为已结算
            err := e.markSettled(ctx, tx, exec.ExecutionID)
            if err != nil {
                return err
            }

            // 3. 更新持仓的已结算数量
            err = e.positionService.SettleQuantity(ctx, tx, exec)
            if err != nil {
                return err
            }

            // 4. 卖出结算: 将冻结资金转为可用
            if exec.Side == SideSell {
                err = e.balanceService.SettleSellProceeds(ctx, tx, exec)
                if err != nil {
                    return err
                }
            }

            return nil
        })
        if err != nil {
            // 单笔结算失败不影响其他，记录错误继续
            log.Error("settlement failed", zap.String("exec_id", exec.ExecutionID), zap.Error(err))
        }
    }

    // 5. 生成结算报告
    return e.generateSettlementReport(ctx, settlementDate)
}
```

### 9.2 公司行动处理

```go
// CorporateActionProcessor 公司行动处理
type CorporateActionProcessor struct {
    positionService PositionService
    ledger          LedgerService
}

// ProcessDividend 股息分红处理
func (p *CorporateActionProcessor) ProcessDividend(ctx context.Context, action *DividendAction) error {
    // 查找所有持有该标的的账户
    positions, _ := p.positionService.ListBySymbol(ctx, action.Symbol, action.RecordDate)

    for _, pos := range positions {
        // 股息金额 = 每股股息 × 持仓数量
        amount := action.DividendPerShare.Mul(decimal.NewFromInt(pos.Quantity))

        // 扣税 (W-8BEN: 非美国居民 30%, 有税收协定可能降低)
        withholding := amount.Mul(pos.Account.TaxWithholdingRate)
        netAmount := amount.Sub(withholding)

        // 入账
        p.ledger.RecordDividend(ctx, pos.AccountID, action, netAmount, withholding)
    }
    return nil
}

// ProcessStockSplit 拆股处理
func (p *CorporateActionProcessor) ProcessStockSplit(ctx context.Context, action *StockSplitAction) error {
    // 例如: 4:1 拆股, ratio = 4
    positions, _ := p.positionService.ListBySymbol(ctx, action.Symbol, action.RecordDate)

    for _, pos := range positions {
        newQuantity := pos.Quantity * int64(action.Ratio)
        newCostBasis := pos.AvgCostBasis.Div(decimal.NewFromInt(int64(action.Ratio)))

        p.positionService.UpdateForSplit(ctx, pos.AccountID, action.Symbol, newQuantity, newCostBasis)
    }
    return nil
}
```

---

## 10. 手续费计算

### 10.1 费用结构

| 费用项 | 美股 | 港股 | 说明 |
|--------|------|------|------|
| 佣金 | $0 或 $0.005/股 | 0.03% (min HK$3) | 平台收取 |
| SEC Fee | $0.0000278/$ (卖出) | — | 美国证监会费 |
| FINRA TAF | $0.000166/股 (卖出) | — | FINRA 交易活动费 |
| Exchange Fee | ~$0.003/股 | — | 交易所费用 (因venue而异) |
| 印花税 | — | 0.13% (双向) | 香港印花税 |
| 交易征费 | — | 0.0027% | 香港证监会征费 |
| 交易费 | — | 0.00565% | 联交所交易费 |
| 平台使用费 | — | HK$0.50/笔 | 平台费 |

```go
type FeeCalculator struct {
    config FeeConfig
}

type FeeBreakdown struct {
    Commission   decimal.Decimal
    SECFee       decimal.Decimal
    TAF          decimal.Decimal
    ExchangeFee  decimal.Decimal
    StampDuty    decimal.Decimal
    TradingLevy  decimal.Decimal
    TradingFee   decimal.Decimal
    PlatformFee  decimal.Decimal
    TotalFees    decimal.Decimal
}

func (c *FeeCalculator) Calculate(exec *ExecutionReport) *FeeBreakdown {
    fb := &FeeBreakdown{}
    tradeValue := exec.LastPx.Mul(decimal.NewFromInt(exec.LastQty))

    if exec.Market == MarketUS {
        // 佣金 (可配置: 免佣或按股数)
        fb.Commission = c.config.USCommissionPerShare.Mul(decimal.NewFromInt(exec.LastQty))

        if exec.Side == SideSell {
            // SEC Fee: $0.0000278 per dollar of sale
            fb.SECFee = tradeValue.Mul(c.config.SECFeeRate).RoundBank(2)
            // FINRA TAF: $0.000166 per share sold
            fb.TAF = c.config.TAFPerShare.Mul(decimal.NewFromInt(exec.LastQty)).RoundBank(2)
        }

        // Exchange fee
        fb.ExchangeFee = c.config.USExchangeFeePerShare.Mul(decimal.NewFromInt(exec.LastQty))

    } else if exec.Market == MarketHK {
        // 佣金: 0.03% (最低 HK$3)
        commission := tradeValue.Mul(c.config.HKCommissionRate)
        if commission.LessThan(c.config.HKMinCommission) {
            commission = c.config.HKMinCommission
        }
        fb.Commission = commission

        // 印花税: 0.13% (不足 $1 按 $1 计)
        fb.StampDuty = tradeValue.Mul(c.config.StampDutyRate).Ceil()

        // 交易征费: 0.0027%
        fb.TradingLevy = tradeValue.Mul(c.config.TradingLevyRate).RoundBank(2)

        // 交易费: 0.00565%
        fb.TradingFee = tradeValue.Mul(c.config.TradingFeeRate).RoundBank(2)

        // 平台使用费
        fb.PlatformFee = c.config.HKPlatformFee
    }

    fb.TotalFees = fb.Commission.Add(fb.SECFee).Add(fb.TAF).
        Add(fb.ExchangeFee).Add(fb.StampDuty).
        Add(fb.TradingLevy).Add(fb.TradingFee).
        Add(fb.PlatformFee)

    return fb
}
```

---

## 11. 数据库设计

### 11.1 核心表

```sql
-- 订单表 (按月分区)
CREATE TABLE orders (
    id                BIGSERIAL,
    order_id          UUID NOT NULL,
    client_order_id   UUID NOT NULL,
    exchange_order_id TEXT,
    user_id           BIGINT NOT NULL,
    account_id        BIGINT NOT NULL,
    symbol            TEXT NOT NULL,
    market            TEXT NOT NULL,         -- 'US' / 'HK'
    exchange          TEXT,                  -- 'NYSE' / 'NASDAQ' / 'HKEX'
    side              TEXT NOT NULL,         -- 'BUY' / 'SELL'
    order_type        TEXT NOT NULL,         -- 'MARKET' / 'LIMIT' / 'STOP' / ...
    time_in_force     TEXT NOT NULL DEFAULT 'DAY',
    quantity          BIGINT NOT NULL,
    price             NUMERIC(20, 8),       -- 限价单价格
    stop_price        NUMERIC(20, 8),       -- 止损价
    trail_amount      NUMERIC(20, 8),       -- 追踪止损偏移
    status            TEXT NOT NULL,         -- 状态机
    filled_qty        BIGINT NOT NULL DEFAULT 0,
    avg_fill_price    NUMERIC(20, 8),
    remaining_qty     BIGINT NOT NULL,
    commission        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    total_fees        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    source            TEXT NOT NULL,         -- 'IOS' / 'ANDROID' / 'WEB' / 'API'
    ip_address        INET,
    device_id         TEXT,
    risk_result       JSONB,
    reject_reason     TEXT,
    idempotency_key   UUID NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    submitted_at      TIMESTAMPTZ,
    completed_at      TIMESTAMPTZ,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, created_at),
    UNIQUE (order_id, created_at),
    UNIQUE (idempotency_key, created_at)
) PARTITION BY RANGE (created_at);

-- 自动创建分区 (每月)
-- CREATE TABLE orders_2026_03 PARTITION OF orders FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE INDEX idx_orders_user ON orders (user_id, created_at DESC);
CREATE INDEX idx_orders_account ON orders (account_id, status, created_at DESC);
CREATE INDEX idx_orders_symbol ON orders (symbol, market, created_at DESC);
CREATE INDEX idx_orders_status ON orders (status, created_at DESC) WHERE status IN ('OPEN', 'PARTIAL_FILL', 'PENDING', 'CANCEL_SENT');

-- 成交明细表
CREATE TABLE executions (
    id                BIGSERIAL PRIMARY KEY,
    execution_id      UUID UNIQUE NOT NULL,
    order_id          UUID NOT NULL,
    user_id           BIGINT NOT NULL,
    account_id        BIGINT NOT NULL,
    symbol            TEXT NOT NULL,
    market            TEXT NOT NULL,
    side              TEXT NOT NULL,
    quantity          BIGINT NOT NULL,
    price             NUMERIC(20, 8) NOT NULL,
    commission        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    sec_fee           NUMERIC(20, 8) NOT NULL DEFAULT 0,
    taf               NUMERIC(20, 8) NOT NULL DEFAULT 0,
    exchange_fee      NUMERIC(20, 8) NOT NULL DEFAULT 0,
    stamp_duty        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    total_fees        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    net_amount        NUMERIC(20, 8) NOT NULL,
    settlement_date   DATE NOT NULL,
    settled           BOOLEAN NOT NULL DEFAULT FALSE,
    settled_at        TIMESTAMPTZ,
    exchange_exec_id  TEXT,
    venue             TEXT,                  -- 成交交易所
    executed_at       TIMESTAMPTZ NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exec_order ON executions (order_id);
CREATE INDEX idx_exec_account ON executions (account_id, executed_at DESC);
CREATE INDEX idx_exec_settlement ON executions (settlement_date, settled) WHERE settled = FALSE;

-- 持仓表
CREATE TABLE positions (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL,
    account_id      BIGINT NOT NULL,
    symbol          TEXT NOT NULL,
    market          TEXT NOT NULL,
    quantity        BIGINT NOT NULL DEFAULT 0,
    avg_cost_basis  NUMERIC(20, 8) NOT NULL DEFAULT 0,
    realized_pnl    NUMERIC(20, 8) NOT NULL DEFAULT 0,
    settled_qty     BIGINT NOT NULL DEFAULT 0,
    unsettled_qty   BIGINT NOT NULL DEFAULT 0,
    first_trade_at  TIMESTAMPTZ,
    last_trade_at   TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    version         INT NOT NULL DEFAULT 0,  -- 乐观锁
    UNIQUE (account_id, symbol, market)
);

CREATE INDEX idx_positions_user ON positions (user_id);
CREATE INDEX idx_positions_symbol ON positions (symbol, market);

-- 订单事件表 (Event Sourcing, Append-Only)
CREATE TABLE order_events (
    id          BIGSERIAL PRIMARY KEY,
    event_id    UUID UNIQUE NOT NULL,
    order_id    UUID NOT NULL,
    event_type  TEXT NOT NULL,              -- 'CREATED' / 'VALIDATED' / 'RISK_APPROVED' / ...
    event_data  JSONB NOT NULL,
    sequence    INT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_events_order ON order_events (order_id, sequence);

-- 保证金快照表 (定时计算)
CREATE TABLE margin_snapshots (
    id                  BIGSERIAL PRIMARY KEY,
    account_id          BIGINT NOT NULL,
    total_equity        NUMERIC(20, 8) NOT NULL,
    initial_margin      NUMERIC(20, 8) NOT NULL,
    maintenance_margin  NUMERIC(20, 8) NOT NULL,
    available_margin    NUMERIC(20, 8) NOT NULL,
    margin_usage_pct    NUMERIC(10, 4) NOT NULL,
    margin_call_amount  NUMERIC(20, 8) NOT NULL DEFAULT 0,
    calculated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_margin_account ON margin_snapshots (account_id, calculated_at DESC);
```

---

## 12. 服务划分

| 服务 | 语言 | 职责 | 实例数 |
|------|------|------|--------|
| `trading-oms` | Go | 订单管理、状态机、订单校验 | 3+ (水平扩展) |
| `trading-risk` | Go | Pre-trade 风控引擎 | 3+ |
| `trading-router` | Go | 智能订单路由 (SOR) | 2 (主备) |
| `trading-fix` | Go | FIX 协议引擎、交易所连接 | 每交易所 2 (主备) |
| `trading-position` | Go | 持仓管理、P&L 计算 | 3+ |
| `trading-margin` | Go | 保证金计算、Margin Call | 2 |
| `trading-settlement` | Go | 结算处理、对账 | 2 |
| `trading-fee` | Go | 手续费计算 | 2 |

---

## 13. Kafka Topic 设计

```
# 订单事件
trading.order.created           # 新订单创建
trading.order.validated         # 订单校验通过
trading.order.risk-approved     # 风控通过
trading.order.submitted         # 已提交交易所
trading.order.execution-report  # 成交/确认回报
trading.order.cancelled         # 已取消
trading.order.rejected          # 已拒绝

# 持仓事件
trading.position.updated        # 持仓变动
trading.position.pnl-updated    # 盈亏更新

# 保证金事件
trading.margin.call             # Margin Call
trading.margin.liquidation      # 强制平仓

# 结算事件
trading.settlement.completed    # 结算完成
trading.settlement.corporate-action # 公司行动

# 死信队列
trading.dlq                     # 处理失败的消息

Partition 策略: 按 account_id hash, 保证同一账户的事件有序
Retention: 30 天
```

---

## 14. 监控告警

```yaml
# Prometheus 核心指标

# 订单
- trading_orders_total{market, side, type, status}       # 订单总量
- trading_order_latency_seconds{phase, quantile}         # 各阶段延迟
  # phase: validation, risk_check, routing, fix_submit, total
- trading_order_reject_total{reason}                      # 拒单统计
- trading_open_orders_count{market}                       # 当前挂单数

# 成交
- trading_executions_total{market, venue}                 # 成交总量
- trading_execution_value_total{market, currency}         # 成交金额
- trading_fill_rate{market, order_type}                   # 成交率

# FIX
- fix_session_status{venue}                               # 会话状态
- fix_messages_sent_total{venue, msg_type}               # 发送消息量
- fix_messages_received_total{venue, msg_type}           # 接收消息量
- fix_roundtrip_latency_seconds{venue, quantile}         # FIX 往返延迟
- fix_reconnects_total{venue}                             # 重连次数

# 风控
- risk_checks_total{check_name, result}                   # 风控检查总量
- risk_check_latency_seconds{check_name, quantile}       # 风控延迟

# 保证金
- margin_call_accounts_count                              # Margin Call 账户数
- margin_utilization_ratio{quantile}                      # 保证金使用率分布

# 告警规则
alerts:
  - name: FIXSessionDown
    condition: fix_session_status == 0
    severity: critical
    message: "FIX session to {venue} is DOWN"

  - name: HighOrderRejectRate
    condition: rate(trading_order_reject_total[5m]) / rate(trading_orders_total[5m]) > 0.1
    severity: warning
    message: "Order reject rate > 10%"

  - name: RiskEngineLatency
    condition: risk_check_latency_seconds{p99} > 0.01
    severity: warning
    message: "Risk engine p99 latency > 10ms"

  - name: MarginCallAlert
    condition: margin_call_accounts_count > 0
    severity: warning
    message: "{count} accounts in margin call"
```

---

## 15. 部署架构

```
┌─────────────────── Kubernetes Cluster ───────────────────┐
│                                                          │
│  Namespace: trading                                      │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Deployments                                         │ │
│  │                                                     │ │
│  │ trading-oms         (3+ replicas, HPA)              │ │
│  │ trading-risk        (3+ replicas, HPA)              │ │
│  │ trading-router      (2 replicas, anti-affinity)     │ │
│  │ trading-fix-nyse    (2 replicas, active-standby)    │ │
│  │ trading-fix-nasdaq  (2 replicas, active-standby)    │ │
│  │ trading-fix-hkex    (2 replicas, active-standby)    │ │
│  │ trading-position    (3+ replicas, HPA)              │ │
│  │ trading-margin      (2 replicas)                    │ │
│  │ trading-settlement  (2 replicas)                    │ │
│  │ trading-fee         (2 replicas)                    │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ CronJobs                                            │ │
│  │                                                     │ │
│  │ settlement-daily     (每日结算, 交易所确认后)         │ │
│  │ margin-check         (每分钟, 维持保证金检查)        │ │
│  │ eod-reconciliation   (每日, 日终对账)                │ │
│  │ corporate-actions    (每日, 公司行动检查)             │ │
│  │ order-cleanup        (每日, GTC 订单到期清理)        │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                          │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ HPA Rules                                           │ │
│  │                                                     │ │
│  │ trading-oms:    CPU > 50% → scale (max 10)          │ │
│  │ trading-risk:   CPU > 50% → scale (max 10)          │ │
│  │ trading-position: CPU > 60% → scale (max 8)         │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

---

## 16. 与其他系统的交互

```
┌───────────────┐       ┌──────────────────┐       ┌────────────────────┐
│  行情系统      │◀─────│  交易系统         │──────▶│  出入金系统         │
│ Market Data   │       │  Trading Engine   │       │  Fund Transfer     │
│               │       │                  │       │                    │
│ 提供:          │       │ 消费:             │       │ 交互:               │
│ • 实时报价     │       │ • 风控价格校验    │       │ • 购买力查询        │
│ • 买卖盘口     │       │ • P&L 计算       │       │ • 余额冻结/释放     │
│ • 交易状态     │       │ • 保证金计算     │       │ • 结算资金解冻      │
└───────────────┘       └──────────────────┘       └────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
                    ▼                     ▼
           ┌──────────────┐      ┌──────────────┐
           │  账户系统     │      │  通知系统     │
           │  Account     │      │  Notification │
           │              │      │              │
           │ 提供:         │      │ 发送:         │
           │ • 账户状态    │      │ • 成交通知    │
           │ • KYC 级别   │      │ • Margin Call │
           │ • 交易权限    │      │ • 风险告警    │
           └──────────────┘      └──────────────┘
```
