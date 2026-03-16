# 交易所对接与 FIX 协议 (Exchange Connectivity & FIX Protocol) 深度调研

> 美港股券商交易引擎 — FIX Protocol & Exchange Connectivity 子域

---

## 1. 业务概述

### 1.1 FIX 协议简介

FIX（Financial Information eXchange）协议是全球证券交易行业的标准消息传输协议，由 FIX Trading Community 维护。自1992年诞生以来，FIX 已成为电子化交易的事实标准，覆盖全球 100+ 交易所和数千家券商。

**本项目使用场景：**
- 美股：通过 FIX 4.4 连接 NYSE、NASDAQ（及其他 venue）
- 港股：通过 FIX 4.4 连接 HKEX（香港交易所）

### 1.2 FIX Engine 在系统中的位置

```
OMS (Order State Machine)
        │
        │ StatusRiskApproved → StatusPending
        ▼
Smart Order Router (SOR)
        │
        │ Decision{Venue, Price, Qty}
        ▼
┌───────────────────────────────────────────┐
│              FIX Engine                   │
│                                           │
│  ┌─────────────┐  ┌─────────────────────┐ │
│  │ NYSE Session│  │ NASDAQ Session      │ │
│  │ (FIX 4.4)  │  │ (FIX 4.4)           │ │
│  └──────┬──────┘  └────────┬────────────┘ │
│         │                  │              │
│  ┌──────▼──────────────────▼──────────┐   │
│  │      Execution Report Handler      │   │
│  │  (成交回报 → Kafka → Position Engine)│   │
│  └────────────────────────────────────┘   │
└───────────────────────────────────────────┘
        │
        │ ExecutionReport → Kafka topic: order.filled
        ▼
  Position Engine / Settlement Engine
```

### 1.3 核心业务场景

**Happy Path — 限价单从提交到成交：**
1. OMS 调用 `FIXEngine.SendNewOrder(order)` 发送 `NewOrderSingle (MsgType=D)`
2. 交易所返回 `ExecutionReport (ExecType=0/New)` → 订单状态变为 OPEN
3. 交易所撮合成交，返回 `ExecutionReport (ExecType=2/Fill)` → 订单状态变为 FILLED
4. Execution Handler 将成交回报推送 Kafka，触发 Position Engine 更新持仓

**Edge Cases：**
- 交易所拒绝订单：`ExecutionReport (ExecType=8/Rejected)` → EXCHANGE_REJECT
- 部分成交：`ExecutionReport (ExecType=1/PartialFill)` → PARTIAL_FILL（多次）
- 撤单确认：`ExecutionReport (ExecType=4/Cancelled)` → CANCELLED
- FIX Session 断线：Session 自动重连，使用 GapFill 恢复丢失消息
- 网络延迟导致的重复消息：通过 MsgSeqNum 幂等处理

---

## 2. 监管与合规要求

### 2.1 FIX 消息记录保留（SEC Rule 17a-4）

**要求：**
- 所有 FIX 消息（发送 + 接收）必须完整保留 **7年**
- WORM（Write Once Read Many）存储，不可篡改
- 必须支持在监管要求下 3 个工作日内检索和重放任意时段的 FIX 消息

**实现：**
```
FIX 消息日志路径: SessionConfig.LogPath
  格式: 标准 FIX ASCII 格式，每行一条消息
  示例:
  8=FIX.4.4|9=178|35=D|49=BROKER|56=NYSE|34=1|52=20240115-14:30:00.123|
    11=ord-uuid-001|55=AAPL|54=1|38=100|40=2|44=185.00|60=20240115-14:30:00.123|10=087|

日志文件按天滚动，归档到 S3 Object Lock（Compliance Mode, 7年）
```

### 2.2 时间戳精度要求

- **CAT（Consolidated Audit Trail）要求**：时间戳精度 **微秒级**（microseconds）
- FIX 标准字段 `TransactTime (60)` 和 `SendingTime (52)` 支持毫秒
- 对于 CAT 上报，需要额外的微秒时间戳扩展字段

### 2.3 Exchange Order ID 追踪

交易所返回的 `ExchangeOrderID`（FIX 字段 37: OrderID）必须映射到内部订单：

```sql
UPDATE orders SET exchange_order_id = ? WHERE order_id = ?
```

此映射是对账和合规审计的关键链接。

### 2.4 FIX 消息完整性

- 每条 FIX 消息有 Checksum（字段 10），接收方必须验证
- 消息序列号（MsgSeqNum, 字段 34）严格递增，断号需要 GapFill
- Logon 时的 `ResetSeqNumFlag (141)` 控制是否重置序列号

---

## 3. 市场差异（US vs HK）

### 3.1 FIX 版本差异

| 市场 | FIX 版本 | 说明 |
|------|---------|------|
| NYSE | FIX 4.2 / 4.4 | NYSE 接受两者，推荐 4.4 |
| NASDAQ | FIX 4.2 / 4.4 | NASDAQ 主要使用 4.4 |
| HKEX | FIX 4.4 | HKEX OMD-C（Orion Market Data）系统 |

### 3.2 扩展字段差异

**NYSE 特有扩展字段（Tag 9000+）：**
- `Tag 9010: NYSEPostingInstruction` — 指定做市商指令
- `Tag 9303: NYSEInternalAcross` — 内部撮合标记
- `Tag 9600: NYSEShortMarkExempt` — Reg SHO 豁免标记

**NASDAQ 特有扩展字段：**
- `Tag 9491: NASDAQInternalizationMarker`
- `Tag 18207: NASDAQCrossType` — 参与 NASDAQ Cross 类型

**HKEX 特有扩展字段：**
- `Tag 20000: HKEXLotType` — 整手/碎股区分
- `Tag 20001: HKEXOrderCapacity` — 客户单 vs 自营单（Principal/Agency）
- `Tag 20002: HKEXShortSellTag` — 卖空标记（港股卖空需特别标注）
- `Tag 20003: HKEXBoardLot` — 每手股数
- 竞价限价单（ELO, Enhanced Limit Order）在收市竞价时段使用

### 3.3 交易时段管理

| 市场 | 正常交易 | 特殊时段 | FIX Session 状态 |
|------|---------|---------|-----------------|
| NYSE/NASDAQ | 09:30-16:00 ET | 盘前04:00-09:30, 盘后16:00-20:00 | Logon 07:00 ET, Logout 21:00 ET |
| HKEX | 09:30-12:00, 13:00-16:00 HKT | 开市前9:00-9:30, 收市竞价16:00-16:10 | Logon 08:00 HKT, Logout 17:00 HKT |

---

## 4. 技术架构

### 4.1 Session 生命周期

```
FIX Session 状态机:

NOT_CONNECTED
      │
      │ 启动/自动连接
      ▼
CONNECTING（TCP 连接建立）
      │
      │ TCP 连接成功
      ▼
CONNECTED（TCP 层已连接）
      │
      │ 发送 Logon (A)
      ▼
LOGGING_ON（等待交易所 Logon 响应）
      │
      │ 收到 Logon 响应
      ▼
LOGGED_ON（正常工作状态）
      │           │
      │ 正常注销   │ 心跳超时/错误
      ▼           ▼
LOGGING_OUT    RECONNECTING
      │              │
      │ 收到 Logout   │ 等待重连间隔
      ▼              │
NOT_CONNECTED ◄───────┘

对应 SessionStatus 代码:
  SessionDisconnected = 0
  SessionConnecting   = 1
  SessionLoggedOn     = 2
  SessionLoggedOut    = 3
```

### 4.2 关键 FIX 消息类型

#### NewOrderSingle (MsgType=D) — 下单

```
关键字段:
  Tag 11: ClOrdID          = 内部订单UUID（客户端订单ID）
  Tag 21: HandlInst        = 1 (Automated execution, no broker intervention)
  Tag 38: OrderQty         = 订单数量
  Tag 40: OrdType          = 1(市价) / 2(限价) / 3(止损) / 4(止损限价)
  Tag 44: Price            = 限价价格（OrdType=2时必填）
  Tag 49: SenderCompID     = 券商标识符（来自 SessionConfig）
  Tag 54: Side             = 1(买) / 2(卖) / 5(卖空)
  Tag 55: Symbol           = 标的代码（美股: "AAPL", 港股: "0700"）
  Tag 56: TargetCompID     = 交易所标识符
  Tag 59: TimeInForce      = 0(DAY) / 1(GTC) / 3(IOC) / 4(FOK/AON)
  Tag 60: TransactTime     = 订单时间（UTC, 毫秒精度）
  Tag 100: ExDestination   = "NYSE" / "NASDAQ" / "HKEX"（路由目标）
  Tag 110: MinQty          = 最小成交量（IOC/AON时使用）

  -- 卖空相关（美股）
  Tag 114: LocateReqd      = Y/N（是否需要 locate）
  Tag 377: SolicitedFlag   = N（非主动询价）
  Tag 8000: ShortSaleLocate = locate token（Reg SHO locate 编号）
```

#### ExecutionReport (MsgType=8) — 成交/状态回报

```
关键字段:
  Tag 6:  AvgPx           = 平均成交价
  Tag 11: ClOrdID         = 客户端订单ID（与下单时一致）
  Tag 14: CumQty          = 累计成交数量
  Tag 17: ExecID          = 交易所成交ID（全局唯一）
  Tag 19: ExecRefID       = 引用的成交ID（撤销时使用）
  Tag 20: ExecTransType   = 0(New) / 1(Cancel) / 2(Correct)
  Tag 29: LastCapacity    = 1(Agent/代理) / 2(Cross/撮合) / 4(Principal/自营)
  Tag 30: LastMkt         = 实际成交场所（"NYSE" / "NASDAQ"）
  Tag 31: LastPx          = 本次成交价格
  Tag 32: LastQty/LastShares = 本次成交数量
  Tag 37: OrderID         = 交易所内部订单ID（ExchangeOrderID）
  Tag 38: OrderQty        = 原始订单数量
  Tag 39: OrdStatus       = 0(New) / 1(PartialFill) / 2(Filled) / 4(Cancelled) / 8(Rejected)
  Tag 41: OrigClOrdID     = 改单/撤单时的原始ClOrdID
  Tag 44: Price           = 原始限价
  Tag 54: Side            = 买/卖方向
  Tag 55: Symbol          = 标的代码
  Tag 58: Text            = 拒绝原因（ExecType=8时）
  Tag 60: TransactTime    = 交易所确认时间（UTC）
  Tag 150: ExecType       = 0(New确认) / 1(PartialFill) / 2(Fill) / 4(Cancelled) / 8(Rejected) / A(PendingNew) / C(Expired)
  Tag 151: LeavesQty      = 剩余数量

ExecType 与 OrdStatus 的对应关系:
  ExecType=0(New)         → OrdStatus=0(New)         → 内部状态: OPEN
  ExecType=1(PartialFill) → OrdStatus=1(PartialFill) → 内部状态: PARTIAL_FILL
  ExecType=2(Fill)        → OrdStatus=2(Filled)       → 内部状态: FILLED
  ExecType=4(Cancelled)   → OrdStatus=4(Cancelled)    → 内部状态: CANCELLED
  ExecType=8(Rejected)    → OrdStatus=8(Rejected)     → 内部状态: EXCHANGE_REJECT
  ExecType=C(Expired)     → OrdStatus=C(Expired)      → 内部状态: CANCELLED (DAY单过期)
```

#### OrderCancelRequest (MsgType=F) — 撤单

```
关键字段:
  Tag 11: ClOrdID     = 新的取消请求ID（UUID）
  Tag 37: OrderID     = 交易所订单ID（ExchangeOrderID）
  Tag 41: OrigClOrdID = 原始下单的 ClOrdID
  Tag 54: Side        = 与原始订单相同
  Tag 55: Symbol      = 与原始订单相同
  Tag 60: TransactTime = 请求时间
```

#### OrderCancelReplaceRequest (MsgType=G) — 改单

```
关键字段:
  Tag 11: ClOrdID     = 新的改单请求ID
  Tag 38: OrderQty    = 新的订单数量（必须 >= 已成交数量）
  Tag 40: OrdType     = 订单类型（通常不变）
  Tag 41: OrigClOrdID = 原始订单的 ClOrdID
  Tag 44: Price       = 新价格
  Tag 55: Symbol      = 与原始订单相同
  Tag 60: TransactTime = 请求时间

注意: 改单只能在 OPEN 或 PARTIAL_FILL 状态下执行
     改单后，ExchangeOrderID 通常会更新（取决于交易所）
```

### 4.3 QuickFIX/Go 集成

```go
// FIX Engine 使用 QuickFIX/Go 库
// github.com/quickfixgo/quickfix

// SessionConfig → quickfix.Settings 配置
func BuildQuickFIXSettings(configs []SessionConfig) (*quickfix.Settings, error) {
    settings := quickfix.NewSettings()

    for _, cfg := range configs {
        sessionSettings := quickfix.NewSessionSettings()
        sessionSettings.Set(quickfix.SenderCompID, cfg.SenderCompID)
        sessionSettings.Set(quickfix.TargetCompID, cfg.TargetCompID)
        sessionSettings.Set(quickfix.BeginString, cfg.FIXVersion)
        sessionSettings.Set(quickfix.SocketConnectHost, cfg.Host)
        sessionSettings.Set(quickfix.SocketConnectPort, strconv.Itoa(cfg.Port))
        sessionSettings.Set(quickfix.HeartBtInt, strconv.Itoa(cfg.HeartbeatInt))
        sessionSettings.Set(quickfix.FileLogPath, cfg.LogPath)
        sessionSettings.Set(quickfix.FileStorePath, cfg.StorePath)

        if cfg.UseTLS {
            sessionSettings.Set(quickfix.SocketUseSSL, "Y")
            sessionSettings.Set(quickfix.SocketInsecureSkipVerify, "N")
        }

        sessionID := quickfix.SessionID{
            BeginString:  cfg.FIXVersion,
            SenderCompID: cfg.SenderCompID,
            TargetCompID: cfg.TargetCompID,
        }
        settings.AddSession(sessionID, sessionSettings)
    }

    return settings, nil
}

// Application 实现 quickfix.Application 接口
type FIXApplication struct {
    execHandler func(*order.ExecutionReport)
    sessions    map[string]quickfix.SessionID
}

func (a *FIXApplication) OnCreate(sessionID quickfix.SessionID)           { /* 记录 session */ }
func (a *FIXApplication) OnLogon(sessionID quickfix.SessionID)            { /* 状态变为 LOGGED_ON */ }
func (a *FIXApplication) OnLogout(sessionID quickfix.SessionID)           { /* 状态变为 LOGGED_OUT */ }
func (a *FIXApplication) ToAdmin(msg *quickfix.Message, sid quickfix.SessionID) { /* 可注入字段 */ }
func (a *FIXApplication) ToApp(msg *quickfix.Message, sid quickfix.SessionID) error { return nil }
func (a *FIXApplication) FromAdmin(msg *quickfix.Message, sid quickfix.SessionID) quickfix.MessageRejectError {
    return nil
}

func (a *FIXApplication) FromApp(msg *quickfix.Message, sid quickfix.SessionID) quickfix.MessageRejectError {
    msgType, _ := msg.Header.GetString(quickfix.Tag(35))
    switch msgType {
    case "8": // ExecutionReport
        report, err := a.parseExecutionReport(msg)
        if err != nil {
            return quickfix.NewMessageRejectError(err.Error(), 0, nil)
        }
        a.execHandler(report)
    }
    return nil
}
```

### 4.4 发送 NewOrderSingle

```go
func (e *Engine) SendNewOrder(ctx context.Context, ord *order.Order) error {
    venue := ord.Exchange  // "NYSE" / "NASDAQ" / "HKEX"
    sessionID, ok := e.sessions[venue]
    if !ok {
        return fmt.Errorf("no FIX session for venue: %s", venue)
    }

    // 检查断路器
    if !e.circuitBreakers[venue].Allow() {
        return fmt.Errorf("circuit breaker open for venue: %s", venue)
    }

    msg := quickfix.NewMessage()
    msg.Header.SetField(quickfix.Tag(35), quickfix.FIXString("D"))  // MsgType=NewOrderSingle

    // 必填字段
    msg.Body.SetField(quickfix.Tag(11), quickfix.FIXString(ord.ClientOrderID))
    msg.Body.SetField(quickfix.Tag(55), quickfix.FIXString(ord.Symbol))
    msg.Body.SetField(quickfix.Tag(54), quickfix.FIXString(sideToFIX(ord.Side)))
    msg.Body.SetField(quickfix.Tag(38), quickfix.FIXInt(ord.Quantity))
    msg.Body.SetField(quickfix.Tag(40), quickfix.FIXString(typeToFIX(ord.Type)))
    msg.Body.SetField(quickfix.Tag(59), quickfix.FIXString(tifToFIX(ord.TimeInForce)))
    msg.Body.SetField(quickfix.Tag(60), quickfix.FIXUTCTimestamp(time.Now().UTC()))
    msg.Body.SetField(quickfix.Tag(21), quickfix.FIXString("1"))  // AutomatedExecution

    // 限价单
    if ord.Type == order.TypeLimit || ord.Type == order.TypeStopLimit {
        msg.Body.SetField(quickfix.Tag(44), quickfix.FIXDecimal(ord.Price, 8))
    }

    // 止损价
    if ord.Type == order.TypeStop || ord.Type == order.TypeStopLimit {
        msg.Body.SetField(quickfix.Tag(99), quickfix.FIXDecimal(ord.StopPrice, 8))
    }

    // 卖空标记（美股）
    if ord.Side == order.SideSell && ord.Market == "US" {
        // 需要在风控层已完成 Locate
        msg.Body.SetField(quickfix.Tag(54), quickfix.FIXString("5"))  // Side=ShortSell
    }

    // 港股特殊字段
    if ord.Market == "HK" {
        msg.Body.SetField(quickfix.Tag(20001), quickfix.FIXString("A"))  // Agency order
    }

    return quickfix.SendToTarget(msg, sessionID)
}
```

### 4.5 处理 ExecutionReport

```go
func (e *Engine) parseExecutionReport(msg *quickfix.Message) (*order.ExecutionReport, error) {
    report := &order.ExecutionReport{}

    report.OrderID, _ = msg.Body.GetString(quickfix.Tag(11))       // ClOrdID
    report.ExecID, _ = msg.Body.GetString(quickfix.Tag(17))        // ExecID
    report.ExecType, _ = msg.Body.GetString(quickfix.Tag(150))     // ExecType

    // 映射交易所订单ID
    if exchangeOrderID, err := msg.Body.GetString(quickfix.Tag(37)); err == nil {
        report.ExchangeOrderID = exchangeOrderID  // 注意: 需要额外存储
    }

    // 成交数量和价格
    if lastQty, err := msg.Body.GetInt(quickfix.Tag(32)); err == nil {
        report.LastQty = int64(lastQty)
    }
    if lastPx, err := msg.Body.GetDecimal(quickfix.Tag(31)); err == nil {
        report.LastPx = lastPx
    }
    report.CumQty, _ = msg.Body.GetInt(quickfix.Tag(14))  // 累计成交
    report.AvgPx, _  = msg.Body.GetDecimal(quickfix.Tag(6))

    if leavesQty, err := msg.Body.GetInt(quickfix.Tag(151)); err == nil {
        report.LeavesQty = int64(leavesQty)
    }

    // 成交场所（实际执行的交易所）
    report.Venue, _ = msg.Body.GetString(quickfix.Tag(30))

    // 交易所时间戳
    if transactTime, err := msg.Body.GetTime(quickfix.Tag(60)); err == nil {
        report.TransactTime = transactTime.UnixNano()
    }

    // 拒绝原因
    report.Text, _ = msg.Body.GetString(quickfix.Tag(58))

    return report, nil
}
```

### 4.6 断线重连与序列号管理

```
FIX Session 重连流程:

1. 检测到断线（HeartBtInt 超时 / TCP 错误）
2. 标记 SessionStatus = SessionDisconnected
3. 触发断路器（连续3次断线 → CircuitBreaker OPEN）
4. 指数退避等待: 1s → 2s → 4s → 8s → 16s（最大）
5. 重新建立 TCP 连接
6. 发送 Logon (A) 消息
   - ResetSeqNumFlag=N: 继续使用上次序列号（需要 GapFill）
   - ResetSeqNumFlag=Y: 重置序列号（需要交易所同意，谨慎使用）
7. 如交易所 MsgSeqNum 与本地不一致:
   - 本地落后于交易所: 发送 ResendRequest (2)，触发 GapFill
   - 本地超前于交易所: 发送 SequenceReset (4)，GapFill=Y
8. SessionStatus = SessionLoggedOn

持久化（FileStore）的作用:
  StorePath 记录: LastSenderMsgSeqNum, LastTargetMsgSeqNum
  重连时从 StorePath 读取上次序列号，确保 GapFill 正确
```

### 4.7 ExecutionReport 处理流水线

```
ExecutionReport 到达
      │
      ▼
1. 解析 FIX 消息（parseExecutionReport）
      │
      ▼
2. 根据 ClOrdID 查询内部订单（Redis 热路径）
      │
      ▼
3. 根据 ExecType 执行状态转换:
   ├── ExecType=0 (New)         → StatusPending → StatusOpen
   ├── ExecType=1 (PartialFill) → StatusOpen/PartialFill → StatusPartialFill
   ├── ExecType=2 (Fill)        → StatusPartialFill → StatusFilled
   ├── ExecType=4 (Cancelled)   → StatusCancelSent → StatusCancelled
   ├── ExecType=8 (Rejected)    → StatusPending → StatusExchangeReject
   └── ExecType=C (Expired)     → StatusOpen → StatusCancelled (DAY单过期)
      │
      ▼
4. 更新 orders 表状态（DB 写入）
      │
      ▼
5. 如果是成交（PartialFill / Fill）:
   a. 创建 executions 记录（含费用计算）
   b. 推送 Kafka topic: order.filled / order.partially_filled
   c. （异步）Position Engine 处理持仓更新
   d. （异步）Settlement Engine 记录待结算成交
      │
      ▼
6. 推送 Kafka topic: order.status_updated（供 mobile 实时推送）
      │
      ▼
7. 记录 order_events（Event Sourcing, 审计追踪）
```

### 4.8 费用实时计算

成交时实时计算各项费用：

```go
func calculateFees(exec *order.ExecutionReport, market string, side string) FeeBreakdown {
    fees := FeeBreakdown{}
    grossAmount := exec.LastPx.Mul(decimal.NewFromInt(exec.LastQty))

    if market == "US" {
        // 佣金: $0.005/股（含交易所费用）
        fees.Commission = decimal.NewFromFloat(0.005).Mul(decimal.NewFromInt(exec.LastQty))

        if side == "SELL" {
            // SEC Fee: 0.00278% of gross amount（取整到分，向上取整）
            fees.SECFee = grossAmount.Mul(decimal.NewFromFloat(0.0000278)).
                RoundUp(2)

            // FINRA TAF: $0.000166/股（卖方）
            fees.TAF = decimal.NewFromFloat(0.000166).Mul(decimal.NewFromInt(exec.LastQty)).
                RoundUp(2)
        }
    } else if market == "HK" {
        // 佣金: 0.03%，最低 HK$3
        fees.Commission = grossAmount.Mul(decimal.NewFromFloat(0.0003))
        if fees.Commission.LessThan(decimal.NewFromFloat(3.0)) {
            fees.Commission = decimal.NewFromFloat(3.0)
        }

        // 印花税: 0.13%（买卖双方各付）
        // 注意: 港股印花税 2023年8月起从 0.1% 提高至 0.13%
        fees.StampDuty = grossAmount.Mul(decimal.NewFromFloat(0.0013)).RoundUp(2)

        // SFC 征费: 0.0027%
        fees.TradingLevy = grossAmount.Mul(decimal.NewFromFloat(0.000027))

        // HKEX 交易费: 0.00565%
        fees.TradingFee = grossAmount.Mul(decimal.NewFromFloat(0.0000565))

        // 平台费: HK$0.50/笔
        fees.PlatformFee = decimal.NewFromFloat(0.50)
    }

    fees.TotalFees = fees.Commission.Add(fees.SECFee).Add(fees.TAF).
        Add(fees.StampDuty).Add(fees.TradingLevy).Add(fees.TradingFee).
        Add(fees.PlatformFee)

    // 净金额
    if side == "BUY" {
        fees.NetAmount = grossAmount.Add(fees.TotalFees)  // 买入: 加费用
    } else {
        fees.NetAmount = grossAmount.Sub(fees.TotalFees)  // 卖出: 减费用
    }

    return fees
}
```

---

## 5. 性能要求与设计决策

### 5.1 延迟目标

| 阶段 | P50 | P99 | 备注 |
|------|-----|-----|------|
| FIX 消息序列化 | <0.1ms | <0.5ms | 内存操作 |
| TCP 发送（本地网络）| 0.1ms | 0.5ms | 与交易所同机房 |
| TCP 往返（跨网络）| 1ms | 5ms | 主机托管（co-location）|
| ExecutionReport 解析 | <0.1ms | <0.5ms | 内存操作 |
| 状态更新（DB 写入）| 1ms | 3ms | 含 Redis 更新 |
| Kafka 推送 | 0.5ms | 2ms | 异步，不阻塞主路径 |
| **成交处理全程** | **<2ms** | **<5ms** | **系统目标** |

### 5.2 设计决策

**决策 1：每个 venue 独立 FIX Session**
- 原因：各交易所有独立的序列号空间，互不影响；一个 venue 断线不影响其他
- 实现：`sessions map[string]quickfix.SessionID`，按 venue 名称索引
- 代价：需要管理多个 Session 生命周期

**决策 2：FileStore 持久化序列号**
- 原因：服务重启后能从上次序列号续连，避免 ResetSeqNum（交易所不一定接受）
- 实现：`SessionConfig.StorePath` 指向持久化存储（非 tmpfs）
- 风险：如 StorePath 文件损坏，需要手动协商 Reset

**决策 3：ExecutionReport 先写 DB，再推 Kafka**
- 原因：确保数据不丢失；Kafka 推送失败不影响持仓计算（Kafka consumer 可从 DB 重放）
- 实现：事务：`BEGIN; INSERT executions; UPDATE orders; COMMIT; THEN Kafka.Produce`
- 替代方案：Outbox Pattern（推荐，更健壮）

**决策 4：FIX 消息日志单独存储**
- 原因：合规要求（7年 WORM），与业务日志分离
- 实现：`SessionConfig.LogPath` 指向专用目录，定期归档到 S3 Object Lock
- 大小估算：每条 FIX 消息约 200 bytes，10,000 orders/s 约 2MB/s，每天约 170GB

**决策 5：心跳间隔配置（HeartbeatInt）**
- 推荐值：30 秒（行业标准）
- 过小（<10s）：可能被交易所认为是异常行为，触发断线
- 过大（>60s）：网络断线检测延迟太长，影响系统可用性

---

## 6. 接口设计

### 6.1 FIX Engine 接口（现有）

```go
// src/internal/fix/engine.go
type Engine interface {
    SendNewOrder(ctx context.Context, ord *order.Order) error
    SendCancelOrder(ctx context.Context, orderID, origClOrdID string) error
    SendAmendOrder(ctx context.Context, ord *order.Order, origClOrdID string) error
    OnExecutionReport(handler func(*order.ExecutionReport))
    SessionStatus(venue string) SessionStatus
    Close() error
}

type SessionConfig struct {
    Venue          string
    SenderCompID   string
    TargetCompID   string
    Host           string
    Port           int
    HeartbeatInt   int
    FIXVersion     string  // "FIX.4.2" / "FIX.4.4"
    UseTLS         bool
    LogPath        string
    StorePath      string
}
```

### 6.2 Kafka 事件

```
Topic: order.status_updated
Partition Key: order_id
Schema:
{
  "order_id": "uuid",
  "account_id": 12345,
  "status": "FILLED",  // 新状态
  "prev_status": "OPEN",  // 前一状态
  "exec_type": "FILL",    // FIX ExecType
  "execution": {          // 仅成交时有值
    "execution_id": "uuid",
    "last_qty": 100,
    "last_px": "185.00",
    "cum_qty": 100,
    "avg_px": "185.00",
    "leaves_qty": 0,
    "venue": "NYSE",
    "transact_time": "2024-01-15T14:30:00.123Z"
  },
  "reject_reason": null,  // ExchangeReject 时有值
  "updated_at": "2024-01-15T14:30:00.123Z"
}

Topic: order.filled
Partition Key: account_id (保证同一账户的成交顺序)
Schema:
{
  "execution_id": "uuid",
  "order_id": "uuid",
  "account_id": 12345,
  "symbol": "AAPL",
  "market": "US",
  "side": "BUY",
  "quantity": 100,
  "price": "185.00",
  "commission": "0.50",
  "sec_fee": "0.05",
  "taf": "0.02",
  "total_fees": "0.57",
  "net_amount": "18500.57",
  "settlement_date": "2024-01-16",  // T+1
  "venue": "NYSE",
  "executed_at": "2024-01-15T14:30:00.123Z"
}
```

### 6.3 管理 API

```
GET  /admin/fix/sessions
Response: 所有 venue 的 FIX Session 状态
[
  {"venue": "NYSE",   "status": "LOGGED_ON", "sent": 1523, "received": 1520, "latency_ms": 1.2},
  {"venue": "NASDAQ", "status": "LOGGED_ON", "sent": 843,  "received": 841,  "latency_ms": 1.5},
  {"venue": "HKEX",   "status": "LOGGED_ON", "sent": 2103, "received": 2103, "latency_ms": 2.1}
]

POST /admin/fix/sessions/{venue}/reconnect
效果: 强制重新建立 FIX Session（Logout + Login）

GET  /admin/fix/sessions/{venue}/messages?from=2024-01-15T14:00:00Z&to=2024-01-15T15:00:00Z
Response: 指定时间段的 FIX 消息日志（合规审计用）
```

---

## 7. 开源参考实现

### 7.1 QuickFIX/Go

- **链接**: https://github.com/quickfixgo/quickfix
- **相关性**: 本项目 FIX Engine 的核心依赖库
- **参考内容**:
  - `Application` 接口实现模式
  - Session 配置参数说明
  - FileStore vs MemoryStore 的权衡（生产环境必须 FileStore）
  - Message 构建和解析 API

### 7.2 QuickFIX/J (Java)

- **链接**: https://github.com/quickfix-j/quickfixj
- **相关性**: Java 版本，文档更完善，概念完全相同
- **参考内容**: Session 状态机的完整描述，HeartBeat 机制文档

### 7.3 FIX Trading Community 官方规范

- **链接**: https://www.fixtrading.org/standards/
- **参考内容**: FIX 4.4 完整字段定义，各交易所扩展字段规范（需注册）

### 7.4 Prometheus 监控

关键 Metrics：
```
fix_session_status{venue="NYSE"} (1=connected, 0=disconnected)
fix_messages_sent_total{venue="NYSE", msg_type="D"}
fix_messages_received_total{venue="NYSE", msg_type="8"}
fix_execution_reports_total{venue="NYSE", exec_type="FILL"}
fix_roundtrip_latency_ms{venue="NYSE"} (从发送NewOrderSingle到收到New确认)
```

---

## 8. PRD Review 检查清单

### 8.1 功能维度 ✅

- [ ] 是否支持改单（Cancel-Replace，MsgType=G）？改单的约束条件（不能减少已成交数量）？
- [ ] 港股收市竞价时段（16:00-16:10）的订单类型限制是否明确？
- [ ] 盘前/盘后交易是否通过 FIX 发送？还是通过 ECN？
- [ ] 交易所拒绝（EXCHANGE_REJECT）的错误信息是否透传给用户？
- [ ] 成交通知的实时性要求（移动端推送延迟 < N ms）？

### 8.2 合规维度 ✅

- [ ] FIX 消息日志7年保留是否已设计存储方案？
- [ ] CAT 时间戳精度是否达到微秒级？
- [ ] Exchange Order ID（Tag 37）是否正确存储到 orders 表？
- [ ] 卖空订单是否正确设置 Side=5 和 Locate 字段？

### 8.3 可靠性维度 ✅

- [ ] FIX Session 断线重连策略是否有超时和重试上限？
- [ ] 断路器触发后的降级策略是否明确（拒单 vs 暂存 vs 路由到备用 venue）？
- [ ] 如何处理 "Pending New" 状态下的断线（订单可能被交易所接受也可能没有）？
- [ ] FileStore 路径是否使用持久化存储（非容器临时目录）？

### 8.4 监控维度 ✅

- [ ] 是否有 FIX Session 状态的实时监控 dashboard？
- [ ] 成交延迟（下单到收到 New 确认）是否有监控指标？
- [ ] 是否有 Session 断线的告警通知（PagerDuty/飞书）？

---

## 9. 工程落地注意事项

### 9.1 常见坑

**坑 1：FileStore 目录权限**
- 问题：QuickFIX/Go 的 FileStore 需要写权限，Docker 容器默认目录可能为 read-only
- 解决：挂载 Volume 到 `StorePath` 和 `LogPath`，确保持久化且有写权限

**坑 2：Logon ResetSeqNumFlag 使用不当**
- 问题：误用 `ResetSeqNumFlag=Y` 会导致交易所拒绝 Logon（认为是异常）
- 解决：仅在交易所明确要求或人工确认后才使用 Reset；日常断线重连始终用 GapFill

**坑 3：多 Symbol 的 TransactTime 时区**
- 问题：NYSE/NASDAQ 用 ET，HKEX 用 HKT，但 FIX 标准要求 UTC
- 解决：所有 FIX 消息时间戳统一使用 UTC（`time.Now().UTC()`），禁止本地时间

**坑 4：Tag 37 (OrderID) vs Tag 11 (ClOrdID) 混淆**
- 问题：Tag 11 是客户端订单 ID（内部生成），Tag 37 是交易所分配的订单 ID
- 解决：明确命名：`ClOrdID = ClientOrderID`，`OrderID (Tag 37) = ExchangeOrderID`
- 撤单/改单时必须填写正确的 `OrigClOrdID (Tag 41)`

**坑 5：成交重复处理**
- 问题：FIX Session 重连后，交易所可能重发之前的 ExecutionReport
- 解决：以 `ExecID (Tag 17)` 做幂等检查（`executions.exchange_exec_id` 唯一索引）

**坑 6：港股订单数量验证**
- 问题：HKEX 只接受整手（board lot）数量，碎股单会被拒绝
- 解决：在 OMS 层和 FIX 发送前双重验证：`quantity % lotSize == 0`

**坑 7：大单的 FIX Session 带宽**
- 问题：10,000 orders/s 时，FIX 消息量约 2MB/s，确保网络带宽充足
- 解决：主机托管（co-location）靠近交易所；监控 `fix_messages_sent_rate`

### 9.2 部署注意事项

- FIX Engine 建议部署在靠近交易所的机房（co-location）以降低网络延迟
- `LogPath` 和 `StorePath` 必须使用独立的持久化 Volume（不与应用代码共享）
- 每个交易所的 Session 参数（SenderCompID/TargetCompID）需要与交易所签署连接协议后获得
- 生产环境必须使用 TLS（`UseTLS: true`），测试环境可用 plain TCP

### 9.3 测试策略

```
单元测试:
├── parseExecutionReport: 各 ExecType 的解析正确性
├── calculateFees: 美股/港股各费用项计算（对比手工计算结果）
├── sideToFIX / typeToFIX / tifToFIX: FIX 枚举映射
└── 断路器状态机转换测试

集成测试（对接 FIX 模拟器）:
├── 使用 QuickFIX/Go 的 acceptor 模式搭建测试交易所
├── NewOrderSingle → ExecutionReport New → Fill 完整流程
├── 撤单流程: Cancel → ExecutionReport Cancelled
├── 交易所拒绝: ExecutionReport Rejected → EXCHANGE_REJECT 状态
└── Session 断线重连: 断开 TCP → 自动重连 → GapFill 验证

压力测试:
├── 10,000 orders/s 发送速率
├── 成交回报处理延迟分布（p50/p99/p999）
└── 长时间运行（24h）内存泄漏检测
```
