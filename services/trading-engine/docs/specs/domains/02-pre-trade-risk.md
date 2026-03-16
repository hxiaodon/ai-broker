# Pre-Trade 风控系统深度调研

> Pre-Trade Risk Controls Deep Dive -- 美港股券商交易引擎风控子域

---

## 1. 业务概述

### 1.1 Pre-Trade 风控的角色

Pre-Trade Risk Controls（交易前风控）是交易引擎中最关键的安全屏障。每一笔订单在发送至交易所之前，必须通过完整的风控流水线检查。**没有例外**。风控系统的核心职责是：防止因账户状态异常、资金不足、持仓过度集中、违反监管规则等原因导致的不当交易。

一个设计不当的风控系统可能导致：
- 客户超额下单（over-buying）→ 券商垫资风险
- 违反 PDT 规则 → 监管处罚
- 保证金不足 → 强制平仓连锁反应
- 操纵市场嫌疑 → 刑事调查

### 1.2 风控在订单生命周期中的位置

```
  订单接收 → 幂等检查 → 格式校验 → [风控检查] → 路由 → FIX发送 → 交易所
                                       ▲
                                       │
                              这是最关键的门控点
                              通过: VALIDATED → RISK_APPROVED
                              拒绝: VALIDATED → REJECTED
```

在当前代码库中，风控引擎位于 `src/internal/risk/risk.go`，定义了 `Engine` 接口和 `Check` 接口：

```go
// Engine 风控引擎
// 按顺序执行所有检查，任一失败即终止
type Engine interface {
    CheckOrder(ctx context.Context, ord *order.Order) (*Result, error)
    RegisterCheck(check Check)
}

// Check 单项风控检查接口
type Check interface {
    Name() string
    Execute(ctx context.Context, ord *order.Order, account *Account) *Result
}

// Result 风控结果
type Result struct {
    Approved bool
    Reason   string
    Warnings []string
}
```

### 1.3 风控流水线概览

当前系统设计了 8 道风控检查（risk gates），按顺序串行执行，任一失败立即终止：

```
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                     Pre-Trade Risk Pipeline (8 Gates)                       │
 │                                                                             │
 │  Order ──▶ [1.Account] ──▶ [2.Symbol] ──▶ [3.BuyingPower] ──▶ [4.Position]│
 │                │              │                │                   │        │
 │                ▼              ▼                ▼                   ▼        │
 │             PASS/FAIL      PASS/FAIL       PASS/FAIL          PASS/FAIL    │
 │                │              │                │                   │        │
 │            ──▶ [5.OrderRate] ──▶ [6.PDT] ──▶ [7.Margin] ──▶ [8.PostTrade] │
 │                    │              │              │                │         │
 │                    ▼              ▼              ▼                ▼         │
 │                 PASS/FAIL      PASS/FAIL     PASS/FAIL       PASS/FAIL     │
 │                                                                             │
 │  全部通过: Result{Approved: true}                                           │
 │  任一失败: Result{Approved: false, Reason: "具体原因"}                       │
 │                                                                             │
 │  性能目标: 全部 8 道检查 < 5ms (p99)                                        │
 └─────────────────────────────────────────────────────────────────────────────┘
```

### 1.4 风控结果存储

风控结果以 JSONB 格式存储在 `orders.risk_result` 字段中，包含每一道检查的详细结果：

```json
{
  "approved": true,
  "checks": [
    {"name": "AccountCheck", "approved": true, "duration_us": 120},
    {"name": "SymbolCheck", "approved": true, "duration_us": 85},
    {"name": "BuyingPowerCheck", "approved": true, "duration_us": 450,
     "details": {"required": "15025.75", "available": "50000.00"}},
    {"name": "PositionLimitCheck", "approved": true, "duration_us": 200},
    {"name": "OrderRateCheck", "approved": true, "duration_us": 50},
    {"name": "PDTCheck", "approved": true, "duration_us": 300,
     "warnings": ["PDT warning: 2 day trades in past 5 days"]},
    {"name": "MarginCheck", "approved": true, "duration_us": 180},
    {"name": "PostTradeCheck", "approved": true, "duration_us": 100}
  ],
  "total_duration_us": 1485,
  "warnings": ["PDT warning: 2 day trades in past 5 days"]
}
```

---

## 2. 监管与合规要求

### 2.1 美股监管框架

#### 2.1.1 FINRA Rule 4210 -- 保证金要求

FINRA Rule 4210 是美股保证金交易的基础规则，直接影响风控系统中的 BuyingPowerCheck 和 MarginCheck：

| 要求 | 比例 | 说明 |
|------|------|------|
| 初始保证金 (Initial Margin) | 50% | 建仓时，客户至少支付证券市值的 50% (Reg T) |
| 维持保证金 (Maintenance Margin) | 25% | 持仓期间，账户净值不得低于证券市值的 25% |
| Day Trading Margin | 25% | PDT 账户日内交易的保证金要求 |
| 最低账户净值 | $2,000 | 保证金账户最低净值要求 |
| PDT 最低净值 | $25,000 | Pattern Day Trader 账户最低净值 |

**关键计算**：

```
初始保证金 = 证券市值 x 50%
维持保证金 = 证券市值 x 25%
Margin Call 触发 = 账户净值 < 维持保证金
Margin Call 金额 = 维持保证金 - 当前净值
```

#### 2.1.2 Regulation T (Federal Reserve Board)

Reg T 规定了证券信用交易的信用额度：

- **买入**：初始保证金 50%（即最多借 50%）
- **卖空**：初始保证金 50% + 卖空所得必须全额留在保证金账户
- **Reg T Call**：如果买入后 T+1 日内保证金不足 50%，发出 Reg T Call，必须在 T+4 日内补足

风控系统必须在下单前验证：
```
买入订单: 订单金额 x 50% <= 可用保证金
卖空订单: 订单金额 x 50% + 预估佣金 <= 可用保证金
```

#### 2.1.3 Regulation SHO -- 卖空规则

Reg SHO 对卖空交易施加了严格限制，直接影响风控系统的 Symbol Check 和 Account Check：

| 规则 | 内容 | 风控影响 |
|------|------|----------|
| **Locate Requirement** | 卖空前必须合理确信可以借到股票 | SymbolCheck 必须验证 locate 可用性 |
| **Close-Out Requirement** | 如果 T+3 仍未交付（Fail-to-Deliver），必须强制买入回补 | PostTrade 监控 |
| **Threshold Securities** | 连续 5 天以上存在大量 FTD 的证券被列入阈值证券名单 | 阈值证券卖空需要 pre-borrow（实际借入）|
| **Short Sale Price Test (Rule 201)** | 当股价当日下跌 10% 以上时，触发 Circuit Breaker，次日之前卖空价不得低于 NBB | 限价校验 |

**Locate 流程**：

```
  风控检查卖空订单:
    │
    ▼
  1. 检查账户是否有卖空权限 (permissions.ShortSelling)
    │
    ▼
  2. 检查标的是否在可卖空名单 (Easy-to-Borrow List)
    │ YES → 自动 locate (internal)
    │ NO → 需要联系 Prime Broker 获取 locate
    │
    ▼
  3. 检查 Reg SHO Rule 201 是否生效
    │ YES → 卖空价必须 > NBB (National Best Bid)
    │ NO → 正常处理
    │
    ▼
  4. 检查是否为阈值证券 (Threshold Security)
    │ YES → 需要 pre-borrow (实际借入确认)
    │ NO → locate 确认即可
    │
    ▼
  APPROVED / REJECTED
```

#### 2.1.4 Pattern Day Trader (PDT) Rule -- FINRA

PDT 规则是美股散户交易最常遇到的限制，必须严格执行：

**定义**：
- **日内交易 (Day Trade)**：同一标的在同一交易日内买入又卖出（或卖出又买入）
- **Pattern Day Trader**：在 5 个连续工作日内执行 4 次或以上日内交易的保证金账户
- **适用范围**：仅适用于保证金账户 (Margin Account)，现金账户不受 PDT 限制（但受 Free-Riding 限制）

**规则**：

| 条件 | 限制 |
|------|------|
| 账户净值 < $25,000 | 5 个工作日内最多 3 次日内交易 |
| 账户净值 >= $25,000 | 不受日内交易次数限制 |
| 被标记为 PDT 且净值 < $25,000 | 账户被冻结 90 天或补足至 $25,000 |

**豁免情况**：
1. 现金账户 (Cash Account) 不适用 PDT
2. 港股交易不计入 PDT（PDT 仅适用于美国证券）
3. 账户净值 >= $25,000 时自动豁免

### 2.2 港股监管框架

#### 2.2.1 SFC 证券保证金融资指引

SFC（香港证券及期货事务监察委员会）对保证金有不同的规则：

| 分类 | 初始保证金 | 维持保证金 | 说明 |
|------|------------|------------|------|
| 蓝筹股 (恒指成分股) | 25-30% | 15-20% | 如 0700.HK, 0005.HK |
| 大型股 | 30-50% | 20-35% | 市值大但非恒指成分 |
| 中小型股 | 50-100% | 30-50% | 流动性较低 |
| 创业板 (GEM) | 100% | 50-100% | 高风险 |
| IPO 新股 | 100% | 100% | 上市初期 |

**与美股的关键差异**：
- 没有统一的 50% 初始保证金规则，而是按标的分级
- 保证金比例由 SFC 指引 + 券商自行设定
- 没有 PDT 规则（无日内交易限制）
- 没有 Reg SHO（卖空规则不同）

#### 2.2.2 HKEX 卖空规则

- 仅允许对「指定证券」进行卖空（SFC 维护名单）
- 卖空订单不得低于当前最佳卖出价（Tick Rule）
- 大额卖空持仓需每日报告 HKEX
- 无覆盖卖空（Naked Short Selling）被严格禁止

#### 2.2.3 港股没有 PDT

港股没有类似美股 PDT 的日内交易限制。客户可以在一天内不限次数地买卖同一标的。但是：
- T+2 结算意味着频繁交易可能导致结算资金不足
- 风控系统仍需要监控高频交易行为（反操纵）

### 2.3 合规差异对风控系统的影响

| 风控检查 | 美股实现 | 港股实现 |
|----------|----------|----------|
| AccountCheck | 检查 US Trading 权限 | 检查 HK Trading 权限 |
| SymbolCheck | 检查是否停牌/退市 + 盘前盘后限制 | 检查停牌 + 午休 + 收市竞价 + LotSize + TickSize |
| BuyingPowerCheck | 统一公式 (含 Reg T) | 按标的分级保证金率 |
| PositionLimitCheck | 单标的 <= 30% portfolio | 同上，但可能有不同阈值 |
| OrderRateCheck | 相同（反操纵） | 相同（反操纵） |
| PDTCheck | 完整 PDT 规则执行 | **跳过** (return Approve) |
| MarginCheck | Reg T 50% + FINRA 25% 维持 | SFC 分级保证金 |
| PostTradeCheck | Wash Sale 检测 + 大额预警 | 大额预警（无 Wash Sale 规则） |

---

## 3. 市场差异 (US vs HK)

### 3.1 保证金体系差异

#### 美股 (Reg T + FINRA)

```
保证金体系 (美股):
┌──────────────────────────────────────────────────────────┐
│  统一规则: 所有证券                                        │
│                                                          │
│  初始保证金 (Reg T):     50% of market value              │
│  维持保证金 (FINRA):     25% of market value              │
│  Day Trading Margin:    25% of highest open position      │
│                                                          │
│  示例: 买入 100 股 AAPL @ $150                            │
│  市值 = $15,000                                          │
│  初始保证金要求 = $15,000 x 50% = $7,500                  │
│  维持保证金要求 = $15,000 x 25% = $3,750                  │
│  最大杠杆 = 2:1 (intraday 可达 4:1 for PDT)              │
└──────────────────────────────────────────────────────────┘
```

#### 港股 (SFC 分级)

```
保证金体系 (港股):
┌──────────────────────────────────────────────────────────┐
│  分级规则: 按标的风险等级                                   │
│                                                          │
│  蓝筹股 (恒指成分):                                       │
│    初始保证金: 25-30%                                     │
│    维持保证金: 15-20%                                     │
│    最大杠杆: ~3.3:1 - 4:1                                │
│                                                          │
│  大型股:                                                  │
│    初始保证金: 30-50%                                     │
│    维持保证金: 20-35%                                     │
│    最大杠杆: 2:1 - 3.3:1                                 │
│                                                          │
│  中小型/创业板:                                           │
│    初始保证金: 50-100%                                    │
│    维持保证金: 30-100%                                    │
│    最大杠杆: 1:1 - 2:1                                   │
│                                                          │
│  示例: 买入 1 手 腾讯 (100股) @ HK$350                    │
│  市值 = HK$35,000                                        │
│  初始保证金要求 = HK$35,000 x 25% = HK$8,750 (蓝筹)     │
│  维持保证金要求 = HK$35,000 x 15% = HK$5,250             │
└──────────────────────────────────────────────────────────┘
```

### 3.2 卖空规则差异

| 维度 | 美股 (Reg SHO) | 港股 (SFC) |
|------|----------------|------------|
| 卖空前提 | Locate Requirement (合理确信可借到) | 必须在「指定证券」名单内 |
| 价格限制 | Rule 201: 跌 10% 后次日前 > NBB | Tick Rule: 不低于最佳卖出价 |
| 交付要求 | T+2 交付，T+3 强制买入 | T+2 交付 |
| 裸卖空 | 理论上被禁止（实践中通过 FTD 机制存在） | 严格禁止 |
| 报告要求 | Form SH (大额卖空持仓) | 每日大额卖空报告 |

### 3.3 购买力计算差异

#### 现金账户 (Cash Account)

```
美股现金账户:
  BuyingPower = CashAvailable + UnsettledProceeds - PendingBuyOrders
  注意: UnsettledProceeds 可以用来买入，但不能提现 (Free-Riding Violation)
  结算: T+1

港股现金账户:
  BuyingPower = CashAvailable + UnsettledProceeds - PendingBuyOrders
  注意: 同上
  结算: T+2 (未结算资金冻结时间更长)
```

#### 保证金账户 (Margin Account)

```
美股保证金账户:
  BuyingPower = AvailableMargin / InitialMarginRate
  AvailableMargin = TotalEquity - InitialMarginUsed
  TotalEquity = CashBalance + PositionsMarketValue
  InitialMarginRate = 50% (Reg T, 统一)

  示例:
    Cash = $10,000
    Positions = $20,000 (AAPL 100 shares @ $200)
    TotalEquity = $30,000
    InitialMarginUsed = $20,000 x 50% = $10,000
    AvailableMargin = $30,000 - $10,000 = $20,000
    BuyingPower = $20,000 / 50% = $40,000

港股保证金账户:
  BuyingPower 需要按标的计算（因为保证金率不同）
  对于特定标的:
    BuyingPower = AvailableMargin / SymbolInitialMarginRate

  示例 (买入腾讯, 初始保证金 25%):
    AvailableMargin = HK$100,000
    BuyingPower (for 0700.HK) = HK$100,000 / 25% = HK$400,000

  示例 (买入创业板股, 初始保证金 100%):
    AvailableMargin = HK$100,000
    BuyingPower (for GEM stock) = HK$100,000 / 100% = HK$100,000
```

### 3.4 结算周期对风控的影响

```
美股 T+1 结算:
  Day 0 (T): 买入 100 AAPL @ $150 → 扣减购买力 $15,000+fees
  Day 1 (T+1): 结算完成 → unsettled_qty 转为 settled_qty
  影响: 卖出后 T+1 资金到账，可较快用于新交易或提现

港股 T+2 结算:
  Day 0 (T): 买入 1 手腾讯 @ HK$350 → 扣减购买力 HK$35,000+fees
  Day 1 (T+1): 仍在结算中
  Day 2 (T+2): 结算完成 → unsettled_qty 转为 settled_qty
  影响: 资金冻结时间更长，频繁交易者的购买力受限更大
```

---

## 4. 技术架构

### 4.1 风控引擎核心架构

```
 ┌────────────────────────────────────────────────────────────────────┐
 │                        Risk Engine                                 │
 │                                                                    │
 │  ┌──────────────────────────────────────────────────────────────┐  │
 │  │                    Check Pipeline                             │  │
 │  │                                                              │  │
 │  │  ┌────────────┐  ┌────────────┐  ┌──────────────────┐       │  │
 │  │  │ 1.Account  │→│ 2.Symbol   │→│ 3.BuyingPower    │       │  │
 │  │  │ Check      │  │ Check      │  │ Check            │       │  │
 │  │  │            │  │            │  │                  │       │  │
 │  │  │ • 账户激活? │  │ • 可交易?  │  │ • 资金充足?      │       │  │
 │  │  │ • KYC通过? │  │ • 停牌?    │  │ • 含预估手续费   │       │  │
 │  │  │ • 未冻结?  │  │ • 交易时段? │  │ • 市价单用       │       │  │
 │  │  │ • 有权限?  │  │ • LotSize? │  │   Ask*1.02 估算  │       │  │
 │  │  └─────┬──────┘  │ • TickSize?│  └────────┬─────────┘       │  │
 │  │        │         └─────┬──────┘           │                 │  │
 │  │        │               │                  │                 │  │
 │  │  ┌─────▼──────┐  ┌────▼───────┐  ┌──────▼──────────┐      │  │
 │  │  │ 4.Position │→│ 5.OrderRate│→│ 6.PDT Check     │      │  │
 │  │  │ Limit      │  │ Check      │  │ (US only)       │      │  │
 │  │  │            │  │            │  │                  │      │  │
 │  │  │ • 单标的   │  │ • N/分钟   │  │ • 5工作日内     │      │  │
 │  │  │   <=30%    │  │ • 按symbol │  │   日内交易计数   │      │  │
 │  │  │   portfolio│  │ • 反操纵   │  │ • $25K净值豁免   │      │  │
 │  │  │ • 最大股数 │  │            │  │ • Cash账户跳过   │      │  │
 │  │  └─────┬──────┘  └─────┬──────┘  └────────┬─────────┘      │  │
 │  │        │               │                  │                 │  │
 │  │  ┌─────▼──────────────┐  ┌────────────────▼─────────┐      │  │
 │  │  │ 7.Margin Check     │→│ 8.PostTrade Check        │      │  │
 │  │  │ (Margin acct only) │  │ (async, non-blocking)    │      │  │
 │  │  │                    │  │                          │      │  │
 │  │  │ • Reg T 50% (US)  │  │ • 大额预警               │      │  │
 │  │  │ • SFC 分级 (HK)   │  │ • Wash Trade 检测        │      │  │
 │  │  │ • 维持保证金检查   │  │ • 维持保证金预警          │      │  │
 │  │  └────────────────────┘  └──────────────────────────┘      │  │
 │  │                                                              │  │
 │  └──────────────────────────────────────────────────────────────┘  │
 │                                                                    │
 │  ┌──────────────────────────────────────────────────────────────┐  │
 │  │                    Data Dependencies                         │  │
 │  │                                                              │  │
 │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │  │
 │  │  │ AMS      │  │ Redis    │  │ Market   │  │ PostgreSQL │  │  │
 │  │  │ (Account)│  │ (Cache)  │  │ Data     │  │ (Positions │  │  │
 │  │  │          │  │          │  │ (Quotes) │  │  Orders)   │  │  │
 │  │  └──────────┘  └──────────┘  └──────────┘  └────────────┘  │  │
 │  └──────────────────────────────────────────────────────────────┘  │
 └────────────────────────────────────────────────────────────────────┘
```

### 4.2 Pipeline 执行模式

#### 4.2.1 串行执行 + 短路模式

风控检查按顺序串行执行。一旦某一道检查失败（`Approved: false`），立即终止后续检查并返回拒绝结果。这是"短路"模式。

```go
// Engine 实现
type engine struct {
    checks  []Check
    account AccountService // 从 AMS 获取账户信息
}

func (e *engine) CheckOrder(ctx context.Context, ord *order.Order) (*Result, error) {
    // 1. 获取账户信息 (从 AMS 服务或缓存)
    account, err := e.account.GetAccount(ctx, ord.AccountID)
    if err != nil {
        return nil, fmt.Errorf("get account %d: %w", ord.AccountID, err)
    }

    // 2. 串行执行每一道检查
    var warnings []string
    var checkResults []CheckResult

    for _, check := range e.checks {
        start := time.Now()
        result := check.Execute(ctx, ord, account)
        duration := time.Since(start)

        checkResults = append(checkResults, CheckResult{
            Name:     check.Name(),
            Approved: result.Approved,
            Reason:   result.Reason,
            Duration: duration,
        })

        // 短路: 任一检查失败则立即返回
        if !result.Approved {
            return &Result{
                Approved: false,
                Reason:   fmt.Sprintf("[%s] %s", check.Name(), result.Reason),
                Checks:   checkResults,
            }, nil
        }

        // 收集警告
        warnings = append(warnings, result.Warnings...)
    }

    return &Result{
        Approved: true,
        Warnings: warnings,
        Checks:   checkResults,
    }, nil
}
```

#### 4.2.2 为什么选择串行而非并行

| 考量 | 串行 | 并行 |
|------|------|------|
| 正确性 | 某些检查依赖前序结果（如 Margin 依赖 BuyingPower） | 需要额外协调 |
| 性能 | 短路避免不必要计算（60%+ 的拒绝在前 3 道检查） | 所有检查都执行 |
| 调试 | 失败原因明确：是第几道检查拒绝的 | 多个检查同时失败，原因不明确 |
| 复杂度 | 简单的 for 循环 | 需要 WaitGroup + channel |
| 总延迟 | 最坏 5ms（全部通过）| 最坏 = 最慢单项（~1ms） |

选择串行的理由：5ms p99 的延迟预算已经足够，串行模式的简洁性和可调试性更重要。

#### 4.2.3 检查顺序优化

检查顺序经过精心设计，将最可能拒绝的检查放在前面：

| 优先级 | 检查 | 拒绝率 | 理由 |
|--------|------|--------|------|
| 1 | AccountCheck | ~5% | 账户异常是最基本的问题 |
| 2 | SymbolCheck | ~3% | 停牌/非交易时段较常见 |
| 3 | BuyingPowerCheck | ~15% | 资金不足是最常见的拒绝原因 |
| 4 | PositionLimitCheck | ~2% | 偶尔触发 |
| 5 | OrderRateCheck | ~1% | 仅异常行为触发 |
| 6 | PDTCheck | ~3% | 美股保证金账户相关 |
| 7 | MarginCheck | ~2% | 保证金账户相关 |
| 8 | PostTradeCheck | ~0% | 异步，仅告警不阻断 |

### 4.3 各检查项详细实现

#### 4.3.1 Gate 1: Account Check (账户状态检查)

```go
type AccountCheck struct{}

func (c *AccountCheck) Name() string { return "AccountCheck" }

func (c *AccountCheck) Execute(ctx context.Context, ord *order.Order, account *Account) *Result {
    // 1. 账户是否激活
    if account.Status != "ACTIVE" {
        return Reject("account status is %s, expected ACTIVE", account.Status)
    }

    // 2. KYC 是否验证通过
    if !account.KYCVerified {
        return Reject("KYC not verified for account %d", account.ID)
    }

    // 3. 市场交易权限
    switch ord.Market {
    case "US":
        if !account.Permissions.USTrading {
            return Reject("US trading not enabled for account %d", account.ID)
        }
    case "HK":
        if !account.Permissions.HKTrading {
            return Reject("HK trading not enabled for account %d", account.ID)
        }
    default:
        return Reject("unsupported market: %s", ord.Market)
    }

    // 4. 卖空权限检查
    if ord.Side == order.SideSell {
        // 需要先检查是否是卖空（需要持仓数据）
        // 如果是卖空且没有卖空权限 → 拒绝
        if !account.Permissions.ShortSelling {
            // 此处简化: 实际需要检查是否有足够持仓
            // 如果无持仓或持仓不足 → 这是卖空
        }
    }

    // 5. 保证金交易权限 (针对保证金订单)
    if account.Type == "MARGIN" && !account.Permissions.MarginTrading {
        return Reject("margin trading not enabled for account %d", account.ID)
    }

    return Approve()
}
```

**数据来源**：`Account` 结构体从 AMS 服务获取，应缓存在 Redis 中（TTL 5 分钟，账户状态变更时主动失效）。

#### 4.3.2 Gate 2: Symbol Check (标的校验)

```go
type SymbolCheck struct {
    symbolService  SymbolService
    calendarService MarketCalendarService
}

func (c *SymbolCheck) Name() string { return "SymbolCheck" }

func (c *SymbolCheck) Execute(ctx context.Context, ord *order.Order, account *Account) *Result {
    // 1. 标的是否存在且可交易
    symbol, err := c.symbolService.Get(ctx, ord.Symbol, ord.Market)
    if err != nil {
        return Reject("symbol not found: %s (%s)", ord.Symbol, ord.Market)
    }
    if !symbol.Tradeable {
        return Reject("symbol %s is not tradeable", ord.Symbol)
    }
    if symbol.Halted {
        return Reject("symbol %s is halted", ord.Symbol)
    }

    // 2. 交易时段校验
    session := c.calendarService.CurrentSession(ord.Market)
    if session == SessionClosed {
        return Reject("market %s is closed", ord.Market)
    }

    // 盘前盘后限制 (美股)
    if ord.Market == "US" && (session == SessionPre || session == SessionPost) {
        if ord.Type != order.TypeLimit {
            return Reject("extended hours: only limit orders accepted")
        }
    }

    // 3. 港股特殊校验
    if ord.Market == "HK" {
        // 午休检查
        if session == SessionLunchBreak {
            return Reject("HK market lunch break (12:00-13:00 HKT)")
        }

        // LotSize 检查
        if ord.Quantity % int64(symbol.LotSize) != 0 {
            return Reject("HK: quantity %d not a multiple of lot size %d",
                ord.Quantity, symbol.LotSize)
        }

        // TickSize 检查 (限价单)
        if ord.Type == order.TypeLimit || ord.Type == order.TypeStopLimit {
            tick := getHKTickSize(ord.Price)
            if !ord.Price.Mod(tick).Equal(decimal.Zero) {
                return Reject("HK: price %s violates tick size %s",
                    ord.Price.String(), tick.String())
            }
        }

        // 收市竞价时段检查
        if session == SessionClosingAuction {
            if ord.Type != order.TypeLimit {
                return Reject("HK closing auction: only limit orders accepted")
            }
        }
    }

    return Approve()
}
```

#### 4.3.3 Gate 3: Buying Power Check (购买力检查)

这是最复杂的检查，也是拒绝率最高的一环。

**购买力计算公式**：

```
现金账户 (Cash Account):
┌──────────────────────────────────────────────────────────────┐
│  BuyingPower = CashAvailable                                 │
│              + UnsettledProceeds (卖出收入, 可用于买入)       │
│              - PendingBuyOrders (未成交买单已冻结金额)        │
│                                                              │
│  OrderCost = EstimatedPrice x Quantity + EstimatedFees       │
│                                                              │
│  其中 EstimatedPrice:                                        │
│    Market Order → AskPrice x 1.02 (2% 滑点缓冲)             │
│    Limit Order  → LimitPrice                                 │
│    Stop Order   → StopPrice x 1.02                           │
│                                                              │
│  通过条件: OrderCost <= BuyingPower                           │
└──────────────────────────────────────────────────────────────┘

保证金账户 (Margin Account):
┌──────────────────────────────────────────────────────────────┐
│  TotalEquity = CashBalance + PositionsMarketValue            │
│  InitialMarginUsed = SUM(position_value x margin_rate)       │
│  AvailableMargin = TotalEquity - InitialMarginUsed           │
│                                                              │
│  美股: BuyingPower = AvailableMargin / 0.50 (Reg T 50%)     │
│  港股: BuyingPower = AvailableMargin / symbol_margin_rate    │
│                                                              │
│  OrderMarginReq = OrderCost x InitialMarginRate              │
│  通过条件: OrderMarginReq <= AvailableMargin                 │
└──────────────────────────────────────────────────────────────┘
```

**卖出订单的购买力检查**：

卖出不检查资金，但检查持仓：

```go
func (c *BuyingPowerCheck) checkSellQuantity(
    ctx context.Context, ord *order.Order, account *Account,
) *Result {
    // 获取当前持仓
    position, err := c.positionService.Get(ctx, account.ID, ord.Symbol, ord.Market)
    if err != nil || position == nil || position.Quantity <= 0 {
        // 无持仓 → 这是卖空
        if !account.Permissions.ShortSelling {
            return Reject("no position in %s and short selling not enabled", ord.Symbol)
        }
        // 卖空有额外的 Locate 检查 (在 MarginCheck 或独立 Check 中处理)
        return Approve()
    }

    // 检查可卖数量 (考虑已冻结的卖单)
    pendingSellQty, _ := c.positionService.GetPendingSellQuantity(ctx, account.ID, ord.Symbol)
    availableToSell := position.Quantity - pendingSellQty

    if ord.Quantity > availableToSell {
        return Reject("insufficient position: want to sell %d, available %d (holding %d, pending sell %d)",
            ord.Quantity, availableToSell, position.Quantity, pendingSellQty)
    }

    return Approve()
}
```

**市价单的成本估算**：

```go
func (c *BuyingPowerCheck) estimateOrderCost(ord *order.Order) decimal.Decimal {
    var price decimal.Decimal

    switch ord.Type {
    case order.TypeMarket:
        // 市价单: 使用卖一价 + 2% 滑点缓冲
        quote, ok := c.quoteCache.Get(ord.Symbol)
        if !ok {
            // 无行情数据，使用保守估计
            return decimal.NewFromInt(999999999) // 拒绝
        }
        price = quote.AskPrice.Mul(decimal.NewFromFloat(1.02))

    case order.TypeLimit, order.TypeStopLimit:
        price = ord.Price

    case order.TypeStop, order.TypeTrailingStop:
        // 止损单触发后变为市价单，使用止损价 + 缓冲
        price = ord.StopPrice.Mul(decimal.NewFromFloat(1.02))

    case order.TypeMOO, order.TypeMOC:
        // 开盘/收盘市价单，使用当前价 + 缓冲
        quote, ok := c.quoteCache.Get(ord.Symbol)
        if !ok {
            return decimal.NewFromInt(999999999)
        }
        price = quote.LastPrice.Mul(decimal.NewFromFloat(1.05)) // 更大缓冲
    }

    // 订单金额
    orderValue := price.Mul(decimal.NewFromInt(ord.Quantity))

    // 加上预估手续费
    estimatedFees := c.feeCalculator.Estimate(ord.Market, ord.Side, orderValue, ord.Quantity)

    return orderValue.Add(estimatedFees)
}
```

**Redis 缓存购买力**：

```go
type CachedBuyingPowerService struct {
    redis   *redis.Client
    calc    BuyingPowerCalculator
    ttl     time.Duration // 60 seconds
}

func (s *CachedBuyingPowerService) Calculate(ctx context.Context, accountID int64) (*BuyingPower, error) {
    key := fmt.Sprintf("buying_power:%d", accountID)

    // 尝试从缓存获取
    cached, err := s.redis.Get(ctx, key).Bytes()
    if err == nil {
        var bp BuyingPower
        json.Unmarshal(cached, &bp)
        return &bp, nil
    }

    // 缓存 miss，重新计算
    bp, err := s.calc.Calculate(ctx, accountID)
    if err != nil {
        return nil, err
    }

    // 写入缓存 (TTL 60s)
    data, _ := json.Marshal(bp)
    s.redis.Set(ctx, key, data, s.ttl)

    return bp, nil
}

// 写时失效: 订单状态变更时删除缓存
func (s *CachedBuyingPowerService) InvalidateCache(ctx context.Context, accountID int64) {
    key := fmt.Sprintf("buying_power:%d", accountID)
    s.redis.Del(ctx, key)
}
```

**缓存失效时机**：
1. 新订单提交成功 → 失效（PendingBuyOrders 变化）
2. 订单取消 → 失效（释放冻结资金）
3. 成交回报 → 失效（实际扣款/入账）
4. 存入/取出资金 → 失效（CashAvailable 变化）
5. 结算完成 → 失效（UnsettledProceeds 变化）

#### 4.3.4 Gate 4: Position Limit Check (持仓限额检查)

```go
type PositionLimitCheck struct {
    positionService PositionService
    quoteCache      QuoteCache
    config          RiskConfig // MaxConcentration: 0.30 (30%)
}

func (c *PositionLimitCheck) Name() string { return "PositionLimitCheck" }

func (c *PositionLimitCheck) Execute(ctx context.Context, ord *order.Order, account *Account) *Result {
    // 卖出不检查持仓限额
    if ord.Side == order.SideSell {
        return Approve()
    }

    // 当前持仓
    position, _ := c.positionService.Get(ctx, account.ID, ord.Symbol, ord.Market)
    currentQty := int64(0)
    if position != nil {
        currentQty = position.Quantity
    }

    // 加上未成交买单
    pendingBuyQty, _ := c.positionService.GetPendingBuyQuantity(ctx, account.ID, ord.Symbol)
    totalAfterOrder := currentQty + pendingBuyQty + ord.Quantity

    // 集中度检查: 单标的不超过总资产的 30%
    portfolioValue, _ := c.positionService.GetPortfolioValue(ctx, account.ID)
    if portfolioValue.GreaterThan(decimal.Zero) {
        quote, ok := c.quoteCache.Get(ord.Symbol)
        if ok {
            positionValue := quote.LastPrice.Mul(decimal.NewFromInt(totalAfterOrder))
            concentration := positionValue.Div(portfolioValue)

            if concentration.GreaterThan(c.config.MaxConcentration) {
                return Reject("concentration limit: %s%% of portfolio in %s (max %s%%)",
                    concentration.Mul(decimal.NewFromInt(100)).StringFixed(1),
                    ord.Symbol,
                    c.config.MaxConcentration.Mul(decimal.NewFromInt(100)).StringFixed(0))
            }
        }
    }

    return Approve()
}
```

#### 4.3.5 Gate 5: Order Rate Check (下单频率检查)

防止操纵市场（spoofing/layering）和系统滥用：

```go
type OrderRateCheck struct {
    redis  *redis.Client
    config RateConfig // MaxOrdersPerMinute: 30, MaxOrdersPerSymbolPerMinute: 10
}

func (c *OrderRateCheck) Name() string { return "OrderRateCheck" }

func (c *OrderRateCheck) Execute(ctx context.Context, ord *order.Order, account *Account) *Result {
    now := time.Now().Unix()
    minute := now / 60 // 按分钟窗口

    // 1. 全局频率: 每分钟最多 N 笔订单 (所有标的合计)
    globalKey := fmt.Sprintf("order_rate:%d:%d", account.ID, minute)
    globalCount, _ := c.redis.Incr(ctx, globalKey).Result()
    c.redis.Expire(ctx, globalKey, 2*time.Minute) // 保留 2 分钟

    if globalCount > int64(c.config.MaxOrdersPerMinute) {
        return Reject("order rate exceeded: %d orders/min (max %d)",
            globalCount, c.config.MaxOrdersPerMinute)
    }

    // 2. 单标的频率: 每分钟最多 M 笔同标的订单
    symbolKey := fmt.Sprintf("order_rate:%d:%s:%d", account.ID, ord.Symbol, minute)
    symbolCount, _ := c.redis.Incr(ctx, symbolKey).Result()
    c.redis.Expire(ctx, symbolKey, 2*time.Minute)

    if symbolCount > int64(c.config.MaxOrdersPerSymbolPerMinute) {
        return Reject("order rate for %s exceeded: %d orders/min (max %d)",
            ord.Symbol, symbolCount, c.config.MaxOrdersPerSymbolPerMinute)
    }

    // 3. 异常模式检测: 短时间大量撤单 (cancel/order ratio)
    cancelKey := fmt.Sprintf("cancel_rate:%d:%s:%d", account.ID, ord.Symbol, minute)
    cancelCount, _ := c.redis.Get(ctx, cancelKey).Int64()

    if symbolCount > 5 && cancelCount > 0 {
        cancelRatio := float64(cancelCount) / float64(symbolCount)
        if cancelRatio > 0.8 {
            // 80% 以上的订单被取消 → Spoofing 嫌疑
            return ApproveWithWarning(
                "high cancel ratio for %s: %.0f%% (possible spoofing)", ord.Symbol, cancelRatio*100)
        }
    }

    return Approve()
}
```

#### 4.3.6 Gate 6: PDT Check (Pattern Day Trader 检查)

```go
type PDTCheck struct {
    pdtService PDTService
    accountService AccountService
}

func (c *PDTCheck) Name() string { return "PDTCheck" }

func (c *PDTCheck) Execute(ctx context.Context, ord *order.Order, account *Account) *Result {
    // 1. 仅适用于美股
    if ord.Market != "US" {
        return Approve()
    }

    // 2. 仅适用于保证金账户
    if account.Type != "MARGIN" {
        return Approve()
    }

    // 3. 净值 >= $25,000 → 豁免
    if account.Equity.GreaterThanOrEqual(decimal.NewFromInt(25000)) {
        return Approve()
    }

    // 4. 检查本次交易是否构成日内交易
    wouldCreateDT, err := c.pdtService.WouldCreateDayTrade(ctx, ord)
    if err != nil {
        return Reject("PDT check failed: %v", err)
    }

    if !wouldCreateDT {
        return Approve() // 不构成日内交易，放行
    }

    // 5. 统计过去 5 个工作日的日内交易次数
    dayTradeCount, err := c.pdtService.CountDayTrades(ctx, ord.AccountID, 5)
    if err != nil {
        return Reject("PDT count failed: %v", err)
    }

    // 本次如果执行，会增加一次日内交易
    projectedCount := dayTradeCount + 1

    // 6. PDT 规则: 5 个工作日内不超过 3 次
    if projectedCount > 3 {
        return Reject(
            "PDT restriction: this would be day trade #%d in 5 business days "+
            "(max 3 for accounts under $25,000; current equity: %s)",
            projectedCount, account.Equity.StringFixed(2))
    }

    // 7. 警告: 接近限制
    if projectedCount == 3 {
        return ApproveWithWarning(
            "PDT warning: this is your 3rd day trade in 5 business days. " +
            "One more will trigger PDT restriction.")
    }

    if projectedCount == 2 {
        return ApproveWithWarning(
            "PDT notice: %d day trades in 5 business days. " +
            "You have %d remaining before PDT restriction.",
            projectedCount, 3-projectedCount)
    }

    return Approve()
}
```

**日内交易判定算法**：

```go
// WouldCreateDayTrade 判断本次交易是否构成日内交易
//
// 定义: 同一标的在同一交易日内买入又卖出（或卖出又买入）
//
// 场景1: 今日已买入 AAPL，现在要卖出 → 构成日内交易
// 场景2: 今日已卖出 AAPL，现在要买入 → 构成日内交易
// 场景3: 之前买入 AAPL（非今日），今日卖出 → 不是日内交易
// 场景4: 今日买入 AAPL 又买入更多 → 不是日内交易（同方向）
func (s *pdtServiceImpl) WouldCreateDayTrade(ctx context.Context, ord *order.Order) (bool, error) {
    today := getTradingDate(time.Now().UTC(), ord.Market) // 考虑时区

    // 查询今日该标的该账户的已成交订单
    todayExecutions, err := s.executionRepo.GetByAccountSymbolDate(
        ctx, ord.AccountID, ord.Symbol, today)
    if err != nil {
        return false, fmt.Errorf("get today executions: %w", err)
    }

    // 检查是否有反向交易
    for _, exec := range todayExecutions {
        if exec.Side != string(ord.Side) {
            // 有反向成交 → 本次交易构成日内交易
            return true, nil
        }
    }

    // 还需要检查今日未成交但同方向的订单
    // 如果今日已买入，当前订单是卖出 → 构成
    // 如果今日已卖出，当前订单是买入 → 构成

    return false, nil
}
```

**日内交易计数算法**：

```go
// CountDayTrades 统计过去 N 个工作日内的日内交易次数
func (s *pdtServiceImpl) CountDayTrades(ctx context.Context, accountID int64, businessDays int) (int, error) {
    // 计算起始日期 (N 个工作日前)
    startDate := getNBusinessDaysAgo(businessDays)

    // 从 day_trade_counts 表查询
    var totalCount int
    rows, err := s.db.QueryContext(ctx,
        `SELECT COALESCE(SUM(count), 0)
         FROM day_trade_counts
         WHERE account_id = $1 AND trade_date >= $2`,
        accountID, startDate)
    if err != nil {
        return 0, fmt.Errorf("count day trades: %w", err)
    }
    defer rows.Close()

    if rows.Next() {
        rows.Scan(&totalCount)
    }

    return totalCount, nil
}
```

数据库表 `day_trade_counts`:
```sql
CREATE TABLE day_trade_counts (
    id          BIGSERIAL PRIMARY KEY,
    account_id  BIGINT NOT NULL,
    trade_date  DATE NOT NULL,
    symbol      TEXT NOT NULL,
    count       INT NOT NULL DEFAULT 1,
    UNIQUE (account_id, trade_date, symbol)
);
```

**PDT 判定决策树**：

```
  收到卖出订单 (AAPL, 美股, 保证金账户)
    │
    ▼
  账户净值 >= $25,000?
    │ YES → APPROVE (PDT 豁免)
    │ NO
    ▼
  今日是否已有 AAPL 的买入成交?
    │ NO → APPROVE (不构成日内交易)
    │ YES
    ▼
  过去 5 工作日的日内交易次数?
    │
    ├── 0-1 次 → APPROVE
    ├── 2 次   → APPROVE + WARNING ("第3次，再来1次触发PDT")
    ├── 3 次   → REJECT ("PDT 限制: 已达4次上限")
    └── 4+次   → REJECT ("PDT 限制: 已超过上限")
```

#### 4.3.7 Gate 7: Margin Check (保证金检查)

```go
type MarginCheck struct {
    marginEngine MarginEngine
}

func (c *MarginCheck) Name() string { return "MarginCheck" }

func (c *MarginCheck) Execute(ctx context.Context, ord *order.Order, account *Account) *Result {
    // 现金账户跳过保证金检查
    if account.Type != "MARGIN" {
        return Approve()
    }

    // 计算下单后的保证金需求
    marginReq, err := c.marginEngine.CalculateAfterOrder(ctx, account.ID, ord)
    if err != nil {
        return Reject("margin calculation failed: %v", err)
    }

    // 初始保证金检查
    if marginReq.InitialMarginRequired.GreaterThan(marginReq.AvailableMargin) {
        shortfall := marginReq.InitialMarginRequired.Sub(marginReq.AvailableMargin)
        return Reject(
            "insufficient margin: required %s, available %s, shortfall %s",
            marginReq.InitialMarginRequired.StringFixed(2),
            marginReq.AvailableMargin.StringFixed(2),
            shortfall.StringFixed(2))
    }

    // 维持保证金预警（不阻断，仅告警）
    if marginReq.PostOrderMaintenanceMargin.GreaterThan(
        marginReq.PostOrderEquity.Mul(decimal.NewFromFloat(0.80))) {
        // 维持保证金超过净值的 80% → 接近 Margin Call
        return ApproveWithWarning(
            "margin usage high: maintenance margin is %s%% of equity",
            marginReq.MaintenanceUsagePct.StringFixed(1))
    }

    return Approve()
}
```

**保证金计算引擎**：

```go
type MarginEngine struct {
    positionService PositionService
    quoteCache      QuoteCache
    marginRates     MarginRateService
}

func (e *MarginEngine) CalculateAfterOrder(
    ctx context.Context, accountID int64, ord *order.Order,
) (*MarginAfterOrder, error) {
    // 1. 获取当前所有持仓
    positions, err := e.positionService.ListByAccount(ctx, accountID)
    if err != nil {
        return nil, err
    }

    // 2. 计算当前保证金需求
    var currentInitial, currentMaintenance decimal.Decimal
    for _, pos := range positions {
        quote, _ := e.quoteCache.Get(pos.Symbol)
        marketValue := quote.LastPrice.Mul(decimal.NewFromInt(abs(pos.Quantity)))

        rate := e.marginRates.Get(pos.Symbol, pos.Market)
        currentInitial = currentInitial.Add(marketValue.Mul(rate.InitialRate))
        currentMaintenance = currentMaintenance.Add(marketValue.Mul(rate.MaintenanceRate))
    }

    // 3. 计算新订单的额外保证金需求
    orderPrice := e.getEstimatedPrice(ord)
    orderValue := orderPrice.Mul(decimal.NewFromInt(ord.Quantity))

    orderRate := e.marginRates.Get(ord.Symbol, ord.Market)
    additionalInitial := orderValue.Mul(orderRate.InitialRate)
    additionalMaintenance := orderValue.Mul(orderRate.MaintenanceRate)

    // 4. 计算净值和可用保证金
    equity := e.calculateEquity(ctx, accountID, positions)
    availableMargin := equity.Sub(currentInitial)

    return &MarginAfterOrder{
        TotalEquity:               equity,
        CurrentInitialMargin:      currentInitial,
        AdditionalInitialMargin:   additionalInitial,
        InitialMarginRequired:     additionalInitial,
        AvailableMargin:           availableMargin,
        PostOrderEquity:           equity, // 下单后净值不变（资金只是冻结）
        PostOrderMaintenanceMargin: currentMaintenance.Add(additionalMaintenance),
        MaintenanceUsagePct:        currentMaintenance.Add(additionalMaintenance).Div(equity).Mul(decimal.NewFromInt(100)),
    }, nil
}
```

#### 4.3.8 Gate 8: Post-Trade Check (交易后检查)

PostTradeCheck 是特殊的一环 -- 它是异步执行的，不阻断订单提交。它在成交后运行，生成告警但不拒绝订单。

```go
type PostTradeCheck struct {
    alertService AlertService
}

func (c *PostTradeCheck) Name() string { return "PostTradeCheck" }

// 在 Pre-Trade 阶段，PostTradeCheck 仅做预检
// 实际 Post-Trade 监控在成交后异步执行
func (c *PostTradeCheck) Execute(ctx context.Context, ord *order.Order, account *Account) *Result {
    // Pre-Trade 阶段的 PostTrade 预检:
    // 仅做预判，不阻断

    // 1. 大额交易预警（不拒绝）
    orderValue := estimateOrderValue(ord)
    if orderValue.GreaterThan(decimal.NewFromInt(100000)) {
        return ApproveWithWarning("large order: estimated value %s", orderValue.StringFixed(2))
    }

    return Approve()
}

// PostTradeMonitor 成交后异步监控（在 ExecutionHandler 中调用）
type PostTradeMonitor struct {
    alertService AlertService
    tradeHistory TradeHistoryService
    marginEngine MarginEngine
}

func (m *PostTradeMonitor) Monitor(ctx context.Context, exec *ExecutionReport) {
    // 1. 大额成交预警
    netAmount := exec.LastPx.Mul(decimal.NewFromInt(exec.LastQty))
    if netAmount.GreaterThan(decimal.NewFromInt(100000)) {
        m.alertService.Send(ctx, Alert{
            Type:      AlertLargeExecution,
            AccountID: exec.AccountID,
            Symbol:    exec.Symbol,
            Amount:    netAmount,
            Message:   fmt.Sprintf("Large execution: %s %d @ %s = %s",
                exec.Symbol, exec.LastQty, exec.LastPx.String(), netAmount.String()),
        })
    }

    // 2. Wash Trade 检测 (同一标的短时间内反向交易)
    if m.isWashTrade(ctx, exec) {
        m.alertService.Send(ctx, Alert{
            Type:      AlertWashTrade,
            AccountID: exec.AccountID,
            Symbol:    exec.Symbol,
            Message:   "Potential wash trade detected",
            Severity:  SeverityHigh,
        })
    }

    // 3. 维持保证金检查
    marginStatus, _ := m.marginEngine.CheckMaintenanceMargin(ctx, exec.AccountID)
    if marginStatus.MarginCallRequired {
        m.alertService.Send(ctx, Alert{
            Type:      AlertMarginCall,
            AccountID: exec.AccountID,
            Amount:    marginStatus.MarginCallAmount,
            Message: fmt.Sprintf("Margin call: need %s to meet maintenance requirement",
                marginStatus.MarginCallAmount.StringFixed(2)),
            Severity: SeverityCritical,
        })
    }

    // 4. Wash Sale 规则检测 (美股税务合规, IRS)
    if exec.Market == "US" && m.isWashSale(ctx, exec) {
        m.alertService.Send(ctx, Alert{
            Type:      AlertWashSale,
            AccountID: exec.AccountID,
            Symbol:    exec.Symbol,
            Message:   "Wash sale detected: loss may not be deductible (IRS 30-day rule)",
            Severity:  SeverityMedium,
        })
    }
}

// isWashTrade 检测 Wash Trade (刷单)
// 定义: 同一账户在短时间内（如 5 分钟）对同一标的执行多次反向交易，
// 且价格接近，本质上没有改变持仓的交易
func (m *PostTradeMonitor) isWashTrade(ctx context.Context, exec *ExecutionReport) bool {
    window := 5 * time.Minute
    recentExecs, _ := m.tradeHistory.GetRecentBySymbol(
        ctx, exec.AccountID, exec.Symbol, window)

    for _, recent := range recentExecs {
        if recent.Side != exec.Side { // 反向交易
            priceDiff := exec.LastPx.Sub(recent.Price).Abs()
            priceThreshold := exec.LastPx.Mul(decimal.NewFromFloat(0.001)) // 0.1%
            if priceDiff.LessThan(priceThreshold) {
                return true // 价格接近 + 反向 → Wash Trade 嫌疑
            }
        }
    }
    return false
}
```

---

## 5. 性能要求与设计决策

### 5.1 延迟预算

全部 8 道风控检查必须在 **5ms (p99)** 内完成。预算分配：

```
┌──────────────────────────────────────────────────────────┐
│  Check             │  预算 (p99)  │  瓶颈              │
├──────────────────────────────────────────────────────────┤
│  1. AccountCheck    │  0.3ms      │  Redis / AMS cache  │
│  2. SymbolCheck     │  0.3ms      │  Redis / 内存       │
│  3. BuyingPowerCheck│  1.5ms      │  Redis + DB 查询    │
│  4. PositionLimit   │  0.5ms      │  Redis / DB 查询    │
│  5. OrderRateCheck  │  0.2ms      │  Redis INCR         │
│  6. PDTCheck        │  1.0ms      │  DB 查询 (day_trade)│
│  7. MarginCheck     │  0.8ms      │  Redis + 计算       │
│  8. PostTradeCheck  │  0.4ms      │  计算 (预检)        │
├──────────────────────────────────────────────────────────┤
│  TOTAL              │  5.0ms      │                    │
└──────────────────────────────────────────────────────────┘
```

### 5.2 缓存策略

| 数据 | 缓存位置 | TTL | 失效策略 |
|------|----------|-----|----------|
| Account 信息 | Redis | 5 min | AMS 状态变更时 Pub/Sub 失效 |
| Symbol 信息 | 内存 (sync.Map) | 10 min | 每日 Pre-Market 全量刷新 |
| 行情数据 (Quote) | 内存 (QuoteCache) | 实时 | Market Data 推送更新 |
| 购买力 | Redis | 60 sec | 订单/成交/资金变动时主动失效 |
| 持仓数据 | Redis | 60 sec | 成交回报时主动失效 |
| PDT 计数 | DB (day_trade_counts) | - | 每日成交时更新 |
| Order Rate | Redis | 2 min | 自动过期 (滑动窗口) |

### 5.3 性能优化策略

1. **账户信息预加载**：OMS 在收到订单时，并行发起账户信息查询和订单校验，而不是串行等待
2. **行情数据本地缓存**：Market Data 通过 Kafka 推送到内存 QuoteCache，读取零延迟
3. **Redis Pipeline**：BuyingPowerCheck 需要多次 Redis 操作，使用 Pipeline 减少 RTT
4. **PDT 计数预计算**：成交后异步更新 day_trade_counts 表，PDTCheck 查询时直接 SUM
5. **保证金率预加载**：MarginRateService 启动时加载全量保证金率到内存

### 5.4 降级策略

当依赖服务不可用时：

| 依赖 | 不可用时的处理 |
|------|--------------|
| Redis 不可用 | 退化为 DB 查询（延迟升高但功能正确） |
| AMS 不可用 | 使用最近缓存的账户信息（TTL 内） |
| Market Data 不可用 | 市价单拒绝，限价单继续（使用限价作为估算） |
| DB 不可用 | 拒绝所有新订单（保护性拒绝） |

---

## 6. 接口设计 (gRPC / REST / Kafka Events)

### 6.1 gRPC 接口

风控引擎作为 Trading Engine 的内部模块，不直接暴露 gRPC 接口。但 `MarginService` 提供购买力查询：

```protobuf
service MarginService {
  // 查询保证金需求
  rpc GetMarginRequirement(GetMarginRequest) returns (MarginRequirement);

  // 检查购买力是否充足
  rpc CheckBuyingPower(CheckBuyingPowerRequest) returns (CheckBuyingPowerResponse);
}

message CheckBuyingPowerRequest {
  int64     account_id = 1;
  string    symbol = 2;
  Market    market = 3;
  OrderSide side = 4;
  int64     quantity = 5;
  string    price = 6;      // 限价 (string for precision)
}

message CheckBuyingPowerResponse {
  bool   sufficient = 1;     // 是否充足
  string buying_power = 2;   // 当前购买力
  string required_amount = 3; // 所需金额
  string shortfall = 4;      // 差额 (不足时)
}
```

### 6.2 REST API

客户端在下单前可以先查询购买力，避免提交后被拒绝：

| Method | Path | 说明 |
|--------|------|------|
| GET | /api/v1/accounts/{id}/buying-power | 查询购买力 |
| POST | /api/v1/accounts/{id}/buying-power/check | 预检购买力 |
| GET | /api/v1/accounts/{id}/margin | 查询保证金需求 |
| GET | /api/v1/accounts/{id}/pdt-status | 查询 PDT 状态 |

### 6.3 Kafka Events

风控相关事件：

| Topic | 触发条件 | 消费者 |
|-------|----------|--------|
| `order.risk_approved` | 风控全部通过 | Monitoring, Audit |
| `order.risk_rejected` | 风控拒绝 | Mobile Push, Monitoring |
| `risk.margin_call` | Margin Call 触发 | Mobile Push, Admin Panel, Email |
| `risk.pdt_warning` | PDT 计数接近限制 | Mobile Push |
| `risk.large_order` | 大额订单 | Compliance, Admin Panel |
| `risk.wash_trade_alert` | Wash Trade 嫌疑 | Compliance |

事件消息格式示例：

```json
// order.risk_rejected
{
  "event_id": "evt-abc-123",
  "event_type": "order.risk_rejected",
  "event_time": "2026-03-16T14:30:00.123Z",
  "payload": {
    "order_id": "ord-abc-123",
    "account_id": 12345,
    "symbol": "AAPL",
    "market": "US",
    "side": "BUY",
    "quantity": 100,
    "price": "150.25",
    "rejected_by": "BuyingPowerCheck",
    "reason": "insufficient buying power: need 15,075.50, available 10,000.00",
    "risk_result": {
      "checks": [
        {"name": "AccountCheck", "approved": true},
        {"name": "SymbolCheck", "approved": true},
        {"name": "BuyingPowerCheck", "approved": false,
         "reason": "insufficient buying power: need 15,075.50, available 10,000.00",
         "details": {"required": "15075.50", "available": "10000.00"}}
      ]
    }
  }
}
```

---

## 7. 开源参考实现

### 7.1 风控系统参考

| 项目 | 语言 | 说明 |
|------|------|------|
| [alpaca-trade-api](https://github.com/alpacahq/alpaca-trade-api-go) | Go | Alpaca 的交易 API，包含 PDT 和 buying power 逻辑参考 |
| [IB Gateway](https://www.interactivebrokers.com/) | - | Interactive Brokers 的风控文档是行业标杆 |
| [robinhood-engineering](https://engineering.robinhood.com/) | - | Robinhood 工程博客，有风控架构分享 |

### 7.2 金融规则参考

| 资源 | 说明 |
|------|------|
| [FINRA Rule 4210](https://www.finra.org/rules-guidance/rulebooks/finra-rules/4210) | 保证金要求官方规则 |
| [Reg T (12 CFR 220)](https://www.law.cornell.edu/cfr/text/12/part-220) | 联邦储备理事会信用额度规定 |
| [Reg SHO](https://www.sec.gov/spotlight/shortsales/regsho.htm) | SEC 卖空规则 |
| [FINRA PDT FAQ](https://www.finra.org/investors/learn-to-invest/advanced-investing/day-trading-margin-requirements-know-rules) | PDT 规则常见问答 |
| [SFC 证券保证金融资指引](https://www.sfc.hk/web/TC/rules-and-standards/guidelines/) | 港股保证金规则 |
| [HKEX 交易规则](https://www.hkex.com.hk/Services/Rules-and-Forms-and-Fee/Rules/SEHK/Rules-of-the-Exchange) | 港交所交易规则 |

### 7.3 技术组件参考

| 项目 | 语言 | 说明 |
|------|------|------|
| [shopspring/decimal](https://github.com/shopspring/decimal) | Go | 金额计算必用 |
| [go-redis/redis](https://github.com/redis/go-redis) | Go | Redis 客户端 (Pipeline 支持) |
| [uber-go/ratelimit](https://github.com/uber-go/ratelimit) | Go | Uber 的速率限制器 |
| [sony/gobreaker](https://github.com/sony/gobreaker) | Go | Circuit Breaker 实现 |

---

## 8. PRD Review 检查清单

### 8.1 功能完整性

- [ ] 8 道风控检查是否全部实现？
- [ ] 短路模式是否正确实现（任一失败立即终止）？
- [ ] 购买力计算是否区分了现金账户和保证金账户？
- [ ] 市价单的成本估算是否使用了 AskPrice * 1.02 缓冲？
- [ ] PDT 规则是否完整实现（5 工作日、$25K 豁免、现金账户跳过）？
- [ ] 港股 PDT 检查是否正确跳过？
- [ ] 保证金检查是否区分了美股 (Reg T 50%) 和港股 (SFC 分级)？
- [ ] 持仓集中度检查是否实现 (30% 限制)？
- [ ] Order Rate 检查是否有全局和单标的两个维度？

### 8.2 数据精度

- [ ] 所有金额计算是否使用 `shopspring/decimal`？
- [ ] 购买力缓存失效逻辑是否完整？
- [ ] 保证金率配置是否可按标的调整？
- [ ] PDT 计数是否基于「工作日」而非「自然日」？
- [ ] 费用预估是否考虑了美股和港股的不同费率？

### 8.3 合规完整性

- [ ] Reg T 50% 初始保证金是否严格执行？
- [ ] FINRA 25% 维持保证金是否检查？
- [ ] Reg SHO Locate Requirement 是否实现？
- [ ] PDT $25,000 净值门槛是否正确？
- [ ] SFC 分级保证金率是否可配置？
- [ ] 风控结果是否完整记录在 `orders.risk_result` JSONB 中？
- [ ] 风控拒绝是否记录在 `order_events` 中？

### 8.4 性能与可靠性

- [ ] 全部 8 道检查是否能在 5ms (p99) 内完成？
- [ ] Redis 不可用时是否有降级策略？
- [ ] 购买力缓存 TTL 是否合理 (建议 60s)？
- [ ] 是否有足够的 Prometheus 指标监控每道检查的延迟？
- [ ] 风控检查失败是否有详细的结构化日志？

### 8.5 边界条件

- [ ] 零持仓卖出（卖空）是否正确处理？
- [ ] 账户刚好 $25,000 净值时 PDT 是否通过？(>= 25000 → 通过)
- [ ] 购买力刚好等于订单成本时是否通过？(<= → 通过)
- [ ] GTC 订单的购买力是否在每日盘前重新检查？
- [ ] 多笔订单并发提交时，购买力是否正确扣减？

---

## 9. 工程落地注意事项

### 9.1 风控检查注册

```go
func NewRiskEngine(deps Dependencies) risk.Engine {
    engine := risk.NewEngine(deps.AccountService)

    // 按顺序注册 8 道检查
    engine.RegisterCheck(NewAccountCheck())
    engine.RegisterCheck(NewSymbolCheck(deps.SymbolService, deps.CalendarService))
    engine.RegisterCheck(NewBuyingPowerCheck(deps.BalanceService, deps.QuoteCache, deps.FeeCalculator))
    engine.RegisterCheck(NewPositionLimitCheck(deps.PositionService, deps.QuoteCache, deps.RiskConfig))
    engine.RegisterCheck(NewOrderRateCheck(deps.Redis, deps.RateConfig))
    engine.RegisterCheck(NewPDTCheck(deps.PDTService, deps.AccountService))
    engine.RegisterCheck(NewMarginCheck(deps.MarginEngine))
    engine.RegisterCheck(NewPostTradeCheck(deps.AlertService))

    return engine
}
```

### 9.2 购买力并发扣减

当同一账户并发提交多笔买入订单时，购买力可能被重复使用。解决方案：

```go
// 方案1: Redis 原子扣减 (推荐)
func (c *BuyingPowerCheck) atomicDeduction(
    ctx context.Context, accountID int64, amount decimal.Decimal,
) (bool, error) {
    key := fmt.Sprintf("buying_power_lock:%d", accountID)

    // 使用 Lua Script 确保原子性
    script := redis.NewScript(`
        local current = tonumber(redis.call('GET', KEYS[1]) or '0')
        local deduction = tonumber(ARGV[1])
        if current >= deduction then
            redis.call('DECRBY', KEYS[1], ARGV[1])
            return 1
        end
        return 0
    `)

    result, err := script.Run(ctx, c.redis, []string{key}, amount.String()).Int()
    if err != nil {
        return false, err
    }
    return result == 1, nil
}

// 方案2: 数据库行级锁 (更安全但更慢)
// SELECT ... FOR UPDATE 锁定余额行，确保串行化
```

### 9.3 保证金率配置

保证金率应该可配置且可按标的覆盖：

```go
type MarginRateService struct {
    defaultRates map[string]MarginRate // market -> rate
    overrides    map[string]MarginRate // symbol -> rate
}

type MarginRate struct {
    InitialRate     decimal.Decimal // 初始保证金率
    MaintenanceRate decimal.Decimal // 维持保证金率
}

func (s *MarginRateService) Get(symbol, market string) MarginRate {
    // 先查标的级别覆盖
    if rate, ok := s.overrides[symbol]; ok {
        return rate
    }

    // 再查市场默认
    if rate, ok := s.defaultRates[market]; ok {
        return rate
    }

    // 最保守的默认值
    return MarginRate{
        InitialRate:     decimal.NewFromFloat(1.0), // 100%
        MaintenanceRate: decimal.NewFromFloat(1.0),
    }
}
```

### 9.4 工作日计算

PDT 规则需要计算「工作日」。必须排除美国联邦假期：

```go
var usHolidays2026 = []time.Time{
    time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),   // New Year's Day
    time.Date(2026, 1, 19, 0, 0, 0, 0, time.UTC),  // MLK Day
    time.Date(2026, 2, 16, 0, 0, 0, 0, time.UTC),  // Presidents' Day
    time.Date(2026, 4, 3, 0, 0, 0, 0, time.UTC),   // Good Friday
    time.Date(2026, 5, 25, 0, 0, 0, 0, time.UTC),  // Memorial Day
    time.Date(2026, 6, 19, 0, 0, 0, 0, time.UTC),  // Juneteenth
    time.Date(2026, 7, 3, 0, 0, 0, 0, time.UTC),   // Independence Day (observed)
    time.Date(2026, 9, 7, 0, 0, 0, 0, time.UTC),   // Labor Day
    time.Date(2026, 11, 26, 0, 0, 0, 0, time.UTC), // Thanksgiving
    time.Date(2026, 12, 25, 0, 0, 0, 0, time.UTC), // Christmas
}

func isUSBusinessDay(t time.Time) bool {
    // 排除周末
    if t.Weekday() == time.Saturday || t.Weekday() == time.Sunday {
        return false
    }
    // 排除联邦假期
    for _, h := range usHolidays2026 {
        if t.Year() == h.Year() && t.YearDay() == h.YearDay() {
            return false
        }
    }
    return true
}

func getNBusinessDaysAgo(n int) time.Time {
    t := time.Now().UTC()
    count := 0
    for count < n {
        t = t.AddDate(0, 0, -1)
        if isUSBusinessDay(t) {
            count++
        }
    }
    return t
}
```

**注意**：假期表应该从外部配置加载，而非硬编码。每年 NYSE/NASDAQ 会提前公布假期安排。

### 9.5 Prometheus 监控

```go
var (
    riskCheckDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "trading_risk_check_duration_seconds",
            Help:    "Duration of each risk check",
            Buckets: []float64{0.0001, 0.0005, 0.001, 0.002, 0.005, 0.01},
        },
        []string{"check_name", "result"}, // result: approved/rejected
    )

    riskCheckTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "trading_risk_check_total",
            Help: "Total number of risk checks executed",
        },
        []string{"check_name", "result"},
    )

    riskPipelineDuration = prometheus.NewHistogram(
        prometheus.HistogramOpts{
            Name:    "trading_risk_pipeline_duration_seconds",
            Help:    "Total duration of the entire risk pipeline",
            Buckets: []float64{0.001, 0.002, 0.003, 0.005, 0.01, 0.025},
        },
    )

    buyingPowerCacheHitRate = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "trading_buying_power_cache",
            Help: "Buying power cache hit/miss",
        },
        []string{"result"}, // hit/miss
    )

    pdtDayTradeCount = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "trading_pdt_day_trade_count",
            Help: "Current day trade count per account",
        },
        []string{"account_id"},
    )
)
```

### 9.6 告警规则

| 告警 | 条件 | 级别 | 通知方式 |
|------|------|------|----------|
| 风控延迟超标 | p99 > 5ms 持续 1 分钟 | P1 | PagerDuty + Slack |
| 风控拒绝率飙升 | 拒绝率 > 50% 持续 5 分钟 | P2 | Slack + Email |
| Margin Call 触发 | 任意账户 | P2 | 短信 + Push + Email |
| 购买力缓存命中率低 | < 80% 持续 5 分钟 | P3 | Slack |
| PDT 违规 | 账户被标记为 PDT | P2 | Admin Panel + Email |
| 大额交易 | 单笔 > $100K | P3 | Compliance Slack |
| Wash Trade 嫌疑 | 检测到 | P2 | Compliance + Email |

### 9.7 测试策略

| 测试类型 | 覆盖范围 |
|----------|----------|
| **单元测试** | 每道 Check 的独立测试（mock dependencies）|
| **购买力计算测试** | 各种账户类型 x 订单类型的组合 |
| **PDT 计数测试** | 边界条件：0/1/2/3/4 次日内交易 |
| **保证金计算测试** | 美股 50% + 港股分级 |
| **集成测试** | 完整 pipeline: 8 道检查串行执行 |
| **并发测试** | 同一账户并发下单的购买力竞争 |
| **压力测试** | 10K orders/sec 下的风控延迟 |
| **降级测试** | Redis 不可用时的退化行为 |

关键测试用例：

```go
func TestBuyingPowerCheck_CashAccount_Sufficient(t *testing.T) {
    // 现金账户，余额 $50,000，买入 100 AAPL @ $150 = $15,000 + fees
    // 预期: 通过
}

func TestBuyingPowerCheck_CashAccount_Insufficient(t *testing.T) {
    // 现金账户，余额 $10,000，买入 100 AAPL @ $150 = $15,000 + fees
    // 预期: 拒绝 "insufficient buying power"
}

func TestBuyingPowerCheck_MarketOrder_UseAskPriceBuffer(t *testing.T) {
    // 市价单，Ask = $150，应使用 $150 * 1.02 = $153 估算
    // 预期: 使用 $153 * qty + fees 作为 required amount
}

func TestPDTCheck_ThirdDayTrade_Warning(t *testing.T) {
    // 保证金账户，净值 $20,000 (< $25K)
    // 过去 5 天已有 1 次日内交易
    // 本次交易构成第 2 次日内交易
    // 预期: 通过 + 警告
}

func TestPDTCheck_FourthDayTrade_Rejected(t *testing.T) {
    // 保证金账户，净值 $20,000 (< $25K)
    // 过去 5 天已有 3 次日内交易
    // 本次交易构成第 4 次日内交易
    // 预期: 拒绝 "PDT restriction"
}

func TestPDTCheck_HKMarket_AlwaysApprove(t *testing.T) {
    // 港股订单
    // 预期: 直接通过（PDT 不适用于港股）
}

func TestPDTCheck_CashAccount_AlwaysApprove(t *testing.T) {
    // 美股现金账户
    // 预期: 直接通过（PDT 仅适用于保证金账户）
}

func TestPDTCheck_EquityAbove25K_AlwaysApprove(t *testing.T) {
    // 保证金账户，净值 $30,000 (>= $25K)
    // 即使已有 10 次日内交易
    // 预期: 直接通过（$25K 豁免）
}

func TestMarginCheck_USStock_RegT50Percent(t *testing.T) {
    // 美股保证金账户
    // 买入 $10,000 市值 → 需要 $5,000 保证金
    // 预期: 检查 $5,000 <= AvailableMargin
}

func TestMarginCheck_HKStock_TieredRate(t *testing.T) {
    // 港股保证金账户
    // 买入腾讯 (蓝筹, 25% 保证金) $100,000 → 需要 $25,000 保证金
    // 预期: 检查 $25,000 <= AvailableMargin
}

func TestRiskPipeline_ShortCircuit(t *testing.T) {
    // AccountCheck 失败 (账户冻结)
    // 预期: 后续 7 道检查不执行
    // 验证: 只有 AccountCheck 的指标被记录
}

func TestRiskPipeline_AllPass_Under5ms(t *testing.T) {
    // 所有检查通过
    // 预期: 总耗时 < 5ms
    // 验证: Prometheus histogram 记录正确
}
```

### 9.8 常见陷阱

1. **购买力缓存和实际扣减的竞态**：两笔订单同时读取缓存得到相同购买力，都认为充足，但实际只够一笔。解决方案：Redis 原子扣减或数据库悲观锁。

2. **PDT 计数的时区问题**：日内交易的「同一天」指的是美国东部时间的交易日，不是 UTC 日期。必须正确转换时区。

3. **保证金率变更**：保证金率可能被券商调整（如市场波动大时提高保证金）。变更后必须重新计算所有相关账户的保证金需求并可能触发 Margin Call。

4. **GTC 订单的持续影响**：GTC 订单在未成交期间持续冻结购买力。每日盘前应该重新评估 GTC 订单是否仍然满足风控要求（特别是在标的价格大幅变动后）。

5. **卖空的特殊处理**：卖空订单不扣减购买力（反而增加 -- 卖空所得计入余额），但需要冻结保证金。BuyingPowerCheck 对卖空的逻辑与买入完全不同。

6. **多币种购买力**：如果用户同时持有 USD 和 HKD，购买力需要考虑币种转换。美股订单用 USD 购买力，港股订单用 HKD 购买力。跨币种的购买力计算需要实时汇率。

7. **Wash Sale 的 30 天窗口**：IRS Wash Sale Rule 禁止在亏损卖出后 30 天内买回同一证券并抵扣税损。这不是交易阻断规则，但需要在 PostTrade 阶段标记并影响税务报告。

8. **OrderRateCheck 的窗口滑动**：当前使用固定分钟窗口 (`now / 60`)。这意味着在窗口边界处可能出现突发（如第 59 秒提交 10 单 + 第 01 秒提交 10 单 = 2 秒内 20 单但分别在两个窗口内）。更精确的方案是 Sliding Window（如 Redis ZSET + ZRANGEBYSCORE），但增加了复杂度和延迟。

---

> 本文档最后更新: 2026-03-16
> 对应代码版本: `src/internal/risk/risk.go`, `src/migrations/001_init_trading.sql`, `docs/specs/trading-system.md`
