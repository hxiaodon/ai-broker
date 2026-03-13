# PRD-05：出入金模块

> **文档状态**: Phase 1 正式版
> **版本**: v1.1
> **日期**: 2026-03-13
> **变更说明**: 根据出入金工程师评审意见修订：修正可提现余额计算公式（卖出未结算应减而非加）；微存款暴力破解防护（最多5次累计机会）；bank_reference 增加 UNIQUE 约束；入金状态机新增 RETURNED 终态；3-day vs 7-day 冷却期三阶段规则说明；Structuring Detection 滑动窗口 Redis 规格；新增 ledger_accounts 余额快照表；数据模型数字精度统一为 NUMERIC(18,4)；ACH Return Code 矩阵（R01-R10）

---

## 一、模块概述

### 1.1 功能范围

| 功能 | Phase 1 | Phase 2/3 |
|------|---------|----------|
| USD 入金（ACH / Wire） | ✅ | - |
| USD 出金（ACH / Wire） | ✅ | - |
| HKD 入金（CHATS Wire） | ❌（见 DEC-2026-003） | ✅ Phase 2 |
| HKD 出金 | ❌ | ✅ Phase 2 |
| FX 换汇 | ❌ | ✅ Phase 2 |
| 港股 FPS 支付 | ❌ | ✅ Phase 2 |
| 即时入金（平台垫资） | ❌ | ✅ Phase 3 |
| Plaid 快捷验证 | ❌ | ✅ Phase 2 |

### 1.2 监管依据

| 监管要求 | 适用规定 |
|---------|---------|
| 同名账户原则 | 内部合规规则 Rule 1 |
| AML 筛查 | OFAC SDN List，BSA，AMLO |
| CTR 申报 | FinCEN（> $10,000），JFIU（> HK$120,000） |
| 结构性交易检测 | Structuring Detection |
| Travel Rule | > $3,000 USD 需传递发/收款方信息 |
| 结算感知提款 | T+1（美股）资金不可提前提现 |
| 双重记账 | 复式记账法（Ledger） |
| 记录保留 | 7 年（SEC 17a-4，SFO） |

---

## 二、资金管理主页

### 2.1 页面结构

```
[余额展示区]
  可用余额（Available Cash）: $X,XXX.XX USD
  持仓市值（Invested Value）: $X,XXX.XX
  总资产（Total Assets）: $X,XXX.XX
  今日盈亏: ±$XX.XX (±X.XX%)

[快捷操作]
  [入金] [出金]

[KYC 限额区]
  当前等级：Tier 2
  日限额：$XX,000 / $100,000 (进度条)
  月限额：$XXX,000 / $500,000 (进度条)

[快速入口]
  银行卡管理 / 交易记录

[FX 换汇入口]（Phase 2，Phase 1 显示 "敬请期待"）
```

### 2.2 余额类型定义

| 类型 | 定义 |
|------|------|
| 可用余额（Available Cash） | 总现金 − 未结算买入资金 − 待处理出金 − 保证金要求（Phase 1 = 0） |
| 未结算资金（Unsettled Funds） | 已卖出但未到 T+1 结算日的资金 |
| 待处理出金（Pending Withdrawal） | 提交出金申请后已冻结的金额 |
| 总资产 | 可用余额 + 未结算资金 + 持仓市值 |

---

## 三、银行卡管理

### 3.1 卡片列表规格

| 元素 | 说明 |
|------|------|
| 银行名称 | 如 JPMorgan Chase |
| 币种 | USD |
| 账号（脱敏） | ****1234（仅显示后 4 位） |
| 账户类型 | Checking / Savings |
| 绑定日期 | 如 2026-03-13 |
| 验证状态 | 已验证 / 冷却期（剩余 X 天）/ 验证中 |
| 操作 | 设为默认 / 删除（软删除） |
| 最大数量 | 5 张，超限后添加按钮禁用并提示 |

**同名提示**（底部固定显示）:
```
"根据合规要求，仅允许绑定与您开户姓名相同的银行账户"
```

### 3.2 添加银行卡流程

**Step 1：选择银行**
- 货币选择：USD（Phase 1 仅 USD）
- 银行名称：搜索输入 + 常用银行快速选择列表
- 账户类型：Checking / Savings

**Step 2：填写账户信息**

| 字段 | 说明 | 验证 |
|------|------|------|
| 账户持有人姓名 | 从 KYC 自动填充，只读 | — |
| Routing Number | 9 位数字 | ABA 路由号校验算法 |
| 账户号码 | 4-17 位数字 | 两次输入对比 |
| 确认账户号码 | 再次输入 | 与上一字段完全匹配 |

**Step 3：选择验证方式**

| 方式 | 说明 | 到账时间 |
|------|------|---------|
| 微存款验证 | 向银行账户打入 2 笔小额存款（$0.01-$0.99），用户确认金额 | 1-3 个工作日 |
| Plaid（Phase 2） | 通过 Plaid 即时连接银行账户 | 即时 |

**微存款验证流程**:
```
提交账户信息 → 系统发送 2 笔微存款（工作日 1-3 天到账）
              ↓
用户收到推送："您的微存款已到账，请确认金额完成银行卡验证"
              ↓
用户在 App 输入 2 笔金额 → 验证成功 → 银行卡状态 "已验证"
                         → 验证失败（累计最多 5 次机会）→ 超限后需重新绑定
```

**暴力破解防护**：
- 微存款验证最多累计 5 次机会（跨会话不重置）
- 5 次失败后：银行卡状态变为 `VERIFICATION_FAILED`（不可恢复），需删除后重新绑定
- 每次失败后指数退避：1次失败后 5 分钟内不可重试，2次后 30 分钟，3次后 2 小时
- 失败记录存入 `bank_cards.verify_attempts`

**冷却期规则（三阶段）**:

| 阶段 | 条件 | 入金 | 出金 |
|------|------|------|------|
| Phase 1：冷却期 | 绑卡后 0-3 天 | ❌ 禁止 | ❌ 禁止 |
| Phase 2：自动审核期 | 绑卡后 3-7 天 | ✅ 允许 | ✅ 允许（自动通过） |
| Phase 3：人工审核期 | 绑卡后 3-7 天且触发大额出金 | ✅ 允许 | ⚠ 触发人工审核 |
| Phase 4：正常期 | 绑卡 7 天后 | ✅ 允许 | ✅ 允许（按普通规则） |

注：出金审核中"目标银行卡绑定 < 7 天"触发人工审核，是在冷却期（3 天）结束后的 4-7 天区间内额外标记，两者不冲突。

---

## 四、入金流程

### 4.1 入金方式

| 方式 | 费用 | 到账时间 | Phase 1 |
|------|------|---------|---------|
| ACH 转账 | 免费 | 3-5 个工作日 | ✅ |
| Wire 转账 | $25/笔 | 当日（工作日前 14:00 ET 提交）| ✅ |

### 4.2 入金页面规格

```
[货币选择] USD（Phase 1 仅 USD）

[转账方式]
  ◉ ACH（免费，3-5 个工作日）
  ○ Wire（$25 手续费，当日到账）

[来源银行卡]
  下拉选择：已验证银行卡列表（未验证/冷却期的禁止选择）

[金额输入]
  大字数字输入框 + $
  快捷金额：$500 / $1,000 / $5,000

[费用明细]
  存款金额：$X,XXX.XX
  手续费：$0.00（ACH）/ $25.00（Wire）
  预计到账：YYYY-MM-DD

[安全说明]
  TLS 1.3 加密 · 同名账户验证 · SIPC 最高保障 $500,000

[生物识别确认按钮]
  🔐 Face ID 确认入金
```

### 4.3 入金金额限制

| 规则 | 限制 |
|------|------|
| 最小入金 | $100（ACH）/ $1,000（Wire） |
| 单笔限制 | 按 KYC 等级（见 PRD-00 限额表） |
| 日限制 | 按 KYC 等级（全天已入金 + 本次 ≤ 日限额） |
| 月限制 | 按 KYC 等级 |

### 4.4 入金状态机

```
SUBMITTED（提交成功）
    ↓
AML_SCREENING（合规筛查，通常秒级完成）
    ↓ [PASS]          [REVIEW]               [BLOCKED]
BANK_PROCESSING   COMPLIANCE_REVIEW      DEPOSIT_BLOCKED（终态，入金拒绝）
（银行处理中）   （人工合规审查，1-2 天）
    ↓ [到账]            ↓ [通过]
COMPLETED（终态）   BANK_PROCESSING
                        ↓ [到账]
                    COMPLETED（终态）
    ↓ [银行退汇]
RETURNED（终态）    ← ACH/Wire 退汇，资金未实际入账，无需资金操作
```

**RETURNED 状态说明**：
- 银行通过 ACH Return Code 或 Wire 退汇通知退回款项
- 系统收到银行回调 → 如资金已预记入则冲销 → 状态更新为 RETURNED
- 触发推送通知："您的入金申请已被银行退回，请检查银行账户信息"
- 退汇原因按 ACH Return Code 处理（见 10.1 ACH Return Code 矩阵）

---

## 五、出金流程

### 5.1 出金页面规格

```
[可提现金额明细]
  总现金余额：$X,XXX.XX
  未结算资金（不可提）：-$XXX.XX  [?]
  待处理出金（已冻结）：-$XXX.XX
  可提现余额：$X,XXX.XX           ← 实际可用

[? 说明]："美股交易结算需 T+1 个工作日，未结算资金暂时不可提现"

[目标银行卡]
  选择卡片（已验证 + 冷却期结束）
  ⚠ 新绑定银行卡（7 天内）→ 触发人工审核标记

[金额输入]
  数字输入框 + [全部提现] 按钮

[提现方式]
  ◉ ACH（免费，3-5 个工作日到账）
  ○ Wire（手续费 $X.XX，当日到账）

[费用 & 时间]
  提现金额：$X,XXX.XX
  手续费：$0.00 / $25.00
  预计到账：YYYY-MM-DD 至 YYYY-MM-DD

[生物识别确认]
  🔐 Face ID 确认提现
```

### 5.2 可提现余额计算

```
可提现余额 =
    现金余额
    − 未结算买入资金（等待 T+1 结算的买入，占用现金不可提）
    − 未结算卖出资金（已卖出但 T+1 未结算，资金尚未到账）
    − 待处理出金（已提交但尚未到账的出金，已被冻结）
```

**勘误说明**（v1.0 错误）：v1.0 中将"未结算卖出资金"写为 `+ unsettled_sells`，这是错误的。
卖出股票后，股票已离开持仓，但卖出所得现金在 T+1 前未实际结算入账，
因此不应计入可提现余额（仍应减去）。

**API Response 对应（见 9.3）**：
```json
{
  "total_cash": "5000.00",       // 账面总现金（含未结算卖出）
  "unsettled_buys": "500.00",    // 未结算买入（展示为正数，计算时减）
  "unsettled_sells": "300.00",   // 未结算卖出（展示为正数，计算时也减）
  "pending_withdrawals": "0.00", // 已冻结出金（展示为正数，计算时减）
  "withdrawable_balance": "4200.00"  // = 5000 - 500 - 300 - 0
}
```

**注**：卖出产生的未结算资金也不可立即提现，必须等 T+1 结算后才计入可提现余额。

### 5.3 出金审核规则

| 触发条件（任一满足） | 审核流程 |
|-------------------|---------|
| 金额 > $50,000（单笔）| 人工审核，1-2 个工作日 |
| 当日累计出金 > 日限额 80% | 人工审核 |
| 目标银行卡绑定 < 7 天 | 人工审核（延长冷却期） |
| 账户注册 < 30 天 | 人工审核 |
| AML 风险评分 MEDIUM/HIGH | 人工审核 |
| AML 筛查返回 REVIEW | 人工审核 |

**升级至合规专员**（任一满足）:
- 金额 > $200,000
- 触发 SAR（可疑交易报告）
- 30 天内多次 AML 筛查失败
- 用户在内部观察名单

**人工审核弹窗（出金提交前展示）**:
```
"您的提现申请需要人工审核"
估计处理时间：1-2 个工作日
原因：[系统不展示具体触发条件，保持描述通用]

[继续提交] [取消]
```

### 5.4 出金状态机

```
SUBMITTED
    ↓
AML_SCREENING（秒级）
    ↓ [PASS]
COMPLIANCE_REVIEW（人工审核，如触发规则）
    ↓ [通过]
APPROVED
    ↓
BANK_PROCESSING（银行处理，3-5 天或当日）
    ↓
COMPLETED
```

另含以下终态：
- `REJECTED`（合规拒绝，通知用户联系客服）
- `FAILED`（银行退汇，触发资金返还 + 推送通知）

### 5.5 状态详情页（时间轴）

```
● 提交成功        2026-03-13 10:00:00
● 合规审查通过    2026-03-13 10:00:03
● 人工审核        ⏳ 处理中（预计 1-2 个工作日）
○ 银行处理中      等待
○ 完成            等待
```

---

## 六、AML 合规

### 6.1 OFAC 筛查

每笔入金/出金在处理前自动筛查：
- 用户姓名 vs OFAC SDN List
- 银行名称 / SWIFT 码 vs 制裁实体列表
- 银行所在国 vs 制裁国家

筛查结果：
- `PASS`：继续处理
- `REVIEW`：转人工审核
- `BLOCK`：直接拒绝，合规专员收到警报

**列表刷新频率**：每日自动更新 OFAC SDN List。

### 6.2 CTR 自动申报

| 触发条件 | 申报类型 | 时限 |
|---------|---------|------|
| 单笔 > $10,000 USD | CTR（Currency Transaction Report）| 提交后 15 天内向 FinCEN 申报 |
| 当日累计 > $10,000 USD | CTR | 同上 |

**结构性交易检测**（Structuring Detection）:

检测规则：24 小时内同一用户多笔入/出金合计超过 CTR 阈值（$10,000 USD）→ 自动标记，转合规审核。

**Redis 滑动窗口实现**（防止 Structuring）：
```
Key：structuring:{user_id}:{currency}
类型：Redis ZSet，score=unix_timestamp，member="{tx_id}:{amount}"

每笔交易提交时：
  1. ZADD structuring:{uid}:{ccy} {now_unix} "{tx_id}:{amount}"
  2. ZREMRANGEBYSCORE structuring:{uid}:{ccy} 0 {now_unix - 86400}  // 清理 24h 外数据
  3. 查询所有成员的 amount 求和
  4. 若 sum > 9000（预警阈值，低于 CTR 门槛 $1000）→ 标记 REVIEW
  5. 若 sum > 10000 且笔数 >= 3 → 标记 SAR_SUSPECTED，通知合规

Key TTL：48 小时（EXPIRE structuring:{uid}:{ccy} 172800）

注：不对用户展示具体检测规则（防范故意规避，合规监管要求）
```

### 6.3 SAR 流程

- SAR 由合规专员在 Admin Panel 手动发起或系统预警触发
- SAR 申报时限：可疑交易发现后 30 天内（最长 60 天）
- SAR 内容不得告知用户（法律要求）

### 6.4 Travel Rule

出金金额 > $3,000 USD：
- 发起方信息（用户 KYC 数据，系统自动传递）
- 收款方信息（银行账户信息，用户绑定时已采集）
- 信息同收款行传递（Wire 通过 SWIFT 报文，ACH 通过 Nacha 格式）

---

## 七、交易记录

### 7.1 列表页

| 元素 | 规格 |
|------|------|
| Tab 过滤 | 全部 / 入金 / 出金 |
| 时间过滤 | 本周 / 本月 / 三个月 / 自定义 |
| 每条记录 | 类型图标 / 金额（±颜色）/ 日期 / 银行卡 / 状态 Badge |

### 7.2 单条记录详情

- 交易类型、金额、货币
- 关联银行卡（脱敏）
- 转账方式（ACH / Wire）
- 提交时间、完成时间
- 参考号（Reference Number）
- 完整状态时间轴

---

## 八、Admin Panel：出金审批

### 8.1 审批队列

| 功能 | 说明 |
|------|------|
| 待审核列表 | 按提交时间排序，显示用户信息、金额、触发原因 |
| SLA 预警 | 超过 24 小时未处理标红 |
| 过滤器 | 状态 / 金额区间 / 触发原因类型 |

### 8.2 审批操作

| 操作 | 所需角色 |
|------|---------|
| 审核通过 | Withdrawal Approver |
| 驳回（资金退回用户账户）| Withdrawal Approver |
| 升级合规专员 | Withdrawal Approver |
| 查看 AML 筛查报告 | Compliance Officer |
| 发起 SAR | Compliance Officer |

### 8.3 三级审批流程（金额 > $50K）

```
Level 1：Withdrawal Approver 初审
Level 2：Senior Approver 复审
Level 3：Compliance Officer 终审（金额 > $200K）
```

---

## 九、后端接口规格

### 9.1 入金申请

```
POST /v1/funding/deposits
Headers:
  Idempotency-Key: {uuid}
Request:
  {
    "bank_card_id": "card-uuid",
    "currency": "USD",
    "amount": "1000.00",
    "method": "ACH" | "WIRE"
  }
Response:
  {
    "deposit_id": "dep-uuid",
    "status": "SUBMITTED",
    "estimated_arrival": "2026-03-18"
  }
```

### 9.2 出金申请

```
POST /v1/funding/withdrawals
Headers:
  Idempotency-Key: {uuid}
Request:
  {
    "bank_card_id": "card-uuid",
    "currency": "USD",
    "amount": "500.00",
    "method": "ACH" | "WIRE"
  }
Response:
  {
    "withdrawal_id": "wdr-uuid",
    "status": "SUBMITTED",
    "requires_review": true | false,
    "estimated_arrival": "2026-03-18"
  }
```

### 9.3 可提现余额查询

```
GET /v1/funding/balance
Response:
  {
    "total_cash": "5000.00",
    "unsettled_buys": "500.00",    // 正数，计算时减
    "unsettled_sells": "300.00",   // 正数，计算时也减（v1.0 此处有符号错误）
    "pending_withdrawals": "0.00",
    "withdrawable_balance": "4200.00",  // = total_cash - unsettled_buys - unsettled_sells - pending_withdrawals
    "currency": "USD",
    "as_of": "2026-03-13T14:30:00Z"
  }
```

### 9.4 添加银行卡

```
POST /v1/funding/bank-cards
Headers:
  Idempotency-Key: {uuid}

前置条件：用户 KYC 状态必须为 PENDING_REVIEW 或之后（即已提交 KYC，不要求 APPROVED）
           KYC 状态为 IN_PROGRESS（未提交）时返回 403 FORBIDDEN:
           {"error": "KYC_REQUIRED", "message": "请先完成 KYC 认证后再绑定银行卡"}

Request:
  {
    "bank_name": "JPMorgan Chase",
    "routing_number": "021000021",
    "account_number_enc": "...",   // 前端 RSA 公钥加密后传输（非对称加密，服务端解密后存 AES-256-GCM）
    "account_type": "CHECKING" | "SAVINGS",
    "currency": "USD"
  }
Response 200:
  {
    "card_id": "card-uuid",
    "status": "MICRO_DEPOSIT_PENDING",
    "cooldown_until": "2026-03-16T10:00:00Z"
  }
Response 400: 超过 5 张银行卡上限
  {"error": "BANK_CARD_LIMIT", "max": 5}
```

### 9.5 验证微存款

```
POST /v1/funding/bank-cards/{card_id}/verify
Headers:
  Idempotency-Key: {uuid}   // 防止网络重试重复扣减次数
Request:
  {
    "amounts": ["0.12", "0.34"]   // 用户输入的两笔金额（NUMERIC，非 float）
  }
Response 200（成功）:
  { "verified": true, "attempts_remaining": 0 }

Response 200（失败）:
  { "verified": false, "attempts_remaining": 3 }  // 剩余次数（初始 5 次）

Response 422（已超限）:
  {
    "verified": false,
    "attempts_remaining": 0,
    "error": "VERIFY_ATTEMPTS_EXHAUSTED",
    "message": "验证次数已用完，请删除此银行卡后重新添加"
  }

Response 409（卡片状态不允许验证，如已 VERIFIED 或 VERIFICATION_FAILED）:
  { "error": "INVALID_CARD_STATUS", "current_status": "VERIFIED" }
```

---

## 十、数据模型

```sql
-- 银行卡表（敏感字段加密）
CREATE TABLE bank_cards (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    bank_name           VARCHAR(200) NOT NULL,
    account_type        VARCHAR(20) NOT NULL,
    currency            VARCHAR(5) NOT NULL DEFAULT 'USD',
    routing_number_enc  BYTEA NOT NULL,            -- AES-256-GCM，key_id 在单独字段
    account_number_enc  BYTEA NOT NULL,            -- AES-256-GCM
    account_last4       VARCHAR(4) NOT NULL,
    holder_name         VARCHAR(200) NOT NULL,
    status              VARCHAR(30) NOT NULL DEFAULT 'MICRO_DEPOSIT_PENDING',
                        -- MICRO_DEPOSIT_PENDING | VERIFIED | VERIFICATION_FAILED | INACTIVE
    verify_attempts     SMALLINT NOT NULL DEFAULT 0,  -- 累计验证次数，最多 5 次
    is_default          BOOLEAN DEFAULT false,
    cooldown_until      TIMESTAMPTZ,               -- 冷却期截止时间（绑卡后 +3天）
    deleted_at          TIMESTAMPTZ,               -- 软删除
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_bank_cards_user ON bank_cards (user_id) WHERE deleted_at IS NULL;

-- 入金记录
CREATE TABLE deposits (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    idempotency_key     UUID UNIQUE NOT NULL,
    bank_card_id        UUID NOT NULL REFERENCES bank_cards(id),
    currency            VARCHAR(5) NOT NULL,
    amount              NUMERIC(18,4) NOT NULL,
    fee                 NUMERIC(18,4) DEFAULT 0,
    method              VARCHAR(10) NOT NULL,      -- 'ACH', 'WIRE'
    status              VARCHAR(30) NOT NULL DEFAULT 'SUBMITTED',
    aml_result          VARCHAR(20),               -- PASS | REVIEW | BLOCK
    bank_reference      VARCHAR(100) UNIQUE,       -- 银行参考号（UNIQUE：防退汇回调重复处理）
    ach_return_code     VARCHAR(5),                -- R01-R10 等退汇码（见附录 B）
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 出金记录
CREATE TABLE withdrawals (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    idempotency_key     UUID UNIQUE NOT NULL,
    bank_card_id        UUID NOT NULL REFERENCES bank_cards(id),
    currency            VARCHAR(5) NOT NULL,
    amount              NUMERIC(18,4) NOT NULL,
    fee                 NUMERIC(18,4) DEFAULT 0,
    method              VARCHAR(10) NOT NULL,
    status              VARCHAR(30) NOT NULL DEFAULT 'SUBMITTED',
    aml_result          VARCHAR(20),
    review_level        SMALLINT DEFAULT 0,        -- 0=自动, 1=L1审核, 2=L2, 3=合规
    reviewer_id         UUID,
    review_notes        TEXT,
    bank_reference      VARCHAR(100) UNIQUE,       -- UNIQUE：防止银行回调重复处理
    completed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

-- 资金账户余额快照表（配合 ledger_entries 实现并发安全余额查询）
CREATE TABLE ledger_accounts (
    user_id             UUID PRIMARY KEY REFERENCES users(id),
    currency            VARCHAR(5) NOT NULL DEFAULT 'USD',
    balance             NUMERIC(18,4) NOT NULL DEFAULT 0,    -- 当前账面余额（含未结算）
    version             BIGINT NOT NULL DEFAULT 0,            -- 乐观锁版本号
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 余额更新使用 CAS（Compare-And-Swap）：
-- UPDATE ledger_accounts SET balance = balance + $1, version = version + 1, updated_at = NOW()
--   WHERE user_id = $2 AND version = $3;
-- 若受影响行数为 0，说明并发冲突，业务层需重试

-- 资金分类账（双重记账，只追加，永久保留）
CREATE TABLE ledger_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    entry_type      VARCHAR(30) NOT NULL,
                    -- DEPOSIT | WITHDRAWAL | TRADE_BUY | TRADE_SELL |
                    -- TRADE_FEE | DEPOSIT_REVERSAL | WITHDRAWAL_REVERSAL |
                    -- HOLD | RELEASE | SETTLEMENT
    debit_amount    NUMERIC(18,4) DEFAULT 0,
    credit_amount   NUMERIC(18,4) DEFAULT 0,
    currency        VARCHAR(5) NOT NULL,
    reference_id    UUID,                  -- 关联入金/出金/订单 ID
    reference_type  VARCHAR(30),           -- 'DEPOSIT' | 'WITHDRAWAL' | 'ORDER' | 'FILL'
    balance_after   NUMERIC(18,4) NOT NULL,-- 写入时冗余快照，方便审计
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 此表禁止 UPDATE 和 DELETE；通过 REVOKE 权限在数据库层面强制
);

-- 约束：debit 和 credit 不能同时为零，不能同时非零
ALTER TABLE ledger_entries ADD CONSTRAINT ck_ledger_entry_amounts
    CHECK ((debit_amount > 0 AND credit_amount = 0) OR (debit_amount = 0 AND credit_amount > 0));

CREATE INDEX idx_ledger_user_time ON ledger_entries (user_id, created_at DESC);
CREATE INDEX idx_ledger_reference ON ledger_entries (reference_id, reference_type);
```

---

## 十一、ACH Return Code 矩阵

当 ACH 入金被银行退回时，系统根据 Return Code 执行对应处理逻辑：

| Return Code | 含义 | 系统处理 | 用户通知 | SAR 触发 |
|-------------|------|---------|---------|---------|
| R01 | 账户余额不足（NSF） | 入金标记 RETURNED；银行卡状态不变 | "入金退回：银行账户余额不足" | ❌ |
| R02 | 账户关闭 | 入金标记 RETURNED；银行卡标记 INACTIVE | "入金退回：该银行账户已关闭，请更新银行卡" | ❌ |
| R03 | 账号错误（无此账户） | 入金标记 RETURNED；银行卡标记 INACTIVE | "入金退回：银行账号信息有误，请重新绑卡" | ❌ |
| R04 | 账号格式无效 | 入金标记 RETURNED；银行卡标记 INACTIVE | "入金退回：银行账号格式有误" | ❌ |
| R05 | 未授权的消费者入账 | 入金标记 RETURNED；升级合规审查 | "入金退回，请联系客服" | ⚠ 合规评估 |
| R07 | 客户撤销授权 | 入金标记 RETURNED；账户标记人工审核 | "入金退回：您已撤销授权" | ✅ 触发 SAR 评估 |
| R08 | 付款方止付 | 入金标记 RETURNED；通知合规 | "入金退回，请联系客服" | ⚠ 合规评估 |
| R10 | 客户声明未授权（欺诈） | 入金标记 RETURNED；冻结账户交易；立即通知合规 | "入金退回，您的账户已暂停交易，请联系客服" | ✅ 立即触发 SAR |
| R16 | 账户冻结 | 入金标记 RETURNED；银行卡标记 INACTIVE | "入金退回：银行账户已被冻结" | ❌ |
| R20 | 非交易账户 | 入金标记 RETURNED；银行卡标记 INACTIVE | "入金退回：该账户不支持 ACH 转账" | ❌ |

**处理原则**：
- 所有退汇均通过 `bank_reference` UNIQUE 约束防止重复处理
- R07/R10 退汇须在 1 个工作日内由合规专员人工处理
- 退汇资金若已记账（balance_after > 0）须通过 ledger_entries 写入冲销记录（entry_type=DEPOSIT_REVERSAL）

---

## 十二、对账规格

### 12.1 每日三方对账

```
对账逻辑：
  内部账：SUM(ledger_accounts.balance) WHERE currency='USD'
  银行账：托管账户当日结束余额（银行 API 拉取）
  期望：内部账 = 银行账 ± $0.01（浮点误差容忍）

执行时间：每日 UTC 06:00（美东时间 01:00/02:00，市场收盘后）
告警阈值：
  差额 > $0.01：发送 Slack/邮件告警
  差额 > $100.00：暂停入金/出金，立即通知合规
```

### 12.2 账户级别每日校验

```sql
-- 每日验证 ledger_entries 与 ledger_accounts 是否一致
SELECT la.user_id,
       la.balance AS snapshot_balance,
       SUM(le.credit_amount - le.debit_amount) AS calculated_balance,
       la.balance - SUM(le.credit_amount - le.debit_amount) AS diff
FROM ledger_accounts la
JOIN ledger_entries le ON le.user_id = la.user_id
GROUP BY la.user_id, la.balance
HAVING ABS(la.balance - SUM(le.credit_amount - le.debit_amount)) > 0.01;
-- 有结果则触发告警
```

---

## 十三、验收标准

| 场景 | 标准 |
|------|------|
| AML 筛查延迟 | 正常情况 < 3 秒完成（不阻塞用户超过 5 秒） |
| 银行卡账号显示 | 始终只显示后 4 位，完整号码不落入日志 |
| 双重记账校验 | 每日对账：所有用户余额之和 = 托管账户余额，偏差 $0.01 触发告警 |
| CTR 自动申报 | 触发条件满足后 15 天内系统自动生成 CTR 草稿 |
| 出金冷却期 | 新绑卡 3 天内无法出金，UI 显示剩余天数 |
| 幂等性 | 重复提交同一 Idempotency-Key 不产生重复交易 |
| 大额审核 | > $50K 出金自动转人工审核，1-2 个工作日完成 |
| 可提现余额 | 买入 T+1 未结算 和 卖出 T+1 未结算 均不计入可提现余额 |
| ACH 退汇处理 | R07/R10 退汇 1 个工作日内合规跟进，bank_reference 不重复处理 |
| 微存款防暴力破解 | 累计 5 次失败后银行卡不可再验证，强制重新绑卡 |
| Structuring 检测 | 24h 内同用户多笔合计 > $9,000 触发预警，> $10,000 + 3笔触发 SAR 评估 |
