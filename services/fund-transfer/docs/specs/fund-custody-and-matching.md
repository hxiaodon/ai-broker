# 资金托管架构与入金匹配机制

> 本文档是 `fund-transfer-system.md` 的补充，聚焦于业务架构层面的基础概念：
> 券商托管模式、入金识别匹配、悬挂资金处理、与交易引擎的资金边界、银行渠道高可用。
>
> 这些内容决定系统的核心复杂度，工程师在实现前必须理解。

---

## 1. 托管账户架构（Custodian Account）

### 1.1 核心原则：客户资金与券商资金严格隔离

```
券商资产负债表
─────────────────────────────────────────
自有资产（自有资金）        负债（运营）
  券商现金账户  $X亿         应付款    $X亿
  IT 资产      $X亿          股东权益  $X亿

↑ 以上是券商自己的钱，可自由使用

─────────────────────────────────────────
表外托管（不在券商资产负债表内）
  客户托管资金  $1000亿       ← 这笔钱归客户所有
                               券商无权动用
─────────────────────────────────────────
```

**监管要求**：
- **美国（SEC Rule 15c3-3）**：客户资金必须存入独立的"Special Reserve Bank Account"，与券商自有资金完全隔离
- **香港（SFC 持牌法团条例）**：客户资产必须存入独立的"客户账户"，不得与公司账户混合
- 违反隔离规定是刑事罪行（参考 MF Global 事件）

### 1.2 托管账户结构

```
                    用户A  用户B  用户C  ...
                      │     │     │
                      └──────────┘
                           │
                    ┌──────▼──────────┐
                    │  Omnibus Account │  ← 一个大池子
                    │  （汇总托管账户）│    由托管行持有
                    │                 │
                    │  托管行：        │
                    │  US: JP Morgan  │
                    │  HK: 汇丰/中银  │
                    └─────────────────┘
                           │
               券商内部系统记账（谁有多少钱）
               ┌──────────────────────────┐
               │  account_balances 表      │
               │  user_id | available | .. │
               └──────────────────────────┘
```

**关键理解**：
- 银行只看到一个大账户（Omnibus），不知道每个用户有多少
- 券商内部数据库维护每个用户的份额
- 这就是为什么券商系统的账本完整性（ledger integrity）是生死线

### 1.3 托管模式选择

我们采用 **全自托管模式**（Self-Custody via Custodian Bank）：

| 模式 | 说明 | 适用场景 |
|------|------|---------|
| **全自托管**（我们的方案） | 券商直接在托管行开立 Omnibus Account | 持牌券商，资金规模大 |
| 第三方托管（Prime Broker） | 资金托管在大型投行（高盛/摩根） | 中小型券商，借用大行信用 |
| 混合模式 | 部分自托管 + 部分 Prime Broker | 跨境业务 |

---

## 2. 入金识别与匹配机制

这是入金流程最核心、也是 `fund-transfer-system.md` 最欠缺的部分。

### 2.1 两种入金模式对比

#### 模式 A：虚拟账号入金（Virtual Account）— 推荐

```
流程：
  1. 用户在 APP 发起入金申请
  2. 系统为该用户生成唯一虚拟收款账号
     例：汇丰香港 Account: 808-XXXX-YYYY（每用户唯一）
  3. 用户用自己的网银转账到该虚拟账号
  4. 银行收到款项后，通过 Webhook 回调通知：
     {"virtual_account": "808-XXXX-YYYY", "amount": 10000, "currency": "HKD"}
  5. 系统通过虚拟账号直接定位用户，无歧义

优点：
  ✅ 自动匹配，无需人工干预
  ✅ 实时到账（FPS/Wire）
  ✅ 无附言填写错误风险

缺点：
  ❌ 需要银行支持虚拟账号功能（不是所有银行都支持）
  ❌ 账号管理复杂（百万用户 = 百万虚拟账号）
```

#### 模式 B：附言匹配入金（Reference Code）— 备用

```
流程：
  1. 所有用户转账到同一个收款账号
     例：汇丰香港 Account: 808-0000-0001（全平台唯一）
  2. 转账时附言（Remarks）填写平台分配的唯一码
     例：附言 "DEPOSIT-UID789456"
  3. 银行对账文件包含附言内容
  4. 系统扫描附言，解析出 UID，匹配用户

优点：
  ✅ 银行要求低，普通企业账户即可
  ✅ 实现简单

缺点：
  ❌ 用户容易填错附言 → 产生悬挂资金
  ❌ 依赖银行文件（T+1 批量），非实时
  ❌ 需要人工处理异常
```

### 2.2 我们的方案：主用虚拟账号，备用附言匹配

```
入金发起
    │
    ▼
用户绑定了银行账户？
    │
    ├─ 是 → 生成虚拟账号（优先）
    │         银行支持虚拟账号？
    │           ├─ 是 → 虚拟账号模式
    │           └─ 否 → 附言匹配模式
    │
    └─ 否 → 引导用户先绑卡
```

### 2.3 入金匹配数据库设计

```sql
-- 虚拟账号映射表
CREATE TABLE virtual_accounts (
    id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    virtual_account  VARCHAR(64) UNIQUE NOT NULL,   -- 虚拟账号号码
    user_id          BIGINT UNSIGNED NOT NULL,
    bank_code        VARCHAR(16) NOT NULL,           -- 所属银行
    currency         VARCHAR(8) NOT NULL,
    is_active        TINYINT(1) NOT NULL DEFAULT 1,
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_va_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 悬挂资金表（无法匹配的入账）
CREATE TABLE suspense_funds (
    id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    suspense_id      CHAR(36) UNIQUE NOT NULL,
    bank_reference   VARCHAR(128) NOT NULL,          -- 银行流水号
    amount           DECIMAL(20, 2) NOT NULL,
    currency         VARCHAR(8) NOT NULL,
    raw_remarks      VARCHAR(256),                   -- 原始附言内容
    received_at      TIMESTAMP NOT NULL,
    status           VARCHAR(16) NOT NULL DEFAULT 'UNMATCHED',
                                                     -- UNMATCHED / MATCHED / REFUNDED
    matched_user_id  BIGINT UNSIGNED,                -- 匹配成功后填写
    matched_at       TIMESTAMP NULL,
    refunded_at      TIMESTAMP NULL,
    notes            TEXT,                           -- 人工处理备注
    created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_suspense_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 3. 悬挂资金处理（Suspense Account）

### 3.1 什么情况会产生悬挂资金

```
场景1：附言填错
  用户转账 $5,000，附言写成 "DEPOSITE-789456"（拼写错误）
  系统无法解析 → 进入悬挂

场景2：金额不匹配
  用户申请入金 $10,000，实际转入 $10,001.50（手续费被扣）
  系统检测到金额不符 → 进入悬挂（人工确认）

场景3：重复转账
  用户网络超时，以为失败，重新转了一笔
  第二笔进入悬挂（幂等检测）

场景4：非客户转账
  错误转账到我们托管账户
  不知道是谁的钱 → 进入悬挂
```

### 3.2 处理流程

```
银行入账回调
     │
     ▼
尝试自动匹配（虚拟账号 or 附言解析）
     │
     ├─ 匹配成功 → 正常入金流程
     │
     └─ 匹配失败 → 写入 suspense_funds 表
                        │
                        ▼
                  运营团队人工处理（Admin Panel）
                        │
                  ┌─────┴─────────┐
                  ▼               ▼
              手动匹配          发起退款
              到用户账户        回原账户
                  │               │
                  ▼               ▼
             正常入账          退款完成
             + 通知用户        + 记录原因
```

### 3.3 处理时限要求

| 状态 | 处理时限 | 超时动作 |
|------|---------|---------|
| UNMATCHED | 3 个工作日内处理 | 自动触发退款流程 |
| 退款中 | 5 个工作日完成 | 升级到合规团队 |
| 长期未处理（>30天） | 上报合规 | 可能需要 SAR 申报 |

### 3.4 Wire / SWIFT 入金金额容忍策略

> **问题背景（P1-5）**：跨境 Wire（SWIFT MT103）经过代理行时，中间行手续费从本金中扣取（Shared / OUR 费用模式差异），实际到账金额可能小于用户申请金额。若系统以 $0.01 为告警门槛，每笔 SWIFT 都将触发金额不匹配悬挂，导致运营量爆炸。

**分渠道匹配策略**：

| 渠道 | 金额容忍区间 | 处理方式 |
|------|------------|---------|
| **ACH**（美国） | 零容忍（ACH 金额精确，不扣手续费） | 差异 ≥ $0.01 → 悬挂，人工处理 |
| **Wire**（美国 Fedwire） | 零容忍（Fedwire 金额精确传递） | 差异 ≥ $0.01 → 悬挂 |
| **FPS / CHATS**（香港） | 零容忍 | 同上 |
| **SWIFT**（国际，含跨境 Wire） | **容忍 `min($50, 申请金额×0.5%)`** | 在容忍区间内 → 按**实际到账金额**入账，差额记入 `wire_fee_absorbed` 字段，不触发悬挂；超出容忍 → 人工审核 |

**SWIFT 容忍入账的账本处理**：

```
用户申请入金 $10,000（SWIFT，OUR 费用模式，但代理行额外扣 $25）
实际到账 $9,975

匹配策略:
  差额 = $25 ≤ $50 → 在容忍范围内

账本分录:
  借：券商银行账户 (ASSET)          $9,975.00   ← 实际到账
  借：wire_fee_absorbed (FEE 负项)  $25.00      ← 吸收的代理行手续费
    贷：用户券商账户 (LIABILITY)      $9,975.00   ← 用户实际到账

用户余额: $9,975（用户看到实际到账金额）
通知: "您的 $10,000 入金已到账 $9,975，差额 $25 为中间行手续费，已自动处理。"
```

**运维要求**：
- 每日汇总 `wire_fee_absorbed` 总金额，生成报表供财务审查
- 月累计代理行费用 > $10,000 时触发告警，考虑切换费用模式（BEN → SHA/OUR）或银行对账谈判
- 如实际到账金额 > 申请金额（用户多汇），差额作为临时 suspense 暂挂，运营确认后退回

### 3.5 入金归属错误纠错流程（P1-15）

**场景**：入金已被系统（自动）或运营（人工）匹配到用户 A，但事后发现应归属用户 B（常见原因：银行附言乱码、虚拟账号映射错误、运营人工误判）。

**关键约束**：
- 账本 append-only，不能修改或删除已有分录，**只能写冲销分录**
- 若用户 A 已动用部分资金（买入/出金），追偿路径不同
- 需完整审计追踪（SEC 17a-4 合规）

**纠错流程**：

```
发现归属错误
        │
        ▼
Step 1: 核实（合规官 + 运营双重确认）
        - 确认原始银行对账单（MT940 / ACH 回单）
        - 确认真实归属（用户 B 的身份 + 汇款证明）
        - 记录错误原因：system_auto_mismatch / human_error / bank_memo_corruption
        │
        ▼
Step 2: 查询用户 A 的当前余额 vs 错误入金金额
        ├── 用户 A 余额 ≥ 错误金额（资金完整）→ Step 3a（全额冲销）
        └── 用户 A 余额 < 错误金额（已动用部分）→ Step 3b（部分冲销 + 追偿）
        │
        ▼
Step 3a（全额冲销）:
        1. 写冲销分录：
           借：用户A账户 (LIABILITY)    $X   ← 追回
             贷：suspense_account      $X
        2. 写重新入账分录：
           借：suspense_account        $X
             贷：用户B账户 (LIABILITY)  $X   ← 正确到账
        3. 通知用户 A（"您账户中的 $X 已更正归属"）+ 用户 B（"您的入金 $X 已到账"）
        4. 写 audit_log（event_type: DEPOSIT_REATTRIBUTION）
        │
        ▼
Step 3b（部分冲销 + 追偿）:
        1. 先冲销用户 A 剩余可用余额部分（同 Step 3a）
        2. 对已动用部分：
           - 如已用于买入（持仓中）→ 写 HOLD_PENDING_RECOVERY 分录冻结等值持仓
             联系用户 A 补充资金或清算对应持仓
           - 如已出金至银行 → 标记为 DEBT_RECOVERY_PENDING
             合规 + 法务介入，必要时走司法追偿
        3. 先行向用户 B 入账正确金额（平台临时垫付差额，记为 platform:receivables）
        4. 追偿成功后还原 platform:receivables
        5. 写完整 audit_log，保留 7 年

**关键规则**：
- 整个流程由合规官审批，Finance Ops 执行，不允许任何人单独操作
- 用户 B 不应等待追偿结果，应尽快收到正确入账（平台垫付）
- 若误匹配是系统 Bug 导致，触发严重事故处理流程，评估是否需要 SEC 报告
```go
// 归属纠错事务（伪代码）
func ReattributeDeposit(ctx context.Context, transferID string, fromUserID, toUserID int64,
    amount decimal.Decimal, reason string, approverID string) error {
    return db.WithTx(ctx, func(tx *sqlx.Tx) error {
        // 1. 冲销 fromUser 余额
        if err := ledger.WriteEntry(tx, LedgerEntry{
            EntryType:     "DEPOSIT_CLAWBACK",
            DebitAccount:  fmt.Sprintf("user:%d:available", fromUserID),
            CreditAccount: "platform:suspense:reattribution",
            Amount:        amount, ApproverID: approverID,
        }); err != nil { return err }
        // 2. 重新入账 toUser
        if err := ledger.WriteEntry(tx, LedgerEntry{
            EntryType:     "DEPOSIT_REATTRIBUTED",
            DebitAccount:  "platform:suspense:reattribution",
            CreditAccount: fmt.Sprintf("user:%d:available", toUserID),
            Amount:        amount, ApproverID: approverID,
            Metadata:      map[string]string{"original_transfer_id": transferID, "reason": reason},
        }); err != nil { return err }
        // 3. 写 audit log（append-only）
        return audit.Write(ctx, AuditEvent{
            EventType: "DEPOSIT_REATTRIBUTION", ActorID: approverID,
            Details: map[string]any{"from": fromUserID, "to": toUserID, "amount": amount, "reason": reason},
        })
    })
}
```

---

## 4. 与交易引擎的资金边界

### 4.1 两套"冻结"逻辑，必须区分

系统中存在两种资金冻结，概念容易混淆：

```
账户余额组成：
┌─────────────────────────────────────────────┐
│  总余额 = available + frozen_withdrawal      │
│                     + frozen_trade           │
│                     + unsettled              │
└─────────────────────────────────────────────┘

frozen_withdrawal（出金冻结）
  → 由 Fund Transfer Service 管理
  → 触发：用户发起提款申请，冻结对应金额防止双花
  → 释放：提款成功（转为实际扣款）或失败（解冻）

frozen_trade（交易冻结）
  → 由 Trading Engine 管理
  → 触发：用户下买单，冻结买入金额
  → 释放：成交（转为 unsettled）或撤单（解冻）

unsettled（未结算）
  → 由 Trading Engine 写入，Fund Transfer Service 读取
  → 触发：卖出成交，资金在结算期内不可提现
  → 释放：T+1（美股）或 T+2（港股）结算完成后转为 available
```

### 4.2 可提现余额计算公式

```
可提现余额 =
    available                    // 可用余额
  - frozen_withdrawal            // 已在途的提款申请
  - margin_requirement           // 融资保证金占用（如有）
  （注意：unsettled 不在这里扣，因为它本来就不在 available 里）

可用于购买（Buying Power）=
    available                    // 可用余额
  + unsettled_sell_proceeds      // 已卖出但未结算的收益（可用于买入，不可提现）
  - frozen_trade                 // 已冻结的买单
  - margin_requirement
```

### 4.3 服务间资金事件接口

```
Trading Engine → Fund Transfer（通过 Kafka）

Topic: trading.settlement.completed
事件结构：
{
  "event_type": "SETTLEMENT_COMPLETED",
  "user_id": 789456,
  "order_id": "ord-abc123",
  "direction": "SELL",           // 卖出结算，资金解冻进入 available
  "amount": "5000.00",
  "currency": "USD",
  "settlement_date": "2026-03-15T00:00:00Z",
  "market": "US"
}

Fund Transfer Service 收到后：
  将对应 unsettled 金额转入 available
  写入 ledger_entries（结算完成分录）
  触发余额更新事件


Fund Transfer → Trading Engine（通过 gRPC）

RPC: GetWithdrawableBalance
  入参：user_id, currency
  出参：withdrawable_amount（可提现余额）
  用途：Trading Engine 展示账户信息时调用

RPC: FreezeForWithdrawal / UnfreezeForWithdrawal
  用途：提款审批期间冻结/解冻余额
  幂等键：withdrawal_id
```

### 4.5 入金到账后可交易时机的跨域契约（P3-5）

**问题**：PRD §2.2 说"银行确认到账后立即可用于交易"，但 Trading Engine 何时感知到资金、盘前盘后是否影响这个"立即"，文档未明确。

**明确规则**：

| 场景 | 资金何时可用于交易 | 说明 |
|------|-----------------|------|
| **ACH 标准入金**（T+2 到账） | 银行回调触发 → Fund Transfer 写账 → **立即**推送 Kafka 事件 → Trading Engine 可用 | 不受市场时段限制 |
| **ACH 即时入金**（Instant Credit） | 用户提交申请后 → **立即**按 ICT 层级授信额度可用于买入 | 即时额度可买入，但不可提现（见 ach-risk §6.2） |
| **Wire 当日到账** | 银行 RTGS 确认 → **立即**可用 | Fedwire 17:00 ET 前到账当日生效 |
| **盘前时段入金**（美股 04:00–09:30 ET） | 同上，**立即**写账 + 事件推送 | Trading Engine 接受盘前订单时资金已可用 |
| **盘后/非交易时段入金** | 同上，**立即**写账 | 下个交易时段开盘即可下单 |

**跨域事件契约**（Fund Transfer → Trading Engine 推送）：

```json
// Topic: fund.balance.updated
{
  "event_type": "BALANCE_UPDATED",
  "user_id": 789456,
  "currency": "USD",
  "delta": "10000.00",
  "new_available": "15000.00",
  "new_buying_power": "15000.00",
  "source": "DEPOSIT_CONFIRMED",
  "transfer_id": "txfr-abc123",
  "effective_at": "2026-05-16T14:30:00.000Z"
}
```

Trading Engine 必须订阅此事件并在收到后 **< 100ms** 内更新本地 buying power 缓存，不得依赖轮询 `GetWithdrawableBalance` RPC 感知入金。

**UI 契约**：Mobile 展示的"可用资金"反映实时余额（含刚到账入金），不论当前是否在交易时段。余额充足但市场未开盘时，提示"当前非交易时段，可在盘前 04:00 ET 开始下单"，而非误导性的"余额不足"。

### 4.4 Settlement 事件丢失的自愈机制（P1-6）

**问题**：如果 Kafka `trading.settlement.completed` 事件因分区重平衡、消费者重启、网络分区而丢失，对应的 `unsettled` 金额永远无法转入 `available`，用户资金将永久被锁定。

**解决方案：周期性 Settlement Reconciliation Job**

```go
// 每小时运行一次（或每 30 分钟）
func (j *SettlementReconciliationJob) Run(ctx context.Context) error {
    now := time.Now().UTC()

    // 查询所有 settlement_date 已过期但仍在 unsettled 状态的记录
    rows, err := j.db.QueryContext(ctx, `
        SELECT user_id, order_id, amount, currency, settlement_date, market
        FROM unsettled_positions
        WHERE status = 'UNSETTLED'
          AND settlement_date < ?
          AND created_at < DATE_SUB(?, INTERVAL 2 HOUR)  -- 给 Trading Engine 2h 正常结算窗口
    `, now, now)
    if err != nil {
        return fmt.Errorf("query overdue unsettled: %w", err)
    }
    defer rows.Close()

    for rows.Next() {
        var pos UnsettledPosition
        rows.Scan(&pos.UserID, &pos.OrderID, &pos.Amount, &pos.Currency,
            &pos.SettlementDate, &pos.Market)

        // 向 Trading Engine 发起确认查询（RPC: GetSettlementStatus）
        status, err := j.tradingClient.GetSettlementStatus(ctx, pos.OrderID)
        if err != nil {
            // Trading Engine 不可用：跳过，下次重试；不要盲目释放
            j.metrics.Inc("settlement_reconciliation.trading_engine_unavailable")
            continue
        }

        switch status {
        case SettlementConfirmed:
            // Trading Engine 确认已结算，但 Kafka 事件丢失
            j.processSettlement(ctx, pos, "KAFKA_EVENT_RECOVERED")
        case SettlementPending:
            // Trading Engine 说还没结算（可能 settlement_date 有延迟）
            j.metrics.Inc("settlement_reconciliation.still_pending")
            j.alerts.Warn(ctx, fmt.Sprintf("order %s overdue settlement_date %v", pos.OrderID, pos.SettlementDate))
        case SettlementFailed:
            // 结算失败（如对方违约）：走失败补偿流程
            j.processSettlementFailure(ctx, pos)
        }
    }
    return nil
}
```

**对账触发条件**（双保险）：

| 触发器 | 运行时间 | 说明 |
|--------|---------|------|
| 周期性 Job | 每 60 分钟 | 扫描所有过期 unsettled |
| 主动 Kafka Consumer Restart | 重启后 backfill 历史消息 | 消费 committed offset 之前的 segment |
| EOD 3-way 对账 | 每日 23:00 UTC | 如 unsettled 总额 + available ≠ custodian 余额，触发告警 + 人工核查 |

**风险边界**：Job 仅在 Trading Engine 明确返回 `SettlementConfirmed` 时才自动释放资金；`Pending` 或 RPC 错误时保守等待，不盲目释放，避免提前给用户资金导致坏账。

---

## 5. 银行渠道高可用策略

### 5.1 多银行冗余架构

```
                Fund Transfer Service
                        │
              ┌─────────┼─────────┐
              ▼         ▼         ▼
          主渠道      备用渠道    应急渠道
          (Primary)  (Secondary) (Fallback)

美国 USD：
  主：JP Morgan ACH    主：Citibank ACH    应急：人工 Wire
  主：JP Morgan Wire   备：BMO Wire

香港 HKD：
  主：汇丰 FPS         备：恒生 FPS        应急：中银 CHATS
```

### 5.2 渠道选择策略

```go
// 渠道选择优先级（伪代码）
func SelectChannel(req DepositRequest) Channel {
    candidates := GetAvailableChannels(req.Currency, req.Amount)

    for _, ch := range candidates {
        if ch.IsHealthy() && ch.SupportsAmount(req.Amount) {
            return ch
        }
    }

    // 所有渠道不可用 → 告警 + 排队等待
    return DeferredQueue
}

// 渠道健康状态：实时探测
type ChannelHealth struct {
    IsUp           bool
    SuccessRate5m  float64   // 最近5分钟成功率
    AvgLatencyMs   int64
    LastError      time.Time
}
```

### 5.3 银行超时处理（关键）

> **规则：银行超时时，绝对不能假设成功或失败，必须标记为 PENDING 等待对账确认。**

```
向银行发起转账请求
        │
        ├─ 200 成功 → 正常流程
        │
        ├─ 4xx 错误 → 明确失败，释放冻结，通知用户
        │
        ├─ 5xx 错误 → 可重试（指数退避，最多3次）
        │              3次后仍失败 → 标记 BANK_ERROR，告警
        │
        └─ 超时/网络断开 → ⚠️ 状态未知
                              标记 PENDING_BANK_CONFIRM
                              不释放冻结！
                              等待 EOD 对账文件确认
                              或主动向银行查询状态
```

```sql
-- 超时状态的转账，EOD 对账时处理
UPDATE fund_transfers
SET status = 'COMPLETED'   -- 或 'FAILED'
WHERE status = 'PENDING_BANK_CONFIRM'
  AND bank_reference IN (
    SELECT reference FROM bank_statement_file WHERE date = TODAY
  );
```

### 5.4 对账驱动的状态修复

```
每日 EOD 对账流程（23:00 UTC）：

1. 下载银行对账文件（SWIFT MT940 / CSV）
2. 与内部 fund_transfers 表进行三方比对：
   ┌──────────────────────────────────────────────────┐
   │  内部状态         银行状态    → 处理动作           │
   │  COMPLETED        到账        → ✅ 一致，无需处理  │
   │  PENDING_CONFIRM  到账        → 更新为 COMPLETED   │
   │  PENDING_CONFIRM  未见        → 继续等待（T+3后报警）│
   │  COMPLETED        未见        → 🚨 严重告警，人工处理│
   │  FAILED           到账        → 🚨 资金已到但未入账 │
   └──────────────────────────────────────────────────┘
3. 无法自动修复的 → 写入 reconciliation_exceptions 表
4. 发送对账报告给运营和合规团队
```

---

## 6. 资金流转全景图

将以上所有概念整合成完整的资金流转视图：

```
用户手机银行
     │ 转账（虚拟账号 or 附言）
     ▼
托管银行（汇丰/JP Morgan）
  Omnibus Account
     │ Webhook 回调
     ▼
Fund Transfer Service
  ├── 匹配引擎
  │     ├─ 匹配成功 → AML → 入账 → 更新 account_balances → Ledger
  │     └─ 匹配失败 → suspense_funds → 人工处理
  │
  ├── account_balances（实时余额）
  │     available / frozen_withdrawal / frozen_trade / unsettled
  │
  └── Kafka Events
        │
        ▼
  Trading Engine
    买卖股票时：
      下单 → frozen_trade++, available--
      成交 → unsettled++, frozen_trade--
      结算 → available++, unsettled--
        │
        │ settlement.completed 事件
        ▼
  Fund Transfer Service
    更新 unsettled → available
    写入 Ledger
        │
        ▼
用户发起提款
  Fund Transfer Service
    可提现余额检查
    → AML → 审批 → frozen_withdrawal++
    → 向银行发起打款
    → 银行确认 → frozen_withdrawal-- → Ledger
        │
        ▼
用户手机银行（收到打款）
```

---

---

## 8. SEC Rule 15c3-3 — 客户保护规则与储备金计算

> **法规**: SEC Rule 15c3-3(e), 17 CFR § 240.15c3-3  
> **优先级**: P0 — Phase 1 上线前必须完成。MF Global 事件与 Robinhood 2020 年 $1,300 万罚款均源于此规则的违反。

### 8.1 核心要求

SEC 15c3-3 要求注册经纪商：

1. **隔离客户资金**：客户资金不能混入券商自有资金（本文档 §1.1 已覆盖 Omnibus Account 结构）
2. **建立 Special Reserve Bank Account (SRBA)**：独立银行账户，只存放"净客户信用余额"
3. **每周执行储备金计算**：每个工作日结束后（通常周五 COB ET），计算应存入 SRBA 的金额
4. **不足时立即补足**：如计算结果要求追加存款，必须在下一个工作日开盘前完成；不足超过 12 小时须通知 SEC

### 8.2 储备金计算公式

```
储备金需求 = Credits - Debits

Credits（应计入）:
  + 客户自由信用余额（Free Credit Balances）= sum(account_balances.available) for all customers
  + 客户应收未收的股息/利息
  + 客户空头仓位产生的应付金额
  + 其他应付给客户的金额

Debits（可抵扣）:
  - 客户账户内的应收保证金（Margin Receivables，如融资余额）
  - 政府证券（Treasury Bills/Notes）：满足 SEC 认可的抵扣资产条件
  - 银行借款（仅限于直接为客户融资的部分）
  - 其他 SEC 15c3-3 附则 A 认可的抵扣项

Net Reserve Required = max(0, Credits - Debits)
```

> **注意**：Credits 大于 Debits 时，差额必须存入 SRBA。Debits 大于 Credits（净借方）时，无需额外存款，但需说明原因。

### 8.3 Fund-Transfer × Trading Engine 契约

15c3-3 计算依赖精确的跨域数据，fund-transfer 和 trading-engine **必须约定以下接口**:

| 数据项 | 提供方 | 接口 / 事件 | 说明 |
|--------|--------|------------|------|
| `account_balances.available` | Fund Transfer | DB 直接读 / `GetCustomerCreditBalances` gRPC | 所有用户可提现余额之和，按币种分组 |
| `customer_margin_receivables` | Trading Engine | `GetMarginReceivables` gRPC | 客户融资余额（16c3-3 Debit 项） |
| `unsettled_sell_proceeds` | Trading Engine | `GetUnsettledPositions` gRPC | T 日卖出未结算资金（Credits 项，已计算至当日） |
| `customer_dividends_payable` | Trading Engine | `GetPendingDividends` gRPC | 应发未发的股息 |

**数据查询时间点**：每个计算日（通常周五）COB ET（22:00 UTC），Trading Engine 提供快照；Fund Transfer 运行计算，结果写入 `reserve_computations` 表。

### 8.4 Special Reserve Bank Account (SRBA) 操作流程

```
每周五 COB ET（22:00 UTC）
        │
        ▼
  运行储备金计算脚本（见 §8.2 公式）
        │
        ├── Net ≤ 当前 SRBA 余额 → 无需操作
        │
        └── Net > 当前 SRBA 余额（差额 = D）
                │
                ▼
        在下一工作日开盘前（09:00 ET = 13:00 UTC）
        从公司运营账户 → SRBA 转入 D（内部账户间转账，非用户出入金）
                │
                ▼
        若 09:30 ET 开盘时 SRBA 仍不足：
        → 立即通知 CFO + 合规官
        → 超过 12 小时不足 → 通知 SEC 区域办公室（电话 + 书面）
```

### 8.5 数据库表设计

```sql
CREATE TABLE reserve_computations (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    computation_date    DATE NOT NULL UNIQUE,          -- 计算基准日（通常周五）
    total_credits_usd   DECIMAL(20, 2) NOT NULL,       -- 客户信用余额总和
    total_debits_usd    DECIMAL(20, 2) NOT NULL,       -- 可抵扣项总和
    net_required_usd    DECIMAL(20, 2) NOT NULL,       -- max(0, credits - debits)
    srba_balance_usd    DECIMAL(20, 2) NOT NULL,       -- 计算时 SRBA 实际余额
    shortfall_usd       DECIMAL(20, 2) NOT NULL,       -- max(0, net_required - srba_balance)
    status              ENUM('COMPUTED','FUNDED','REPORTED_SEC') NOT NULL DEFAULT 'COMPUTED',
    funded_at           TIMESTAMP NULL,                -- SRBA 补足时间
    notes               TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_computation_date (computation_date),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 8.6 合规责任分配

| 职责 | 负责人 |
|------|--------|
| 每周储备金计算执行 | Fund Transfer 系统自动运行（定时任务，周五 22:00 UTC） |
| 计算结果审核 | CFO 或指定财务主管（次工作日 09:00 ET 前签署） |
| SRBA 划转执行 | Finance Ops（在系统触发告警后手动执行银行转账） |
| SEC 通知 | Chief Compliance Officer（如 12h 仍不足时） |
| 年度合规认证 | Compliance Officer + external auditor（FINRA FOCUS Report） |

### 8.7 HK 对应要求

香港 SFC 《持牌法团持有客户资产规定》（CIS 条例）要求类似隔离，但计算周期为**每月**（月末最后工作日）：
- 客户资金隔离账户 ≠ 公司资金
- 如托管行为恒生/中银，需签订独立的"客户资金保管协议"
- Fund Transfer 需分别维护 USD SRBA 和 HKD 客户账户，并定期与 SFC 申报



在实现前，以下问题需要明确：

| # | 问题 | 影响范围 |
|---|------|---------|
| 1 | 入金模式选择：虚拟账号 or 附言匹配？取决于合作银行是否支持虚拟账号 | 整个入金流程 |
| 2 | Omnibus Account 开在哪家托管行？US 和 HK 分别用哪家银行？ | 银行渠道接入 |
| 3 | 悬挂资金的退款时限：3个工作日 or 其他？ | 运营 SLA |
| 4 | 是否支持用户直接在 APP 内换汇（USD ↔ HKD）？ | FX 模块复杂度 |
| 5 | Trading Engine 的余额更新是同步 gRPC 还是异步 Kafka？涉及一致性设计 | 服务间接口 |
