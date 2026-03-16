# 智能订单路由 (Smart Order Routing) 深度调研

> Trading Engine Sub-domain: Smart Order Routing (SOR)
> 最后更新: 2026-03-16

---

## 1. 业务概述

### 1.1 什么是智能订单路由

智能订单路由 (Smart Order Routing, SOR) 是交易系统中负责**为每一笔订单选择最佳执行场所**的核心子系统。当用户提交一个买入 AAPL 100股的限价单时，SOR 必须在毫秒级别内决定：把这笔订单发送到 NYSE、NASDAQ、ARCA、BATS 还是 IEX？或者拆分成多笔子单分别发送到不同交易所？

SOR 不是简单的"看哪便宜发哪里"——它是一个多维度优化问题，需要综合考虑：

- **价格 (Price)**: 当前各 Venue 的最优报价
- **流动性深度 (Liquidity Depth)**: Order Book 的深度和可用数量
- **交易费用 (Cost)**: Maker-Taker 费率结构、交易所返佣
- **延迟 (Latency)**: 到各 Venue 的网络延迟
- **历史成交率 (Fill Rate)**: 该 Venue 对该类型订单的历史成交概率
- **市场冲击 (Market Impact)**: 大单对市场价格的影响

### 1.2 SOR 在系统中的位置

```
用户下单请求
    │
    ▼
┌──────────────┐
│ Order Validator │  格式校验、市场时段校验
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Risk Engine  │  购买力、持仓限额、PDT、保证金
└──────┬───────┘
       │ 风控通过
       ▼
┌══════════════╗
║  SOR Engine   ║  ◄── 本文的主角
║  (路由决策)    ║
╚══════╤═══════╝
       │ RoutingDecision
       ▼
┌──────────────┐
│  FIX Engine   │  发送到交易所
└──────────────┘
```

在现有代码中，SOR 的接口定义在 `src/internal/routing/router.go`:

```go
// Router 智能订单路由接口
type Router interface {
    Route(ctx context.Context, ord *order.Order) (*Decision, error)
}

type Decision struct {
    Venue         string          // "NYSE" / "NASDAQ" / "HKEX"
    Price         decimal.Decimal // tick-aligned price
    Quantity      int64
    EstimatedCost decimal.Decimal
    Reason        string          // for compliance audit
}
```

### 1.3 美股 vs 港股路由复杂度

| 维度 | 美股 (US) | 港股 (HK) |
|------|-----------|-----------|
| 交易所数量 | 16+ (NYSE, NASDAQ, ARCA, BATS, IEX, EDGX...) | 1 (HKEX) |
| SOR 复杂度 | 高: 多 Venue 竞争，需要多维评分 | 低: 单一 Venue，直接路由 |
| 监管要求 | Reg NMS Best Execution 强制义务 | SFC Code of Conduct 最优执行原则 |
| 费率结构 | Maker-Taker 模型 (部分 Venue 反转) | 统一费率 |
| 暗池 | 允许，受 Reg ATS 监管 | 极少，HKEX 有 Dark Pool 但非主流 |
| Order Book 访问 | 需订阅各 Venue 的 L2 数据 | 单一 HKEX Order Book |

### 1.4 核心业务流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SOR 路由决策完整流程                               │
│                                                                     │
│  Order ──▶ [1. 市场识别] ──▶ [2. Venue 可用性检查]                    │
│                                      │                              │
│                              ┌───────┴───────┐                      │
│                              ▼               ▼                      │
│                         US Market        HK Market                  │
│                              │               │                      │
│                              ▼               ▼                      │
│                    [3. 获取各 Venue      [直接路由到 HKEX]            │
│                     实时报价 (NBBO)]          │                      │
│                              │               │                      │
│                              ▼               │                      │
│                    [4. Reg NMS 合规检查]      │                      │
│                    (禁止 Trade-Through)       │                      │
│                              │               │                      │
│                              ▼               │                      │
│                    [5. 多因子评分计算]         │                      │
│                    Price × 0.50              │                      │
│                    Liquidity × 0.25          │                      │
│                    Cost × 0.15               │                      │
│                    Latency × 0.10            │                      │
│                              │               │                      │
│                              ▼               │                      │
│                    [6. 大单判断]              │                      │
│                    需要拆单? VWAP/TWAP?       │                      │
│                              │               │                      │
│                              ▼               ▼                      │
│                    [7. Tick Size 对齐]                               │
│                              │                                      │
│                              ▼                                      │
│                    [8. 生成 RoutingDecision]                         │
│                    (含 Reason 审计字段)                               │
│                              │                                      │
│                              ▼                                      │
│                    [9. 记录路由日志]                                  │
│                    (合规留存 7 年)                                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. 监管与合规要求

### 2.1 美股: Regulation NMS (National Market System)

Reg NMS 是 SEC 在 2005 年颁布、2007 年全面实施的一组规则，旨在确保投资者获得最优执行价格。对 SOR 影响最大的是以下三条规则：

#### Rule 611 — Order Protection Rule (Trade-Through Rule)

**核心含义**: 禁止在一个交易所以劣于另一个交易所公布的最优价格（Protected Quote）的价格执行交易。

```
例子:
  NYSE Best Ask = $150.00
  NASDAQ Best Ask = $149.98
  ARCA Best Ask = $150.01

  用户下市价买单:
    ✅ 正确: 路由到 NASDAQ ($149.98 是 NBO)
    ❌ 违规: 路由到 NYSE ($150.00 > $149.98, 构成 Trade-Through)
    ❌ 违规: 路由到 ARCA ($150.01 > $149.98, 构成 Trade-Through)
```

**Protected Quote 定义**:
- 来自 NMS Exchange (SRO) 的自动可执行报价
- 不包括手动报价 (manual quote)
- 不包括 Sub-Penny 报价 (< $0.01 for stocks > $1)

**SOR 必须做的事**:
1. 在路由前获取 NBBO (National Best Bid and Offer)
2. 确保路由目标的执行价格不劣于 NBBO
3. 如果目标 Venue 价格劣于 NBBO，必须 re-route 到报价更优的 Venue
4. 保留完整的路由决策记录（为什么选了这个 Venue）

**Trade-Through 豁免情形**:
- ISO (Intermarket Sweep Order): 同时向多个 Venue 发送 sweep 订单
- Flickering Quote: 报价在决策和执行之间发生变化（毫秒级窗口）
- Self-Help: 对方 Venue 系统故障时
- Benchmark Trades: VWAP、TWAP 等算法单
- Sub-Penny Improvement: 提供至少 sub-penny 的价格改善

#### Rule 610 — Access Rule

**核心含义**: 确保所有市场参与者可以合理地访问其他交易所的报价。

- 交易所对 "Access Fee" 有上限: $0.0030/share（对于 > $1.00 的股票）
- 不得对访问其报价收取不合理的费用
- SOR 可以合法地获取各 Venue 的报价并发送订单

#### Rule 606 — Order Routing Disclosure

**核心含义**: Broker-Dealer 必须定期公开披露其订单路由行为。

- **季度报告**: 披露每个月将 non-directed orders 路由到了哪些 Venue
- **统计维度**: Market Order vs Limit Order, S&P 500 vs Others
- **Payment for Order Flow (PFOF)**: 必须披露从 Venue 收到的返佣/PFOF 金额
- **SOR 影响**: 路由决策日志必须完整保留，支持生成 606 报告

### 2.2 NBBO (National Best Bid and Offer) 详解

NBBO 是 Reg NMS 的核心概念，代表全市场的最优买卖报价。

#### NBBO 计算逻辑

```
NBBO Calculation:

  National Best Bid (NBB) = MAX(所有 NMS Exchange 的 Best Bid)
  National Best Offer (NBO) = MIN(所有 NMS Exchange 的 Best Ask)

  例子:
  ┌──────────┬────────────┬────────────┐
  │  Venue   │  Best Bid  │  Best Ask  │
  ├──────────┼────────────┼────────────┤
  │  NYSE    │  $149.95   │  $150.02   │
  │  NASDAQ  │  $149.97   │  $149.98   │  ◄ NBO (最低 Ask)
  │  ARCA    │  $149.98   │  $150.00   │  ◄ NBB (最高 Bid)
  │  BATS    │  $149.96   │  $149.99   │
  │  IEX     │  $149.94   │  $150.01   │
  └──────────┴────────────┴────────────┘

  NBBO = Bid $149.98 (ARCA) × Ask $149.98 (NASDAQ)
  Spread = $0.00 (locked market)
```

#### NBBO 数据来源

- **SIP (Securities Information Processor)**: CTA/UTP 合并行情
  - CTA Plan: NYSE-listed 股票的合并行情
  - UTP Plan: NASDAQ-listed 股票的合并行情
  - 延迟: 通常 1-5ms
- **Direct Feed**: 直接从各交易所获取行情
  - 延迟更低（< 1ms），但需要自行聚合计算 NBBO
  - 成本更高，需要与每个交易所签订数据协议

**SOR 实现建议**: 使用 Market Data 服务提供的合并行情，该服务已经聚合了各 Venue 的报价。通过 gRPC 调用 `MarketData.GetVenueQuotes(symbol)` 获取。

### 2.3 港股: SFC Code of Conduct 最优执行义务

香港证监会 (SFC) 的《证券及期货事务监察委员会持牌人或注册人操守准则》(Code of Conduct) 对最优执行有以下要求:

#### Paragraph 3.2 — Best Execution

- Broker 应当采取一切合理步骤，以客户最佳利益行事
- 在执行客户订单时，应当取得最佳可得的执行结果
- **关键差异**: 没有 Reg NMS 那样严格的 Trade-Through 禁令
- HKEX 是唯一主要交易所，路由决策简单

#### 港股 SOR 的简化逻辑

```go
// 港股路由: 直接发送到 HKEX
func (r *Router) routeHK(ctx context.Context, ord *order.Order) (*Decision, error) {
    // 1. 检查 HKEX 连接状态
    if r.fixEngine.SessionStatus("HKEX") != fix.SessionLoggedOn {
        return nil, fmt.Errorf("HKEX session not available")
    }

    // 2. Tick Size 对齐
    alignedPrice := r.alignHKTickSize(ord.Price)

    // 3. Lot Size 对齐 (港股必须整手交易)
    // 注: 这在 Order Validator 阶段已经校验过

    return &Decision{
        Venue:    "HKEX",
        Price:    alignedPrice,
        Quantity: ord.Quantity,
        Reason:   "HK market: single venue HKEX",
    }, nil
}
```

### 2.4 合规记录保留要求

| 记录类型 | 保留期限 | 法规依据 |
|---------|---------|---------|
| 路由决策日志 (每笔订单) | 7 年 | SEC Rule 17a-4(b)(1) |
| Venue 评分详情 | 7 年 | SEC Rule 17a-4 |
| NBBO 快照 (决策时刻) | 7 年 | Reg NMS Rule 611 |
| 606 报告数据 | 3 年 | SEC Rule 606 |
| 路由策略变更记录 | 7 年 | Internal compliance |

**实现**: 路由决策写入 `order_events` 表（Event Sourcing），`event_type = 'ROUTED'`, `event_data` 包含完整的 `Decision` JSON + NBBO 快照。

---

## 3. 市场差异 (US vs HK)

### 3.1 交易所生态

#### 美股交易所 (NMS Exchanges)

| 交易所 | 代码 | 费率模型 | Maker Fee | Taker Fee | 特点 |
|--------|------|---------|-----------|-----------|------|
| NYSE | NYSE | Maker-Taker | -$0.0020 (rebate) | +$0.0025 | 上市所，开盘/收盘竞价主导 |
| NASDAQ | NSDQ | Maker-Taker | -$0.0020 (rebate) | +$0.0030 | 科技股主阵地 |
| NYSE Arca | ARCA | Maker-Taker | -$0.0020 (rebate) | +$0.0030 | ETF 交易量大 |
| Cboe EDGX | EDGX | Maker-Taker | -$0.0032 (rebate) | +$0.0030 | 高返佣吸引 Maker |
| Cboe BZX | BATS | Maker-Taker | -$0.0025 (rebate) | +$0.0030 | 第二大交易所 |
| IEX | IEX | Flat | $0.0000 | +$0.0009 | "Speed Bump" 350us延迟，反 HFT |
| Cboe BYX | BYX | Inverted | +$0.0005 (taker rebate) | -$0.0018 (maker pays) | 反转费率模型 |
| MEMX | MEMX | Flat | $0.0000 | +$0.0003 | 最低费率交易所 |

> **Maker-Taker 解释**: Maker (挂单方，提供流动性) 获得返佣；Taker (吃单方，消耗流动性) 支付费用。限价单通常是 Maker；市价单一定是 Taker。

> **Inverted Model 解释**: BYX 等少数交易所反转费率——Taker 获得返佣，Maker 付费。对于追求低成本的大额市价单有利。

#### 港股交易所

| 交易所 | 代码 | 特点 |
|--------|------|------|
| HKEX (联交所) | HKEX | 唯一主要交易所 |

港股没有美股那样复杂的多 Venue 竞争，费率统一。

### 3.2 Tick Size (最小变动价位)

#### 美股 Tick Size

```
价格 >= $1.00:  Tick Size = $0.01
价格 <  $1.00:  Tick Size = $0.0001

例外: Tick Size Pilot Program (已结束) 部分股票曾使用 $0.05 tick
```

#### 港股 Tick Size (HKEX Tick Size Table)

```
┌───────────────────┬──────────────┐
│    价格区间 (HKD)  │  Tick Size   │
├───────────────────┼──────────────┤
│  0.01 - 0.25      │    0.001     │
│  0.25 - 0.50      │    0.005     │
│  0.50 - 10.00     │    0.010     │
│  10.00 - 20.00    │    0.020     │
│  20.00 - 100.00   │    0.050     │
│  100.00 - 200.00  │    0.100     │
│  200.00 - 500.00  │    0.200     │
│  500.00 - 1000.00 │    0.500     │
│  1000.00 - 2000.00│    1.000     │
│  2000.00 - 5000.00│    2.000     │
│  5000.00 - 9995.00│    5.000     │
└───────────────────┴──────────────┘
```

**SOR 职责**: 在路由前确保订单价格已对齐到 Tick Size。如果用户提交的限价不在 Tick Size 网格上，SOR 需要向下取整（买单）或向上取整（卖单）。

```go
// alignTickSize 将价格对齐到最近的合法 Tick
func alignTickSize(price decimal.Decimal, market string) decimal.Decimal {
    if market == "HK" {
        return alignHKTickSize(price)
    }
    // US: $1+ → $0.01 tick, <$1 → $0.0001 tick
    if price.GreaterThanOrEqual(decimal.NewFromInt(1)) {
        return price.Div(decimal.NewFromFloat(0.01)).Floor().Mul(decimal.NewFromFloat(0.01))
    }
    return price.Div(decimal.NewFromFloat(0.0001)).Floor().Mul(decimal.NewFromFloat(0.0001))
}
```

### 3.3 Lot Size (最小交易单位)

| 市场 | 规则 |
|------|------|
| 美股 | 1 股 (支持碎股/fractional share 取决于 broker) |
| 港股 | 按标的不同，每手股数不同 (100/200/400/500/1000/...) |

港股碎股 (Odd Lot) 只能在碎股交易市场交易，通常以折价成交。SOR 在订单验证阶段已确认 Lot Size 合规，但路由时仍需确认。

### 3.4 交易时段对比

```
                  美股 (Eastern Time)
  ├─────────┼──────────────────┼──────────────────┤
  04:00    09:30              16:00              20:00
  Pre-Market   Regular Session     After-Hours

  盘前/盘后: 仅限价单，流动性较差

                  港股 (Hong Kong Time)
  ├───────┼─────────┼─────┼─────────┼──────┤
  09:00  09:30    12:00 13:00    16:00 16:10
  开市    上午连续   午休  下午连续  收市竞价
  竞价    交易           交易      时段

  午休时段: 不接受新订单
  收市竞价: 仅限竞价限价单
```

### 3.5 费用计算对比

#### 美股费用 (每笔交易)

```
总费用 = Commission + Exchange Fee/Rebate + SEC Fee + FINRA TAF

其中:
  Commission:    $0.005/share (平台佣金，可配置)
  Exchange Fee:  因 Venue 和 Maker/Taker 而异 (见 3.1 表格)
  SEC Fee:       $0.0000278 × 成交金额 (仅卖出)
  FINRA TAF:     $0.000166/share (仅卖出, max $8.30)

例子: 买入 100 股 AAPL @ $150.00 via NASDAQ (Taker)
  Commission:    100 × $0.005    = $0.50
  Exchange Fee:  100 × $0.003    = $0.30 (Taker fee)
  SEC Fee:       N/A (买入不收)
  FINRA TAF:     N/A (买入不收)
  总费用:                         = $0.80

例子: 卖出 100 股 AAPL @ $150.00 via NASDAQ (Taker)
  Commission:    100 × $0.005    = $0.50
  Exchange Fee:  100 × $0.003    = $0.30
  SEC Fee:       $15,000 × 0.0000278 = $0.42
  FINRA TAF:     100 × $0.000166 = $0.02
  总费用:                         = $1.24
```

#### 港股费用 (每笔交易)

```
总费用 = 佣金 + 印花税 + 交易征费 + 交易费 + 中央结算费 + 平台费

其中:
  佣金:        0.03% (min HK$3)
  印花税:      0.13% (双向, 不足 $1 按 $1 计)
  交易征费:    0.0027% (SFC)
  交易费:      0.00565% (HKEX)
  中央结算费:  0.002% (min HK$2, max HK$100)
  平台费:      HK$0.50/笔

例子: 买入 100 股 0700.HK (腾讯) @ HK$350.00
  成交金额:     100 × HK$350   = HK$35,000
  佣金:         HK$35,000 × 0.03%  = HK$10.50
  印花税:       HK$35,000 × 0.13%  = HK$46 (向上取整)
  交易征费:     HK$35,000 × 0.0027% = HK$0.95
  交易费:       HK$35,000 × 0.00565% = HK$1.98
  中央结算费:   HK$35,000 × 0.002%  = HK$2.00 (min HK$2)
  平台费:       HK$0.50
  总费用:                             ≈ HK$61.93
```

---

## 4. 技术架构

### 4.1 SOR 模块架构

```
┌───────────────────────────────────────────────────────────────────┐
│                      Smart Order Router                            │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │                     Router (Interface)                        │ │
│  │    Route(ctx, *Order) → (*Decision, error)                   │ │
│  └───────────────────────┬──────────────────────────────────────┘ │
│                          │                                        │
│          ┌───────────────┴───────────────┐                        │
│          ▼                               ▼                        │
│  ┌───────────────────┐       ┌───────────────────┐               │
│  │  US Router        │       │  HK Router        │               │
│  │                   │       │                   │               │
│  │  ┌─────────────┐ │       │  Route → HKEX     │               │
│  │  │ NBBO Check  │ │       │  Tick Size Align  │               │
│  │  └──────┬──────┘ │       │  Lot Size Verify  │               │
│  │         │        │       └───────────────────┘               │
│  │  ┌──────▼──────┐ │                                            │
│  │  │Multi-Factor │ │   ┌──────────────────────────────────────┐ │
│  │  │Score Engine │ │   │         Shared Components            │ │
│  │  └──────┬──────┘ │   │                                      │ │
│  │         │        │   │  ┌────────────────────────────────┐  │ │
│  │  ┌──────▼──────┐ │   │  │ VenueQuoteProvider             │  │ │
│  │  │Order Slicer │ │   │  │ (从 Market Data 服务获取报价)   │  │ │
│  │  │VWAP/TWAP/   │ │   │  └────────────────────────────────┘  │ │
│  │  │Iceberg      │ │   │  ┌────────────────────────────────┐  │ │
│  │  └──────┬──────┘ │   │  │ VenueConfigStore               │  │ │
│  │         │        │   │  │ (Venue 费率/延迟/状态配置)      │  │ │
│  │  ┌──────▼──────┐ │   │  └────────────────────────────────┘  │ │
│  │  │ Tick Size   │ │   │  ┌────────────────────────────────┐  │ │
│  │  │ Aligner     │ │   │  │ CircuitBreaker                 │  │ │
│  │  └─────────────┘ │   │  │ (Venue 连接状态断路器)          │  │ │
│  └───────────────────┘   │  └────────────────────────────────┘  │ │
│                          │  ┌────────────────────────────────┐  │ │
│                          │  │ RoutingAuditLogger             │  │ │
│                          │  │ (路由决策合规日志)               │  │ │
│                          │  └────────────────────────────────┘  │ │
│                          └──────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

### 4.2 核心数据结构

以下是 SOR 需要的核心类型定义，基于现有 `router.go` 扩展：

```go
// VenueQuote 交易所实时报价 (来自 Market Data 服务)
type VenueQuote struct {
    Venue     string
    BidPrice  decimal.Decimal
    BidSize   int64
    AskPrice  decimal.Decimal
    AskSize   int64
    Depth     int64           // 总深度 (bid + ask 各层累加)
    Timestamp int64           // Unix nanos, 报价时间
}

// VenueConfig 交易所配置
type VenueConfig struct {
    Name           string
    Enabled        bool
    FeePerShare    decimal.Decimal  // Taker fee (正数=费用)
    RebatePerShare decimal.Decimal  // Maker rebate (正数=返佣)
    AvgLatencyMs   int              // 平均网络延迟 (ms)
    FillRate       decimal.Decimal  // 历史成交率 (0-1)
    MaxOrderSize   int64            // 单笔最大委托量
    SupportedTypes []order.Type     // 支持的订单类型
}

// NBBO 全市场最优报价快照
type NBBO struct {
    Symbol   string
    BidPrice decimal.Decimal
    BidSize  int64
    BidVenue string
    AskPrice decimal.Decimal
    AskSize  int64
    AskVenue string
    Spread   decimal.Decimal  // Ask - Bid
    Locked   bool             // Bid == Ask
    Crossed  bool             // Bid > Ask (异常状态)
    Timestamp int64
}

// RoutingScore 路由评分详情 (审计用)
type RoutingScore struct {
    Venue          string
    PriceScore     decimal.Decimal  // 0-1
    LiquidityScore decimal.Decimal  // 0-1
    CostScore      decimal.Decimal  // 0-1
    LatencyScore   decimal.Decimal  // 0-1
    FinalScore     decimal.Decimal  // 加权总分
    Details        string           // 人类可读的评分详情
}

// RoutingAuditRecord 路由审计记录 (写入 order_events)
type RoutingAuditRecord struct {
    OrderID      string
    NBBO         *NBBO
    VenueQuotes  []*VenueQuote
    VenueScores  []*RoutingScore
    Decision     *Decision
    Strategy     string           // "BEST_EXECUTION" / "VWAP" / "TWAP"
    Timestamp    int64
}
```

### 4.3 多因子评分模型

SOR 路由决策的核心是一个多因子加权评分模型。对每个可用的 Venue，计算一个综合分数，选择分数最高的 Venue。

#### 评分公式

```
FinalScore = PriceScore × W_price
           + LiquidityScore × W_liquidity
           + CostScore × W_cost
           + LatencyScore × W_latency

默认权重:
  W_price     = 0.50  (价格是最重要的因子，Reg NMS 要求)
  W_liquidity = 0.25  (深度影响大单的实际成交价)
  W_cost      = 0.15  (交易所费用/返佣影响净成本)
  W_latency   = 0.10  (延迟影响执行确定性)
```

#### 各因子计算伪代码

```go
// priceScore 价格因子 (0-1, 越高越好)
//
// 对于买单: Ask 越低越好
// 对于卖单: Bid 越高越好
func (r *Router) priceScore(ord *order.Order, quote *VenueQuote, nbbo *NBBO) decimal.Decimal {
    if ord.Side == order.SideBuy {
        if quote.AskPrice.IsZero() || nbbo.AskPrice.IsZero() {
            return decimal.Zero
        }
        // 如果 Venue 的 Ask == NBO (全市场最优), score = 1.0
        // 如果 Venue 的 Ask > NBO, score 按比例降低
        // Score = NBO / VenueAsk (比值越接近 1 越好)
        return nbbo.AskPrice.Div(quote.AskPrice)
    }

    // 卖单: Bid 越高越好
    if quote.BidPrice.IsZero() || nbbo.BidPrice.IsZero() {
        return decimal.Zero
    }
    // Score = VenueBid / NBB
    return quote.BidPrice.Div(nbbo.BidPrice)
}

// liquidityScore 流动性因子 (0-1)
//
// 衡量 Venue 在 BBO 层的可用数量相对于订单数量的充足程度
func (r *Router) liquidityScore(ord *order.Order, quote *VenueQuote) decimal.Decimal {
    var availableSize int64
    if ord.Side == order.SideBuy {
        availableSize = quote.AskSize
    } else {
        availableSize = quote.BidSize
    }

    if availableSize <= 0 {
        return decimal.Zero
    }

    // 可用量 >= 订单量: score = 1.0
    // 可用量 < 订单量: score = available / orderQty
    ratio := decimal.NewFromInt(availableSize).Div(decimal.NewFromInt(ord.Quantity))
    if ratio.GreaterThan(decimal.NewFromInt(1)) {
        return decimal.NewFromInt(1)
    }
    return ratio
}

// costScore 费用因子 (0-1)
//
// 将交易所费用标准化为 0-1 分数
// 有返佣 (maker) 的 venue 分数更高
func (r *Router) costScore(venue string, ord *order.Order) decimal.Decimal {
    cfg := r.venueConfigs[venue]
    if cfg == nil {
        return decimal.Zero
    }

    var netCost decimal.Decimal
    if ord.Type == order.TypeLimit {
        // 限价单可能是 Maker: 净成本 = FeePerShare - RebatePerShare
        // 如果有返佣, netCost 可能为负 (越低越好)
        netCost = cfg.FeePerShare.Sub(cfg.RebatePerShare)
    } else {
        // 市价单一定是 Taker
        netCost = cfg.FeePerShare
    }

    // 标准化: 假设费用范围 [-$0.004, +$0.004]
    // Score = 1 - (netCost + 0.004) / 0.008
    maxRange := decimal.NewFromFloat(0.008)
    offset := decimal.NewFromFloat(0.004)
    score := decimal.NewFromInt(1).Sub(netCost.Add(offset).Div(maxRange))

    // Clamp to [0, 1]
    if score.LessThan(decimal.Zero) {
        return decimal.Zero
    }
    if score.GreaterThan(decimal.NewFromInt(1)) {
        return decimal.NewFromInt(1)
    }
    return score
}

// latencyScore 延迟因子 (0-1)
//
// 延迟越低分数越高
func (r *Router) latencyScore(venue string) decimal.Decimal {
    cfg := r.venueConfigs[venue]
    if cfg == nil {
        return decimal.Zero
    }

    // 假设延迟范围 [0ms, 10ms]
    // Score = 1 - latency/10
    latency := decimal.NewFromInt(int64(cfg.AvgLatencyMs))
    maxLatency := decimal.NewFromInt(10)
    score := decimal.NewFromInt(1).Sub(latency.Div(maxLatency))

    if score.LessThan(decimal.Zero) {
        return decimal.Zero
    }
    return score
}
```

### 4.4 完整路由流程实现

```go
func (r *USRouter) Route(ctx context.Context, ord *order.Order) (*Decision, error) {
    // Step 1: 获取所有启用的 Venue 的实时报价
    venueQuotes, err := r.quoteProvider.GetVenueQuotes(ctx, ord.Symbol)
    if err != nil {
        return nil, fmt.Errorf("get venue quotes for %s: %w", ord.Symbol, err)
    }
    if len(venueQuotes) == 0 {
        return nil, fmt.Errorf("no venue quotes available for %s", ord.Symbol)
    }

    // Step 2: 计算 NBBO
    nbbo := r.calculateNBBO(venueQuotes)
    if nbbo.Crossed {
        // NBBO 交叉是异常状态，记录警告但继续
        r.logger.Warn("NBBO crossed",
            zap.String("symbol", ord.Symbol),
            zap.String("bid", nbbo.BidPrice.String()),
            zap.String("ask", nbbo.AskPrice.String()),
        )
    }

    // Step 3: Reg NMS 合规预检 — 过滤掉劣于 NBBO 的 Venue
    eligibleVenues := r.filterByNBBO(ord, venueQuotes, nbbo)
    if len(eligibleVenues) == 0 {
        // Fallback: 使用 NBBO Venue
        return r.fallbackToNBBOVenue(ord, nbbo)
    }

    // Step 4: 对每个合规 Venue 计算多因子评分
    var scores []*RoutingScore
    bestScore := decimal.NewFromInt(-1)
    var bestVenue string

    for venue, quote := range eligibleVenues {
        ps := r.priceScore(ord, quote, nbbo)
        ls := r.liquidityScore(ord, quote)
        cs := r.costScore(venue, ord)
        las := r.latencyScore(venue)

        final := ps.Mul(r.weights.Price).
            Add(ls.Mul(r.weights.Liquidity)).
            Add(cs.Mul(r.weights.Cost)).
            Add(las.Mul(r.weights.Latency))

        scores = append(scores, &RoutingScore{
            Venue:          venue,
            PriceScore:     ps,
            LiquidityScore: ls,
            CostScore:      cs,
            LatencyScore:   las,
            FinalScore:     final,
        })

        if final.GreaterThan(bestScore) {
            bestScore = final
            bestVenue = venue
        }
    }

    // Step 5: 检查 Venue 断路器状态
    if r.circuitBreaker.IsOpen(bestVenue) {
        // 选择次优 Venue
        bestVenue, bestScore = r.selectFallbackVenue(scores, bestVenue)
        if bestVenue == "" {
            return nil, fmt.Errorf("all venues unavailable for %s", ord.Symbol)
        }
    }

    // Step 6: Tick Size 对齐
    alignedPrice := r.alignTickSize(r.getExecutionPrice(ord, eligibleVenues[bestVenue]), "US")

    // Step 7: 估算总成本
    estimatedCost := r.estimateTotalCost(ord, bestVenue, alignedPrice)

    // Step 8: 构建 Decision
    decision := &Decision{
        Venue:         bestVenue,
        Price:         alignedPrice,
        Quantity:      ord.Quantity,
        EstimatedCost: estimatedCost,
        Reason: fmt.Sprintf("best_execution: venue=%s, score=%s, nbbo_bid=%s, nbbo_ask=%s",
            bestVenue, bestScore.StringFixed(4),
            nbbo.BidPrice.String(), nbbo.AskPrice.String()),
    }

    // Step 9: 记录审计日志
    r.auditLogger.LogRoutingDecision(&RoutingAuditRecord{
        OrderID:     ord.OrderID,
        NBBO:        nbbo,
        VenueQuotes: mapToSlice(eligibleVenues),
        VenueScores: scores,
        Decision:    decision,
        Strategy:    "BEST_EXECUTION",
        Timestamp:   time.Now().UTC().UnixNano(),
    })

    return decision, nil
}
```

### 4.5 NBBO 合规检查

```go
// filterByNBBO 过滤掉不符合 Reg NMS 的 Venue
// Rule 611: 不能 Trade-Through Protected Quote
func (r *USRouter) filterByNBBO(
    ord *order.Order,
    quotes map[string]*VenueQuote,
    nbbo *NBBO,
) map[string]*VenueQuote {
    eligible := make(map[string]*VenueQuote)

    for venue, quote := range quotes {
        if ord.Side == order.SideBuy {
            // 买单: Venue 的 Ask 必须 <= NBO (不能以高于最优卖价的价格买)
            // 但如果 Venue 有足够深度且价格合理，也可以考虑
            if quote.AskPrice.LessThanOrEqual(nbbo.AskPrice) {
                eligible[venue] = quote
            }
            // 即使 Ask > NBO，如果是 ISO order 也可以
        } else {
            // 卖单: Venue 的 Bid 必须 >= NBB (不能以低于最优买价的价格卖)
            if quote.BidPrice.GreaterThanOrEqual(nbbo.BidPrice) {
                eligible[venue] = quote
            }
        }
    }

    return eligible
}

// calculateNBBO 从各 Venue 报价计算 NBBO
func (r *USRouter) calculateNBBO(quotes map[string]*VenueQuote) *NBBO {
    nbbo := &NBBO{
        BidPrice: decimal.NewFromInt(-1),
        AskPrice: decimal.NewFromInt(999999999),
    }

    for venue, q := range quotes {
        // National Best Bid = MAX of all venue bids
        if q.BidPrice.GreaterThan(nbbo.BidPrice) && q.BidSize > 0 {
            nbbo.BidPrice = q.BidPrice
            nbbo.BidSize = q.BidSize
            nbbo.BidVenue = venue
        }
        // National Best Offer = MIN of all venue asks
        if q.AskPrice.LessThan(nbbo.AskPrice) && q.AskSize > 0 {
            nbbo.AskPrice = q.AskPrice
            nbbo.AskSize = q.AskSize
            nbbo.AskVenue = venue
        }
    }

    nbbo.Spread = nbbo.AskPrice.Sub(nbbo.BidPrice)
    nbbo.Locked = nbbo.BidPrice.Equal(nbbo.AskPrice)
    nbbo.Crossed = nbbo.BidPrice.GreaterThan(nbbo.AskPrice)
    nbbo.Timestamp = time.Now().UTC().UnixNano()

    return nbbo
}
```

### 4.6 暗池 (Dark Pool) 路由

暗池是不公开显示订单簿的交易场所 (Alternative Trading System, ATS)。对大单交易有以下优势：

- **减少市场冲击**: 订单不公开显示，不会引起价格变动
- **匿名性**: 交易对手不知道谁在买/卖
- **价格改善**: 暗池通常在 NBBO 中间价 (midpoint) 成交

#### 暗池路由逻辑

```
大单判断 (Order Size > ADV的 1%?)
    │
    ├─ YES → 考虑暗池路由
    │         │
    │         ├─ 尝试暗池 (midpoint crossing)
    │         │   成交? → 部分/全部在暗池完成
    │         │   未成交? → 超时后路由到明市
    │         │
    │         └─ 或者: 拆单 (暗池 + 明市并行)
    │
    └─ NO → 直接明市路由 (上述多因子评分)
```

**注意**: 暗池路由在 MVP 阶段不实现。初期系统仅路由到 Lit Market (明市)。暗池路由需要与 ATS 签订连接协议，且有额外的 Reg ATS 合规要求。

### 4.7 大单拆分算法

当订单数量远大于 BBO 可用数量时，直接发送整单会造成严重的市场冲击（价格被推高/压低）。SOR 提供以下拆单策略：

#### VWAP (Volume Weighted Average Price)

```
目标: 使订单的平均成交价接近当天的 VWAP

原理:
  - 将订单拆分为多个子单
  - 每个时间段的子单量与该时间段的历史成交量占比一致
  - 例如: 如果历史上 10:00-10:30 的成交量占全天 8%，
    则在此时间段执行总订单的 8%

伪代码:
  totalQty := order.Quantity
  volumeProfile := getHistoricalVolumeProfile(order.Symbol) // 按30分钟分桶

  for each timeBucket in tradingDay {
      sliceQty := totalQty × volumeProfile[timeBucket].Percentage
      schedule = append(schedule, {Time: timeBucket.Start, Qty: sliceQty})
  }

适用场景:
  - 大型机构单 (> ADV 的 5%)
  - 目标是不偏离市场均价太多
  - 时间跨度: 全天或指定时段
```

#### TWAP (Time Weighted Average Price)

```
目标: 在指定时间段内均匀执行

原理:
  - 将总数量均匀分配到 N 个时间段
  - 每个时间段执行相同数量
  - 比 VWAP 更简单，但不考虑成交量分布

伪代码:
  totalQty := order.Quantity
  numSlices := (endTime - startTime) / interval  // 例如每5分钟一个 slice
  sliceQty := totalQty / numSlices

  for i := 0; i < numSlices; i++ {
      schedule = append(schedule, {Time: startTime + i*interval, Qty: sliceQty})
  }

适用场景:
  - 中等规模订单
  - 希望执行过程可预测
  - 时间跨度: 30分钟到数小时
```

#### Iceberg (冰山订单)

```
目标: 只显示部分数量，隐藏真实规模

原理:
  - 只将 displayQty (显示量) 发送到交易所
  - 每次 displayQty 被完全成交后，自动补充下一批
  - 总量 = totalQty, 每次显示 = displayQty

伪代码:
  displayQty := order.Quantity / 10  // 显示 10%
  remainingQty := order.Quantity

  while remainingQty > 0 {
      sliceQty := min(displayQty, remainingQty)
      sendOrder(sliceQty)
      waitForFill()
      remainingQty -= filledQty
  }

适用场景:
  - 不想暴露真实订单规模
  - 在交易所原生支持 Iceberg 的情况下由交易所管理
  - 也可以由 SOR 在客户端实现 (synthetic iceberg)

注意:
  NYSE/NASDAQ 原生支持 Iceberg Order (Reserve Order)
  HKEX 不支持原生 Iceberg
```

**MVP 阶段**: 仅支持单 Venue 直接路由，不实现 VWAP/TWAP/Iceberg。在 `Decision.Reason` 中记录"single venue direct routing"。大单拆分作为 Phase 2 功能。

### 4.8 路由失败与降级策略

```
路由失败场景:
    │
    ├─ 1. Venue 断路器打开 (连接故障)
    │     → 选择次优 Venue
    │     → 如果所有 Venue 断路器都打开 → 拒绝订单 (REJECT)
    │
    ├─ 2. FIX Session 未登录
    │     → 检查 SessionStatus != LoggedOn
    │     → 选择备选 Venue
    │     → 记录 "primary venue unavailable, routed to fallback"
    │
    ├─ 3. 报价数据不可用
    │     → Market Data 服务超时
    │     → 使用缓存的上次报价 (如果 < 5s 内)
    │     → 如果缓存过期 → 拒绝订单
    │
    ├─ 4. 所有 Venue 报价不满足限价
    │     → 限价单: 路由到流动性最深的 Venue 挂单
    │     → 市价单: 路由到 NBBO Venue
    │
    └─ 5. 交易所拒绝 (ExecType=REJECTED)
        → 记录拒绝原因
        → 不自动重路由 (需要人工审核)
        → 通知用户订单被交易所拒绝
```

#### 断路器实现

```go
type VenueCircuitBreaker struct {
    mu       sync.RWMutex
    state    map[string]CircuitState  // venue -> state
    failures map[string]int           // venue -> consecutive failures
    lastFail map[string]time.Time     // venue -> last failure time
    config   CircuitBreakerConfig
}

type CircuitBreakerConfig struct {
    FailureThreshold  int           // 连续失败次数触发断路 (default: 5)
    RecoveryTimeout   time.Duration // 断路后多久尝试恢复 (default: 30s)
    HalfOpenMaxOrders int           // Half-Open 状态最多尝试几笔 (default: 3)
}

type CircuitState int

const (
    CircuitClosed   CircuitState = 0  // 正常: 放行所有请求
    CircuitOpen     CircuitState = 1  // 断路: 拒绝所有请求
    CircuitHalfOpen CircuitState = 2  // 半开: 允许少量试探请求
)

func (cb *VenueCircuitBreaker) IsOpen(venue string) bool {
    cb.mu.RLock()
    defer cb.mu.RUnlock()

    state := cb.state[venue]
    if state == CircuitOpen {
        // 检查是否到了恢复时间
        if time.Since(cb.lastFail[venue]) > cb.config.RecoveryTimeout {
            // 转为 Half-Open (注意: 此处需要写锁, 简化示意)
            return false
        }
        return true
    }
    return false
}

func (cb *VenueCircuitBreaker) RecordSuccess(venue string) {
    cb.mu.Lock()
    defer cb.mu.Unlock()
    cb.failures[venue] = 0
    cb.state[venue] = CircuitClosed
}

func (cb *VenueCircuitBreaker) RecordFailure(venue string) {
    cb.mu.Lock()
    defer cb.mu.Unlock()
    cb.failures[venue]++
    cb.lastFail[venue] = time.Now()
    if cb.failures[venue] >= cb.config.FailureThreshold {
        cb.state[venue] = CircuitOpen
    }
}
```

---

## 5. 性能要求与设计决策

### 5.1 性能指标

| 指标 | 目标 | 说明 |
|------|------|------|
| 路由决策延迟 | < 2ms (p99) | 从 `Route()` 调用到返回 `Decision` |
| NBBO 计算 | < 0.5ms (p99) | 聚合各 Venue 报价 |
| 报价获取 | < 1ms (p99) | 从 Market Data 缓存读取 |
| 评分计算 | < 0.5ms (p99) | 所有 Venue 的多因子评分 |
| 整体路由 (含日志) | < 3ms (p99) | 包括审计日志写入 |

> 注意: 路由决策的 3ms 是订单到交易所总延迟 10ms 预算的一部分。剩余 7ms 给 FIX 消息构建 + 网络传输。

### 5.2 关键设计决策

#### 决策 1: 报价数据使用本地缓存而非实时 RPC

```
方案 A: 每次路由时 RPC 调用 Market Data 服务获取报价
  优点: 数据最新
  缺点: 网络延迟 1-5ms，吞吐瓶颈

方案 B: Market Data 推送报价到本地缓存 (Redis / In-Memory)
  优点: 读取延迟 < 0.1ms
  缺点: 数据可能有 1-10ms 的延迟

选择: 方案 B
原因:
  - 1-10ms 的行情延迟在零售券商场景下完全可接受
  - HFT 级别的延迟敏感度不是我们的目标用户群
  - 减少一次网络往返对 p99 延迟有巨大改善

实现:
  - Market Data 服务通过 Kafka topic 'venue.quotes' 推送
  - Trading Engine 订阅并维护 in-memory 缓存 (sync.Map)
  - 缓存 TTL: 5 秒 (超过则视为 stale)
```

#### 决策 2: 路由审计日志异步写入

```
方案 A: 同步写入 order_events 表
  优点: 保证一致性
  缺点: 数据库写入增加 1-3ms 延迟

方案 B: 异步写入 (先写 Kafka，再消费入库)
  优点: 不阻塞路由决策
  缺点: 短暂的不一致窗口 (< 100ms)

选择: 方案 B
原因:
  - 路由日志是合规审计用途，不需要实时查询
  - 对 p99 延迟的影响从 3ms 降到 0.1ms (仅写 Kafka)
  - Kafka 的持久化保证足以满足合规要求

实现:
  - 路由决策完成后，将 RoutingAuditRecord 序列化写入 Kafka
  - 下游 Consumer 异步写入 order_events 表
  - event_type = 'ROUTING_DECISION'
```

#### 决策 3: 权重可动态配置

```
路由评分权重不应硬编码，需要支持运行时调整:

  - 存储在配置中心 (如 Redis / Consul / 环境变量)
  - 修改权重后无需重启服务
  - 权重变更记录到审计日志

默认权重:
  price:     0.50
  liquidity: 0.25
  cost:      0.15
  latency:   0.10

调整场景:
  - 高波动市场: 降低 latency 权重, 提高 price 权重
  - 大单执行: 提高 liquidity 权重, 降低 cost 权重
  - 费用敏感客户: 提高 cost 权重
```

#### 决策 4: 港股无需评分，直接路由

```
港股市场只有 HKEX 一个交易所:
  - 跳过 NBBO 计算
  - 跳过多因子评分
  - 仅做 Tick Size 和 Lot Size 对齐
  - 检查 FIX Session 状态
  - 延迟: < 0.5ms (几乎零计算)
```

### 5.3 内存管理

```go
// 使用 sync.Pool 复用 RoutingScore slice 减少 GC 压力
var routingScorePool = sync.Pool{
    New: func() interface{} {
        return make([]*RoutingScore, 0, 16) // 预分配 16 个 venue
    },
}

func (r *USRouter) Route(ctx context.Context, ord *order.Order) (*Decision, error) {
    scores := routingScorePool.Get().([]*RoutingScore)
    scores = scores[:0]
    defer func() {
        for i := range scores {
            scores[i] = nil // help GC
        }
        routingScorePool.Put(scores)
    }()
    // ... use scores ...
}
```

---

## 6. 接口设计 (gRPC / REST / Kafka Events)

### 6.1 内部接口 (Go Interface)

SOR 是 Trading Engine 的内部模块，不直接暴露 gRPC/REST 接口。它通过 Go interface 被 Order Service 调用。

```go
// 文件: src/internal/routing/router.go (已定义)
type Router interface {
    Route(ctx context.Context, ord *order.Order) (*Decision, error)
}
```

### 6.2 依赖的外部接口

#### 从 Market Data 服务获取报价 (gRPC)

```protobuf
// 文件: docs/specs/api/grpc/market_data.proto

service MarketDataService {
    // 获取指定标的在各 Venue 的实时报价
    rpc GetVenueQuotes(VenueQuotesRequest) returns (VenueQuotesResponse);

    // 订阅报价流 (用于维护本地缓存)
    rpc SubscribeVenueQuotes(SubscribeRequest) returns (stream VenueQuoteUpdate);
}

message VenueQuotesRequest {
    string symbol = 1;
    string market = 2;  // "US" / "HK"
}

message VenueQuotesResponse {
    repeated VenueQuote quotes = 1;
    NBBO nbbo = 2;  // 预计算的 NBBO (仅 US)
}

message VenueQuote {
    string venue = 1;
    string bid_price = 2;   // decimal string
    int64 bid_size = 3;
    string ask_price = 4;
    int64 ask_size = 5;
    int64 depth = 6;
    int64 timestamp_nanos = 7;
}

message NBBO {
    string bid_price = 1;
    int64 bid_size = 2;
    string bid_venue = 3;
    string ask_price = 4;
    int64 ask_size = 5;
    string ask_venue = 6;
}
```

### 6.3 Kafka Events

#### 路由决策事件 (SOR 产出)

```json
// Topic: trading.routing.decisions
// Key: order_id
{
    "event_type": "ROUTING_DECISION",
    "order_id": "ord-abc-123",
    "symbol": "AAPL",
    "market": "US",
    "decision": {
        "venue": "NASDAQ",
        "price": "149.98",
        "quantity": 100,
        "estimated_cost": "15001.30",
        "reason": "best_execution: venue=NASDAQ, score=0.9234, nbbo_bid=149.98, nbbo_ask=149.98"
    },
    "nbbo_snapshot": {
        "bid_price": "149.98",
        "bid_size": 500,
        "bid_venue": "ARCA",
        "ask_price": "149.98",
        "ask_size": 200,
        "ask_venue": "NASDAQ"
    },
    "venue_scores": [
        {"venue": "NYSE",   "score": "0.8712"},
        {"venue": "NASDAQ", "score": "0.9234"},
        {"venue": "ARCA",   "score": "0.9100"},
        {"venue": "BATS",   "score": "0.8500"},
        {"venue": "IEX",    "score": "0.7800"}
    ],
    "timestamp": "2026-03-16T14:30:00.123456789Z"
}
```

#### 行情更新事件 (SOR 消费)

```json
// Topic: market.venue.quotes
// Key: symbol
{
    "symbol": "AAPL",
    "market": "US",
    "venue": "NASDAQ",
    "bid_price": "149.97",
    "bid_size": 300,
    "ask_price": "149.98",
    "ask_size": 200,
    "depth": 15000,
    "timestamp_nanos": 1742137800123456789
}
```

### 6.4 监控指标 (Prometheus)

```go
var (
    routingDecisionLatency = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "sor_routing_decision_duration_seconds",
            Help:    "Time to make routing decision",
            Buckets: prometheus.ExponentialBuckets(0.0001, 2, 15), // 0.1ms to ~3s
        },
        []string{"market", "venue", "order_type"},
    )

    routingVenueSelection = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "sor_venue_selections_total",
            Help: "Number of times each venue was selected",
        },
        []string{"venue", "market"},
    )

    routingFallbackCount = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "sor_fallback_total",
            Help: "Number of fallback routing decisions",
        },
        []string{"primary_venue", "fallback_venue", "reason"},
    )

    routingNBBOSpread = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "sor_nbbo_spread",
            Help:    "NBBO spread at time of routing decision",
            Buckets: []float64{0, 0.001, 0.005, 0.01, 0.02, 0.05, 0.10, 0.50},
        },
        []string{"symbol"},
    )

    venueCircuitBreakerState = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "sor_venue_circuit_breaker_state",
            Help: "Circuit breaker state: 0=closed, 1=open, 2=half-open",
        },
        []string{"venue"},
    )
)
```

---

## 7. 开源参考实现

### 7.1 直接可用的库

| 库名 | 语言 | 用途 | 适用性 |
|------|------|------|--------|
| `quickfixgo/quickfix` | Go | FIX 协议引擎 | 高: SOR 路由的下游 |
| `shopspring/decimal` | Go | 精确金额计算 | 必须: 价格/费用计算 |
| `sony/gobreaker` | Go | Circuit Breaker 实现 | 高: Venue 断路器 |
| `prometheus/client_golang` | Go | 监控指标 | 高: 路由延迟/频次监控 |

### 7.2 参考架构

| 项目 | 说明 | 参考价值 |
|------|------|---------|
| [QuantConnect/Lean](https://github.com/QuantConnect/Lean) | C# 量化交易框架 | 路由策略、订单拆分算法 |
| [quickfixgo/examples](https://github.com/quickfixgo/examples) | QuickFIX/Go 示例 | FIX 消息构建和 Session 管理 |
| [lob/robinhood-to-csv](https://github.com/lob/robinhood-to-csv) | 美股经纪商 API | 理解零售券商的路由决策字段 |
| [IEX Cloud](https://iexcloud.io/docs/) | IEX 交易所 API 文档 | 理解 NBBO、Venue Quote 数据结构 |
| [SEC MIDAS](https://www.sec.gov/marketstructure/midas) | SEC 市场结构分析 | Reg NMS 合规分析参考 |

### 7.3 关键文档

| 文档 | 内容 | 用途 |
|------|------|------|
| [Reg NMS Full Text](https://www.sec.gov/rules/final/34-51808.htm) | Reg NMS 完整条文 | 法规合规基础 |
| [NYSE Connectivity Guide](https://www.nyse.com/market-data/guides) | NYSE 连接指南 | FIX 字段差异 |
| [NASDAQ TotalView-ITCH](https://www.nasdaqtrader.com/content/technicalsupport/specifications/dataproducts/NQTVITCHspecification.pdf) | NASDAQ 行情协议 | 报价数据格式 |
| [HKEX Trading Rules](https://www.hkex.com.hk/Services/Rules-and-Forms-and-Fees/Rules/Securities) | HKEX 交易规则 | 港股路由规则 |
| [SFC Code of Conduct](https://www.sfc.hk/en/Rules-and-standards/Codes-and-guidelines/Codes) | SFC 操守准则 | 港股最优执行义务 |

### 7.4 Circuit Breaker 参考: sony/gobreaker

```go
import "github.com/sony/gobreaker"

// 使用 gobreaker 替代自研断路器
cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "NYSE",
    MaxRequests: 3,                    // Half-Open 状态最多 3 个请求
    Interval:    60 * time.Second,     // 统计窗口
    Timeout:     30 * time.Second,     // Open -> Half-Open 的等待时间
    ReadyToTrip: func(counts gobreaker.Counts) bool {
        // 连续 5 次失败触发断路
        return counts.ConsecutiveFailures >= 5
    },
    OnStateChange: func(name string, from, to gobreaker.State) {
        logger.Warn("circuit breaker state change",
            zap.String("venue", name),
            zap.String("from", from.String()),
            zap.String("to", to.String()),
        )
        venueCircuitBreakerState.WithLabelValues(name).Set(float64(to))
    },
})
```

---

## 8. PRD Review 检查清单

以下是 PM/合规团队在审阅 SOR 相关 PRD 时需要逐项确认的清单：

### 8.1 功能完整性

- [ ] SOR 是否覆盖所有支持的市场 (US, HK)?
- [ ] 是否支持所有订单类型 (MARKET, LIMIT, STOP, STOP_LIMIT, MOO, MOC)?
- [ ] 盘前/盘后 (Extended Hours) 订单的路由策略是否定义?
- [ ] 港股午休时段 (12:00-13:00) 的路由行为是否定义?
- [ ] 港股收市竞价 (16:00-16:10) 的路由行为是否定义?
- [ ] 路由失败时的降级策略是否完整?
- [ ] 所有 Venue 均不可用时的用户提示是否定义?

### 8.2 Reg NMS 合规 (美股)

- [ ] Rule 611 Trade-Through Protection 是否正确实现?
- [ ] NBBO 数据来源是否可靠 (SIP / Direct Feed)?
- [ ] ISO (Intermarket Sweep Order) 是否需要支持?
- [ ] NBBO 快照是否随路由决策一起记录?
- [ ] Trade-Through 豁免情形是否正确处理?
- [ ] Rule 606 报告所需的路由统计数据是否采集?
- [ ] Rule 610 Access Fee 上限是否在成本模型中体现?

### 8.3 SFC 合规 (港股)

- [ ] Best Execution 义务是否在路由日志中有据可查?
- [ ] HKEX Tick Size Table 是否完整实现?
- [ ] Lot Size 校验是否在路由前完成?
- [ ] 港股特殊订单类型 (如竞价限价单) 的路由是否正确?

### 8.4 审计与记录

- [ ] 每笔路由决策是否记录到 order_events (append-only)?
- [ ] 路由审计记录是否包含: NBBO 快照、各 Venue 评分、最终决策、原因?
- [ ] 记录保留是否满足 7 年合规要求?
- [ ] 路由策略变更是否有审计记录?

### 8.5 性能

- [ ] 路由决策延迟是否 < 2ms (p99)?
- [ ] 报价缓存 TTL 是否合理 (建议 < 5s)?
- [ ] 断路器配置是否合理 (阈值、恢复时间)?
- [ ] 是否有足够的 Prometheus 监控指标?

### 8.6 大单处理 (Phase 2)

- [ ] VWAP/TWAP 算法是否定义了触发条件?
- [ ] Iceberg 订单是否区分交易所原生 vs Synthetic?
- [ ] 暗池路由的触发条件和合规要求是否定义?
- [ ] 大单拆分是否有最大子单数量限制?

---

## 9. 工程落地注意事项

### 9.1 实施分期

#### Phase 1 (MVP)

```
目标: 基础路由能力，满足合规最低要求

实现范围:
  ✅ 美股: 单 Venue 最优选择 (NBBO + 多因子评分)
  ✅ 港股: 直接路由到 HKEX
  ✅ Tick Size 对齐
  ✅ NBBO 合规检查 (Rule 611)
  ✅ 路由审计日志 (写入 Kafka → order_events)
  ✅ Venue 断路器 (Circuit Breaker)
  ✅ Prometheus 监控指标
  ❌ 大单拆分 (VWAP/TWAP/Iceberg)
  ❌ 暗池路由
  ❌ 动态权重调整 UI

预计工期: 3 周
```

#### Phase 2

```
目标: 高级路由策略

实现范围:
  ✅ VWAP/TWAP 大单拆分
  ✅ Iceberg 订单 (Synthetic)
  ✅ 动态权重配置 (Admin Panel)
  ✅ 路由效果回测分析
  ❌ 暗池路由 (需要与 ATS 签约)

预计工期: 4 周
```

#### Phase 3

```
目标: 暗池 + 高级分析

实现范围:
  ✅ 暗池路由 (ATS 连接)
  ✅ 实时路由效果分析 (Execution Quality Dashboard)
  ✅ Rule 606 报告自动生成
  ✅ 路由策略 A/B 测试框架

预计工期: 6 周
```

### 9.2 测试策略

#### 单元测试

```go
func TestPriceScore_BuyOrder_BestVenue(t *testing.T) {
    nbbo := &NBBO{
        AskPrice: decimal.NewFromFloat(149.98),
        AskVenue: "NASDAQ",
    }
    quote := &VenueQuote{
        AskPrice: decimal.NewFromFloat(149.98),
    }
    ord := &order.Order{Side: order.SideBuy}

    score := router.priceScore(ord, quote, nbbo)
    assert.True(t, score.Equal(decimal.NewFromInt(1)), "best venue should score 1.0")
}

func TestPriceScore_BuyOrder_InferiorVenue(t *testing.T) {
    nbbo := &NBBO{
        AskPrice: decimal.NewFromFloat(149.98),
    }
    quote := &VenueQuote{
        AskPrice: decimal.NewFromFloat(150.02), // worse than NBBO
    }
    ord := &order.Order{Side: order.SideBuy}

    score := router.priceScore(ord, quote, nbbo)
    assert.True(t, score.LessThan(decimal.NewFromInt(1)), "inferior venue should score < 1.0")
}

func TestNBBOFilter_RejectsTradeThrough(t *testing.T) {
    quotes := map[string]*VenueQuote{
        "NYSE":   {AskPrice: decimal.NewFromFloat(150.02), AskSize: 100},
        "NASDAQ": {AskPrice: decimal.NewFromFloat(149.98), AskSize: 200},
        "ARCA":   {AskPrice: decimal.NewFromFloat(150.05), AskSize: 50}, // worst
    }
    nbbo := &NBBO{AskPrice: decimal.NewFromFloat(149.98)}
    ord := &order.Order{Side: order.SideBuy}

    eligible := router.filterByNBBO(ord, quotes, nbbo)

    assert.Contains(t, eligible, "NASDAQ")
    assert.NotContains(t, eligible, "NYSE")   // Trade-through
    assert.NotContains(t, eligible, "ARCA")    // Trade-through
}

func TestHKRouter_DirectToHKEX(t *testing.T) {
    ord := &order.Order{
        Symbol: "0700.HK",
        Market: "HK",
        Price:  decimal.NewFromFloat(350.20),
    }

    decision, err := router.Route(ctx, ord)

    assert.NoError(t, err)
    assert.Equal(t, "HKEX", decision.Venue)
    assert.Equal(t, "350.20", decision.Price.String()) // tick=0.20 for 200-500 range
}

func TestTickSizeAlignment_HK(t *testing.T) {
    tests := []struct {
        price    float64
        expected string
    }{
        {0.123, "0.123"},    // tick=0.001, already aligned
        {0.1234, "0.123"},   // tick=0.001, round down
        {5.55, "5.55"},      // tick=0.01, already aligned
        {5.553, "5.55"},     // tick=0.01, round down
        {150.13, "150.10"},  // tick=0.10, round down
        {350.25, "350.20"},  // tick=0.20, round down
    }
    for _, tt := range tests {
        result := alignHKTickSize(decimal.NewFromFloat(tt.price))
        assert.Equal(t, tt.expected, result.String(),
            "price %f should align to %s", tt.price, tt.expected)
    }
}
```

#### 集成测试

```go
func TestSOR_EndToEnd_USMarket(t *testing.T) {
    // 设置 mock venue quotes
    quoteProvider.SetQuotes("AAPL", map[string]*VenueQuote{
        "NYSE":   {BidPrice: d("149.95"), BidSize: 500, AskPrice: d("150.02"), AskSize: 300},
        "NASDAQ": {BidPrice: d("149.97"), BidSize: 200, AskPrice: d("149.98"), AskSize: 200},
        "ARCA":   {BidPrice: d("149.98"), BidSize: 100, AskPrice: d("150.00"), AskSize: 150},
    })

    ord := &order.Order{
        OrderID:  "test-001",
        Symbol:   "AAPL",
        Market:   "US",
        Side:     order.SideBuy,
        Type:     order.TypeLimit,
        Quantity: 100,
        Price:    decimal.NewFromFloat(150.00),
    }

    decision, err := router.Route(ctx, ord)

    require.NoError(t, err)
    assert.Equal(t, "NASDAQ", decision.Venue, "should route to NASDAQ with best ask")
    assert.Equal(t, "149.98", decision.Price.String())
    assert.Contains(t, decision.Reason, "best_execution")

    // 验证审计日志已写入 Kafka
    msg := kafkaConsumer.ReadMessage(time.Second)
    assert.Contains(t, string(msg.Value), "ROUTING_DECISION")
    assert.Contains(t, string(msg.Value), "NASDAQ")
}
```

#### 压力测试

```go
func BenchmarkSOR_Route(b *testing.B) {
    // 预填充 5 个 venue 的报价缓存
    setupVenueQuotes()

    ord := &order.Order{
        Symbol:   "AAPL",
        Market:   "US",
        Side:     order.SideBuy,
        Type:     order.TypeLimit,
        Quantity: 100,
        Price:    decimal.NewFromFloat(150.00),
    }

    b.ResetTimer()
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            _, err := router.Route(context.Background(), ord)
            if err != nil {
                b.Fatal(err)
            }
        }
    })
    // 目标: > 500,000 ops/sec
}
```

### 9.3 关键注意事项

#### 绝对不能做的事

1. **不要用 float64 计算价格评分** -- 虽然评分本身不是"钱"，但参与评分的价格都是 `decimal.Decimal`。保持一致性，避免精度问题。
2. **不要跳过 NBBO 检查** -- 即使看起来"没什么用"（例如只有一个 Venue 有好报价），Rule 611 要求每笔订单都有 NBBO 合规证据。
3. **不要硬编码 Venue 列表** -- 新交易所随时可能接入，使用配置驱动。
4. **不要在路由逻辑中使用 `time.Now()`** -- 使用注入的 `Clock` 接口，便于测试。
5. **不要吞掉 Venue 报价获取错误** -- 如果无法获取某个 Venue 的报价，记录日志并排除该 Venue，但不能 panic 或返回零分。

#### 容易踩的坑

1. **NBBO Crossed Market**: Bid > Ask 是异常状态（通常是报价延迟导致）。不要基于 crossed NBBO 做路由决策，应该跳过或使用缓存的上次有效 NBBO。
2. **Locked Market**: Bid == Ask 意味着 spread = 0。市价单在此情况下任何 Venue 都等价。
3. **Tick Size 边界**: 港股 Tick Size 在价格区间边界处变化（如 HK$10 处 tick 从 0.01 变为 0.02）。限价恰好在边界上时，需要特别注意对齐方向。
4. **Maker vs Taker 判定**: 限价单不一定是 Maker。如果限价 >= 当前 Ask（买单），会立即 match，视为 Taker。费用模型需要根据预期执行方式判断。
5. **断路器恢复后的瞬间涌入**: Half-Open 状态只允许少量试探请求，避免恢复瞬间的负载峰值。
6. **报价时间戳验证**: 拒绝使用超过 5 秒前的报价做路由决策。行情延迟可能导致 stale NBBO。

### 9.4 文件结构建议

```
src/internal/routing/
├── router.go              # Router interface + Decision struct (已有)
├── us_router.go           # 美股路由实现 (NBBO + 多因子)
├── hk_router.go           # 港股路由实现 (直接 HKEX)
├── dispatcher.go          # 根据 market 分发到 US/HK router
├── scoring.go             # 多因子评分算法
├── nbbo.go                # NBBO 计算和 Reg NMS 合规检查
├── tick_size.go           # Tick Size 对齐逻辑 (US + HK)
├── circuit_breaker.go     # Venue 断路器
├── venue_config.go        # VenueConfig 配置管理
├── quote_cache.go         # 报价缓存 (消费 Kafka 维护)
├── audit.go               # 路由审计日志
├── metrics.go             # Prometheus 指标定义
├── router_test.go         # 单元测试
├── us_router_test.go      # 美股路由测试
├── hk_router_test.go      # 港股路由测试
├── scoring_test.go        # 评分算法测试
├── tick_size_test.go      # Tick Size 测试
└── benchmark_test.go      # 性能基准测试
```

### 9.5 配置示例

```yaml
# config/routing.yaml
routing:
  # 评分权重 (可动态调整)
  weights:
    price: 0.50
    liquidity: 0.25
    cost: 0.15
    latency: 0.10

  # 报价缓存
  quote_cache:
    ttl_seconds: 5
    stale_threshold_seconds: 10

  # 断路器
  circuit_breaker:
    failure_threshold: 5
    recovery_timeout_seconds: 30
    half_open_max_requests: 3

  # Venue 配置
  venues:
    NYSE:
      enabled: true
      fee_per_share: "0.0025"
      rebate_per_share: "0.0020"
      avg_latency_ms: 2
      max_order_size: 1000000
    NASDAQ:
      enabled: true
      fee_per_share: "0.0030"
      rebate_per_share: "0.0020"
      avg_latency_ms: 1
      max_order_size: 1000000
    ARCA:
      enabled: true
      fee_per_share: "0.0030"
      rebate_per_share: "0.0020"
      avg_latency_ms: 2
      max_order_size: 1000000
    BATS:
      enabled: true
      fee_per_share: "0.0030"
      rebate_per_share: "0.0025"
      avg_latency_ms: 1
      max_order_size: 1000000
    IEX:
      enabled: true
      fee_per_share: "0.0009"
      rebate_per_share: "0.0000"
      avg_latency_ms: 2  # 含 350us speed bump
      max_order_size: 500000
    HKEX:
      enabled: true
      fee_per_share: "0"  # HK 费用按金额百分比，不按股数
      rebate_per_share: "0"
      avg_latency_ms: 5
      max_order_size: 10000000

  # 大单判断阈值 (Phase 2)
  large_order:
    adv_percentage_threshold: 0.01  # 订单量 > ADV 的 1% 视为大单
    vwap_enabled: false
    twap_enabled: false
    iceberg_enabled: false
```

### 9.6 与其他模块的交互时序

```
用户下单
   │
   ▼
OrderService.Submit()
   │
   ├── OrderValidator.Validate()     ← 格式/市场/标的校验
   │      如果失败 → REJECTED
   │
   ├── RiskEngine.CheckOrder()       ← 购买力/持仓/PDT/保证金
   │      如果失败 → REJECTED
   │
   ├── Router.Route()                ← 本模块: SOR 路由决策
   │      │
   │      ├── 获取 Venue Quotes     (从本地缓存 / Market Data 服务)
   │      ├── 计算 NBBO             (仅美股)
   │      ├── Reg NMS 合规检查      (仅美股)
   │      ├── 多因子评分
   │      ├── Tick Size 对齐
   │      ├── 生成 Decision
   │      └── 写入审计日志 (Kafka)
   │      │
   │      ▼ Decision{Venue, Price, Quantity, Reason}
   │
   ├── FIXEngine.SendNewOrder()      ← 使用 Decision.Venue 确定 Session
   │      Order.Exchange = Decision.Venue
   │      Order.Status → PENDING
   │
   └── (等待 ExecutionReport)        ← FIX Engine 异步回调
```

### 9.7 监控与告警

| 告警条件 | 严重级别 | 处理方式 |
|---------|---------|---------|
| 路由决策延迟 p99 > 5ms | WARNING | 检查报价缓存健康 |
| 路由决策延迟 p99 > 10ms | CRITICAL | 降级到简化路由模式 |
| 某 Venue 断路器打开 | WARNING | 检查 FIX Session 状态 |
| 所有 US Venue 断路器打开 | CRITICAL | 暂停接单，人工介入 |
| NBBO 持续交叉 > 1min | WARNING | 检查行情数据源 |
| 报价缓存命中率 < 90% | WARNING | 检查 Kafka consumer lag |
| 路由到次优 Venue 比例 > 20% | WARNING | 检查首选 Venue 健康 |
| 交易所拒绝率 > 5% | CRITICAL | 检查订单参数合规性 |

---

> **文档维护说明**: 本文档由 trading-engineer agent 负责维护。任何路由策略、权重配置、或 Venue 列表的变更都应先更新本文档，再修改代码。Reg NMS 相关内容如有法规更新，需及时同步。
