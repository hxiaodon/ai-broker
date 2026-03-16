# 保证金系统（Margin System）深度调研

> 美港股券商交易引擎 -- Margin Calculation, Margin Call & Liquidation
> 最后更新: 2026-03-16

---

## 1. 业务概述

### 1.1 什么是保证金交易

保证金交易（Margin Trading）是指投资者通过向券商借入资金来购买证券的交易方式。投资者只需支付一部分购买价格（保证金），其余部分由券商以贷款形式提供。这放大了投资者的购买力（Buying Power），同时也放大了盈亏。

**核心概念**：
- **融资买入（Buying on Margin）**: 借钱买股票，股票作为抵押品。
- **融券卖出（Short Selling）**: 借股票卖出，等价格下跌后买回还券。
- **杠杆（Leverage）**: 用少量自有资金控制更大价值的资产。
- **保证金（Margin）**: 投资者投入的自有资金，作为券商贷款的抵押。

### 1.2 账户类型对比

| 维度 | 现金账户（Cash Account） | 保证金账户（Margin Account） |
|------|----------------------|--------------------------|
| 借款 | 不允许 | 允许（按规定比例） |
| 购买力 | = 可用现金 | = 可用现金 + 可用保证金 |
| 卖空 | 不允许 | 允许（需 locate） |
| 结算要求 | 必须全额支付 | 可部分自有+部分融资 |
| 风险 | 最多亏损本金 | 可能亏损超过本金 |
| 最低要求 | 无 | 美股 $2,000，港股由券商定 |
| PDT 规则 | 不适用 | 适用（美股，$25K 要求） |
| 适用人群 | 保守投资者 | 有经验的投资者 |

### 1.3 保证金业务核心流程

```
用户申请保证金账户
    │
    ├── 1. KYC 审核 + 风险评估
    │       ├── 投资经验
    │       ├── 风险承受能力
    │       └── 资产状况
    │
    ├── 2. 审批通过，开通保证金账户
    │
    ├── 3. 入金（Deposit）
    │       └── 至少 $2,000 (美股 FINRA 要求)
    │
    ├── 4. 融资买入
    │       ├── 风控检查: 购买力是否足够？
    │       ├── 保证金计算: 需要多少初始保证金？
    │       └── 下单执行
    │
    ├── 5. 盘中监控
    │       ├── 市价变动 → 持仓市值变动
    │       ├── 保证金比例变动
    │       └── 是否触发 Margin Call？
    │
    ├── 6. 日终计算
    │       ├── Reg T 初始保证金检查
    │       ├── FINRA 维持保证金检查
    │       └── 生成 margin_snapshots 记录
    │
    └── 7. Margin Call 处理（如触发）
            ├── 通知用户补足保证金
            ├── 限定补足期限（通常 T+2 到 T+5）
            └── 未补足 → 强制平仓（Liquidation）
```

### 1.4 与其他子域的关系

```
┌──────────────┐                      ┌──────────────────┐
│Position Engine│── 持仓市值变动 ────►│   Margin Engine   │
└──────────────┘                      └────────┬─────────┘
                                               │
                  ┌─────────────────┬──────────┼──────────────────┐
                  │                 │          │                  │
                  ▼                 ▼          ▼                  ▼
          ┌─────────────┐  ┌──────────────┐ ┌──────────────┐ ┌──────────┐
          │ Risk Engine │  │ Order Service│ │Fund Transfer │ │Mobile UI │
          │ (购买力检查) │  │ (下单前检查) │ │(可提余额限制)│ │(保证金展示)│
          └─────────────┘  └──────────────┘ └──────────────┘ └──────────┘
```

---

## 2. 监管与合规要求

### 2.1 美国市场监管体系

美国保证金交易受到三个层面的监管：

#### 2.1.1 Federal Reserve Board - Regulation T

Reg T 是美国保证金交易的基础法规，由美联储制定。

**核心规则**：

| 规则 | 内容 | 细节 |
|------|------|------|
| 初始保证金（Initial Margin） | 买入时客户必须支付至少 50% | 即最大杠杆 2:1 |
| 计算时点 | **日终（End-of-Day）** | 非实时，T+1 日检查 |
| 适用范围 | 大部分权益类证券 | 豁免: 国债、货币市场基金 |
| 补足期限 | 5 个工作日 | 即 T+5 前补足 |
| Free-Riding 禁止 | 现金账户不得使用未结算资金 | 违规冻结 90 天 |

**Reg T 计算示例**：

```
场景: 用户有 $10,000 现金，想买 $20,000 的 AAPL

初始保证金要求 = $20,000 * 50% = $10,000
用户自有资金: $10,000
融资金额: $20,000 - $10,000 = $10,000 (券商提供)
杠杆比例: 2:1

→ 通过 Reg T 检查，允许买入
```

**Reg T 的"日终"特性**：

Reg T 的一个关键特性是它是**日终**（End-of-Day）计算的，而不是实时的。这意味着：
1. 盘中可以临时超过 Reg T 限制（Day Trading Buying Power）。
2. 但到日终收盘时，初始保证金必须满足 50%。
3. 如果日终不满足，将在 T+1 收到 Reg T Margin Call。

#### 2.1.2 FINRA Rule 4210 - 维持保证金

FINRA 4210 是在 Reg T 基础上的补充规则，设定了更严格的**日内**维持要求。

| 规则 | 多头（Long） | 空头（Short） |
|------|------------|-------------|
| 最低维持比例 | 25% | 30% |
| 监控频率 | 实时（盘中） | 实时（盘中） |
| 触发条件 | 账户净值 < 维持保证金要求 | 同左 |
| 补足期限 | 通常 2-5 个工作日 | 同左 |

**实际执行**：大部分券商（包括本系统）设定比 FINRA 最低要求更高的维持保证金比例（通常 30% 多头、40% 空头），以增加安全缓冲。

**FINRA 维持保证金计算示例**：

```
场景: 用户持有 $20,000 AAPL（多头），融资 $10,000

维持保证金要求 = $20,000 * 25% = $5,000
账户净值 = $20,000 - $10,000 = $10,000
→ $10,000 > $5,000, 安全

--- AAPL 跌到 $150 ---

新持仓市值 = 150/200 * $20,000 = $15,000
维持保证金要求 = $15,000 * 25% = $3,750
账户净值 = $15,000 - $10,000 = $5,000
→ $5,000 > $3,750, 仍然安全

--- AAPL 跌到 $130 ---

新持仓市值 = 130/200 * $20,000 = $13,000
维持保证金要求 = $13,000 * 25% = $3,250
账户净值 = $13,000 - $10,000 = $3,000
→ $3,000 < $3,250, 触发 Margin Call!
Margin Call 金额 = $3,250 - $3,000 = $250 (+缓冲)
```

#### 2.1.3 FINRA Rule 4210 - Pattern Day Trader (PDT)

PDT 规则是 FINRA 4210 的一个特殊子条款，针对频繁日内交易的投资者。

| 维度 | 规则 |
|------|------|
| PDT 定义 | 5 个工作日内执行 4 次或以上 Day Trade |
| Day Trade 定义 | 同一证券在同一天买入并卖出（或卖出并买入） |
| 最低权益要求 | $25,000 |
| 违规后果 | 限制账户只能平仓（90 天或直到权益恢复到 $25K） |
| 购买力 | PDT 账户享有 4:1 日内杠杆（非 PDT 为 2:1） |

**PDT 检测逻辑**：

```go
func IsDayTrade(buyExecution, sellExecution *Execution) bool {
    // 同一证券
    if buyExecution.Symbol != sellExecution.Symbol {
        return false
    }
    // 同一个交易日（注意使用交易所时区）
    buyDate := toTradingDate(buyExecution.ExecutedAt, buyExecution.Market)
    sellDate := toTradingDate(sellExecution.ExecutedAt, sellExecution.Market)
    return buyDate.Equal(sellDate)
}

func CountDayTrades(accountID int64, lookbackDays int) int {
    // 查询过去 lookbackDays 个工作日的日内交易次数
    // 注意: "工作日" 使用美股交易日历
    return db.QueryCount(`
        SELECT COUNT(*) FROM day_trade_counts
        WHERE account_id = $1
        AND trade_date >= $2
    `, accountID, businessDaysAgo(lookbackDays))
}
```

**PDT 与保证金的关系**：
- 非 PDT 保证金账户：日内购买力 = 2x 买入力（Reg T 标准）
- PDT 保证金账户（$25K+）：日内购买力 = 4x 买入力
- 超过日内购买力的交易会产生 Day Trading Call

### 2.2 香港市场监管体系

#### 2.2.1 SFC (Securities and Futures Commission) 规则

香港的保证金融资（Margin Financing）受 SFC 监管，但与美国不同，没有联邦级别的统一初始保证金比例。

| 维度 | 美股 (Reg T) | 港股 (SFC) |
|------|-------------|-----------|
| 初始保证金 | 统一 50% | **券商自定**（通常 40-80%） |
| 维持保证金 | FINRA 25% | **券商自定**（通常 30-60%） |
| 可融资证券 | 大部分上市证券 | **SFC 指定的融资证券名单** |
| 集中度限制 | 无联邦规定 | SFC 要求分散化 |
| 审计要求 | SEC/FINRA 审计 | SFC 定期审查 |

#### 2.2.2 SFC Guidelines on Margin Lending

SFC 对券商的保证金贷款有以下关键要求：

1. **保证金融资证券名单**：只有被 SFC 认可的证券才能进行保证金交易。通常是恒生指数成分股或大型蓝筹股。
2. **Hair Cut（折扣率）**：每只证券有不同的 hair cut 比例，表示该证券作为抵押品时的折扣。例如 hair cut 20% 意味着 $100 市值的股票只能算作 $80 的抵押品。
3. **集中度限制**：单一证券不能超过保证金贷款总额的一定比例。
4. **压力测试**：券商必须定期进行保证金贷款的压力测试。

#### 2.2.3 港股保证金比例示例

| 证券类型 | 典型初始保证金 | 典型维持保证金 | Hair Cut |
|---------|-------------|-------------|---------|
| 恒生指数成分股 | 40% | 30% | 20% |
| 国企指数成分股 | 50% | 35% | 30% |
| 大型主板股 | 60% | 40% | 40% |
| 中小型股 | 70-80% | 50-60% | 50-60% |
| GEM 板（创业板） | 不接受融资 | N/A | 100% |
| 新上市股（IPO 首月） | 不接受融资 | N/A | 100% |

### 2.3 合规对系统设计的具体影响

| 合规要求 | 系统设计 | 实现方式 |
|---------|---------|---------|
| Reg T 日终计算 | 日终批处理 Job | 每日 US Market Close 后运行 |
| FINRA 4210 实时监控 | 盘中实时重算 | 行情变动触发 |
| PDT 检测 | 日内交易计数 | day_trade_counts 表 |
| PDT $25K 要求 | 下单前检查权益 | Risk Engine 检查 |
| 港股融资证券名单 | 证券配置表 | margin_rates 表 + 缓存 |
| Hair Cut 差异化 | 按证券配置比例 | margin_rates 表 |
| Margin Call 通知 | 多渠道通知 | Kafka + Push + Email + SMS |
| 强制平仓审计 | 完整审计记录 | 台账 + 事件日志 |
| 保证金利率披露 | 合同 + 账单 | 日终利息计算 |

---

## 3. 市场差异（US vs HK）

### 3.1 保证金规则对比

| 维度 | 美股 | 港股 |
|------|------|------|
| 初始保证金 | 50% (Reg T, 联邦法规) | 40-80% (券商自定, SFC 监管) |
| 维持保证金 | 25% (FINRA 最低) | 30-60% (券商自定) |
| 计算频率 (初始) | 日终 | 日终 |
| 计算频率 (维持) | 实时 | 实时 |
| 最低权益 | $2,000 (标准), $25,000 (PDT) | 由券商定 |
| PDT 规则 | 适用 | 不适用 |
| 可融资证券 | 大部分上市证券 | SFC 指定名单 |
| 杠杆上限 | 2:1 (日终), 4:1 (PDT 日内) | 通常 2:1 - 2.5:1 |
| 结算影响 | T+1 | T+2 |
| 融资利率 | 通常 5-12% 年化 | 通常 5-8% 年化 |
| 币种 | USD | HKD |

### 3.2 Margin Call 流程差异

#### 美股 Margin Call 流程

```
日终计算
    │
    ├── Reg T Call (初始保证金不足)
    │     ├── 触发时机: 日终
    │     ├── 补足期限: T+5 工作日
    │     ├── 限制: 补足前不得新增融资买入
    │     └── 未补足: 强制平仓（只平补足部分）
    │
    ├── Maintenance Call (维持保证金不足)
    │     ├── 触发时机: 实时
    │     ├── 补足期限: 通常 T+2 工作日（券商决定）
    │     ├── 限制: 限制所有新开仓
    │     └── 未补足: 强制平仓至满足维持要求
    │
    └── Day Trading Call (日内购买力超限)
          ├── 触发时机: 日终
          ├── 补足期限: T+5 工作日
          ├── 限制: 降为 2:1 杠杆（从 4:1）
          └── 连续未补足: 限制为只平仓（90 天）
```

#### 港股 Margin Call 流程

```
日终计算 + 盘中监控
    │
    ├── 初始保证金不足
    │     ├── 触发时机: 日终
    │     ├── 补足期限: T+2 至 T+3 工作日（券商决定）
    │     ├── 限制: 不得新增融资买入
    │     └── 未补足: 强制平仓
    │
    └── 维持保证金不足
          ├── 触发时机: 实时
          ├── 补足期限: 通常 T+1 至 T+2
          ├── 限制: 限制所有交易
          └── 未补足: 立即强制平仓
              (港股券商通常比美股更积极平仓)
```

### 3.3 融资利率计算差异

#### 美股融资利率

美股融资利率通常基于 **Fed Funds Rate** 或 **SOFR (Secured Overnight Financing Rate)** 加上券商的 spread：

```
年化利率 = Base Rate (SOFR/Fed Funds) + Spread
日利息 = 融资余额 * 年化利率 / 360 (美国使用 360 天制)
```

利率通常按阶梯计算：

| 融资金额 (USD) | 典型年化利率 |
|---------------|------------|
| < $25,000 | 12.0% |
| $25,000 - $100,000 | 10.5% |
| $100,000 - $500,000 | 9.0% |
| $500,000 - $1,000,000 | 7.5% |
| > $1,000,000 | 6.0% |

#### 港股融资利率

港股融资利率通常基于 **HIBOR (Hong Kong Interbank Offered Rate)** 或券商的 **Prime Rate** 加上 spread：

```
年化利率 = Prime Rate + Spread (或 HIBOR + Spread)
日利息 = 融资余额 * 年化利率 / 365 (香港使用 365 天制)
```

**注意差异**: 美股用 360 天计算日利息，港股用 365 天。系统必须根据市场使用不同的天数基准。

### 3.4 强制平仓差异

| 维度 | 美股 | 港股 |
|------|------|------|
| 平仓权限 | 券商可不经通知直接平仓 | 券商可不经通知直接平仓 |
| 通知要求 | 通常会提前通知（但非必须） | 通常会提前通知 |
| 平仓范围 | 平足以满足维持保证金 | 平足以满足维持保证金 |
| 优先平仓标的 | 亏损最大/保证金贡献最低 | 类似美股 |
| 碎股处理 | 无特殊限制 | 碎股可能在碎股市场平仓 |
| 合规留存 | 平仓记录保留 7 年 | 平仓记录保留 7 年 |

---

## 4. 技术架构

### 4.1 核心数据模型

#### 4.1.1 Margin Requirement（保证金要求）

基于代码库中的 `src/internal/margin/margin.go`：

```go
type Requirement struct {
    AccountID         int64
    TotalEquity       decimal.Decimal // 账户总净值 = 持仓市值 + 现金余额 - 融资余额
    InitialMargin     decimal.Decimal // 初始保证金要求
    MaintenanceMargin decimal.Decimal // 维持保证金要求
    AvailableMargin   decimal.Decimal // 可用保证金 = TotalEquity - InitialMargin
    MarginUsagePct    decimal.Decimal // 保证金使用率 = InitialMargin / TotalEquity * 100
    MarginCallAmount  decimal.Decimal // Margin Call 金额 (0 = 无 Margin Call)
}
```

#### 4.1.2 Margin Rate（保证金比例）

```go
type Rate struct {
    Symbol          string
    Market          string
    InitialRate     decimal.Decimal // 初始保证金比例 (e.g., 0.50 = 50%)
    MaintenanceRate decimal.Decimal // 维持保证金比例 (e.g., 0.25 = 25%)
}
```

**设计要点**：
- 每只证券有独立的保证金比例。
- 美股默认 Initial = 50%, Maintenance = 25%。
- 港股由 `margin_rates` 配置表决定，不同证券差异较大。
- 高波动或低流动性证券可以设置更高的保证金要求。

#### 4.1.3 Margin Call Status（状态机）

```go
type CallStatus int

const (
    CallStatusNone        CallStatus = 0 // 正常，无 Margin Call
    CallStatusWarning     CallStatus = 1 // 接近触发线（净值 < 维持保证金 * 1.1）
    CallStatusTriggered   CallStatus = 2 // 已触发，等待补足
    CallStatusLiquidation CallStatus = 3 // 未补足，需要强制平仓
)
```

状态转换图：

```
    ┌──────────┐
    │   NONE   │ ◄─── 补足保证金 / 市价回升
    └────┬─────┘
         │ 净值接近维持保证金线
         ▼
    ┌──────────┐
    │ WARNING  │ ◄─── 市价小幅回升
    └────┬─────┘
         │ 净值 < 维持保证金
         ▼
    ┌──────────┐
    │TRIGGERED │ ◄─── 部分补足（但未完全满足）
    └────┬─────┘
         │ 补足期限到期且未补足
         ▼
    ┌───────────────┐
    │ LIQUIDATION   │ ──── 强制平仓直到满足维持要求
    └───────────────┘
         │ 平仓完成
         ▼
    ┌──────────┐
    │   NONE   │
    └──────────┘
```

### 4.2 核心计算公式

#### 4.2.1 账户净值（Total Equity）

```
账户净值 = 持仓市值 + 现金余额
         = SUM(position_quantity * market_price) + cash_balance
```

对于融资账户，也可以表达为：
```
账户净值 = 持仓市值 - 融资余额
         = SUM(position_quantity * market_price) - margin_loan_balance
```

两种表达等价，因为：`cash_balance = (用户入金 - 融资余额)` 在某些模型下。

**我们的系统使用第一种定义**：`TotalEquity = TotalMarketValue + CashBalance`，其中 CashBalance 可能为负（表示融资负债）。

#### 4.2.2 初始保证金要求（Initial Margin）

```
初始保证金要求 = SUM(abs(position_quantity) * market_price * initial_rate)
```

对于每个持仓：
```
position_initial_margin = abs(quantity) * market_price * initial_rate(symbol, market)
```

其中 `initial_rate` 由 `margin_rates` 表决定：
- 美股默认: 0.50 (50%)
- 港股: 按证券配置 (0.40 - 0.80)

Go 实现：

```go
func (e *engine) calculateInitialMargin(positions []*position.Position, quotes map[string]decimal.Decimal) decimal.Decimal {
    total := decimal.Zero
    for _, pos := range positions {
        if pos.Quantity == 0 {
            continue
        }
        key := pos.Symbol + ":" + pos.Market
        price, ok := quotes[key]
        if !ok {
            continue // 无行情时使用最后已知价格
        }
        rate := e.rateService.Get(pos.Symbol, pos.Market)
        absQty := decimal.NewFromInt(abs(pos.Quantity))
        posMargin := absQty.Mul(price).Mul(rate.InitialRate)
        total = total.Add(posMargin)
    }
    return total
}
```

#### 4.2.3 维持保证金要求（Maintenance Margin）

```
维持保证金要求 = SUM(abs(position_quantity) * market_price * maintenance_rate)
```

多头和空头的维持比例不同：
```
维持保证金(多头) = quantity * market_price * 0.25  (FINRA 最低)
维持保证金(空头) = abs(quantity) * market_price * 0.30  (FINRA 最低)
```

#### 4.2.4 保证金使用率（Margin Usage Percentage）

```
保证金使用率 = 初始保证金要求 / 账户净值 * 100
```

| 使用率 | 状态 | 含义 |
|--------|------|------|
| 0-60% | 健康 | 有充足缓冲 |
| 60-80% | 注意 | 接近警戒线 |
| 80-90% | 警告 | 接近 Margin Call |
| > 100% | 危险 | 初始保证金不足，不得新增仓位 |

#### 4.2.5 Margin Call 触发条件

```
Margin Call 触发条件: 账户净值 < 维持保证金要求
Margin Call 金额 = 维持保证金要求 - 账户净值 + 安全缓冲
```

安全缓冲（Buffer）通常为维持保证金要求的 5-10%，防止补足后市价微跌再次触发。

```go
func (e *engine) CheckMarginCall(ctx context.Context, accountID int64) (CallStatus, decimal.Decimal, error) {
    req, err := e.Calculate(ctx, accountID)
    if err != nil {
        return CallStatusNone, decimal.Zero, fmt.Errorf("calculate margin for account %d: %w", accountID, err)
    }

    // 触发条件: 净值 < 维持保证金
    if req.TotalEquity.LessThan(req.MaintenanceMargin) {
        callAmount := req.MaintenanceMargin.Sub(req.TotalEquity)
        buffer := req.MaintenanceMargin.Mul(decimal.NewFromFloat(0.05)) // 5% 缓冲
        callAmount = callAmount.Add(buffer)
        return CallStatusTriggered, callAmount, nil
    }

    // 预警条件: 净值 < 维持保证金 * 1.1
    warningThreshold := req.MaintenanceMargin.Mul(decimal.NewFromFloat(1.1))
    if req.TotalEquity.LessThan(warningThreshold) {
        warningAmount := warningThreshold.Sub(req.TotalEquity)
        return CallStatusWarning, warningAmount, nil
    }

    return CallStatusNone, decimal.Zero, nil
}
```

#### 4.2.6 购买力（Buying Power）

```
# 现金账户
购买力 = 可用现金 + 未结算卖出收入 - 未成交买单冻结金额

# 保证金账户（非 PDT）
购买力 = 可用保证金 / 初始保证金比例
       = (账户净值 - 初始保证金要求) / 0.50  (美股)
       = 可用保证金 * 2

# PDT 保证金账户（日内）
日内购买力 = 可用保证金 / 0.25
          = 可用保证金 * 4
```

#### 4.2.7 下单后保证金影响预估

```
新初始保证金要求 = 当前初始保证金 + 新订单市值 * initial_rate(symbol, market)
新可用保证金 = 账户净值 - 新初始保证金要求
```

```go
func (e *engine) CalculateAfterOrder(ctx context.Context, accountID int64, orderValue decimal.Decimal, market string) (*Requirement, error) {
    current, err := e.Calculate(ctx, accountID)
    if err != nil {
        return nil, err
    }

    // 使用该市场的默认初始保证金比例（实际应按具体证券查询）
    var rate decimal.Decimal
    switch market {
    case "US":
        rate = decimal.NewFromFloat(0.50)
    case "HK":
        rate = decimal.NewFromFloat(0.50) // 使用具体证券的比例
    }

    additionalMargin := orderValue.Mul(rate)
    newInitial := current.InitialMargin.Add(additionalMargin)
    newAvailable := current.TotalEquity.Sub(newInitial)

    return &Requirement{
        AccountID:         accountID,
        TotalEquity:       current.TotalEquity,
        InitialMargin:     newInitial,
        MaintenanceMargin: current.MaintenanceMargin, // 维持保证金在成交后才更新
        AvailableMargin:   newAvailable,
        MarginUsagePct:    newInitial.Div(current.TotalEquity).Mul(decimal.NewFromInt(100)),
        MarginCallAmount:  decimal.Zero,
    }, nil
}
```

#### 4.2.8 融资利率计算

```
# 美股 (360 天制)
日利息 = 融资余额 * 年化利率 / 360

# 港股 (365 天制)
日利息 = 融资余额 * 年化利率 / 365

# 月利息 = SUM(每日利息) (从上月结息日到本月结息日)
```

```go
func CalculateDailyInterest(loanBalance, annualRate decimal.Decimal, market string) decimal.Decimal {
    var daysInYear decimal.Decimal
    switch market {
    case "US":
        daysInYear = decimal.NewFromInt(360) // 美国惯例
    case "HK":
        daysInYear = decimal.NewFromInt(365) // 香港惯例
    default:
        daysInYear = decimal.NewFromInt(365)
    }

    return loanBalance.Mul(annualRate).Div(daysInYear)
}
```

### 4.3 日终批处理（End-of-Day Batch）

#### 4.3.1 批处理流程

```
US Market Close (16:00 ET)
    │
    ├── 1. 获取所有保证金账户列表
    │
    ├── 2. 获取所有持仓的收盘价
    │
    ├── 3. 对每个账户:
    │       │
    │       ├── 3a. 计算 Reg T 初始保证金
    │       │       initial_margin = SUM(position * close_price * initial_rate)
    │       │
    │       ├── 3b. 计算 FINRA 维持保证金
    │       │       maintenance = SUM(position * close_price * maintenance_rate)
    │       │
    │       ├── 3c. 计算账户净值
    │       │       equity = SUM(position * close_price) + cash
    │       │
    │       ├── 3d. 判断是否触发 Margin Call
    │       │       if equity < maintenance → Maintenance Call
    │       │       if equity < initial_margin → Reg T Call (首次)
    │       │
    │       ├── 3e. 计算融资利息
    │       │       interest = loan_balance * rate / 360 (or 365)
    │       │
    │       ├── 3f. 检查 PDT 状态
    │       │       day_trades_5d = count_day_trades(account, 5)
    │       │       if day_trades_5d >= 4 && equity < 25000 → PDT violation
    │       │
    │       └── 3g. 保存 margin_snapshot
    │
    ├── 4. 发布 Margin Call 通知 (Kafka)
    │
    └── 5. 生成日终报告
```

#### 4.3.2 批处理实现

```go
func (e *engine) RunEndOfDayBatch(ctx context.Context, market string) error {
    logger := zap.L().With(zap.String("market", market))
    logger.Info("starting end-of-day margin batch")

    // 1. 获取所有保证金账户
    accounts, err := e.accountService.ListMarginAccounts(ctx, market)
    if err != nil {
        return fmt.Errorf("list margin accounts: %w", err)
    }

    // 2. 获取收盘价
    closePrices, err := e.marketData.GetClosingPrices(ctx, market)
    if err != nil {
        return fmt.Errorf("get closing prices: %w", err)
    }

    // 3. 逐账户处理（可并行）
    var wg sync.WaitGroup
    errCh := make(chan error, len(accounts))
    sem := make(chan struct{}, 32) // 并发限制

    for _, acc := range accounts {
        wg.Add(1)
        go func(account Account) {
            defer wg.Done()
            sem <- struct{}{} // acquire
            defer func() { <-sem }() // release

            if err := e.processAccountEOD(ctx, account, closePrices); err != nil {
                errCh <- fmt.Errorf("account %d: %w", account.ID, err)
            }
        }(acc)
    }

    wg.Wait()
    close(errCh)

    // 收集错误
    var errs []error
    for err := range errCh {
        errs = append(errs, err)
    }
    if len(errs) > 0 {
        logger.Error("EOD batch completed with errors",
            zap.Int("total", len(accounts)),
            zap.Int("errors", len(errs)))
        return fmt.Errorf("%d accounts failed: %v", len(errs), errs[0])
    }

    logger.Info("EOD batch completed successfully",
        zap.Int("accounts_processed", len(accounts)))
    return nil
}
```

### 4.4 盘中实时监控

#### 4.4.1 触发机制

盘中保证金监控通过 Market Data 行情变动触发：

```
Market Data Price Tick
    │
    ├── 1. 收到行情: {symbol: "AAPL", price: "145.00"}
    │
    ├── 2. 查询持有 AAPL 的所有保证金账户
    │       (从 Redis Set: margin_accounts:AAPL:US)
    │
    ├── 3. 对每个受影响的账户:
    │       │
    │       ├── 读取缓存: margin:{account_id}
    │       │     包含: total_equity, initial_margin, maintenance_margin
    │       │
    │       ├── 增量更新:
    │       │     delta_equity = (new_price - old_price) * position_quantity
    │       │     new_equity = old_equity + delta_equity
    │       │     new_maintenance = 重算（如果价格变化大于阈值）
    │       │
    │       └── 检查是否触发 Margin Call
    │             if new_equity < maintenance → 触发
    │
    └── 4. 如果状态变化，发布 Kafka 事件
```

#### 4.4.2 增量计算优化

为了满足 P&L 更新 < 1ms p99 的目标，盘中监控使用**增量计算**而非全量重算：

```go
// 增量更新保证金状态（性能关键路径）
func (e *engine) UpdateOnPriceChange(accountID int64, symbol, market string, oldPrice, newPrice decimal.Decimal) {
    // 1. 从 Redis 读取当前保证金状态
    state := e.redis.HGetAll(fmt.Sprintf("margin:%d", accountID))

    // 2. 获取该证券的持仓数量
    qty := e.redis.HGet(fmt.Sprintf("position:%d:%s:%s", accountID, symbol, market), "quantity")

    // 3. 增量计算
    priceDelta := newPrice.Sub(oldPrice)
    equityDelta := priceDelta.Mul(decimal.NewFromInt(qty))

    newEquity := state.TotalEquity.Add(equityDelta)

    // 4. 维持保证金也需要更新（因为市值变了）
    rate := e.rateService.Get(symbol, market)
    marginDelta := priceDelta.Mul(decimal.NewFromInt(abs(qty))).Mul(rate.MaintenanceRate)
    newMaintenance := state.MaintenanceMargin.Add(marginDelta)

    // 5. 检查是否触发 Margin Call
    if newEquity.LessThan(newMaintenance) {
        e.triggerMarginCall(accountID, newEquity, newMaintenance)
    }

    // 6. 更新 Redis
    e.redis.HMSet(fmt.Sprintf("margin:%d", accountID), map[string]string{
        "total_equity":       newEquity.String(),
        "maintenance_margin": newMaintenance.String(),
    })
}
```

#### 4.4.3 全量重算触发条件

增量计算的精度会随时间累积误差。以下情况触发全量重算：

| 条件 | 触发 |
|------|------|
| 新成交发生 | 立即全量重算 |
| 入金/出金 | 立即全量重算 |
| 累积增量超过 100 次 | 全量重算重置计数器 |
| 企业行动 | 立即全量重算 |
| 定时（每 5 分钟） | 全量重算 + 对账 |

### 4.5 margin_snapshots 表设计

```sql
CREATE TABLE margin_snapshots (
    id                  BIGSERIAL PRIMARY KEY,
    account_id          BIGINT NOT NULL,
    total_equity        NUMERIC(20, 8) NOT NULL,
    initial_margin      NUMERIC(20, 8) NOT NULL,
    maintenance_margin  NUMERIC(20, 8) NOT NULL,
    available_margin    NUMERIC(20, 8) NOT NULL,
    margin_usage_pct    NUMERIC(10, 4) NOT NULL,
    margin_call_amount  NUMERIC(20, 8) NOT NULL DEFAULT 0,
    margin_call_status  TEXT NOT NULL DEFAULT 'NONE', -- NONE/WARNING/TRIGGERED/LIQUIDATION
    loan_balance        NUMERIC(20, 8) NOT NULL DEFAULT 0,
    daily_interest      NUMERIC(20, 8) NOT NULL DEFAULT 0,
    calculated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_margin_account ON margin_snapshots (account_id, calculated_at DESC);
CREATE INDEX idx_margin_call ON margin_snapshots (margin_call_status)
    WHERE margin_call_status != 'NONE';
```

**设计要点**：
- 每日至少生成一条快照（日终批处理）。
- Margin Call 期间可能产生额外快照（状态变更时）。
- 保留历史快照用于合规审计和争议处理。
- `loan_balance` 记录当日融资余额，`daily_interest` 记录当日利息。

### 4.6 强制平仓算法

#### 4.6.1 平仓优先级

当 Margin Call 未在规定时间内补足，系统需要自动强制平仓。平仓的目标是：
1. **最小化对用户的影响**：平仓最少的持仓来满足保证金要求。
2. **优先平保证金贡献最低的持仓**：释放更多保证金空间。
3. **考虑流动性**：优先平高流动性股票，确保能成交。

```go
type LiquidationCandidate struct {
    Symbol              string
    Market              string
    Quantity            int64
    MarketValue         decimal.Decimal
    MarginContribution  decimal.Decimal // 该持仓释放的保证金
    Liquidity           int             // 流动性评分 (1-10)
    UnrealizedPnL       decimal.Decimal // 亏损越大越优先平仓
}

func (e *engine) SelectLiquidationTargets(
    accountID int64,
    callAmount decimal.Decimal,
    positions []*LiquidationCandidate,
) []*LiquidationOrder {

    // 1. 按优先级排序
    sort.Slice(positions, func(i, j int) bool {
        // 优先平: 流动性高 + 保证金贡献低 + 亏损大
        scoreI := calcLiquidationScore(positions[i])
        scoreJ := calcLiquidationScore(positions[j])
        return scoreI > scoreJ
    })

    // 2. 逐个选择，直到释放足够保证金
    var targets []*LiquidationOrder
    remaining := callAmount

    for _, pos := range positions {
        if remaining.LessThanOrEqual(decimal.Zero) {
            break
        }

        // 计算需要平多少
        sharesNeeded := remaining.Div(pos.MarginContribution.Div(
            decimal.NewFromInt(abs(pos.Quantity))))
        sharesToSell := min(sharesNeeded.IntPart()+1, abs(pos.Quantity))

        targets = append(targets, &LiquidationOrder{
            Symbol:   pos.Symbol,
            Market:   pos.Market,
            Quantity: sharesToSell,
            Side:     determineSide(pos.Quantity), // 多头卖出，空头买入
            Reason:   "MARGIN_CALL_LIQUIDATION",
        })

        marginReleased := decimal.NewFromInt(sharesToSell).Mul(
            pos.MarginContribution.Div(decimal.NewFromInt(abs(pos.Quantity))))
        remaining = remaining.Sub(marginReleased)
    }

    return targets
}
```

#### 4.6.2 平仓评分函数

```go
func calcLiquidationScore(pos *LiquidationCandidate) decimal.Decimal {
    // 权重配置
    liquidityWeight := decimal.NewFromFloat(0.30)
    marginWeight := decimal.NewFromFloat(0.40)
    pnlWeight := decimal.NewFromFloat(0.30)

    // 流动性分 (流动性越高分越高，越优先平)
    liquidityScore := decimal.NewFromInt(int64(pos.Liquidity)).Div(decimal.NewFromInt(10))

    // 保证金效率分 (保证金贡献越高分越高，释放更多保证金)
    marginScore := pos.MarginContribution.Div(pos.MarketValue)

    // 盈亏分 (亏损越大分越高，先止损)
    pnlScore := decimal.Zero
    if pos.UnrealizedPnL.IsNegative() {
        pnlScore = pos.UnrealizedPnL.Abs().Div(pos.MarketValue)
    }

    return liquidityScore.Mul(liquidityWeight).
        Add(marginScore.Mul(marginWeight)).
        Add(pnlScore.Mul(pnlWeight))
}
```

#### 4.6.3 平仓执行

```
选定平仓目标
    │
    ├── 1. 生成平仓订单
    │       ├── order_type: MARKET（确保成交）
    │       ├── source: "SYSTEM_LIQUIDATION"
    │       ├── 关联 Margin Call ID
    │       └── 审计记录: 平仓原因、账户状态快照
    │
    ├── 2. 提交到 OMS
    │       ├── 跳过购买力检查（强平不需要）
    │       ├── 跳过 PDT 检查（强平豁免）
    │       └── 保留其他风控检查（价格合理性等）
    │
    ├── 3. 监控成交
    │       ├── 成交后重算保证金
    │       └── 如果仍不足，继续选择下一个目标
    │
    └── 4. 通知用户
            ├── Push Notification
            ├── Email
            ├── SMS（如果配置）
            └── 站内信
```

### 4.7 Margin Call 通知流程

```
Margin Call 触发
    │
    ├── 1. 更新 margin_snapshots 状态
    │       margin_call_status = 'TRIGGERED'
    │       margin_call_amount = calculated_amount
    │
    ├── 2. 发布 Kafka 事件: margin.call.triggered
    │       {
    │         "account_id": 12345,
    │         "call_amount": "3250.00",
    │         "deadline": "2026-03-18T16:00:00Z",
    │         "current_equity": "3000.00",
    │         "maintenance_req": "3250.00"
    │       }
    │
    ├── 3. 通知服务消费事件:
    │       ├── Push Notification (即时)
    │       │     "Your account requires additional margin of $3,250.00
    │       │      by March 18, 2026. Please deposit funds or close positions."
    │       │
    │       ├── Email (即时)
    │       │     详细 Margin Call 通知，包含持仓明细和补足说明
    │       │
    │       ├── SMS (如配置)
    │       │     "Margin Call: $3,250.00 required by 03/18. Login to deposit."
    │       │
    │       └── 站内信 (即时)
    │
    ├── 4. 定时检查 (每小时)
    │       ├── 如果已补足 → 解除 Margin Call
    │       ├── 如果市价回升 → 重算，可能自动解除
    │       └── 如果到期未补足 → 转入 LIQUIDATION 状态
    │
    └── 5. Deadline 到达
            ├── 检查是否已补足
            ├── 未补足 → 执行强制平仓
            └── 记录完整审计日志
```

---

## 5. 性能要求与设计决策

### 5.1 性能目标

| 指标 | 目标值 | 场景 |
|------|--------|------|
| 保证金全量计算 | < 5ms p99 | 单账户 |
| 保证金增量更新 | < 1ms p99 | 行情触发 |
| 购买力检查 | < 3ms p99 | 下单前 |
| 日终批处理 | < 60s | 全部保证金账户 |
| 强制平仓决策 | < 10ms | 选择平仓目标 |
| Margin Call 通知延迟 | < 5s | 从触发到推送 |

### 5.2 关键设计决策

#### 决策 1: 日终批处理 vs 纯实时

**选择: 日终批处理 + 盘中增量监控**

理由：
1. Reg T 本身就是日终规则，不需要实时计算。
2. 维持保证金需要实时监控，但可以用增量计算满足性能要求。
3. 日终批处理确保每日至少有一个精确的 snapshot，用于合规审计。
4. 纯实时方案在市场剧烈波动时容易产生大量 Margin Call 又立即解除的"闪烁"问题。

#### 决策 2: Redis 缓存保证金状态

**选择: Redis 存储实时保证金状态，PostgreSQL 存储快照**

```
Redis (实时):
    margin:{account_id}
        total_equity       -> "50000.00"
        initial_margin     -> "17500.00"
        maintenance_margin -> "8750.00"
        available_margin   -> "32500.00"
        margin_usage_pct   -> "35.00"
        call_status        -> "NONE"
        last_full_calc     -> "1710600000000"  // 上次全量计算时间

PostgreSQL (快照):
    margin_snapshots (每日 + 状态变更时写入)
```

理由：
1. 盘中行情变动频繁，如果每次都写 PostgreSQL，IO 成为瓶颈。
2. Redis 的 HMSET/HMGET 延迟 < 0.5ms，满足 < 1ms 的目标。
3. PostgreSQL 快照用于审计，不需要实时。
4. Redis 是缓存，即使丢失也可以从 PostgreSQL + 当前行情重建。

#### 决策 3: 增量计算精度控制

**选择: 增量 + 定期全量校准**

理由：
1. 增量计算可能由于浮点累积误差偏离真实值。
2. 使用 `shopspring/decimal` 可以消除浮点误差，但行情价格本身可能有微小延迟。
3. 每 5 分钟执行一次全量校准，最大容忍 5 分钟的精度偏差。
4. 在 Margin Call 边界附近（margin_usage_pct > 80%），缩短到每 30 秒校准一次。

#### 决策 4: 保证金比例配置

**选择: 数据库配置 + 内存缓存**

```go
type RateService struct {
    cache    sync.Map                   // symbol:market -> *Rate
    defaults map[string]*Rate           // market -> default Rate
    db       *sqlx.DB
}

func (s *RateService) Get(symbol, market string) *Rate {
    key := symbol + ":" + market
    if rate, ok := s.cache.Load(key); ok {
        return rate.(*Rate)
    }
    // 返回该市场的默认比例
    return s.defaults[market]
}
```

配置表：

```sql
CREATE TABLE margin_rates (
    id               BIGSERIAL PRIMARY KEY,
    symbol           TEXT NOT NULL,
    market           TEXT NOT NULL,
    initial_rate     NUMERIC(10, 4) NOT NULL, -- 初始保证金比例
    maintenance_rate NUMERIC(10, 4) NOT NULL, -- 维持保证金比例
    eligible         BOOLEAN NOT NULL DEFAULT TRUE, -- 是否可融资
    effective_from   DATE NOT NULL,
    effective_to     DATE,
    updated_by       TEXT NOT NULL,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (symbol, market, effective_from)
);

-- 默认比例
INSERT INTO margin_rates (symbol, market, initial_rate, maintenance_rate, eligible, effective_from, updated_by) VALUES
    ('*', 'US', 0.50, 0.25, TRUE, '2026-01-01', 'SYSTEM'),
    ('*', 'HK', 0.50, 0.35, TRUE, '2026-01-01', 'SYSTEM');

-- 特定证券比例 (港股示例)
INSERT INTO margin_rates (symbol, market, initial_rate, maintenance_rate, eligible, effective_from, updated_by) VALUES
    ('0700.HK', 'HK', 0.40, 0.30, TRUE, '2026-01-01', 'RISK_ADMIN'),
    ('9988.HK', 'HK', 0.45, 0.30, TRUE, '2026-01-01', 'RISK_ADMIN'),
    ('1299.HK', 'HK', 0.40, 0.30, TRUE, '2026-01-01', 'RISK_ADMIN');
```

#### 决策 5: 强平不走完整风控流程

**选择: 强制平仓订单跳过部分风控检查**

理由：
1. 强平的目的是降低风险，如果被购买力检查拦截就自相矛盾了。
2. 跳过: 购买力检查、PDT 检查、频率限制。
3. 保留: 价格合理性检查、市场状态检查、证券停牌检查。
4. 强平订单标记 `source: "SYSTEM_LIQUIDATION"`，在审计日志中明确标识。

### 5.3 容量规划

| 维度 | 估算 | 备注 |
|------|------|------|
| 保证金账户数 | ~30K | 总用户的 30% |
| 日终批处理 | 30K 账户 * ~5ms/账户 ≈ 150s | 32 并发 → ~5s |
| 盘中监控 | ~150K 持仓（30K * 5） | Redis 增量更新 |
| margin_snapshots 写入 | ~30K/day | 日终 + 状态变更 |
| Margin Call 事件 | ~100/day (估计) | 正常市场条件 |
| 强制平仓 | ~10/day (估计) | 正常市场条件 |
| 极端行情（Black Swan） | Margin Call 可能达 ~5000 | 需要支撑 |

---

## 6. 接口设计（gRPC / REST / Kafka Events）

### 6.1 gRPC 接口

基于代码库中的 `docs/specs/api/grpc/trading.proto`：

#### 6.1.1 MarginService

```proto
service MarginService {
  // 获取账户保证金要求
  rpc GetMarginRequirement(GetMarginRequest) returns (MarginRequirement);

  // 检查购买力（下单前调用）
  rpc CheckBuyingPower(CheckBuyingPowerRequest) returns (CheckBuyingPowerResponse);
}
```

#### 6.1.2 GetMarginRequirement 详细说明

请求：
```proto
message GetMarginRequest {
  int64 account_id = 1;  // 必填
}
```

响应：
```proto
message MarginRequirement {
  int64  account_id = 1;
  string total_equity = 2;          // 账户净值
  string initial_margin = 3;        // 初始保证金要求
  string maintenance_margin = 4;    // 维持保证金要求
  string available_margin = 5;      // 可用保证金
  string margin_usage_pct = 6;      // 使用率 (%)
  string margin_call_amount = 7;    // Margin Call 金额 (0 = 无)
}
```

实现要求：
1. 优先从 Redis 读取缓存的保证金状态。
2. 缓存 miss 时全量计算（需要读取所有持仓 + 行情）。
3. 所有金额使用 string 类型传输（Protobuf 不支持 decimal）。
4. 如果账户不是保证金账户，返回简化结果（equity + buying power，无 margin 字段）。

#### 6.1.3 CheckBuyingPower 详细说明

请求：
```proto
message CheckBuyingPowerRequest {
  int64     account_id = 1;   // 必填
  string    symbol = 2;       // 必填
  Market    market = 3;       // 必填
  OrderSide side = 4;         // 必填
  int64     quantity = 5;     // 必填
  string    price = 6;        // 必填 (预估价格)
}
```

响应：
```proto
message CheckBuyingPowerResponse {
  bool   sufficient = 1;      // 购买力是否足够
  string buying_power = 2;    // 当前购买力
  string required_amount = 3; // 该订单需要的金额（含手续费预估）
  string shortfall = 4;       // 不足金额 (0 if sufficient)
}
```

实现要求：
1. 预估金额 = quantity * price * initial_rate + estimated_commission。
2. 考虑当前未成交订单已冻结的购买力。
3. 对于 SELL 订单，不需要购买力（但需要检查持仓数量）。
4. 响应时间 < 3ms p99。

### 6.2 REST 接口

#### 6.2.1 GET /v1/margin

```http
GET /v1/margin
Authorization: Bearer <jwt>
```

响应：
```json
{
  "account_id": 12345,
  "account_type": "MARGIN",
  "total_equity": "50000.00",
  "total_market_value": "70000.00",
  "cash_balance": "-20000.00",
  "loan_balance": "20000.00",
  "initial_margin": "35000.00",
  "maintenance_margin": "17500.00",
  "available_margin": "15000.00",
  "margin_usage_pct": "70.00",
  "buying_power": "30000.00",
  "margin_call": {
    "status": "NONE",
    "amount": "0",
    "deadline": null
  },
  "interest_rate": "8.50",
  "accrued_interest": "4.72",
  "pdt_status": {
    "is_pdt": false,
    "day_trades_5d": 2,
    "equity_sufficient": true
  }
}
```

#### 6.2.2 GET /v1/margin/buying-power

下单前客户端调用，预检查购买力：

```http
GET /v1/margin/buying-power?symbol=AAPL&market=US&side=BUY&quantity=100&price=155.00
Authorization: Bearer <jwt>
```

响应：
```json
{
  "sufficient": true,
  "buying_power": "30000.00",
  "required_amount": "7802.50",
  "breakdown": {
    "order_value": "15500.00",
    "margin_required": "7750.00",
    "estimated_commission": "0.50",
    "estimated_fees": "2.00"
  },
  "remaining_buying_power": "22197.50"
}
```

#### 6.2.3 GET /v1/margin/rates/{symbol}

查询特定证券的保证金比例：

```http
GET /v1/margin/rates/0700.HK
Authorization: Bearer <jwt>
```

响应：
```json
{
  "symbol": "0700.HK",
  "market": "HK",
  "eligible": true,
  "initial_rate": "0.40",
  "maintenance_rate": "0.30",
  "max_leverage": "2.5",
  "effective_from": "2026-01-01"
}
```

### 6.3 Kafka Events

#### 6.3.1 margin.call.triggered

```json
{
  "event_id": "uuid",
  "event_type": "MARGIN_CALL_TRIGGERED",
  "timestamp": "2026-03-16T16:05:00Z",
  "account_id": 12345,
  "user_id": 67890,
  "data": {
    "call_amount": "3250.00",
    "deadline": "2026-03-18T16:00:00Z",
    "current_equity": "13000.00",
    "maintenance_required": "13250.00",
    "margin_usage_pct": "115.00",
    "positions": [
      {
        "symbol": "AAPL",
        "market": "US",
        "quantity": 200,
        "market_value": "26000.00",
        "margin_contribution": "6500.00"
      }
    ],
    "previous_status": "WARNING",
    "new_status": "TRIGGERED"
  }
}
```

消费者：
- **Notification Service**: 推送通知、邮件、短信
- **Admin Panel**: 风控仪表盘实时更新
- **Audit Service**: 合规记录

#### 6.3.2 margin.call.resolved

```json
{
  "event_id": "uuid",
  "event_type": "MARGIN_CALL_RESOLVED",
  "timestamp": "2026-03-17T10:30:00Z",
  "account_id": 12345,
  "data": {
    "resolution": "DEPOSIT",
    "deposit_amount": "5000.00",
    "new_equity": "18000.00",
    "new_maintenance": "13250.00",
    "new_status": "NONE"
  }
}
```

#### 6.3.3 margin.liquidation.executed

```json
{
  "event_id": "uuid",
  "event_type": "MARGIN_LIQUIDATION_EXECUTED",
  "timestamp": "2026-03-18T16:01:00Z",
  "account_id": 12345,
  "data": {
    "reason": "MARGIN_CALL_DEADLINE_EXPIRED",
    "liquidation_orders": [
      {
        "order_id": "liq-order-uuid",
        "symbol": "AAPL",
        "market": "US",
        "side": "SELL",
        "quantity": 50,
        "estimated_value": "6500.00",
        "margin_released": "3250.00"
      }
    ],
    "pre_liquidation_equity": "13000.00",
    "post_liquidation_equity_est": "16250.00",
    "maintenance_required": "10000.00"
  }
}
```

消费者：
- **Notification Service**: 平仓通知
- **Admin Panel**: 强平记录
- **Compliance**: 监管报告

#### 6.3.4 margin.snapshot.daily

```json
{
  "event_id": "uuid",
  "event_type": "MARGIN_SNAPSHOT_DAILY",
  "timestamp": "2026-03-16T21:00:00Z",
  "account_id": 12345,
  "data": {
    "snapshot_date": "2026-03-16",
    "total_equity": "50000.00",
    "initial_margin": "35000.00",
    "maintenance_margin": "17500.00",
    "available_margin": "15000.00",
    "margin_usage_pct": "70.00",
    "loan_balance": "20000.00",
    "daily_interest": "4.72",
    "call_status": "NONE",
    "pdt_day_trades_5d": 2
  }
}
```

---

## 7. 开源参考实现

### 7.1 相关开源项目

| 项目 | 语言 | 相关性 | 参考价值 |
|------|------|--------|---------|
| [Alpaca Markets API](https://github.com/alpacahq/alpaca-trade-api-go) | Go | 券商 API | Margin/Buying Power API 设计 |
| [Interactive Brokers API](https://github.com/stoqey/ib) | Go | 券商 API | Margin 计算模型参考 |
| [Shopspring/decimal](https://github.com/shopspring/decimal) | Go | 精确计算 | 保证金金额计算必用 |
| [go-finance](https://github.com/alpeb/go-finance) | Go | 金融计算 | 利率计算、复利等 |
| [GoCryptoTrader](https://github.com/thrasher-corp/gocryptotrader) | Go | 交易系统 | Margin 和 Leverage 计算 |

### 7.2 行业参考

#### 7.2.1 Interactive Brokers (IBKR) Margin Model

IBKR 使用 **Portfolio Margin** 模型（TIMS - Theoretical Intermarket Margin System），比 Reg T 更精细：

- 基于 OCC（Options Clearing Corporation）的 TIMS 模型。
- 考虑持仓之间的对冲关系。
- 通常比 Reg T 的保证金要求更低（因为考虑了分散化）。
- 最低权益 $110,000。

我们的 MVP 使用标准 Reg T 模型，未来可以考虑 Portfolio Margin。

#### 7.2.2 Robinhood Margin

Robinhood Gold 的保证金模型相对简单：
- $2,000 最低要求。
- 50% 初始保证金（标准 Reg T）。
- 25% 维持保证金。
- 利率: ~11.75% 年化（2024 年）。
- 自动平仓无需用户确认。

#### 7.2.3 Tiger Brokers (老虎证券)

同时支持美股和港股，与我们的场景最接近：
- 美股: 标准 Reg T (50%/25%)。
- 港股: 根据证券类型 (40-80% / 30-60%)。
- 融资利率: 美股 ~7%, 港股 ~5.8%。
- 支持跨市场保证金（部分）。

### 7.3 值得借鉴的模式

1. **IBKR 的实时 Margin 监控页面**：向用户清晰展示保证金使用情况、Margin Call 状态、各持仓的保证金贡献。
2. **Robinhood 的 "Margin Maintenance" 可视化**：用进度条展示保证金使用率，绿(安全) → 黄(警告) → 红(危险)。
3. **Tiger 的跨市场保证金**：美股和港股的保证金可以一定程度上互通。
4. **Alpaca 的 Buying Power API**：下单前实时返回购买力和所需金额的详细分解。

---

## 8. PRD Review 检查清单

### 8.1 功能完整性

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 保证金账户开通流程 | -- | KYC + 风险评估 + 审批 |
| 2 | 初始保证金计算（Reg T 50%） | -- | 日终批处理 |
| 3 | 维持保证金计算（FINRA 25%/30%） | -- | 盘中实时 |
| 4 | 港股差异化保证金比例 | -- | margin_rates 配置 |
| 5 | 购买力计算（现金/保证金/PDT） | -- | 分账户类型 |
| 6 | 下单前购买力检查 | -- | < 3ms p99 |
| 7 | Margin Call 触发 | -- | 净值 < 维持保证金 |
| 8 | Margin Call 通知（多渠道） | -- | Push/Email/SMS |
| 9 | Margin Call 补足检测 | -- | 定时检查 |
| 10 | 强制平仓算法 | -- | 优先级排序 |
| 11 | 强制平仓执行 | -- | 市价单，跳过部分风控 |
| 12 | PDT 检测 | -- | 5 天窗口，4 次 day trade |
| 13 | PDT $25K 要求 | -- | 权益检查 |
| 14 | 融资利率计算 | -- | 美股 360 天，港股 365 天 |
| 15 | 日终批处理 | -- | 快照 + Reg T 检查 |
| 16 | 保证金比例配置管理 | -- | Admin Panel |

### 8.2 数据准确性

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 所有金额使用 shopspring/decimal | -- | 绝不使用 float64 |
| 2 | 增量计算与全量计算结果一致 | -- | 定期对账 |
| 3 | 购买力 >= 0 | -- | 永远不应为负 |
| 4 | 保证金使用率 0-100%（正常范围） | -- | 可以超过 100%（需 Margin Call） |
| 5 | 利率计算精度到 0.01 | -- | 每日利息精度 |
| 6 | 跨市场保证金正确隔离 | -- | US 和 HK 分别计算 |

### 8.3 合规要求

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | Reg T 50% 初始保证金 | -- | 日终检查 |
| 2 | FINRA 4210 25%/30% 维持保证金 | -- | 实时监控 |
| 3 | PDT 规则完整实施 | -- | $25K + 4 次规则 |
| 4 | 港股 SFC 融资证券名单 | -- | eligible 标记 |
| 5 | 所有 Margin Call 有审计记录 | -- | margin_snapshots |
| 6 | 强制平仓有完整审计日志 | -- | 事件 + 台账 |
| 7 | 保证金利率披露 | -- | 合同 + 账单 |
| 8 | 快照记录保留 7 年 | -- | 合规存储 |

### 8.4 性能要求

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 购买力检查 < 3ms p99 | -- | 下单热路径 |
| 2 | 增量保证金更新 < 1ms p99 | -- | 行情触发 |
| 3 | 全量保证金计算 < 5ms p99 | -- | 单账户 |
| 4 | 日终批处理 < 60s | -- | 全部账户 |
| 5 | Margin Call 通知 < 5s | -- | 端到端延迟 |

### 8.5 异常场景

| # | 检查项 | 状态 | 备注 |
|---|--------|------|------|
| 1 | 行情中断时的保证金处理 | -- | 使用最后已知价格 |
| 2 | 多只证券同时暴跌 | -- | 批量 Margin Call 处理 |
| 3 | 强平订单无法成交（停牌） | -- | 跳过停牌证券 |
| 4 | 强平后仍不满足保证金 | -- | 继续平仓下一个目标 |
| 5 | 用户在 Margin Call 期间下单 | -- | 仅允许减仓/平仓 |
| 6 | 盘后市价大幅变动 | -- | 盘前重新检查 |
| 7 | 极端行情（熔断/涨跌停） | -- | 特殊处理逻辑 |
| 8 | Redis 不可用 | -- | 降级到 PostgreSQL 全量计算 |

---

## 9. 工程落地注意事项

### 9.1 实现优先级

| 阶段 | 功能 | 复杂度 | 依赖 |
|------|------|--------|------|
| P0 (MVP) | 保证金全量计算 (Calculate) | 中 | Position Engine, Market Data |
| P0 (MVP) | 购买力检查 (CheckBuyingPower) | 中 | Margin Calculate, Order Value |
| P0 (MVP) | 下单前保证金影响预估 | 中 | CalculateAfterOrder |
| P0 (MVP) | 默认保证金比例（Reg T） | 低 | 配置 |
| P1 | 维持保证金实时监控 | 高 | Market Data 订阅 |
| P1 | Margin Call 触发 + 通知 | 高 | Kafka, Notification Service |
| P1 | Redis 缓存层 | 中 | Redis 部署 |
| P1 | 日终批处理 | 高 | 批处理框架, 市场日历 |
| P1 | PDT 检测 | 中 | day_trade_counts 表 |
| P2 | 强制平仓算法 | 很高 | OMS 内部调用 |
| P2 | 港股差异化保证金比例 | 中 | margin_rates 配置 |
| P2 | 融资利率计算 | 中 | 利率配置, 日终批处理 |
| P3 | Margin Warning 可视化 | 低 | Mobile UI |
| P3 | Portfolio Margin（进阶） | 很高 | 对冲计算模型 |

### 9.2 测试策略

#### 9.2.1 单元测试

```go
// 必须覆盖的测试场景

// 保证金计算
func TestCalculate_SingleLongPosition(t *testing.T)          {}
func TestCalculate_MultiplePositions(t *testing.T)            {}
func TestCalculate_MixedLongShort(t *testing.T)               {}
func TestCalculate_EmptyAccount(t *testing.T)                 {}
func TestCalculate_CashAccountNoMargin(t *testing.T)          {}
func TestCalculate_HKDifferentRates(t *testing.T)             {}

// 购买力
func TestBuyingPower_CashAccount(t *testing.T)                {}
func TestBuyingPower_MarginAccount(t *testing.T)              {}
func TestBuyingPower_PDTAccount(t *testing.T)                 {}
func TestBuyingPower_WithPendingOrders(t *testing.T)          {}
func TestBuyingPower_SufficientForOrder(t *testing.T)         {}
func TestBuyingPower_InsufficientForOrder(t *testing.T)       {}

// Margin Call
func TestMarginCall_NotTriggered(t *testing.T)                {}
func TestMarginCall_Warning(t *testing.T)                     {}
func TestMarginCall_Triggered(t *testing.T)                   {}
func TestMarginCall_Resolved_ByDeposit(t *testing.T)          {}
func TestMarginCall_Resolved_ByPriceRecovery(t *testing.T)    {}
func TestMarginCall_Liquidation(t *testing.T)                 {}

// PDT
func TestPDT_NotTriggered_3DayTrades(t *testing.T)           {}
func TestPDT_Triggered_4DayTrades(t *testing.T)               {}
func TestPDT_EquityAbove25K(t *testing.T)                     {}
func TestPDT_EquityBelow25K_Blocked(t *testing.T)             {}
func TestPDT_NotApplicable_HK(t *testing.T)                   {}

// 强制平仓
func TestLiquidation_SelectTargets_ByPriority(t *testing.T)   {}
func TestLiquidation_MinimalImpact(t *testing.T)              {}
func TestLiquidation_SkipSuspended(t *testing.T)              {}

// 利率
func TestInterest_US_360DayBasis(t *testing.T)                {}
func TestInterest_HK_365DayBasis(t *testing.T)                {}
func TestInterest_TieredRate(t *testing.T)                    {}
```

#### 9.2.2 集成测试

```go
func TestEndOfDayBatch_FullPipeline(t *testing.T) {
    // 1. 创建保证金账户 + 持仓
    // 2. 设置收盘价
    // 3. 运行日终批处理
    // 4. 验证 margin_snapshots 写入
    // 5. 验证 Margin Call 事件（如适用）
    // 6. 验证利息计算
}

func TestMarginCallLifecycle(t *testing.T) {
    // 1. 初始化: 保证金账户，持仓接近维持线
    // 2. 价格下跌 → 触发 Margin Call
    // 3. 验证通知事件发布
    // 4. 模拟用户入金
    // 5. 验证 Margin Call 解除
}

func TestLiquidationLifecycle(t *testing.T) {
    // 1. 初始化: 触发 Margin Call
    // 2. 模拟到期未补足
    // 3. 验证强制平仓订单生成
    // 4. 模拟成交
    // 5. 验证保证金恢复
    // 6. 验证审计日志完整
}
```

#### 9.2.3 压力测试

```go
func BenchmarkCalculate_SingleAccount(b *testing.B) {
    // 单账户保证金计算性能
    // 目标: < 5ms p99
}

func BenchmarkIncrementalUpdate(b *testing.B) {
    // 增量更新性能
    // 目标: < 1ms p99
}

func BenchmarkEndOfDayBatch(b *testing.B) {
    // 日终批处理性能
    // 目标: 30K 账户 < 60s
}

func TestStressTest_MassMarginCall(t *testing.T) {
    // 极端场景: 5000 个账户同时触发 Margin Call
    // 验证系统不过载，通知不丢失
}
```

### 9.3 监控和告警

#### 9.3.1 Prometheus Metrics

```go
// 保证金计算延迟
trading_margin_calculation_duration_seconds (histogram)
    labels: market, calc_type (full/incremental)

// Margin Call 数量
trading_margin_calls_total (counter)
    labels: market, status (warning/triggered/liquidation/resolved)

// 活跃 Margin Call 数量
trading_margin_calls_active (gauge)
    labels: market, status

// 购买力检查
trading_buying_power_checks_total (counter)
    labels: market, result (sufficient/insufficient)

// 日终批处理
trading_margin_eod_batch_duration_seconds (histogram)
    labels: market

trading_margin_eod_accounts_processed (gauge)
    labels: market, outcome (success/failure)

// 强制平仓
trading_margin_liquidations_total (counter)
    labels: market

trading_margin_liquidation_value_total (counter)
    labels: market

// PDT 检测
trading_pdt_violations_total (counter)

// 保证金比例缓存
trading_margin_rate_cache_hits_total (counter)
trading_margin_rate_cache_misses_total (counter)
```

#### 9.3.2 告警规则

| 告警 | 条件 | 严重级别 | 处理方式 |
|------|------|---------|---------|
| Margin Call 激增 | > 50 个新 Margin Call / 小时 | P1 | 市场可能剧烈波动，通知风控 |
| 强制平仓失败 | 任何一次 | P0 | 立即人工介入 |
| 日终批处理失败 | 任何一次 | P1 | 排查并重跑 |
| 日终批处理超时 | > 120s | P2 | 排查慢查询 |
| 购买力检查超时 | p99 > 10ms 持续 5 分钟 | P1 | 排查 Redis / PostgreSQL |
| 保证金计算不一致 | 增量 vs 全量差异 > 1% | P2 | 触发全量重算 |
| Redis 缓存不可用 | 连续失败 > 10 次 | P1 | 降级到 PostgreSQL |

### 9.4 常见踩坑点

#### 9.4.1 Reg T 是日终规则

```go
// 错误: 盘中实时检查 Reg T 初始保证金
func checkRegT(equity, initialMargin decimal.Decimal) error {
    if equity.LessThan(initialMargin) {
        return ErrRegTViolation // 错误! 盘中不应该检查 Reg T
    }
    return nil
}

// 正确: 只在日终批处理中检查 Reg T
func (e *engine) processEndOfDay(account Account) {
    // ... 日终时才检查 Reg T
    if equity.LessThan(initialMargin) {
        e.triggerRegTCall(account)
    }
}

// 盘中只检查维持保证金 (FINRA 4210)
func (e *engine) realtimeMonitor(account Account) {
    if equity.LessThan(maintenanceMargin) {
        e.triggerMaintenanceCall(account)
    }
}
```

#### 9.4.2 PDT 只适用于美股保证金账户

```go
// 错误: 对港股账户检查 PDT
func checkPDT(order *Order) error {
    if countDayTrades(order.AccountID) >= 4 {
        return ErrPDTRestriction
    }
    return nil
}

// 正确: 只对美股保证金账户检查
func checkPDT(order *Order, account *Account) error {
    if account.Market != "US" || account.Type != "MARGIN" {
        return nil // PDT 不适用于港股和现金账户
    }
    if countDayTrades(order.AccountID) >= 4 && account.Equity.LessThan(pdtMinEquity) {
        return ErrPDTRestriction
    }
    return nil
}
```

#### 9.4.3 强平订单不应被风控拦截

```go
// 错误: 强平订单经过完整风控流程
func submitOrder(order *Order) error {
    if err := riskEngine.CheckOrder(order); err != nil {
        return err // 如果购买力不足，强平订单也会被拒绝！
    }
    // ...
}

// 正确: 强平订单跳过特定风控检查
func submitOrder(order *Order) error {
    if order.Source == "SYSTEM_LIQUIDATION" {
        // 只做基础检查: 市场状态、证券状态
        if err := riskEngine.CheckBasicOnly(order); err != nil {
            return err
        }
    } else {
        if err := riskEngine.CheckOrder(order); err != nil {
            return err
        }
    }
    // ...
}
```

#### 9.4.4 利率天数基准差异

```go
// 错误: 所有市场统一用 365 天
interest := loanBalance.Mul(annualRate).Div(decimal.NewFromInt(365))

// 正确: 美股 360 天, 港股 365 天
var daysInYear int64
switch market {
case "US":
    daysInYear = 360 // 美国金融惯例 (30/360)
case "HK":
    daysInYear = 365 // 香港惯例 (Actual/365)
}
interest := loanBalance.Mul(annualRate).Div(decimal.NewFromInt(daysInYear))
```

#### 9.4.5 Margin Call 闪烁问题

```go
// 问题: 市价在维持保证金线附近反复波动，
// 导致频繁触发和解除 Margin Call，用户收到大量通知

// 解决: 引入 hysteresis（迟滞）
const (
    triggerThreshold = 1.00  // 净值 < 维持保证金 * 1.00 → 触发
    resolveThreshold = 1.10  // 净值 > 维持保证金 * 1.10 → 解除
    // 区间内: 保持当前状态
)

func checkCallWithHysteresis(equity, maintenance decimal.Decimal, currentStatus CallStatus) CallStatus {
    ratio := equity.Div(maintenance)

    switch currentStatus {
    case CallStatusNone:
        if ratio.LessThan(decimal.NewFromFloat(triggerThreshold)) {
            return CallStatusTriggered
        }
    case CallStatusTriggered:
        if ratio.GreaterThanOrEqual(decimal.NewFromFloat(resolveThreshold)) {
            return CallStatusNone
        }
        // 在 1.00 和 1.10 之间，保持 TRIGGERED
    }
    return currentStatus
}
```

### 9.5 跨市场保证金的未来考量

当前 MVP 阶段，美股和港股的保证金**独立计算**。未来可能需要考虑：

1. **跨市场保证金互认**: 美股持仓的保证金余额是否可以部分用于港股交易？
2. **汇率风险**: 跨市场保证金需要考虑 USD/HKD 汇率波动。
3. **时区差异**: 美股和港股的交易时段不同，保证金检查时点不同。
4. **监管限制**: 可能需要监管批准才能实现跨市场保证金互认。

当前建议：保持独立计算，但在 PortfolioSummary 中合并展示。

### 9.6 灾难恢复

| 场景 | 恢复策略 | RTO | RPO |
|------|---------|-----|-----|
| Redis 全部丢失 | 从 PostgreSQL + 当前行情全量重建 | < 5 分钟 | 0 |
| 日终批处理中断 | 幂等重跑 | < 10 分钟 | 0 |
| Margin Call 通知失败 | 重试队列 + 人工通知 | < 30 分钟 | 0 |
| 强制平仓订单被拒 | 人工审核 + 手动下单 | < 5 分钟 | 0 |
| PostgreSQL 主库宕机 | 切换从库 | < 30 秒 | < 1 秒 |
| 市场数据中断 | 使用最后已知价格，暂停新 Margin Call | 0 | N/A |

---

## 附录 A: 保证金计算完整示例

### 场景: 美股保证金账户全生命周期

**初始状态**: 保证金账户，入金 $30,000

```
total_equity:       $30,000
initial_margin:     $0
maintenance_margin: $0
available_margin:   $30,000
buying_power:       $60,000 (2x leverage)
```

**步骤 1: 买入 200 股 AAPL @ $150**

```
order_value = 200 * $150 = $30,000
margin_required = $30,000 * 50% = $15,000
cash_used = $15,000 (自有资金)
loan = $15,000 (融资)

--- 成交后 ---
total_market_value: $30,000
cash_balance:       $15,000 ($30,000 - $15,000)
loan_balance:       $15,000
total_equity:       $30,000 ($30,000 + $15,000 - $15,000)
initial_margin:     $15,000 ($30,000 * 50%)
maintenance_margin: $7,500  ($30,000 * 25%)
available_margin:   $15,000 ($30,000 - $15,000)
buying_power:       $30,000 ($15,000 / 50%)
margin_usage_pct:   50.0%
```

**步骤 2: AAPL 涨到 $170**

```
total_market_value: $34,000 (200 * $170)
cash_balance:       $15,000 (不变)
loan_balance:       $15,000 (不变)
total_equity:       $34,000 ($34,000 + $15,000 - $15,000)
initial_margin:     $17,000 ($34,000 * 50%)
maintenance_margin: $8,500  ($34,000 * 25%)
available_margin:   $17,000 ($34,000 - $17,000)
buying_power:       $34,000 ($17,000 / 50%)
margin_usage_pct:   50.0%
```

**步骤 3: 再买入 100 股 AAPL @ $170**

```
additional_order = 100 * $170 = $17,000
additional_margin = $17,000 * 50% = $8,500
cash_used = $8,500
additional_loan = $8,500

--- 成交后 ---
total_market_value: $51,000 (300 * $170)
cash_balance:       $6,500 ($15,000 - $8,500)
loan_balance:       $23,500 ($15,000 + $8,500)
total_equity:       $27,500 ($51,000 + $6,500 - $23,500 ... 等价于 $51,000 - $23,500)
                    // 注意: total_equity = market_value + cash - loan = market_value - loan (当 cash 可以为负)
                    // 实际上: equity = $51,000 + $6,500 = $57,500? 不对
                    // 正确: equity = cash_balance + market_value = $6,500 + $51,000 = $57,500
                    //        但 loan_balance = $23,500
                    //        net_equity = $57,500 - $23,500 = $34,000? 也不对

// 重新计算:
// 入金: $30,000
// 第1笔融资: 出 $15,000 现金 + 借 $15,000 → 买 $30,000 AAPL
// 第2笔融资: 出 $8,500 现金 + 借 $8,500 → 买 $17,000 AAPL
// 现金余额: $30,000 - $15,000 - $8,500 = $6,500
// 融资余额: $15,000 + $8,500 = $23,500
// 持仓市值: $51,000

total_equity = 持仓市值 - 融资余额 + 现金余额
             = $51,000 - $23,500 + $6,500 = $34,000
// 验证: 入金$30,000 + 浮盈(300*$170 - 200*$150 - 100*$170) = $30,000 + $4,000 = $34,000 ✓

initial_margin:     $25,500 ($51,000 * 50%)
maintenance_margin: $12,750 ($51,000 * 25%)
available_margin:   $8,500  ($34,000 - $25,500)
buying_power:       $17,000 ($8,500 / 50%)
margin_usage_pct:   75.0%
```

**步骤 4: AAPL 暴跌到 $100**

```
total_market_value: $30,000 (300 * $100)
loan_balance:       $23,500 (不变)
cash_balance:       $6,500  (不变)
total_equity:       $13,000 ($30,000 - $23,500 + $6,500)

maintenance_margin: $7,500 ($30,000 * 25%)

$13,000 > $7,500 → 暂无 Margin Call

--- AAPL 继续跌到 $80 ---

total_market_value: $24,000 (300 * $80)
total_equity:       $7,000 ($24,000 - $23,500 + $6,500)
maintenance_margin: $6,000 ($24,000 * 25%)

$7,000 > $6,000 → 仍然安全（但接近）

--- AAPL 跌到 $75 ---

total_market_value: $22,500 (300 * $75)
total_equity:       $5,500 ($22,500 - $23,500 + $6,500)
maintenance_margin: $5,625 ($22,500 * 25%)

$5,500 < $5,625 → 触发 Margin Call!
call_amount = $5,625 - $5,500 + buffer($281) = $406
```

**步骤 5: Margin Call 未补足 → 强制平仓**

```
需要释放的保证金 = $406
AAPL 保证金贡献率 = 25% (维持比例)
需要平仓市值 = $406 / 25% = $1,624
需要平仓股数 = ceil($1,624 / $75) = 22 股

→ 强制卖出 22 股 AAPL @ 市价

--- 平仓后 ---
remaining_qty: 278
market_value: $20,850 (278 * $75)
cash_from_sale: 22 * $75 = $1,650
new_loan: $23,500 - $1,650 = $21,850 (部分偿还融资)
total_equity: $20,850 - $21,850 + ($6,500 + $1,650) = $7,150
maintenance: $5,212.50 ($20,850 * 25%)
$7,150 > $5,212.50 → Margin Call 解除 ✓
```
