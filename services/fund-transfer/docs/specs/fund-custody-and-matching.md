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

## 7. 遗留决策项（需产品/业务确认）

在实现前，以下问题需要明确：

| # | 问题 | 影响范围 |
|---|------|---------|
| 1 | 入金模式选择：虚拟账号 or 附言匹配？取决于合作银行是否支持虚拟账号 | 整个入金流程 |
| 2 | Omnibus Account 开在哪家托管行？US 和 HK 分别用哪家银行？ | 银行渠道接入 |
| 3 | 悬挂资金的退款时限：3个工作日 or 其他？ | 运营 SLA |
| 4 | 是否支持用户直接在 APP 内换汇（USD ↔ HKD）？ | FX 模块复杂度 |
| 5 | Trading Engine 的余额更新是同步 gRPC 还是异步 Kafka？涉及一致性设计 | 服务间接口 |
