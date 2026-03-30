# 出入金系统架构设计

> **配套文档**：本文档描述系统技术架构与流程。
> 业务架构基础（托管模式、入金匹配机制、悬挂资金、资金边界、银行高可用）
> 请先阅读 [`fund-custody-and-matching.md`](./fund-custody-and-matching.md)。

---

> **业务规则源头**：本文档的所有审批阈值、合规要求、SLA 承诺均实现自
> [出入金系统 Domain PRD](../prd/fund-transfer-system.md)。
>
> 如发现本 Spec 与 Domain PRD 的冲突或差异，**以 Domain PRD 为准**。
> 关键映射关系见 [Domain PRD vs Tech Specs 对标文档](../prd/DOMAIN-SPEC-MAPPING.md)。

---## 1. 系统概述

出入金系统负责用户资金在银行账户与券商账户之间的双向流转，包括入金（Deposit）、出金（Withdrawal）、对账（Reconciliation）和合规审查。

**核心职责**
- 入金：银行 → 券商账户
- 出金：券商账户 → 银行
- 实时对账与月度对账
- AML/KYC 合规审查
- 双币种支持（USD/HKD）

## 2. 系统架构

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
┌──────▼──────────────────────────────────────┐
│         API Gateway (gRPC/REST)             │
└──────┬──────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────┐
│      Fund Transfer Service (Go)             │
│  ┌────────────────────────────────────────┐ │
│  │  Transfer Engine                       │ │
│  │  - Deposit Flow (6 steps)              │ │
│  │  - Withdrawal Flow (8 steps)           │ │
│  │  - Idempotency (request_id)            │ │
│  └────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────┐ │
│  │  Compliance Engine                     │ │
│  │  - Same-name verification              │ │
│  │  - AML screening (OFAC/Sanctions/SFC/  │ │
│  │      AMLO)                              │ │
│  │  - Travel Rule (>$3000)                │ │
│  │  - KYC tier limits                     │ │
│  └────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────┐ │
│  │  Ledger Engine                         │ │
│  │  - Double-entry bookkeeping            │ │
│  │  - Balance calculation                 │ │
│  │  - Transaction history                 │ │
│  └────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────┐ │
│  │  Reconciliation Engine                 │ │
│  │  - Real-time matching                  │ │
│  │  - EOD batch reconciliation            │ │
│  │  - Monthly audit report                │ │
│  └────────────────────────────────────────┘ │
└──────┬──────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────┐
│      Bank Adapter Layer                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │   ACH    │ │   Wire   │ │   FPS    │    │
│  │ (US 3-5d)│ │(US same) │ │(HK real) │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│  ┌──────────┐ ┌──────────┐                 │
│  │  CHATS   │ │  SWIFT   │                 │
│  │(HK same) │ │(Intl 3d) │                 │
│  └──────────┘ └──────────┘                 │
└──────┬──────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────┐
│      External Services                      │
│  - Account Service (balance query)          │
│  - KYC Service (tier verification)          │
│  - Notification Service (SMS/Email)         │
│  - Risk Service (fraud detection)           │
└─────────────────────────────────────────────┘

Storage:
┌──────────────────────────────────────────────┐
│  MySQL 8.0+                                  │
│  - fund_transfers (partitioned by month)     │
│  - account_balances (real-time)              │
│  - ledger_entries (immutable)                │
│  - bank_accounts (encrypted)                 │
│  - reconciliation_records                    │
│  - virtual_accounts (入金匹配)               │
│  - suspense_funds (悬挂资金)                 │
└──────────────────────────────────────────────┘

Event Bus:
┌──────────────────────────────────────────────┐
│  Kafka Topics                                │
│  - fund.transfer.requested                   │
│  - fund.transfer.completed                   │
│  - fund.transfer.failed                      │
│  - fund.reconciliation.mismatch              │
└──────────────────────────────────────────────┘
```

## 3. 入金流程（Deposit）

```
User Request → Compliance Check → Bank Instruction →
Bank Confirmation → Ledger Update → Balance Update → Notification
```

**6个步骤**
1. 用户提交入金请求（金额、银行账户）
2. 合规检查（同名验证、AML、KYC 额度）
3. 生成银行入金指令（ACH/Wire/FPS）
4. 等待银行确认（webhook 或轮询）
5. 更新分类账（借：券商账户，贷：银行账户）
6. 发送通知（SMS/Email/Push）

**状态机**
```
PENDING → COMPLIANCE_CHECK → BANK_PROCESSING →
CONFIRMED → LEDGER_UPDATED → COMPLETED
                ↓
              FAILED (任何环节失败)
```

## 4. 出金流程（Withdrawal）

```
User Request → Balance Check → Settlement Check →
Compliance Check → Approval → Bank Transfer →
Bank Confirmation → Ledger Update → Notification
```

**8个步骤**
1. 用户提交出金请求
2. 检查可用余额（已结算资金）
3. 检查是否有未结算交易（US T+1, HK T+2）
4. 合规检查（AML、Travel Rule、同名账户）
5. 审批流程（自动审批/人工审核/合规专员，详见 Domain PRD）
   - 自动审批：金额 ≤ 日限额 + 无 AML 标记 + 低风险评分
   - 人工审核：金额 > $50,000 USD 或其他条件（1 工作日）
   - 合规专员：金额 > $200,000 USD 或 SAR 触发（1-2 工作日）
6. 发起银行转账
7. 等待银行确认
8. 更新分类账和余额

**状态机**
```
PENDING → BALANCE_CHECK → SETTLEMENT_CHECK →
COMPLIANCE_CHECK → APPROVAL → BANK_PROCESSING →
CONFIRMED → LEDGER_UPDATED → COMPLETED
                ↓
              REJECTED (余额不足/合规失败/审批拒绝)
```

## 5. 银行通道

| 通道 | 市场 | 到账时间 | 费用 | 限额 |
|------|------|----------|------|------|
| ACH | US | T+1～T+3（Standard）/ 当日（Same Day ACH） | $0-3 | $250K/day |
| Wire | US | 当日 | $15-30 | $1M/day |
| FPS | HK | 实时 | HK$0-5 | HK$1M/day |
| CHATS | HK | 当日 | HK$10-50 | HK$10M/day |
| SWIFT | 国际 | 3-5 工作日 | $30-50 | $1M/day |

## 6. 合规规则

**同名验证**
- 银行账户姓名必须与券商账户 KYC 姓名完全匹配
- 支持中文/英文姓名对比

**AML 筛查**
- OFAC SDN List（美国出口管制）
- OFAC Sectoral Sanctions（行业制裁）
- SFC Designated Persons List（香港金融管理局指定人员，Phase 2）
- AMLO Part 4A Designated Entities（香港反洗钱条例，Phase 2）
- 实时 API 调用或本地缓存（每日更新）

**Travel Rule**
- 单笔 >$3,000 需记录受益人信息
- 跨境转账需向监管机构报告

**KYC 额度限制**
| 等级 | 单笔限额 | 日限额 | 月限额 |
|------|----------|--------|--------|
| Tier 1 | $5K | $10K | $50K |
| Tier 2 | $50K | $100K | $500K |
| Tier 3 | $500K | $1M | $10M |

> **📝 NOTE**: 出金审批阈值已更新对齐 Domain PRD。人工审核 > $50K，合规专员 > $200K。
> 详见 [Domain PRD § 2.4](../prd/fund-transfer-system.md#24-出金审批规则) 和
> [Domain-Spec 对标](../prd/DOMAIN-SPEC-MAPPING.md)。

## 7. 双币种处理

> **注意**：下方"结算周期"指证券交易的 DTCC/HKSCC 结算周期（卖出股票后资金多久变为可提现），
> 不是银行出入金渠道的到账时间。详见 `docs/references/clearing-settlement-primer.md`。

**USD 账户**
- 入金：ACH（T+1～T+3）/ Wire（当日）
- 出金：ACH（T+1～T+3）/ Wire（当日）
- 证券结算周期：T+1（美股，2024年5月起）

**HKD 账户**
- 入金：FPS（实时）/ CHATS（当日）
- 出金：FPS（实时）/ CHATS（当日）
- 证券结算周期：T+2（港股）

**货币转换**
- 使用实时汇率（Reuters/Bloomberg）
- 收取 0.3% 货币转换费
- 记录汇率快照到 ledger_entries

## 8. 对账系统

**实时对账**
- 每笔交易完成后立即匹配
- 比对金额、账户、时间戳
- 不匹配立即告警（Slack/PagerDuty）

**EOD 批量对账**
- 每日 23:00 UTC 运行
- 生成对账报告（CSV/PDF）
- 自动标记异常交易

**月度审计**
- 每月 1 号生成上月报告
- 包含：总入金、总出金、手续费、异常笔数
- 发送给财务和合规团队

## 9. 双记账系统

**账户类型**
```go
const (
    AccountTypeAsset      = "ASSET"       // 资产（券商账户）
    AccountTypeLiability  = "LIABILITY"   // 负债（用户账户）
    AccountTypeBank       = "BANK"        // 银行账户
    AccountTypeFee        = "FEE"         // 手续费收入
)
```

**入金分录**
```
借：券商银行账户 (ASSET)     $10,000
  贷：用户券商账户 (LIABILITY)  $10,000
```

**出金分录**
```
借：用户券商账户 (LIABILITY)  $10,000
借：手续费收入 (FEE)          $25
  贷：券商银行账户 (ASSET)     $10,025
```

## 10. 数据库设计

见 `services/fund-transfer/migrations/001_init_fund_transfer.sql`

**核心表**
- `fund_transfers` — 转账记录（按月分区）
- `account_balances` — 账户余额（实时）
- `ledger_entries` — 分类账（不可变）
- `bank_accounts` — 银行账户（加密存储）
- `reconciliation_records` — 对账记录

## 11. API 设计

见 `api/grpc/fund_transfer.proto`

**核心 RPC**
- `SubmitDeposit` — 提交入金
- `SubmitWithdrawal` — 提交出金
- `GetTransferStatus` — 查询状态
- `ListTransfers` — 查询历史
- `GetBalance` — 查询余额
- `AddBankAccount` — 添加银行账户
- `ListBankAccounts` — 查询银行账户

## 12. 性能指标

| 指标 | 目标 | 监控 |
|------|------|------|
| 入金请求响应 | < 200ms | P99 |
| 出金请求响应 | < 500ms | P99 |
| 对账延迟 | < 5min | 实时 |
| 余额查询 | < 50ms | P99 |
| 系统可用性 | 99.9% | 月度 |

## 13. 安全措施

**数据加密**
- 银行账号：AES-256 加密存储
- 传输：TLS 1.3
- 密钥管理：AWS KMS/HashiCorp Vault

**访问控制**
- JWT 认证
- RBAC 权限模型
- 审计日志（所有操作）

**防欺诈**
- 设备指纹识别
- IP 白名单
- 异常金额告警（>$50K）
- 频率限制（5 次/小时）

## 14. 监控告警

**关键指标**
- 入金成功率（目标 >99%）
- 出金成功率（目标 >98%）
- 对账不匹配率（目标 <0.1%）
- 平均处理时间

**告警规则**
- 单笔转账失败 → Slack
- 对账不匹配 → PagerDuty
- 余额异常 → Email + SMS
- 系统错误率 >1% → PagerDuty

## 15. 部署架构

**Kubernetes**
```yaml
Deployment:
  - fund-transfer-api (3 replicas)
  - fund-transfer-worker (2 replicas)
  - reconciliation-job (CronJob, daily)

Resources:
  - CPU: 2 cores
  - Memory: 4Gi
  - Storage: 100Gi (PostgreSQL)

Autoscaling:
  - Min: 3 replicas
  - Max: 10 replicas
  - Target CPU: 70%
```

## 16. 参考资料

**监管文档**
- [FinCEN Travel Rule](https://www.fincen.gov/resources/statutes-regulations/guidance/funds-travel-regulations-questions-answers)
- [OFAC Sanctions List](https://sanctionssearch.ofac.treas.gov/)
- [SEC Customer Protection Rule](https://www.sec.gov/rules/final/34-42728.htm)

**技术参考**
- [Stripe Treasury API](https://stripe.com/docs/treasury)
- [Plaid Transfer API](https://plaid.com/docs/transfer/)
- [Dwolla ACH Integration](https://developers.dwolla.com/)
- [HKMA FPS Technical Specs](https://www.hkma.gov.hk/eng/key-functions/international-financial-centre/financial-market-infrastructure/faster-payment-system/)

**开源项目**
- [Moov ACH](https://github.com/moov-io/ach) — ACH file processing
- [Ledger](https://github.com/numary/ledger) — Double-entry ledger
- [Vault](https://github.com/hashicorp/vault) — Secrets management

**行业案例**
- Robinhood: ACH instant deposit (up to $1,000)
- Webull: Wire transfer same-day processing
- Tiger Brokers: Multi-currency account (USD/HKD/CNY)
- Futu: FPS real-time deposit (HK market)

## 17. 配套文档索引

本文档描述整体架构与流程，以下文档覆盖更深层细节：

| 文档 | 路径 | 内容 |
|------|------|------|
| 托管架构与入金匹配 | `docs/specs/fund-custody-and-matching.md` | Omnibus Account、虚拟账号/附言匹配、悬挂资金、资金边界、银行高可用 |
| 清结算体系区分 | `docs/references/clearing-settlement-primer.md` | 银行清结算 vs 证券清结算，两套体系的唯一交汇点 |
| 支付网络技术原理 | `docs/references/payment-networks-primer.md` | ACH/Wire/FPS 运营主体、技术本质、Bank Adapter 接口设计 |
| 银行渠道文档索引 | `docs/references/bank-channel-docs.md` | JP Morgan、恒生、HKICL、Nacha 等公开文档链接 |
