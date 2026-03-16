# 订单管理系统 (OMS) 深度调研

> Order Management System Deep Dive -- 美港股券商交易引擎核心子域

---

## 1. 业务概述

### 1.1 OMS 在交易系统中的角色

订单管理系统 (Order Management System, OMS) 是整个交易平台的中枢神经系统。它负责接收来自客户端的下单指令，对订单进行格式校验、风控检查、智能路由，通过 FIX 协议发送至交易所，接收交易所回报并更新订单状态，最终触发持仓更新和结算流程。

从业务角度看，OMS 管理的是「用户的交易意图」到「实际成交」的全过程。每一笔订单从创建到终结，都必须经过严格的状态机管理，确保不丢单、不重单、不漏状态。

### 1.2 核心职责

| 职责 | 说明 | 关联系统 |
|------|------|----------|
| 订单接收 | 接收多端（iOS/Android/Web/API）下单请求 | API Gateway |
| 幂等校验 | 通过 Idempotency-Key 防止重复下单 | Redis |
| 格式校验 | 校验订单字段合法性（Symbol、Price、Quantity等） | Market Data (标的信息) |
| 风控检查 | 调用 Risk Engine 执行 Pre-Trade 风控流水线 | Risk Engine |
| 订单路由 | 通过 Smart Order Router 选择最优交易所 | SOR / Market Data |
| FIX 发送 | 将订单转换为 FIX 消息发送至交易所 | FIX Engine |
| 回报处理 | 接收交易所 ExecutionReport 更新订单状态 | FIX Engine |
| 事件发布 | 每次状态变更发布 Kafka 事件 | Kafka |
| 持仓更新 | 成交后触发持仓和余额更新 | Position Engine |
| 审计追踪 | 全量记录订单生命周期事件 | PostgreSQL (order_events) |

### 1.3 订单生命周期全景

一笔典型的限价买入订单（US Market）的完整生命周期：

```
1. 用户在 Flutter App 点击「买入 AAPL 100股 @$150.00」
2. App 生成 Idempotency-Key (UUID v4) 并发送 gRPC SubmitOrder 请求
3. API Gateway 转发至 Trading Engine
4. OMS 收到请求：
   a. Redis 幂等检查 → 新请求 → 继续
   b. 创建 Order 对象 → 状态 CREATED → 写入 DB + 发布 order.created 事件
   c. Validator 校验 → 通过 → 状态 VALIDATED
   d. Risk Engine 8 道检查 → 全部通过 → 状态 RISK_APPROVED
   e. SOR 选择 NYSE → FIX Engine 发送 NewOrderSingle (MsgType=D) → 状态 PENDING
5. NYSE 接受订单 → ExecutionReport (ExecType=NEW) → 状态 OPEN
6. 部分成交 50 股 @$149.98 → ExecutionReport (ExecType=PARTIAL_FILL) → 状态 PARTIAL_FILL
7. 剩余 50 股成交 @$150.00 → ExecutionReport (ExecType=FILL) → 状态 FILLED
8. Post-Trade 处理：持仓 +100 AAPL，余额扣减，写入 executions 表
9. T+1 结算：标记为已结算，unsettled_qty → settled_qty
```

---

## 2. 监管与合规要求

### 2.1 美国市场 (SEC / FINRA)

#### 2.1.1 SEC Rule 17a-4 -- 记录保存要求

所有订单记录（含修改、撤销、拒绝）必须以 WORM (Write Once Read Many) 方式保存至少 **7 年**。前 2 年需随时可访问（hot storage），后 5 年可在 cold storage。

对 OMS 的具体要求：
- **order_events 表必须是 append-only**：禁止 UPDATE 或 DELETE 操作
- 每次订单状态变更必须生成一条不可变的事件记录
- 事件数据必须包含完整上下文：订单 ID、时间戳、操作人、变更前后状态、IP 地址
- 需支持按 order_id 重建完整订单历史（Event Replay）

#### 2.1.2 CAT (Consolidated Audit Trail) 上报

自 2024 年起，broker-dealer 必须向 CAT 系统上报所有订单事件。关键上报字段：

| CAT 字段 | 对应 OMS 字段 | 说明 |
|-----------|---------------|------|
| `orderID` | `order_id` (UUID) | 订单唯一标识 |
| `senderIMID` | 券商 IMID | 行业成员标识 |
| `symbol` | `symbol` | 标的代码 |
| `eventTimestamp` | 事件时间 (纳秒精度) | CAT 要求至少毫秒精度，推荐纳秒 |
| `side` | `side` (BUY/SELL) | 买卖方向 |
| `price` | `price` | 价格 |
| `quantity` | `quantity` | 数量 |
| `orderType` | `order_type` | 订单类型 |
| `timeInForce` | `time_in_force` | 有效期类型 |
| `routedOrderID` | `exchange_order_id` | 交易所返回的订单 ID |

CAT 上报时间窗口：T+1 08:00 ET 前必须完成前一交易日的上报。

#### 2.1.3 Reg NMS (National Market System)

- **Order Protection Rule (Rule 611)**：禁止以劣于 NBBO (National Best Bid and Offer) 的价格成交，SOR 必须考虑多个交易所的报价
- **Access Rule (Rule 610)**：限制交易所手续费上限 $0.003/股（影响 SOR 成本模型）
- **Sub-Penny Rule (Rule 612)**：$1.00 以上股票最小报价增量为 $0.01，以下为 $0.0001

#### 2.1.4 Pattern Day Trader (PDT) Rule -- FINRA Rule 4210

- 保证金账户在 5 个工作日内进行 4 次或以上日内交易（同标的当日买卖）→ 被标记为 PDT
- PDT 账户净资产必须 >= $25,000
- 不满足时，限制为 3 次日内交易 / 5 个工作日

### 2.2 香港市场 (SFC / HKEX)

#### 2.2.1 SFC 证券及期货条例

- 持牌人必须保存所有交易记录至少 **7 年**
- 必须记录下单时间、执行时间、客户身份
- 客户订单必须得到 Best Execution

#### 2.2.2 HKEX 交易规则

- **LotSize（每手股数）**：港股必须以整手为单位交易（碎股只能在碎股市场卖出）
- **Tick Size（最小价格变动）**：根据股价区间有不同的 Tick Size
- **收市竞价**：16:00-16:10 仅接受竞价限价单
- **午休**：12:00-13:00 不接受新订单
- **卖空限制**：仅允许指定的卖空证券，需要借券确认

#### 2.2.3 SFC 卖空规则

- 只有在「指定证券」名单内的股票才能卖空
- 卖空订单价格不得低于当前最佳卖出价（Uptick Rule 的变体）
- 卖空持仓需每日报告给 HKEX

### 2.3 跨市场合规差异总结

| 合规要求 | 美股 | 港股 |
|----------|------|------|
| 记录保存 | 7 年 (SEC 17a-4) | 7 年 (SFO) |
| 审计追踪 | CAT 上报 (T+1) | SFC 交易记录保存 |
| 最佳执行 | Reg NMS 611 | SFC Best Execution |
| PDT 规则 | 4 次/5 天 + $25K 要求 | 不适用 |
| 卖空规则 | Reg SHO (Locate + Uptick) | 指定证券 + Uptick |
| 结算周期 | T+1 | T+2 |
| 碎股交易 | 支持 (fractional shares) | 仅整手 (碎股只能卖) |
| 盘前盘后 | 限价单 only (04:00-20:00 ET) | 有限 (收市竞价) |

---

## 3. 市场差异 (US vs HK)

### 3.1 交易时段对比

```
美股交易时段 (Eastern Time)
├── 盘前交易   04:00 - 09:30  (Pre-Market)    → 仅限价单
├── 常规交易   09:30 - 16:00  (Regular Hours) → 所有订单类型
└── 盘后交易   16:00 - 20:00  (After Hours)   → 仅限价单

港股交易时段 (Hong Kong Time)
├── 开市前时段  09:00 - 09:30  (Pre-Opening)   → 竞价限价盘
├── 持续交易    09:30 - 12:00  (Morning)       → 所有订单类型
├── 午间休市    12:00 - 13:00  (Lunch Break)   → 不接受订单
├── 持续交易    13:00 - 16:00  (Afternoon)     → 所有订单类型
└── 收市竞价    16:00 - 16:10  (Closing Auction) → 竞价限价盘
```

### 3.2 订单类型支持矩阵

| 订单类型 | 代码 | US | HK | FIX OrdType | 说明 |
|----------|------|:--:|:--:|-------------|------|
| 市价单 | MARKET | Y | Y | 1 | 以当前最优价格立即执行 |
| 限价单 | LIMIT | Y | Y | 2 | 指定价格或更优 |
| 止损单 | STOP | Y | Y | 3 | 触达 StopPrice 后转市价 |
| 止损限价单 | STOP_LIMIT | Y | Y | 4 | 触达 StopPrice 后转限价 |
| 追踪止损单 | TRAILING_STOP | Y | N | P | 止损价跟随市价浮动 |
| 开盘市价单 | MOO | Y | Y | - | 开盘集合竞价市价 |
| 收盘市价单 | MOC | Y | Y | - | 收盘集合竞价市价 |

| 有效期类型 | 代码 | US | HK | FIX TimeInForce | 说明 |
|------------|------|:--:|:--:|-----------------|------|
| 当日有效 | DAY | Y | Y | 0 | 收盘自动取消 |
| 有效至取消 | GTC | Y | Y | 1 | 持续有效 (max 90 天) |
| 立即成交或取消 | IOC | Y | Y | 3 | 尽量成交，剩余取消 |
| 全额成交或取消 | AON | Y | N | - | 必须全部成交 |

### 3.3 港股特殊规则

#### 3.3.1 LotSize（每手股数）

港股交易必须以整手（board lot）为单位。每手股数因标的而异：

| 标的 | 股票代码 | 每手股数 | 示例价格 | 每手金额约 |
|------|----------|----------|----------|-----------|
| 腾讯控股 | 0700.HK | 100 | HK$350 | HK$35,000 |
| 阿里巴巴 | 9988.HK | 100 | HK$80 | HK$8,000 |
| 汇丰控股 | 0005.HK | 400 | HK$60 | HK$24,000 |
| 长和 | 0001.HK | 500 | HK$45 | HK$22,500 |
| 中国移动 | 0941.HK | 500 | HK$65 | HK$32,500 |

OMS 校验逻辑：`order.Quantity % lotSize != 0` → 拒绝

碎股（odd lot）只能在专门的碎股市场卖出，不能买入碎股。

#### 3.3.2 Tick Size（价格最小变动单位）

港交所的 Tick Size 根据股价区间分级：

| 价格区间 (HK$) | Tick Size (HK$) | 示例 |
|----------------|----------------|------|
| 0.01 - 0.25 | 0.001 | $0.123 合法, $0.1235 非法 |
| 0.25 - 0.50 | 0.005 | $0.305 合法, $0.302 非法 |
| 0.50 - 10.00 | 0.010 | $5.23 合法, $5.235 非法 |
| 10.00 - 20.00 | 0.020 | $15.34 合法, $15.35 非法 |
| 20.00 - 100.00 | 0.050 | $55.15 合法, $55.13 非法 |
| 100.00 - 200.00 | 0.100 | $150.3 合法, $150.35 非法 |
| 200.00 - 500.00 | 0.200 | $350.4 合法, $350.3 非法 |
| 500.00 - 1000.00 | 0.500 | $750.5 合法, $750.3 非法 |
| 1000.00 - 2000.00 | 1.000 | $1500 合法, $1500.50 非法 |
| 2000.00 - 5000.00 | 2.000 | $3500 合法, $3501 非法 |
| >= 5000.00 | 5.000 | $6000 合法, $6003 非法 |

OMS 校验实现：

```go
func isValidTickSize(price decimal.Decimal, market string) bool {
    if market != "HK" {
        return true // 美股 tick size 由交易所验证
    }

    tick := getHKTickSize(price)
    // price 必须是 tick 的整数倍
    remainder := price.Mod(tick)
    return remainder.Equal(decimal.Zero)
}

func getHKTickSize(price decimal.Decimal) decimal.Decimal {
    // HKEX Tick Size 表
    ranges := []struct {
        min, max, tick decimal.Decimal
    }{
        {d("0.01"), d("0.25"), d("0.001")},
        {d("0.25"), d("0.50"), d("0.005")},
        {d("0.50"), d("10.00"), d("0.010")},
        {d("10.00"), d("20.00"), d("0.020")},
        {d("20.00"), d("100.00"), d("0.050")},
        {d("100.00"), d("200.00"), d("0.100")},
        {d("200.00"), d("500.00"), d("0.200")},
        {d("500.00"), d("1000.00"), d("0.500")},
        {d("1000.00"), d("2000.00"), d("1.000")},
        {d("2000.00"), d("5000.00"), d("2.000")},
        {d("5000.00"), d("999999.00"), d("5.000")},
    }

    for _, r := range ranges {
        if price.GreaterThanOrEqual(r.min) && price.LessThan(r.max) {
            return r.tick
        }
    }
    return d("5.000") // 默认最大 tick
}
```

#### 3.3.3 午休时段处理

港股 12:00-13:00 HKT 午间休市：
- 不接受新订单提交
- 已存在的未成交订单在午休期间不会被撮合
- 13:00 持续交易恢复后，未成交限价单继续有效
- OMS 在午休时段收到下单请求应返回 `ErrLunchBreak`

#### 3.3.4 收市竞价时段 (CAS)

16:00-16:10 HKT 收市竞价时段：
- 仅接受竞价限价盘（At-Auction Limit Order）
- 不接受市价单
- 价格必须在参考价的 +/- 5% 范围内
- 成交价为单一收市价格

### 3.4 美股特殊规则

#### 3.4.1 盘前盘后交易

```
盘前 (Pre-Market): 04:00 - 09:30 ET
盘后 (After Hours): 16:00 - 20:00 ET

限制:
- 仅接受限价单 (LIMIT)
- 不支持 MOO/MOC/STOP/TRAILING_STOP
- TimeInForce 只能是 DAY
- 流动性较低，价差较大
- 不是所有 broker 都支持所有标的的盘前盘后交易
```

OMS 校验：
```go
if (session == SessionPre || session == SessionPost) {
    if order.Type != TypeLimit {
        return ErrExtendedHoursLimitOnly
    }
    if order.TimeInForce != TIFDay {
        return ErrExtendedHoursDayOnly
    }
}
```

#### 3.4.2 碎股交易 (Fractional Shares)

美股支持碎股交易（如买入 0.5 股 AAPL）：
- 碎股订单通常以市价执行
- 碎股部分不在交易所成交，由 broker 内部撮合或与流动性提供商交易
- 当前代码中 `Quantity` 为 `int64`，如需支持碎股需改为 `decimal.Decimal`
- 碎股交易不参与 pre-market / after-hours
- 碎股不支持限价单（部分 broker 支持，但不常见）

**注意**：当前系统 `Order.Quantity` 为 `int64` 类型，暂不支持碎股交易。如未来需要支持，需要重大重构：
- `Quantity`、`FilledQty`、`RemainingQty` 改为 `decimal.Decimal`
- 数据库 `quantity` 列改为 `NUMERIC(20, 8)`
- gRPC proto 中 `quantity` 改为 `string` 类型
- 所有涉及数量比较和计算的逻辑需要适配

#### 3.4.3 美股 Tick Size

| 价格 | Tick Size | 说明 |
|------|-----------|------|
| >= $1.00 | $0.01 | Sub-Penny Rule (Reg NMS 612) |
| < $1.00 | $0.0001 | 允许更精细报价 |

### 3.5 手续费差异

#### 美股费用结构

| 费用项 | 费率 | 适用方向 | 收取方 |
|--------|------|----------|--------|
| Commission | $0.005/股 (可配置) | 双向 | 平台 |
| SEC Fee | 0.00278% of 成交金额 | 仅卖出 | SEC |
| FINRA TAF | $0.000166/股 | 仅卖出 | FINRA |
| Exchange Fee | ~$0.003/股 (因 venue 异) | 双向 | 交易所 |

#### 港股费用结构

| 费用项 | 费率 | 最低收费 | 适用方向 | 收取方 |
|--------|------|----------|----------|--------|
| Commission | 0.03% | HK$3 | 双向 | 平台 |
| Stamp Duty (印花税) | 0.13% | 不足 $1 按 $1 计 (进1) | 双向 | 港府 |
| Trading Levy (交易征费) | 0.0027% | - | 双向 | SFC |
| Trading Fee (交易费) | 0.00565% | - | 双向 | HKEX |
| Platform Fee | HK$0.50/笔 | - | 双向 | 平台 |

---

## 4. 技术架构

### 4.1 订单状态机

这是 OMS 的核心数据结构。当前代码库定义了 11 个状态和严格的转换规则：

```
                              ┌──────────────────┐
                              │   CREATED (1)     │
                              │   订单已创建       │
                              └────────┬─────────┘
                                       │
                              validate() / reject()
                                       │
                          ┌────────────┼─────────────┐
                          │            │             │
                          │            ▼             ▼
                          │   ┌──────────────┐  ┌───────────────┐
                          │   │ VALIDATED (2) │  │ REJECTED (10) │
                          │   │ 校验通过      │  │ 被拒绝 [终态]  │
                          │   └──────┬───────┘  └───────────────┘
                          │          │                    ▲
                          │   riskCheck() / reject()      │
                          │          │                    │
                          │   ┌──────┴────────────────────┘
                          │   │      │
                          │   │      ▼
                          │   │  ┌───────────────────┐
                          │   │  │ RISK_APPROVED (3)  │
                          │   │  │ 风控通过            │
                          │   │  └────────┬──────────┘
                          │   │           │
                          │   │    submit() → FIX NewOrderSingle (D)
                          │   │           │
                          │   │           ▼
                          │   │  ┌───────────────────┐
                          │   │  │   PENDING (4)      │
                          │   │  │ 已发送至交易所      │
                          │   │  └────────┬──────────┘
                          │   │           │
                          │   │    exchange_ack() / exchange_reject()
                          │   │           │
                          │   │  ┌────────┼──────────────────┐
                          │   │  │        │                  │
                          │   │  │        ▼                  ▼
                          │   │  │  ┌──────────────┐  ┌────────────────────┐
                          │   │  │  │   OPEN (5)    │  │ EXCHANGE_REJECT(11)│
                          │   │  │  │ 交易所已确认  │  │ 交易所拒绝 [终态]  │
                          │   │  │  └───┬──┬──┬────┘  └────────────────────┘
                          │   │  │      │  │  │
                          │   │  │      │  │  └── cancel() ──┐
                          │   │  │      │  │                 ▼
                          │   │  │      │  │          ┌──────────────┐
                          │   │  │      │  │          │CANCEL_SENT(8)│
                          │   │  │      │  │          │取消请求已发送 │
                          │   │  │      │  │          └───┬──┬──┬───┘
                          │   │  │      │  │              │  │  │
                          │   │  │      │  │  cancel_ack()│  │  │fill()/partial()
                          │   │  │      │  │              ▼  │  │
                          │   │  │      │  │   ┌───────────┐ │  │
                          │   │  │      │  │   │CANCELLED  │ │  │
                          │   │  │      │  │   │(9) [终态] │ │  │
                          │   │  │      │  │   └───────────┘ │  │
                          │   │  │      │  │                 │  │
                  fill()  │   │  │      │  │                 │  │
                          │   │  │      │  │  fill()         │  │
                          │   │  │      ▼  ▼                 ▼  ▼
                          │   │  │  ┌──────────────┐  ┌────────────────┐
                          │   │  │  │  FILLED (7)  │  │PARTIAL_FILL(6)│◄─┐
                          │   │  │  │ 全部成交     │  │ 部分成交       │──┘
                          │   │  │  │   [终态]     │  │               │ (自循环)
                          │   │  │  └──────────────┘  └───────────────┘
```

#### 4.1.1 状态转换规则（Go 实现）

直接对应代码库 `src/internal/order/order.go`：

```go
var validTransitions = map[Status][]Status{
    StatusCreated:        {StatusValidated, StatusRejected},
    StatusValidated:      {StatusRiskApproved, StatusRejected},
    StatusRiskApproved:   {StatusPending},
    StatusPending:        {StatusOpen, StatusExchangeReject, StatusRejected},
    StatusOpen:           {StatusPartialFill, StatusFilled, StatusCancelSent},
    StatusPartialFill:    {StatusPartialFill, StatusFilled, StatusCancelSent},
    StatusCancelSent:     {StatusCancelled, StatusFilled, StatusPartialFill},
    // 终态: 不允许任何转换
    StatusFilled:         {},
    StatusCancelled:      {},
    StatusRejected:       {},
    StatusExchangeReject: {},
}
```

#### 4.1.2 关键转换路径分析

| 转换 | 触发条件 | 系统动作 |
|------|----------|----------|
| CREATED -> VALIDATED | Validator.Validate() 通过 | 记录 order_event |
| CREATED -> REJECTED | Validator.Validate() 失败 | 记录 reject_reason, 发布 order.rejected 事件 |
| VALIDATED -> RISK_APPROVED | Risk Engine 8 道检查全部通过 | 记录 risk_result JSONB |
| VALIDATED -> REJECTED | 任一风控检查失败 | 记录 reject_reason + risk_result |
| RISK_APPROVED -> PENDING | FIX NewOrderSingle 成功发送 | 记录 submitted_at |
| PENDING -> OPEN | Exchange ExecutionReport (ExecType=NEW) | 记录 exchange_order_id |
| PENDING -> EXCHANGE_REJECT | Exchange ExecutionReport (ExecType=REJECTED) | 记录 Text 作为 reject_reason |
| OPEN -> PARTIAL_FILL | ExecutionReport (ExecType=PARTIAL_FILL) | 更新 filled_qty, avg_fill_price, remaining_qty |
| PARTIAL_FILL -> PARTIAL_FILL | 继续部分成交 | 累计更新 filled_qty, avg_fill_price |
| OPEN/PARTIAL_FILL -> FILLED | ExecutionReport (ExecType=FILL, LeavesQty=0) | 记录 completed_at, 触发 Post-Trade |
| OPEN/PARTIAL_FILL -> CANCEL_SENT | FIX OrderCancelRequest 发送 | 等待交易所确认 |
| CANCEL_SENT -> CANCELLED | Exchange 确认取消 | 记录 completed_at |
| CANCEL_SENT -> FILLED | 取消请求发出前已全部成交 | 竞争条件处理 |
| CANCEL_SENT -> PARTIAL_FILL | 取消请求发出前有部分成交 | 继续等待取消确认 |

#### 4.1.3 终态定义

```go
func (sm *StateMachine) IsTerminal(status Status) bool {
    transitions, ok := validTransitions[status]
    return ok && len(transitions) == 0
}
// 终态: FILLED(7), CANCELLED(9), REJECTED(10), EXCHANGE_REJECT(11)
```

终态的业务含义：
- **FILLED**：订单全部成交，进入 Post-Trade 处理
- **CANCELLED**：订单被用户或系统成功取消
- **REJECTED**：订单在内部校验或风控阶段被拒绝
- **EXCHANGE_REJECT**：订单被交易所拒绝（如价格超限、标的停牌等）

### 4.2 幂等性设计

#### 4.2.1 Idempotency-Key 机制

每个下单请求必须携带一个 UUID v4 格式的 Idempotency-Key。系统保证：相同的 Idempotency-Key 只会创建一个订单。

```
幂等性检查流程:

  Client                Redis                    OMS
    │                     │                       │
    │  SubmitOrder        │                       │
    │  (idem_key=abc-123) │                       │
    │ ──────────────────▶ │                       │
    │                     │                       │
    │                     │  SET NX abc-123       │
    │                     │  EXPIRE 72h            │
    │                     │ ◄─────────────────     │
    │                     │                       │
    │                     │  if SET success:       │
    │                     │    → 新请求，继续处理   │
    │                     │    ───────────────────▶│
    │                     │                       │
    │                     │  if SET fail (exists): │
    │                     │    → 查找已有订单       │
    │                     │    → 返回已有响应       │
    │ ◄──────────────────────────────────────────│
```

关键实现要点：

```go
type IdempotencyService struct {
    redis *redis.Client
    repo  order.Repository
}

func (s *IdempotencyService) CheckOrCreate(ctx context.Context, key string) (*order.Order, bool, error) {
    // SET NX with 72h TTL
    set, err := s.redis.SetNX(ctx, "idem:"+key, "processing", 72*time.Hour).Result()
    if err != nil {
        return nil, false, fmt.Errorf("redis set nx: %w", err)
    }

    if set {
        // 新请求
        return nil, true, nil
    }

    // 重复请求 -- 查找已有订单
    existing, err := s.repo.GetByIdempotencyKey(ctx, key)
    if err != nil {
        return nil, false, fmt.Errorf("get by idempotency key: %w", err)
    }
    return existing, false, nil
}
```

#### 4.2.2 数据库层幂等保障

除了 Redis，数据库层也有幂等保障：

```sql
-- orders 表的 idempotency_key 有唯一约束
UNIQUE (idempotency_key, created_at)
```

即使 Redis 故障，数据库唯一约束也能防止重复订单。

#### 4.2.3 ExecID 去重

交易所的 ExecutionReport 也需要幂等处理，通过 `ExecID` 去重：

```go
func (h *ExecutionHandler) HandleReport(report *ExecutionReport) error {
    // ExecID 幂等检查
    if h.isDuplicate(report.ExecID) {
        log.Warn("duplicate execution report", zap.String("exec_id", report.ExecID))
        return nil // 静默忽略
    }
    // ... 正常处理
}
```

### 4.3 Event Sourcing (事件溯源)

#### 4.3.1 order_events 表设计

```sql
CREATE TABLE order_events (
    id          BIGSERIAL PRIMARY KEY,
    event_id    UUID UNIQUE NOT NULL,       -- 事件唯一标识
    order_id    UUID NOT NULL,              -- 关联的订单 ID
    event_type  TEXT NOT NULL,              -- 事件类型
    event_data  JSONB NOT NULL,             -- 事件负载（完整快照）
    sequence    INT NOT NULL,               -- 同一订单内的事件序号（单调递增）
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_events_order ON order_events (order_id, sequence);
CREATE INDEX idx_order_events_type ON order_events (event_type, created_at DESC);
```

**关键约束**：
- **Append-Only**：此表禁止 UPDATE 和 DELETE 操作。应用层不应有任何 UPDATE/DELETE SQL。
- **数据库级强制**：生产环境应通过 PostgreSQL Row-Level Security 或 TRIGGER 阻止修改。
- **sequence 单调递增**：同一 order_id 的 sequence 必须连续且递增，用于检测事件丢失。

#### 4.3.2 事件类型定义

| event_type | 触发时机 | event_data 关键字段 |
|------------|----------|-------------------|
| `ORDER_CREATED` | Submit 接收到 | 完整订单快照 |
| `ORDER_VALIDATED` | Validator 通过 | validation_result |
| `ORDER_RISK_APPROVED` | Risk Engine 通过 | risk_result (8 项检查结果) |
| `ORDER_RISK_REJECTED` | Risk Engine 拒绝 | risk_result, reject_reason |
| `ORDER_SUBMITTED` | FIX 发送成功 | venue, fix_msg_seq_num |
| `ORDER_ACKNOWLEDGED` | 交易所确认 | exchange_order_id |
| `ORDER_EXCHANGE_REJECTED` | 交易所拒绝 | reject_reason, exchange_text |
| `ORDER_PARTIAL_FILL` | 部分成交 | exec_id, last_qty, last_px, cum_qty, avg_px, leaves_qty |
| `ORDER_FILLED` | 全部成交 | exec_id, last_qty, last_px, cum_qty, avg_px |
| `CANCEL_REQUESTED` | 用户发起取消 | cancel_reason |
| `CANCEL_SENT` | FIX Cancel 发送 | fix_msg_seq_num |
| `ORDER_CANCELLED` | 交易所确认取消 | cancelled_qty |
| `ORDER_REJECTED` | 内部拒绝 | reject_reason, stage |

#### 4.3.3 event_data JSONB 结构示例

```json
// ORDER_CREATED
{
  "order_id": "550e8400-e29b-41d4-a716-446655440000",
  "account_id": 12345,
  "symbol": "AAPL",
  "market": "US",
  "side": "BUY",
  "type": "LIMIT",
  "time_in_force": "DAY",
  "quantity": 100,
  "price": "150.25",
  "source": "IOS",
  "ip_address": "203.198.1.100",
  "device_id": "dev-abc-123",
  "idempotency_key": "660e8400-e29b-41d4-a716-446655440001"
}

// ORDER_PARTIAL_FILL
{
  "exec_id": "exec-001",
  "exchange_exec_id": "NYSE-20260316-00001",
  "last_qty": 50,
  "last_px": "149.98",
  "cum_qty": 50,
  "avg_px": "149.98",
  "leaves_qty": 50,
  "commission": "0.25",
  "venue": "NYSE",
  "transact_time": "2026-03-16T14:30:00.123456Z"
}

// ORDER_RISK_APPROVED
{
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
  "total_duration_us": 1485
}
```

#### 4.3.4 Event Replay (事件回放)

事件溯源的核心优势是可以从事件序列重建任意时刻的订单状态：

```go
func ReplayOrderState(events []*OrderEvent) (*Order, error) {
    var order Order
    for _, event := range events {
        switch event.EventType {
        case "ORDER_CREATED":
            order = orderFromCreatedEvent(event.EventData)
        case "ORDER_VALIDATED":
            order.Status = StatusValidated
        case "ORDER_RISK_APPROVED":
            order.Status = StatusRiskApproved
        case "ORDER_SUBMITTED":
            order.Status = StatusPending
            order.SubmittedAt = event.CreatedAt
        case "ORDER_ACKNOWLEDGED":
            order.Status = StatusOpen
            order.ExchangeOrderID = event.EventData["exchange_order_id"]
        case "ORDER_PARTIAL_FILL":
            order.Status = StatusPartialFill
            order.FilledQty = event.EventData["cum_qty"]
            order.AvgFillPrice = event.EventData["avg_px"]
            order.RemainingQty = event.EventData["leaves_qty"]
        case "ORDER_FILLED":
            order.Status = StatusFilled
            order.FilledQty = event.EventData["cum_qty"]
            order.AvgFillPrice = event.EventData["avg_px"]
            order.RemainingQty = 0
            order.CompletedAt = event.CreatedAt
        case "ORDER_CANCELLED":
            order.Status = StatusCancelled
            order.CompletedAt = event.CreatedAt
        }
    }
    return &order, nil
}
```

### 4.4 CQRS 模式

```
                    ┌──────────────────────────────────┐
                    │         Write Path (命令路径)      │
                    │                                   │
  SubmitOrder ─────▶│ OMS → Validate → Risk → SOR → FIX│
  CancelOrder ─────▶│    ↓                              │
                    │ PostgreSQL (orders, order_events)  │
                    │    ↓                              │
                    │ Kafka (order.* events)            │
                    └──────────────────────────────────┘
                                   │
                                   ▼ (异步消费)
                    ┌──────────────────────────────────┐
                    │         Read Path (查询路径)       │
                    │                                   │
  GetOrder ────────▶│ Redis Cache (热数据)               │
  ListOrders ──────▶│    ↓ miss                         │
  StreamUpdates ───▶│ PostgreSQL Read Replica            │
                    │    ↓                              │
                    │ Elasticsearch (全文搜索/CAT审计)   │
                    └──────────────────────────────────┘
```

写路径与读路径分离的好处：
1. 写路径专注低延迟：5ms p99 内完成验证+风控
2. 读路径可以独立扩展 Read Replica
3. 订单状态推送通过 Kafka -> WebSocket 实现，不影响写路径性能
4. 历史订单查询走 Elasticsearch，不影响在线交易数据库

### 4.5 数据库分区策略

```sql
-- orders 表按月分区（基于 created_at）
CREATE TABLE orders (
    id              BIGSERIAL,
    order_id        UUID NOT NULL,
    -- ... 其他字段
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, created_at),
    UNIQUE (order_id, created_at),
    UNIQUE (idempotency_key, created_at)
) PARTITION BY RANGE (created_at);

-- 自动创建分区（需要 cron job 或 pg_partman 扩展）
CREATE TABLE orders_2026_03 PARTITION OF orders
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE orders_2026_04 PARTITION OF orders
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
```

分区策略考量：
- **为什么按月**：交易数据量大但查询通常限定在近期，月度分区平衡了分区数量和数据量
- **分区裁剪**：查询时带 `created_at` 范围条件可自动裁剪不相关分区
- **归档**：7 年以上数据可以 DETACH 分区并迁移到 cold storage
- **部分索引**：活跃订单使用部分索引提升查询性能

```sql
-- 仅索引活跃状态的订单（节省 90%+ 的索引空间）
CREATE INDEX idx_orders_active ON orders (status, created_at DESC)
    WHERE status IN ('OPEN', 'PARTIAL_FILL', 'PENDING', 'CANCEL_SENT');
```

### 4.6 订单修改与撤销流程

#### 4.6.1 订单撤销 (Cancel)

```
  Client                    OMS                     FIX Engine              Exchange
    │                        │                         │                       │
    │  CancelOrder(order_id) │                         │                       │
    │───────────────────────▶│                         │                       │
    │                        │                         │                       │
    │                        │ 1. 查找订单              │                       │
    │                        │ 2. 校验: 是否可取消       │                       │
    │                        │    (OPEN/PARTIAL_FILL)   │                       │
    │                        │ 3. 状态 → CANCEL_SENT    │                       │
    │                        │                         │                       │
    │                        │ OrderCancelRequest (F)   │                       │
    │                        │────────────────────────▶│                       │
    │                        │                         │ FIX MsgType=F         │
    │                        │                         │──────────────────────▶│
    │                        │                         │                       │
    │                        │                         │ ExecutionReport (8)   │
    │                        │                         │ ExecType=CANCELLED    │
    │                        │                         │◄──────────────────────│
    │                        │                         │                       │
    │                        │◄────────────────────────│                       │
    │                        │ 4. 状态 → CANCELLED      │                       │
    │                        │ 5. 发布 order.cancelled  │                       │
    │◄───────────────────────│                         │                       │
```

取消请求可能被交易所拒绝（OrderCancelReject, MsgType=9）：
- 订单已全部成交
- 订单已被交易所取消
- 订单处于不可取消状态

OMS 必须处理 CANCEL_SENT 状态下的竞争条件：
- 取消请求发出后，交易所可能先返回成交回报再返回取消确认
- CANCEL_SENT -> PARTIAL_FILL 和 CANCEL_SENT -> FILLED 都是合法转换

#### 4.6.2 订单修改 (Cancel-Replace)

FIX 协议不支持直接修改订单，而是通过 Cancel-Replace（MsgType=G）实现：

```
修改流程:
1. 客户端请求修改订单（改价格或数量）
2. OMS 生成新的 ClOrdID
3. 发送 OrderCancelReplaceRequest (MsgType=G)
   - OrigClOrdID = 原订单的 ClOrdID
   - ClOrdID = 新生成的 ClOrdID
   - 新的 Price / Quantity
4. 交易所接受: 返回 ExecutionReport (ExecType=REPLACED)
   - 原订单取消，新订单生效
5. 交易所拒绝: 返回 OrderCancelReject (MsgType=9)
   - 原订单保持不变
```

**注意**：当前代码库的 Order Service 接口中没有 Amend/Modify 方法。如果需要支持改单，需要新增：

```go
type Service interface {
    Submit(ctx context.Context, req *SubmitRequest) (*SubmitResponse, error)
    Cancel(ctx context.Context, orderID string, accountID int64) error
    // 新增: 改单
    Amend(ctx context.Context, req *AmendRequest) (*AmendResponse, error)
    Get(ctx context.Context, orderID string) (*Order, error)
    List(ctx context.Context, req *ListRequest) (*ListResponse, error)
    HandleExecutionReport(ctx context.Context, report *ExecutionReport) error
}

type AmendRequest struct {
    OrderID     string
    AccountID   int64
    NewPrice    decimal.Decimal // 新价格 (零值表示不修改)
    NewQuantity int64           // 新数量 (零值表示不修改)
}
```

### 4.7 超时自动撤销

#### 4.7.1 DAY 单日终自动取消

DAY 类型订单在交易日结束时自动取消。实现方式：

```go
// DayOrderCanceller 日终取消定时任务
type DayOrderCanceller struct {
    orderRepo    order.Repository
    fixEngine    FIXEngine
    calendar     MarketCalendarService
}

// CancelExpiredDayOrders 在市场收盘后执行
// US: 16:00 ET (如有盘后交易则 20:00 ET)
// HK: 16:10 HKT (收市竞价结束后)
func (c *DayOrderCanceller) CancelExpiredDayOrders(ctx context.Context, market string) error {
    // 1. 查找所有 DAY + 未终态 的订单
    activeOrders, err := c.orderRepo.GetActiveDayOrders(ctx, market)
    if err != nil {
        return fmt.Errorf("get active day orders: %w", err)
    }

    for _, ord := range activeOrders {
        // 2. 发送取消请求至交易所
        err := c.fixEngine.SendCancelOrder(ctx, ord.OrderID, ord.ClientOrderID)
        if err != nil {
            log.Error("cancel day order failed",
                zap.String("order_id", ord.OrderID),
                zap.Error(err))
            continue
        }

        // 3. 更新状态为 CANCEL_SENT
        ord.Status = order.StatusCancelSent
        c.orderRepo.Update(ctx, ord)
    }
    return nil
}
```

#### 4.7.2 GTC 单最大有效期

GTC (Good Till Cancel) 订单最长有效期为 90 个自然日。超过 90 天未成交的 GTC 订单自动取消。

#### 4.7.3 Pending 超时处理

如果订单在 PENDING 状态超过 30 秒没有收到交易所 ACK，系统应：
1. 查询交易所订单状态
2. 如果交易所无此订单记录 → 标记为 REJECTED
3. 如果交易所有记录但回报丢失 → 同步状态

---

## 5. 性能要求与设计决策

### 5.1 延迟预算分配

```
总预算: 订单接收到交易所 < 10ms (p99)

  ┌──────────────────────────────────────────────────────┐
  │  Stage            │  预算 (p99)  │  优化策略           │
  ├──────────────────────────────────────────────────────┤
  │  幂等检查 (Redis)  │  0.5ms      │  Redis 本地连接     │
  │  订单校验          │  0.5ms      │  内存中校验         │
  │  风控检查 (8道)    │  3.0ms      │  缓存+短路         │
  │  DB 写入 (orders)  │  2.0ms      │  异步+批量         │
  │  SOR 路由决策      │  1.0ms      │  内存行情缓存      │
  │  FIX 消息构造+发送 │  1.0ms      │  连接池+预分配     │
  │  网络传输          │  2.0ms      │  co-location       │
  ├──────────────────────────────────────────────────────┤
  │  TOTAL             │  10.0ms     │                    │
  └──────────────────────────────────────────────────────┘
```

### 5.2 关键设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 状态机实现 | 自研 (非第三方库) | 关键路径零依赖，完全可控 |
| 金额类型 | `shopspring/decimal` | 禁止 float64，金融精度 |
| 时间戳 | Unix nanos (`int64`) | 纳秒精度，避免 time.Time 序列化开销 |
| DB | PostgreSQL + 月度分区 | JSONB 支持 + 分区裁剪 |
| 缓存 | Redis (idem key, buying power) | 亚毫秒读写 |
| 消息队列 | Kafka | 持久化 + 高吞吐 + 事件重放 |
| RPC | gRPC (内部) + REST (外部) | gRPC 低延迟，REST 兼容性 |
| FIX | quickfixgo/quickfix | Go 生态最成熟的 FIX 库 |
| 日志 | uber-go/zap | 零分配结构化日志 |

### 5.3 吞吐量设计

目标：10,000+ orders/sec 峰值

```
架构:
  API Gateway (N 个 Pod)
       │
       ▼
  OMS Worker Pool (goroutine pool)
       │
  ┌────┼────┐
  ▼    ▼    ▼
 DB  Redis  Kafka  ← 均采用连接池
       │
       ▼
  FIX Engine (per-venue goroutine)
```

关键优化：
- **goroutine pool**：限制并发数，防止 DB 连接耗尽
- **batch write**：order_events 可以批量写入（微批次 1-5ms 窗口）
- **pipeline**：Redis 操作使用 Pipeline 减少 RTT
- **zero-copy FIX**：FIX 消息构造避免内存分配

### 5.4 可用性设计

目标：99.99% (盘中 ~4 分钟/年 不可用)

| 策略 | 实现 |
|------|------|
| 多实例部署 | K8s Deployment replicas >= 3 |
| 数据库高可用 | PostgreSQL Primary + Sync Standby + Async Read Replica |
| Redis 高可用 | Redis Sentinel 或 Redis Cluster |
| FIX 重连 | Circuit Breaker + Exponential Backoff |
| 消息持久化 | Kafka replication factor = 3 |
| 健康检查 | gRPC Health Check + FIX Session 心跳 |

---

## 6. 接口设计 (gRPC / REST / Kafka Events)

### 6.1 gRPC Service 定义

基于代码库 `docs/specs/api/grpc/trading.proto`：

```protobuf
service OrderService {
  // 提交新订单
  rpc SubmitOrder(SubmitOrderRequest) returns (SubmitOrderResponse);
  // 取消订单
  rpc CancelOrder(CancelOrderRequest) returns (CancelOrderResponse);
  // 查询单个订单
  rpc GetOrder(GetOrderRequest) returns (GetOrderResponse);
  // 查询订单列表
  rpc ListOrders(ListOrdersRequest) returns (ListOrdersResponse);
  // 订单状态流式推送
  rpc StreamOrderUpdates(StreamOrderUpdatesRequest) returns (stream OrderUpdate);
}
```

#### 6.1.1 SubmitOrder 请求/响应

```protobuf
message SubmitOrderRequest {
  int64       account_id = 1;       // 账户 ID
  string      symbol = 2;           // 标的代码 "AAPL" / "0700.HK"
  Market      market = 3;           // MARKET_US / MARKET_HK
  OrderSide   side = 4;             // SIDE_BUY / SIDE_SELL
  OrderType   type = 5;             // TYPE_MARKET / TYPE_LIMIT / ...
  TimeInForce time_in_force = 6;    // TIF_DAY / TIF_GTC / TIF_IOC / TIF_AON
  int64       quantity = 7;         // 数量 (整数)
  string      price = 8;            // 限价 (string 类型保精度)
  string      stop_price = 9;       // 止损价
  string      trail_amount = 10;    // 追踪止损偏移
  string      idempotency_key = 11; // UUID v4 幂等键
  string      source = 12;          // IOS / ANDROID / WEB / API
  string      device_id = 13;       // 设备 ID
}

message SubmitOrderResponse {
  string      order_id = 1;         // 系统生成的订单 ID (UUID)
  OrderStatus status = 2;           // 当前状态 (CREATED / REJECTED)
  string      reject_reason = 3;    // 拒绝原因 (仅 REJECTED 时有值)
}
```

**注意**：`price`、`stop_price`、`trail_amount`、`avg_fill_price` 等金额字段在 proto 中使用 `string` 类型，而非 `double`，以保证金融精度。Go 端接收后用 `shopspring/decimal` 解析。

#### 6.1.2 StreamOrderUpdates

服务端流式 RPC，用于实时推送订单状态更新到客户端：

```protobuf
message OrderUpdate {
  Order     order = 1;              // 完整订单快照
  Execution latest_execution = 2;   // 最新成交 (如有)
  string    event_type = 3;         // 事件类型
}
```

客户端连接后，OMS 将该 account_id 的所有订单状态变更实时推送。底层通过 Kafka Consumer -> gRPC Stream 桥接实现。

### 6.2 REST API (通过 API Gateway 暴露)

| Method | Path | 说明 | 幂等 |
|--------|------|------|:----:|
| POST | /api/v1/orders | 提交订单 | Y (Idempotency-Key header) |
| DELETE | /api/v1/orders/{order_id} | 取消订单 | Y |
| GET | /api/v1/orders/{order_id} | 查询订单 | - |
| GET | /api/v1/orders | 查询订单列表 | - |
| GET | /api/v1/positions | 查询持仓 | - |
| GET | /api/v1/portfolio | 查询组合概要 | - |

REST 请求头要求：
```
Authorization: Bearer <jwt_token>
Idempotency-Key: <uuid-v4>          (仅 POST)
X-Device-ID: <device_id>
X-Request-ID: <correlation_id>
X-Signature: <hmac_sha256_signature> (交易类请求)
X-Timestamp: <unix_ms>              (防重放, 30s 窗口)
```

### 6.3 Kafka Events

#### 6.3.1 Topic 设计

| Topic | Partition Key | 消费者 | 说明 |
|-------|---------------|--------|------|
| `order.created` | account_id | Mobile Push, Admin Panel | 订单创建 |
| `order.risk_approved` | account_id | Risk Dashboard | 风控通过 |
| `order.risk_rejected` | account_id | Mobile Push, Risk Dashboard | 风控拒绝 |
| `order.submitted` | order_id | Monitoring | 已发送至交易所 |
| `order.acknowledged` | order_id | Monitoring | 交易所确认 |
| `order.partial_fill` | account_id | Mobile Push, Position Engine | 部分成交 |
| `order.filled` | account_id | Mobile Push, Position Engine, Settlement | 全部成交 |
| `order.cancelled` | account_id | Mobile Push | 已取消 |
| `order.rejected` | account_id | Mobile Push | 被拒绝 |
| `position.updated` | account_id | Mobile (P&L 推送), Fund Transfer (buying power) | 持仓变更 |
| `margin.call` | account_id | Mobile Push, Admin Panel, Compliance | Margin Call |
| `settlement.completed` | account_id | Fund Transfer | 结算完成 |

#### 6.3.2 事件消息格式

```json
{
  "event_id": "evt-550e8400-e29b-41d4-a716-446655440000",
  "event_type": "order.filled",
  "event_time": "2026-03-16T14:30:00.123456789Z",
  "correlation_id": "req-abc-123",
  "payload": {
    "order_id": "ord-550e8400-e29b-41d4-a716-446655440000",
    "account_id": 12345,
    "user_id": 67890,
    "symbol": "AAPL",
    "market": "US",
    "side": "BUY",
    "type": "LIMIT",
    "quantity": 100,
    "filled_qty": 100,
    "avg_fill_price": "149.99",
    "commission": "0.50",
    "total_fees": "0.50",
    "status": "FILLED",
    "completed_at": "2026-03-16T14:30:00.123456789Z"
  },
  "metadata": {
    "source": "trading-engine",
    "version": "1.0"
  }
}
```

#### 6.3.3 Outbox Pattern (事务性事件发布)

为保证「数据库写入」和「Kafka 发布」的一致性，采用 Outbox Pattern：

```
                    ┌──────────────────────────────┐
                    │       PostgreSQL TX           │
                    │                              │
                    │  1. UPDATE orders SET status  │
                    │  2. INSERT INTO order_events  │
                    │  3. INSERT INTO outbox        │  ← 事件写入 outbox 表
                    │                              │
                    │  COMMIT                       │
                    └──────────────────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │   Outbox Poller (异步)        │
                    │                              │
                    │  SELECT * FROM outbox         │
                    │  WHERE published = false      │
                    │  ORDER BY id ASC              │
                    │  LIMIT 100                    │
                    │                              │
                    │  → 发布到 Kafka               │
                    │  → UPDATE outbox SET          │
                    │    published = true           │
                    └──────────────────────────────┘
```

Outbox 表结构：

```sql
CREATE TABLE outbox (
    id          BIGSERIAL PRIMARY KEY,
    topic       TEXT NOT NULL,
    partition_key TEXT NOT NULL,
    payload     JSONB NOT NULL,
    published   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ
);

CREATE INDEX idx_outbox_unpublished ON outbox (id)
    WHERE published = FALSE;
```

---

## 7. 开源参考实现

### 7.1 FIX 协议

| 项目 | 语言 | 说明 |
|------|------|------|
| [quickfixgo/quickfix](https://github.com/quickfixgo/quickfix) | Go | 本项目选用的 FIX Engine，支持 FIX 4.0-5.0 |
| [quickfixj](https://github.com/quickfixj/quickfixj) | Java | Java 版 QuickFIX，功能最完整 |
| [QuickFIX/C++](https://github.com/quickfix/quickfix) | C++ | 原版 QuickFIX，超低延迟场景 |

quickfixgo 关键概念：
- `Application` 接口：实现 `OnCreate`, `OnLogon`, `OnLogout`, `FromApp`, `ToApp`
- `Session`：一个 FIX 连接实例
- `MessageStore`：消息持久化（FileStore / DBStore）
- `MessageFactory`：消息构造

### 7.2 OMS 参考

| 项目 | 语言 | 说明 |
|------|------|------|
| [lmax-exchange/disruptor](https://github.com/LMAX-Exchange/disruptor) | Java | LMAX 交易所的无锁环形缓冲区 |
| [ray-project/matching-engine](https://github.com/Ray-project/matching-engine) | Go | 简单的订单撮合引擎参考 |
| [chronicle-software](https://chronicle.software/) | Java | 超低延迟交易基础设施 |

### 7.3 Event Sourcing

| 项目 | 语言 | 说明 |
|------|------|------|
| [EventStoreDB](https://www.eventstore.com/) | - | 专业事件存储数据库 |
| [cqrs](https://github.com/ThreeDotsLabs/watermill) | Go | Watermill -- Go 事件驱动框架 |
| [message-db](https://github.com/message-db/message-db) | PostgreSQL | 基于 PostgreSQL 的消息存储 |

### 7.4 金融计算

| 项目 | 语言 | 说明 |
|------|------|------|
| [shopspring/decimal](https://github.com/shopspring/decimal) | Go | 本项目选用的精确十进制库 |
| [cockroachdb/apd](https://github.com/cockroachdb/apd) | Go | CockroachDB 的任意精度十进制库 |
| [govalues/decimal](https://github.com/govalues/decimal) | Go | 更新的高性能 decimal 库 |

---

## 8. PRD Review 检查清单

### 8.1 功能完整性检查

- [ ] 11 个订单状态是否全部覆盖？
- [ ] 所有合法状态转换路径是否有对应的处理逻辑？
- [ ] 所有终态是否有对应的清理逻辑（释放冻结资金、更新统计）？
- [ ] 7 种订单类型 (Market/Limit/Stop/StopLimit/TrailingStop/MOO/MOC) 是否全部实现？
- [ ] 4 种有效期 (DAY/GTC/IOC/AON) 是否全部实现？
- [ ] US 和 HK 市场的订单类型限制是否正确（如 HK 不支持 TRAILING_STOP/AON）？
- [ ] 盘前盘后交易限制是否实现（仅限价单）？
- [ ] 港股午休时段拒绝下单是否实现？
- [ ] 港股收市竞价时段限制是否实现？

### 8.2 数据完整性检查

- [ ] 所有金额字段是否使用 `shopspring/decimal` (Go) / `NUMERIC(20,8)` (DB)？
- [ ] 是否有任何地方使用了 `float64` 进行金额计算？
- [ ] Idempotency-Key 是否在 Redis + DB 双层保障？
- [ ] order_events 表是否 append-only？是否有代码执行 UPDATE/DELETE？
- [ ] 持仓更新与余额更新是否在同一事务中？
- [ ] 乐观锁 (version) 是否在持仓更新时检查？

### 8.3 合规检查

- [ ] 每次状态转换是否都写入 order_events？
- [ ] event_data 是否包含足够的审计信息（IP、设备、时间戳）？
- [ ] 是否支持按 order_id 重建完整订单历史？
- [ ] CAT 上报字段是否全部可从 order_events 中提取？
- [ ] 数据保留策略是否满足 7 年要求？
- [ ] 分区归档策略是否已规划？

### 8.4 性能检查

- [ ] 订单校验+风控 < 5ms (p99) 是否可达？
- [ ] Redis 幂等检查是否有超时保护（建议 1ms 超时）？
- [ ] DB 写入是否有连接池配置？
- [ ] FIX 消息发送是否有 Circuit Breaker？
- [ ] Kafka 事件发布是否异步（不阻塞主路径）？
- [ ] 是否有足够的 Prometheus 指标覆盖每个阶段的延迟？

### 8.5 异常处理检查

- [ ] FIX 连接断开时，PENDING 状态的订单如何处理？
- [ ] 交易所回报丢失时（超时），如何检测和恢复？
- [ ] 数据库故障时，是否有降级策略？
- [ ] Redis 故障时，幂等检查是否退化为 DB 查询？
- [ ] Kafka 发布失败时，Outbox 重试机制是否可靠？
- [ ] CANCEL_SENT 状态下的竞争条件是否正确处理？

---

## 9. 工程落地注意事项

### 9.1 订单 ID 生成策略

```go
// 使用 UUID v4 作为 OrderID
// 优点：全局唯一，无需中央分配
// 缺点：无序，对 B-Tree 索引不友好
// 优化：可考虑使用 UUID v7 (time-sorted) 改善索引局部性
import "github.com/google/uuid"

func NewOrderID() string {
    return uuid.New().String() // UUID v4
}

// 或使用 UUID v7 (Go 1.22+ uuid 库支持)
// UUID v7 包含时间戳，B-Tree 写入更友好
```

### 9.2 时间戳精度

当前代码使用 Unix nanos (`int64`)：

```go
type Order struct {
    // ...
    CreatedAt   int64 // Unix nanos
    SubmittedAt int64
    CompletedAt int64
}
```

Unix nanos 的范围：`int64` 可表示到 2262 年，足够使用。

数据库层使用 `TIMESTAMPTZ`，转换时注意精度：
```go
func unixNanosToTime(nanos int64) time.Time {
    return time.Unix(0, nanos).UTC()
}

func timeToUnixNanos(t time.Time) int64 {
    return t.UnixNano()
}
```

### 9.3 并发安全

订单状态转换必须是原子的。关键并发场景：

1. **同一订单的多个 ExecutionReport 同时到达**：使用 `SELECT FOR UPDATE` 或 Advisory Lock
2. **用户取消 vs 交易所成交的竞争**：状态机严格执行，不合法转换直接拒绝
3. **多个 Pod 处理同一订单**：通过 Kafka 分区保证同一 order_id 的事件由同一 consumer 处理

```go
// 订单级别锁（基于 Redis 分布式锁）
func (s *OrderService) withOrderLock(ctx context.Context, orderID string, fn func() error) error {
    lockKey := fmt.Sprintf("order_lock:%s", orderID)
    lock, err := s.redis.Lock(ctx, lockKey, 5*time.Second)
    if err != nil {
        return fmt.Errorf("acquire order lock: %w", err)
    }
    defer lock.Release(ctx)
    return fn()
}
```

### 9.4 监控指标 (Prometheus)

```go
var (
    // 订单提交计数
    orderSubmitTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "trading_order_submit_total",
            Help: "Total number of order submissions",
        },
        []string{"market", "side", "type", "status"}, // status: accepted/rejected
    )

    // 订单处理延迟
    orderProcessDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "trading_order_process_duration_seconds",
            Help:    "Order processing duration by stage",
            Buckets: []float64{0.001, 0.002, 0.005, 0.01, 0.025, 0.05, 0.1},
        },
        []string{"stage"}, // validate, risk_check, route, fix_send
    )

    // 活跃订单数
    activeOrdersGauge = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "trading_active_orders",
            Help: "Number of active (non-terminal) orders",
        },
        []string{"market", "status"},
    )

    // FIX 会话状态
    fixSessionStatus = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "trading_fix_session_status",
            Help: "FIX session status (1=connected, 0=disconnected)",
        },
        []string{"venue"},
    )

    // 成交处理延迟
    executionProcessDuration = prometheus.NewHistogram(
        prometheus.HistogramOpts{
            Name:    "trading_execution_process_duration_seconds",
            Help:    "Execution report processing duration",
            Buckets: []float64{0.0005, 0.001, 0.002, 0.003, 0.005, 0.01},
        },
    )
)
```

### 9.5 错误处理规范

交易系统的错误处理必须遵循以下原则：

```go
// 1. 永远不要吞掉错误
// BAD:
result, _ := doSomething()

// GOOD:
result, err := doSomething()
if err != nil {
    return fmt.Errorf("do something for order %s: %w", orderID, err)
}

// 2. 错误信息必须包含完整上下文
// BAD:
return fmt.Errorf("order rejected")

// GOOD:
return fmt.Errorf("order %s rejected: account %d, symbol %s, reason: %s",
    order.OrderID, order.AccountID, order.Symbol, reason)

// 3. 区分可重试和不可重试错误
type RetryableError struct {
    Err error
}

type PermanentError struct {
    Err error
}

// 4. FIX 连接错误应触发 Circuit Breaker
// 连续 5 次失败 → 断路器打开 → 30s 后半开 → 1 次成功 → 关闭
```

### 9.6 测试策略

| 测试类型 | 覆盖范围 | 工具 |
|----------|----------|------|
| 单元测试 | 状态机转换、校验逻辑、费用计算 | Go testing + testify |
| 集成测试 | OMS -> DB -> Kafka 全流程 | testcontainers-go |
| FIX 测试 | FIX 消息构造、回报解析 | quickfixgo simulator |
| 压力测试 | 10K orders/sec 峰值 | k6 / vegeta |
| 混沌测试 | DB 故障、Redis 故障、FIX 断连 | chaos-monkey |

关键测试用例：
1. 幂等性：相同 Idempotency-Key 重复提交，应返回相同结果
2. 状态机：所有非法转换必须被拒绝
3. 竞争条件：CANCEL_SENT 状态下同时收到成交回报和取消确认
4. 部分成交：多次 PARTIAL_FILL 后 FILLED 的累计金额计算
5. 港股 LotSize：非整手订单必须被拒绝
6. 港股 TickSize：不符合 Tick 规则的价格必须被拒绝
7. 盘前盘后：非限价单必须被拒绝
8. DAY 单超时：收盘后 DAY 单必须被取消

### 9.7 上线 Checklist

- [ ] 所有 DB migration 已在 staging 环境验证
- [ ] 分区表自动创建任务已配置 (pg_partman 或 cron)
- [ ] Redis 幂等缓存 TTL 已设为 72h
- [ ] Kafka topic 已创建，partition 数量已规划
- [ ] FIX session 配置已获取（SenderCompID, TargetCompID, 密钥）
- [ ] FIX message log 存储路径已配置
- [ ] Prometheus 指标已接入 Grafana dashboard
- [ ] AlertManager 已配置关键告警（FIX 断连、延迟超标、错误率）
- [ ] 日终 DAY 单取消定时任务已配置
- [ ] GTC 90 天过期定时任务已配置
- [ ] 数据库连接池参数已调优（max_open, max_idle, lifetime）
- [ ] 灰度发布策略已制定（先 HK 后 US，或先小流量）
- [ ] 回滚方案已制定并演练

### 9.8 常见陷阱

1. **float64 用于金额计算**：这是零容忍的 bug。`150.25 * 100` 在 float64 下可能产生 `15024.999999999998`。必须使用 `shopspring/decimal`。

2. **时区混淆**：美股使用 Eastern Time，港股使用 HKT，系统内部一律 UTC。只在显示层转换。常见错误：用 `time.Now()` 而不是 `time.Now().UTC()`。

3. **FIX 消息序号不连续**：FIX 协议要求消息序号严格递增。重连后必须正确处理 gap-fill。

4. **遗忘终态检查**：修改订单前必须检查是否已在终态。已 FILLED 的订单不能再取消。

5. **Partial Fill 累计错误**：多次 Partial Fill 的 `AvgFillPrice` 必须用加权平均计算，不能简单取算术平均。

   ```go
   // CORRECT: VWAP (Volume-Weighted Average Price)
   newAvgPrice = (oldFillQty * oldAvgPrice + lastQty * lastPrice) / (oldFillQty + lastQty)

   // WRONG: Simple average
   newAvgPrice = (oldAvgPrice + lastPrice) / 2
   ```

6. **港股印花税进位**：港股印花税不足 HK$1 按 HK$1 计算，必须使用 `Ceil()` 而非 `Round()`。

7. **Kafka 消费者 offset 管理**：必须在成功处理后才 commit offset。否则消息丢失。

8. **订单取消的竞争条件**：在 CANCEL_SENT 状态下，交易所可能先返回成交再确认取消。代码必须正确处理 `CANCEL_SENT -> FILLED` 和 `CANCEL_SENT -> PARTIAL_FILL` 的转换。

---

> 本文档最后更新: 2026-03-16
> 对应代码版本: `src/internal/order/order.go`, `src/migrations/001_init_trading.sql`, `docs/specs/api/grpc/trading.proto`
