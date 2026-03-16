# AMS 金融业务模型规格说明

> **版本**: v0.2-draft
> **日期**: 2026-03-15
> **作者**: AMS Engineering
> **状态**: Draft — 待产品评审
>
> **变更记录**: v0.2 新增"账户系统架构模式"章节，整合 ISO 20022、Fowler Analysis Patterns、Stripe/Monzo Ledger、Apache Fineract 等行业参考实现的设计洞察

本文档定义 Account Management Service（AMS）的**金融业务模型**，覆盖账户类型体系、KYC/AML 合规模型、账户生命周期，以及跨服务的数据权威边界。注册、会话管理、认证授权等内容另见独立 spec。

---

## 目录

1. [监管框架概述](#1-监管框架概述)
2. [账户类型体系](#2-账户类型体系)
3. [KYC 信息模型](#3-kyc-信息模型)
4. [AML 合规模型](#4-aml-合规模型)
5. [账户生命周期状态机](#5-账户生命周期状态机)
6. [投资者适合性](#6-投资者适合性)
7. [数据权威边界](#7-数据权威边界)
8. [核心数据模型](#8-核心数据模型)
9. [账户系统架构模式](#9-账户系统架构模式)
10. [合规字段保留策略](#10-合规字段保留策略)
11. [待决策项](#11-待决策项)
12. [参考文献](#参考文献)

---

## 1. 监管框架概述

本平台同时运营美股（NYSE/NASDAQ）和港股（HKEX）业务，AMS 须满足**双司法管辖区**监管要求。

### 美股监管框架

| 监管层 | 机构 | 核心规则 |
|--------|------|----------|
| 联邦法律 | 美国国会 | Bank Secrecy Act (BSA)、USA PATRIOT Act Section 326 |
| 证券监管 | SEC | Rule 17a-3（账户记录）、Reg BI（最佳利益标准）、FATCA |
| 行业自律 | FINRA | Rule 4512（账户信息）、Rule 4210（保证金）、Rule 2111（适合性） |
| 反洗钱 | FinCEN | CDD Rule（31 CFR § 1010.230）、CTR/SAR 申报义务 |
| 制裁 | OFAC | SDN List 筛查 |

### 港股监管框架

| 监管层 | 机构 | 核心规则 |
|--------|------|----------|
| 证券监管 | SFC | 操守准则（Code of Conduct 2024年10月版）、AML/CFT 指引（2023年6月版） |
| 反洗钱 | AMLO | Anti-Money Laundering and Counter-Terrorist Financing Ordinance Cap. 615 |
| 保险/银行 | HKMA | 相关AML指引（跨境业务适用） |
| 可疑报告 | JFIU | STR 申报（STREAMS 2平台，2026年2月启用） |
| 税务交换 | IRD | CRS（126个管辖区）、FATCA（Model 2 IGA） |

### 关键原则

- **AMS 是账户身份的权威数据源**。所有下游服务（Trading Engine、Fund Transfer）只读引用，不写入账户属性。
- **双司法管辖区 KYC 要求叠加**，不互相替代。同时持有美股+港股账户的客户须满足两套要求。
- **合规优先于功能**。任何账户状态变更必须先满足合规要求，再触发功能开放。

---

## 2. 账户类型体系

账户类型由**三个独立维度**交叉定义，分别在不同字段存储。

### 2.1 维度一：客户主体类型（client_type）

| 枚举值 | 中文 | 美股适用 | 港股适用 | 备注 |
|--------|------|----------|----------|------|
| `INDIVIDUAL` | 个人账户 | ✅ | ✅ | 最常见类型 |
| `JOINT_JTWROS` | 联名账户（共同继承） | ✅ | ✅（以 Joint 处理） | 任一持有人去世，权益自动转移至生存方 |
| `JOINT_TIC` | 联名账户（分权共有） | ✅ | ✅ | 各方可单独处置其份额 |
| `CORPORATE` | 公司/机构账户 | ✅ | ✅ | 需 UBO 穿透识别 |
| `TRUST` | 信托账户 | ✅ | ✅ | 需信托协议+受托人KYC |
| `IRA_TRADITIONAL` | 传统 IRA | ✅ | ❌ | 美国退休账户，税前供款 |
| `IRA_ROTH` | Roth IRA | ✅ | ❌ | 美国退休账户，税后供款 |
| `CUSTODIAL` | 托管账户（UGMA/UTMA） | ✅ | ❌ | 为未成年人设立 |

**MVP 范围建议**：优先实现 `INDIVIDUAL`、`JOINT_JTWROS`、`CORPORATE`，其他类型 Phase 2。

### 2.2 维度二：资金结构类型（trading_type）

| 枚举值 | 中文 | 规则要求 |
|--------|------|----------|
| `CASH` | 现金账户 | 全额支付，不允许透支；US T+1 结算，HK T+2 结算 |
| `MARGIN_REG_T` | 保证金账户（Reg T） | 初始保证金 50%（Reg T）；维持保证金 25%（FINRA 最低）；最低权益 $2,000 |
| `MARGIN_PORTFOLIO` | 组合保证金账户 | 基于风险模型计算；最低净清算价值 $110,000（行业标准） |

**Margin 账户额外要求**：
- 须签署额外风险披露协议
- 港股 Margin 需 SFC Type 8 牌照覆盖（Securities Margin Financing）
- 开启 Margin 须人工审批，不允许自助升级

### 2.3 维度三：委托类型（delegation_type）

| 枚举值 | 中文 | 监管要求 |
|--------|------|----------|
| `SELF_DIRECTED` | 自主交易 | 默认类型，无需额外牌照 |
| `ND` | 非全权委托（Non-Discretionary） | 顾问可提建议，不可代客下单；FINRA Rule 2111 适合性适用 |
| `FD` | 全权委托（Fully Discretionary） | 顾问可代客下单；港股需 SFC Type 9 牌照；须签投资授权书（Investment Mandate） |

### 2.4 维度四：司法管辖区（jurisdiction）

| 枚举值 | 说明 | KYC 要求 |
|--------|------|----------|
| `US` | 仅美股 | SSN（美国人）或护照+W-8BEN（非美国人） |
| `HK` | 仅港股 | HKID 或护照；银行转账 ≥ HK$10,000 验证 |
| `BOTH` | 美股+港股 | 两套 KYC 全部满足；FATCA + CRS 双报 |

### 2.5 维度五：投资者分类（investor_class）

| 枚举值 | 中文 | 港股适用 | 资产门槛 |
|--------|------|----------|----------|
| `RETAIL` | 零售投资者 | 默认 | — |
| `PROFESSIONAL` | 专业投资者（PI） | ✅ | 投资组合 ≥ HK$800万 或总资产 ≥ HK$4,000万（机构） |
| `INSTITUTIONAL` | 机构专业投资者 | ✅ | 持牌金融机构、交易所等无门槛 |

**PI 管理要求**：
- PI 认定须每 12 个月更新证明文件
- 系统须记录 `pi_verified_at`、`pi_expires_at`、`pi_asset_evidence` 字段
- PI 到期前 30 天推送续期通知

---

## 3. KYC 信息模型

### 3.1 个人账户 KYC 必填字段

| 字段 | 美股依据 | 港股依据 | 备注 |
|------|----------|----------|------|
| 法定姓名（first/last） | CIP, FINRA Rule 4512 | AMLO Cap. 615 | 与证件完全一致 |
| 出生日期 | CIP | AMLO | 强制收集 |
| 居住地址（非P.O. Box） | CIP | SFC Code of Conduct | 3个月内证明文件 |
| 国籍 | CIP | AMLO | 与身份证件一致 |
| 身份证件号 | SSN/护照号（CIP） | HKID 或护照号（AMLO） | 加密存储 AES-256-GCM |
| 税务居住地 | W-9/W-8BEN | CRS 自我声明 | 可能多个 |
| 税务识别号（TIN） | IRS 要求 | IRD（HK TIN = HKID） | — |
| 职业/雇主 | FINRA Rule 4512 | SFC KYC | 了解资金来源 |
| 年收入 | FINRA Rule 4512 | SFC 适合性 | 枚举区间即可 |
| 流动净资产 | FINRA Rule 4512 | SFC 适合性 | 枚举区间即可 |
| 资金来源 | FinCEN CDD Rule | AMLO Schedule 2 | 薪酬/投资/经营等 |
| 投资目标 | FINRA Rule 4512 | SFC 适合性 | 枚举：GROWTH/INCOME/SPECULATION 等 |
| 投资经验 | FINRA Rule 4512 | SFC KYC | 年数 + 品种经验 |
| 风险承受能力 | FINRA Rule 4512 | SFC 适合性评估 | 问卷评分结果 |
| 受信联络人（TCP） | FINRA Rule 4512（非机构账户须努力获取） | 不适用 | 姓名+联系方式 |

**港股特别要求**：
- 非面对面开户须通过指定香港持牌银行账户转入 ≥ HK$10,000 验证
- 所有存取款须通过同一指定银行账户（同名账户原则）

### 3.2 公司账户 KYC 必填字段

| 字段 | 要求 | 来源 |
|------|------|------|
| 公司法定名称 | 与注册证书一致 | CIP / AMLO |
| 注册国家/地区 | — | CIP / AMLO |
| 注册号码 | 营业执照/注册证书号 | CIP / AMLO |
| 注册地址 | — | CIP / AMLO |
| 经营地址 | 如与注册地址不同 | AMLO |
| 公司章程 (M&A) | 扫描件存档 | CIP / AMLO |
| 董事会决议 | 授权开户及授权签署人 | CIP / AMLO |
| 股权架构图 | 穿透至自然人 | FinCEN CDD / AMLO |
| UBO 列表 | 持股 ≥ 25% 的所有自然人（每人完整 KYC） | FinCEN CDD / AMLO |
| 控制人（Controller） | 最高管理控制权自然人 1 名 | FinCEN CDD |
| 授权签署人 | 身份证明 + 授权文件 | CIP / AMLO |

**UBO 穿透规则**：
- 美股：持股 ≥ 25% 的每位自然人（FinCEN 31 CFR § 1010.230）+ 1 名控制人
- 港股：持股 > 25% 的每位自然人（AMLO Schedule 2）；高风险时降至 10%
- 无法识别 UBO 时，须由董事签署 UBO 声明（Declaration）

### 3.3 税务表格状态机

```
开户时判断税务身份
       │
   ┌───┴───────────┐
   ▼               ▼
美国税务居民      非美国税务居民
   │               │
   ▼           ┌───┴────────┐
W-9            ▼            ▼
(无需定期更新)  个人         机构
               │            │
               ▼            ▼
           W-8BEN       W-8BEN-E
       (3年有效期，    (3年有效期，
        身份变更30天   含FATCA第四章
        内须通知)      状态声明)
```

**W-8BEN 生命周期管理**：
- 有效期：签署之日起至第三个公历年度最后一天
- 到期前 **90 天**：系统自动推送更新提醒
- 到期后未更新：冻结美股股息分配，预扣 30% FATCA 预提税
- 身份变更（如成为美国居民）：须在 **30 天**内通知，更新为 W-9

### 3.4 KYC 文件管理

- 文件存储：加密对象存储（S3-compatible），不存储在 MySQL
- MySQL 只存储文件引用（file_key）、文档类型、上传时间、核验状态
- 文件访问：仅合规人员和审计流程可访问原始文件
- 保存期限：账户关闭后 **6 年**（港股 KYC）；**5 年**（美股 CIP）

---

## 4. AML 合规模型

### 4.1 AML 风险评分

每个账户维护一个动态 AML 风险评分，影响审批流程和监控强度。

| 风险等级 | 枚举值 | 触发条件 |
|----------|--------|----------|
| 低风险 | `LOW` | 本地居民、工薪收入、交易行为正常 |
| 中风险 | `MEDIUM` | 非居民、资金来源较复杂、存在 PEP 关联 |
| 高风险 | `HIGH` | 高风险国家/地区、PEP 本人、异常交易模式 |

风险等级影响：
- `MEDIUM` 以上：出入金须人工审核（见 Fund Transfer 合规规则）
- `HIGH`：须 EDD（强化尽职调查），需合规官员批准

### 4.2 制裁筛查（Sanctions Screening）

**筛查时机**：
1. 账户开立时（必须通过才能激活）
2. KYC 信息变更时
3. 每日定时批量筛查（制裁名单每日更新）

**筛查名单**：

| 名单 | 适用市场 | 更新频率 |
|------|----------|----------|
| OFAC SDN List | US | 实时/每日 |
| OFAC Sectoral Sanctions | US | 每日 |
| OFAC Non-SDN Lists | US | 每日 |
| UN Sanctions List（UNSO/UNATMO） | HK | 每日 |
| HK 内部指定名单 | HK | 不定期（须监控 SFC/JFIU 通告） |

**匹配策略**：
- 精确匹配 + 模糊匹配（处理拼写变体）
- 命中任一名单：立即冻结账户，触发人工审核
- 需记录每次筛查结果（时间戳 + 名单版本 + 匹配结果）

### 4.3 PEP（政治公众人物）筛查

依据 2023 年 AMLO 修订（2023年6月1日生效），PEP 分类如下：

| 类别 | 定义 | EDD 要求 |
|------|------|----------|
| 非香港 PEP（Non-HK PEP） | 外国政府/国际组织高级职位人士，**含中国内地 PEP** | 强制 EDD + 高管批准 + 财富来源证明 |
| 香港 PEP | 香港政府高级职位人士 | 风险评估后决定是否 EDD |
| 国际组织 PEP | 国际组织高级职位人士 | 风险评估后决定是否 EDD |
| 前非香港 PEP | 上述职位已卸任者 | 风险评估后可豁免 EDD |

**PEP 字段**：
- `is_pep`：boolean
- `pep_type`：`NON_HK_PEP` / `HK_PEP` / `INTL_ORG_PEP` / `FORMER_NON_HK_PEP`
- `pep_verified_at`：筛查时间
- `edd_approved_by`：高管审批人 ID（Non-HK PEP 必填）

### 4.4 CTR/SAR 联动

AMS 不直接负责 CTR/SAR 申报（这属于 Fund Transfer 服务的触发责任），但 AMS 须维护以下字段供下游服务查询：

| 字段 | 说明 |
|------|------|
| `aml_risk_score` | 当前 AML 风险评分 |
| `aml_flags` | JSON，记录当前活跃的 AML 标记 |
| `ctr_filing_count` | 历史 CTR 申报次数（参考用） |
| `sar_filing_count` | 历史 SAR 申报次数（高度敏感，严格访问控制） |
| `last_aml_review_at` | 最近一次 AML 审查时间 |

SAR 相关字段须严格访问控制：
- 绝对不能在客户界面暴露
- API 响应中须过滤掉 SAR 相关字段（防止 Tipping-Off）
- 访问须有审计日志

---

## 5. 账户生命周期状态机

### 5.1 完整状态图

```
APPLICATION_SUBMITTED
        │
        ▼
   CIP_PENDING ─────────────────────────────────┐
        │                                        │
   CIP 自动核验                                  │
   ┌────┴────┐                                  │
   ▼         ▼                                  │
通过      需人工审核 ──► COMPLIANCE_REVIEW ──► 拒绝
   │         │
   │         │（补充材料后可回到 CIP_PENDING）
   │         │
   └────┬────┘
        │
   AML_SCREENING
        │
   ┌────┴────┐
   ▼         ▼
通过      命中名单 ──► SANCTIONS_REVIEW ──► REJECTED
   │
   ▼
DOCUMENT_PENDING（等待文件上传/核验）
        │
        ▼
ACCOUNT_PENDING（文件审核中）
        │
        ▼
   ACTIVE ◄──────────────────────────────────┐
        │                                     │
   ┌────┼────────────────┐                   │
   ▼    ▼                ▼                   │
触发   SUSPENDED     UNDER_REVIEW ───────────┘
AML    （操作限制）    （人工审查中）
   │
   ▼
CLOSED（账户关闭，数据保留合规期）
```

### 5.2 状态转换规则

每次状态转换必须：
1. 产生不可变的审计事件记录（`account_status_events` 表，append-only）
2. 记录：操作人（user_id 或 system）、原因代码（reason_code）、时间戳（UTC）
3. 触发相应的通知（见通知服务规范）

**关键约束**：
- `CLOSED` 为终态，不可逆转（关闭后若需重开须走全新开户流程）
- `SUSPENDED` 期间：禁止下单，禁止出入金，可查看持仓和账户信息
- `UNDER_REVIEW` 期间：功能限制与 SUSPENDED 相同，但强调正在调查

### 5.3 美股账户特殊状态

| 状态标记 | 说明 | 来源 |
|----------|------|------|
| `pdt_flagged` | Pattern Day Trader 标记 | Trading Engine 写入，每日更新 |
| `margin_call_active` | 存在未满足的保证金追缴 | Trading Engine 写入 |
| `w8ben_expired` | W-8BEN 已过期 | AMS 定时任务写入 |

---

## 6. 投资者适合性

### 6.1 美股：Reg BI + FINRA Rule 2111

**适用场景**：持牌投资顾问向零售客户提出**建议或推销**时触发。

客户提供 Execution-Only（纯自主下单）服务时，适合性义务**不触发**，但 KYC 信息仍须完整收集（FINRA Rule 4512 要求）。

**需收集的适合性信息**：

| 字段 | 说明 |
|------|------|
| `investment_objective` | 枚举：CAPITAL_PRESERVATION / INCOME / GROWTH / SPECULATION |
| `risk_tolerance` | 枚举：CONSERVATIVE / MODERATE / AGGRESSIVE |
| `time_horizon` | 枚举：SHORT（<1年）/ MEDIUM（1-5年）/ LONG（>5年） |
| `liquidity_needs` | 枚举：LOW / MEDIUM / HIGH |
| `tax_status` | 税务状况（影响产品推荐） |
| `investment_experience_stocks` | 股票投资经验年数 |
| `investment_experience_options` | 期权投资经验年数 |
| `investment_experience_margin` | 保证金交易经验年数 |

### 6.2 港股：SFC 适合性评估

**触发条件**：持牌人向客户**建议或推销**（solicitation）时触发。

**特别注意**：
- SFC 已发现部分平台允许客户在极短时间内（如1小时内8次）修改风险问卷——**系统须限制修改频率**
- 建议：同一客户24小时内风险问卷修改次数 ≤ 1次；超出须人工审核

### 6.3 期权权限等级（美股）

| 等级 | 允许策略 | 升级审批 |
|------|----------|----------|
| 0 | 无期权交易 | 默认 |
| 1 | Covered Call、Protective Put | 自动审批（满足基本条件） |
| 2 | Level 1 + 买入看涨/看跌期权 | 自动审批（满足经验要求） |
| 3 | Level 2 + 价差策略 | 需人工审核 |
| 4 | Level 3 + 裸期权卖出 | 需合规审核 |

字段：`options_level`（0-4），变更须记录审批历史。

### 6.4 Pattern Day Trader（PDT）规则

**当前规则**（FINRA Rule 4210(f)(8)，**2026年内仍有效**）：
- 5个交易日内 ≥ 4 次日内交易，且占该5日总交易量 > 6% → 标记为 PDT
- PDT 账户须维持最低权益 **$25,000**
- 若权益 < $25,000：限制日内交易功能

**注意**：FINRA 已于2026年1月提交 PDT 规则修订案至 SEC，拟废除 $25,000 要求，改为基于风险的保证金模型。**修订案尚未生效，现行规则持续执行**。

系统须向 Trading Engine 暴露 `pdt_flagged` 和 `pdt_equity_check` 接口。

---

## 7. 数据权威边界

### 7.1 AMS 拥有（权威写入）

```
accounts 表（账户维度属性）
├── client_type          // INDIVIDUAL / JOINT_JTWROS / CORPORATE / ...
├── trading_type         // CASH / MARGIN_REG_T / MARGIN_PORTFOLIO
├── delegation_type      // SELF_DIRECTED / ND / FD
├── jurisdiction         // US / HK / BOTH
├── investor_class       // RETAIL / PROFESSIONAL / INSTITUTIONAL
├── account_status       // PENDING → ACTIVE → SUSPENDED → CLOSED
├── kyc_tier             // BASIC / STANDARD / ENHANCED
├── kyc_status           // PENDING / VERIFIED / REJECTED
├── aml_risk_score       // LOW / MEDIUM / HIGH
└── trading_permissions  // JSON: 允许的市场/品种/功能
```

### 7.2 Trading Engine 消费（只读）

| 字段 | 用途 | 获取方式 |
|------|------|----------|
| `account_status` | 每次下单校验账户是否 ACTIVE | gRPC 实时查询（每次下单） |
| `trading_type` | 决定买入力计算方式（现金 vs 保证金） | Redis 缓存，TTL=60s |
| `trading_permissions` | 校验下单品种/市场是否被允许 | Redis 缓存，TTL=60s |
| `options_level` | 校验期权策略是否被授权 | Redis 缓存，TTL=60s |
| `delegation_type` | FD 账户下单时记录授权人 | Redis 缓存，TTL=60s |

### 7.3 Fund Transfer 消费（只读）

| 字段 | 用途 | 获取方式 |
|------|------|----------|
| `kyc_tier` | 决定出入金日限额 | gRPC 查询 |
| `account_status` | 校验账户是否允许出入金 | gRPC 查询 |
| `aml_risk_score` | 决定是否需要人工审核 | gRPC 查询 |
| `jurisdiction` | 决定适用哪套出入金规则 | gRPC 查询 |

### 7.4 gRPC 接口概览（供下游服务）

```protobuf
service AccountService {
    // 校验账户状态（Trading Engine 下单前调用）
    rpc ValidateAccount(ValidateAccountRequest) returns (ValidateAccountResponse);

    // 获取账户属性快照（Fund Transfer 出入金前调用）
    rpc GetAccountSnapshot(GetAccountSnapshotRequest) returns (AccountSnapshot);

    // 获取KYC层级（Fund Transfer 查限额用）
    rpc GetKYCTier(GetKYCTierRequest) returns (GetKYCTierResponse);

    // 获取 PI 状态（港股产品推荐前校验）
    rpc GetInvestorClass(GetInvestorClassRequest) returns (GetInvestorClassResponse);
}
```

---

## 8. 核心数据模型

### 8.1 accounts 表（主表）

```sql
CREATE TABLE accounts (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id          CHAR(36) UNIQUE NOT NULL,        -- UUID，对外暴露的账户ID
    user_id             BIGINT UNSIGNED NOT NULL,         -- 关联 users 表

    -- 账户类型维度
    client_type         VARCHAR(20) NOT NULL,             -- INDIVIDUAL / JOINT_JTWROS / CORPORATE / ...
    trading_type        VARCHAR(20) NOT NULL DEFAULT 'CASH', -- CASH / MARGIN_REG_T / MARGIN_PORTFOLIO
    delegation_type     VARCHAR(20) NOT NULL DEFAULT 'SELF_DIRECTED',
    jurisdiction        VARCHAR(8) NOT NULL,              -- US / HK / BOTH
    investor_class      VARCHAR(20) NOT NULL DEFAULT 'RETAIL',

    -- 账户状态
    account_status      VARCHAR(20) NOT NULL DEFAULT 'APPLICATION_SUBMITTED',

    -- KYC
    kyc_status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    kyc_tier            VARCHAR(20) NOT NULL DEFAULT 'BASIC', -- BASIC / STANDARD / ENHANCED
    kyc_verified_at     TIMESTAMP NULL,
    kyc_reviewer_id     BIGINT UNSIGNED NULL,            -- 人工审核人

    -- AML
    aml_risk_score      VARCHAR(10) NOT NULL DEFAULT 'LOW', -- LOW / MEDIUM / HIGH
    aml_flags           JSON,                             -- 活跃的AML标记
    aml_last_screened_at TIMESTAMP NULL,
    is_pep              TINYINT(1) NOT NULL DEFAULT 0,
    pep_type            VARCHAR(30) NULL,
    pep_verified_at     TIMESTAMP NULL,
    edd_approved_by     BIGINT UNSIGNED NULL,

    -- 投资者适合性
    options_level       TINYINT NOT NULL DEFAULT 0,       -- 0-4
    investment_objective VARCHAR(30) NULL,
    risk_tolerance      VARCHAR(20) NULL,

    -- PI（港股专业投资者）
    pi_verified_at      TIMESTAMP NULL,
    pi_expires_at       TIMESTAMP NULL,

    -- 税务
    tax_form_type       VARCHAR(20) NULL,                 -- W9 / W8BEN / W8BEN_E
    tax_form_expires_at TIMESTAMP NULL,

    -- 美股特殊标记
    pdt_flagged         TINYINT(1) NOT NULL DEFAULT 0,
    margin_call_active  TINYINT(1) NOT NULL DEFAULT 0,

    -- 交易权限
    trading_permissions JSON,                             -- {"markets":["US","HK"],"products":["STOCK","ETF"]}

    -- 审计
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version             INT NOT NULL DEFAULT 0,           -- 乐观锁

    INDEX idx_accounts_user (user_id),
    INDEX idx_accounts_status (account_status),
    INDEX idx_accounts_kyc (kyc_status, kyc_tier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 8.2 account_kyc_profiles 表

```sql
CREATE TABLE account_kyc_profiles (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id          CHAR(36) NOT NULL,
    profile_type        VARCHAR(20) NOT NULL,            -- INDIVIDUAL / CORPORATE

    -- 个人信息（加密字段）
    full_name_encrypted VARBINARY(512),                  -- AES-256-GCM
    dob_encrypted       VARBINARY(256),                  -- AES-256-GCM
    id_number_encrypted VARBINARY(512),                  -- SSN/HKID/Passport，AES-256-GCM
    id_type             VARCHAR(20),                     -- SSN / HKID / PASSPORT
    nationality         VARCHAR(64),
    address_line1       VARCHAR(256),
    address_city        VARCHAR(128),
    address_country     CHAR(2),                         -- ISO 3166-1 alpha-2

    -- 职业与财务
    employment_status   VARCHAR(30),
    employer_name       VARCHAR(256),
    annual_income_range VARCHAR(30),                     -- 枚举区间
    net_worth_range     VARCHAR(30),
    source_of_funds     VARCHAR(512),

    -- 税务
    tax_residency       JSON,                            -- [{"country":"US","tin":"xxx"},{"country":"HK","tin":"yyy"}]
    w8_status           VARCHAR(20),                     -- W8BEN / W8BEN_E / W9 / NONE

    -- 受信联络人（美股）
    tcp_name            VARCHAR(256),
    tcp_phone           VARCHAR(64),
    tcp_collected_at    TIMESTAMP NULL,

    -- 文件引用（不存文件本身）
    id_doc_key          VARCHAR(512),                    -- S3 key
    address_proof_key   VARCHAR(512),
    additional_docs     JSON,

    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_account_profile (account_id, profile_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 8.3 account_ubos 表（机构账户 UBO）

```sql
CREATE TABLE account_ubos (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id          CHAR(36) NOT NULL,
    ubo_type            VARCHAR(20) NOT NULL,            -- OWNERSHIP / CONTROL
    full_name_encrypted VARBINARY(512) NOT NULL,         -- AES-256-GCM
    dob_encrypted       VARBINARY(256),
    id_number_encrypted VARBINARY(512),
    nationality         VARCHAR(64),
    ownership_pct       DECIMAL(5,2),                   -- 持股百分比
    is_pep              TINYINT(1) NOT NULL DEFAULT 0,
    kyc_status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    doc_key             VARCHAR(512),
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_ubos_account (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 8.4 account_status_events 表（Append-Only 审计）

```sql
CREATE TABLE account_status_events (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id            CHAR(36) UNIQUE NOT NULL,
    account_id          CHAR(36) NOT NULL,
    event_type          VARCHAR(50) NOT NULL,            -- KYC_VERIFIED / STATUS_CHANGED / AML_FLAGGED / ...
    from_status         VARCHAR(30),
    to_status           VARCHAR(30),
    actor_id            BIGINT UNSIGNED,                 -- 操作人，NULL=系统
    actor_type          VARCHAR(20) NOT NULL,            -- CUSTOMER / COMPLIANCE_OFFICER / SYSTEM
    reason_code         VARCHAR(50),
    details             JSON,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_events_account (account_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 注意：此表只允许 INSERT，禁止 UPDATE 和 DELETE（通过应用层+DB权限双重保证）
```

### 8.5 account_sanctions_screenings 表

```sql
CREATE TABLE account_sanctions_screenings (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    screening_id        CHAR(36) UNIQUE NOT NULL,
    account_id          CHAR(36) NOT NULL,
    screening_type      VARCHAR(20) NOT NULL,            -- ONBOARDING / PERIODIC / TRIGGERED
    lists_screened      JSON NOT NULL,                   -- ["OFAC_SDN","UN_SANCTIONS","HK_DESIGNATED"]
    list_versions       JSON NOT NULL,                   -- 每个名单的版本/日期
    result              VARCHAR(20) NOT NULL,            -- CLEAR / MATCH / REVIEW_REQUIRED
    matched_entries     JSON,                            -- 命中的名单条目
    reviewed_by         BIGINT UNSIGNED,
    review_decision     VARCHAR(20),                     -- APPROVED / REJECTED
    reviewed_at         TIMESTAMP NULL,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_screenings_account (account_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

## 9. 账户系统架构模式

> 本章整合 ISO 20022、Martin Fowler Analysis Patterns、Stripe/Monzo Ledger、Apache Fineract 等行业参考实现，明确我们的架构决策。

### 9.1 账户多维类型的建模决策

账户类型是"多维交叉"的，行业上有三种常见建模方案，我们采用**分层组合**策略：

```
┌──────────────────────────────────────────────────────────┐
│                  账户类型建模分层                          │
│                                                          │
│  层一：强类型固定枚举（DB 约束，可索引，业务核心）          │
│  ├── ownership_type  SIGL / JOIT / CORP / TRUS / CUST   │
│  ├── account_class   CASH / MARGIN_REG_T / MARGIN_PORT   │
│  ├── jurisdiction    US / HK / BOTH                      │
│  └── investor_class  RETAIL / PROFESSIONAL / INSTITIONAL │
│                                                          │
│  层二：能力标记 JSON（稀疏，随产品迭代演化）               │
│  capabilities: {                                         │
│    "can_trade_us": true,                                 │
│    "can_trade_hk": true,                                 │
│    "options_level": 2,                                   │
│    "can_short": false,                                   │
│    "kyc_tier": 3,                                        │
│    "daily_withdrawal_limit_usd": "50000"                 │
│  }                                                       │
│                                                          │
│  层三：关联表（多对多关系，如联名账户持有人）              │
│  account_holders: (account_id, user_id, role)            │
└──────────────────────────────────────────────────────────┘
```

**决策依据**：
- **固定枚举**：业务查询的主要过滤条件（如"找所有港股账户"），需强类型约束和 B-Tree 索引
- **JSON 能力标记**：账户权限随 KYC 推进动态开放，字段数量多但单账户只用一部分，适合 JSON + GIN 索引
- **关联表**：联名账户的第 2+ 持有人不宜放 JSON 里，否则无法高效按用户反查所有账户

**参考来源**：ISO 20022 AccountOwnershipType 枚举 + Apache Fineract capabilities 模式 + Berlin Group PRIV/ORGA 正交分类

### 9.2 账户状态编码规范

参考 Apache Fineract 的**百位整数编码**，预留扩展空间：

```
100 = APPLICATION_SUBMITTED   ← 申请受理
200 = KYC_IN_PROGRESS         ← KYC 核验中（CIP / AML / 人工审核）
250 = KYC_ADDITIONAL_INFO     ← 需要补充材料（可回到 200）
300 = ACTIVE                  ← 正常激活
400 = SUSPENDED               ← 账户暂停（操作受限）
450 = UNDER_REVIEW            ← 合规调查中
500 = CLOSING                 ← 关闭流程中（资产清算/转移）
600 = CLOSED                  ← 已关闭（终态，软删除，数据保留合规期）
900 = REJECTED                ← 开户被拒绝（终态）
```

**设计原则**：
- 百位间隔预留子状态（如 200 区间可扩展 210、220 等）
- 每次状态变更写入 `account_status_events`（append-only 审计表）
- `CLOSED` 和 `REJECTED` 是终态，不可逆转

### 9.3 Party-Account 关系模型（来自 ISO 20022）

ISO 20022 `acmt` 消息族将**当事方（Party）** 与**账户（Account）** 分离建模，通过角色关联。我们采用同样的思想：

```
users 表（Party）
    │
    │ 1 .. n（通过 account_holders 关联）
    ▼
accounts 表（Account）
    │
    │ AccountPartyRole（借鉴 ISO 20022）
    ├── OWNE: AccountOwner（主持有人）
    ├── JOWN: JointOwner（联名持有人，来自 account_holders）
    ├── AUTH: AuthorisedPerson（FD账户授权操作人）
    └── BENE: Beneficiary（IRA账户受益人，US特有）
```

**ISO 20022 AccountOwnershipType 枚举映射**：

| ISO 20022 代码 | 含义 | 我们的 ownership_type |
|---------------|------|-----------------------|
| `SIGL` | Single | `INDIVIDUAL` |
| `JOIT` | Joint (JTWROS) | `JOINT_JTWROS` |
| `CORP` | Corporate | `CORPORATE` |
| `TRUS` | Trust | `TRUST` |
| `CUST` | Custodial | `CUSTODIAL` |
| `NACC` | Nominee | （暂不支持） |

### 9.4 Ledger 设计：余额不直接存储

**核心原则**（来自 Martin Fowler Analysis Patterns + Stripe + Monzo）：

> **账户余额不是直接存储的字段，而是分录（Entry）的聚合推导结果。**

```
BusinessEvent（业务事件）
    │
    │ PostingRule（记账规则，策略模式）
    ▼
AccountingTransaction（会计凭证，原子）
    │
    ├── LedgerEntry（借方）→ Account（借方账户）
    └── LedgerEntry（贷方）→ Account（贷方账户）

余额 = SUM(credit entries) - SUM(debit entries) for a given account
```

**实践中的物化策略**（余额字段是"派生"的物化结果）：

```
account_balances 表（物化视图，定期从 ledger_entries SUM 刷新）
├── cash_balance          现金余额（已结算）
├── unsettled_cash        未结算现金（卖出 T+1/T+2 待结算）
├── market_value          持仓市值（来自行情服务）
├── margin_used           已用保证金（来自交易引擎）
└── withdrawable_cash     可提现金额（= cash - unsettled - margin_req）
```

**Monzo 的 Ledger 地址（LedgerAddress）设计启发**：

不同用途的资金在不同的 Ledger 维度记账，避免混账：

```
LedgerAddress = (entity, namespace, name, currency, account_id)

customer-facing-balance / USD / acc_001   ← 用户可见余额
unsettled-proceeds / USD / acc_001        ← 未结算卖出款
margin-collateral / HKD / acc_001        ← 保证金抵押物
```

**快照策略**（避免历史分录过多时余额查询退化）：
- 每 100 条 ledger_entries 触发一次账户快照
- 查询余额：找最新快照 → 重放快照后的增量 entries

### 9.5 双层账户结构（清算层 vs 投资者层）

我们的 AMS 账户是**投资者受益所有权层**，不是清算参与者层：

```
AMS 账户（受益所有权层）
    │  "Jane Smith 持有 100 股 AAPL"
    │
    ▼ 通过清算对接
清算层（名义持有层）
    ├── 美股：DTC / Cede & Co.（DTCC）持有名义股份
    └── 港股：HKSCC-NOMS（CCASS）持有名义股份
```

**对 AMS 的影响**：
- AMS 只需维护投资者的内部子账本（Sub-ledger）
- 与 CCASS/DTC 的对账通过**每日对账任务**完成，而非实时同步
- 账户里的 `position` 数据是我们内部记录的副本，真实结算由清算层决定

### 9.6 KYC 工作流：动态旅程模式

参考 Ballerine（开源 KYC 引擎）的设计，KYC 流程应是**可配置的工作流**，而非硬编码的固定步骤：

```
KYC 工作流（状态机驱动）

DOCUMENT_COLLECTION
    ├── IDENTITY_DOCUMENT（HKID / Passport）
    ├── ADDRESS_PROOF
    └── [CORPORATE: UBO_DOCUMENTS, BOARD_RESOLUTION]
         │
         ▼
AUTOMATED_CHECKS（并行执行）
    ├── OCR_VERIFICATION（文件真伪）
    ├── LIVENESS_CHECK（人脸+活体）
    ├── SANCTIONS_SCREENING（OFAC/UN）
    └── PEP_SCREENING
         │
    ┌────┴────┐
    ▼         ▼
AUTO_PASS   MANUAL_REVIEW（任一检查返回 REVIEW/FAIL）
    │         │
    │    COMPLIANCE_OFFICER_REVIEW
    │         │
    └────┬────┘
         ▼
    KYC_APPROVED / KYC_REJECTED
```

**动态旅程**的意思是：根据用户风险评分实时调整 KYC 步骤：
- 低风险 Retail 用户：标准3步（身份 → 自动核验 → 激活）
- 中风险（非港居民）：增加地址证明 + 人工审核
- 高风险（非香港PEP）：增加 EDD（财富来源 + 高管批准）
- 机构账户：完整 UBO 穿透 + 公司文件核验

### 9.7 Stripe DQ 模式：资金流动主动核验

参考 Stripe Ledger 的数据质量（DQ）平台思想，我们需要构建**三方自动核对机制**：

```
每日对账任务（Fund Transfer 触发，AMS 提供账户维度）

内部账本（ledger_entries）
    ↕ 差额 = 0 ✅ | 差额 > $0.01 → 告警 | 差额 > $100 → 暂停操作
银行流水（Bank Statement）
    ↕
托管账户（Custodian Balance）
```

**告警阈值**（来自 fund-transfer-compliance.md 规则6）：
- 差额 > $0.01：自动告警
- 差额 > $100：暂停相关账户的出入金操作，等待人工核查

### 9.8 多货币子账户设计（Revolut Currency Pocket 模式）

虽然我们初期只有 USD 和 HKD，但从第一天起就应按**多货币子账户**架构设计，避免后期重构：

```sql
-- 货币子账户（Currency Pocket）
CREATE TABLE account_currency_pockets (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id  CHAR(36) NOT NULL,
    currency    CHAR(3) NOT NULL,              -- ISO 4217: USD / HKD
    -- 余额字段（物化，从 ledger_entries 派生）
    cash_balance      DECIMAL(20,4) NOT NULL DEFAULT 0,
    unsettled_cash    DECIMAL(20,4) NOT NULL DEFAULT 0,
    withdrawable_cash DECIMAL(20,4) NOT NULL DEFAULT 0,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    version     INT NOT NULL DEFAULT 0,        -- 乐观锁
    UNIQUE KEY uk_pocket (account_id, currency)
) ENGINE=InnoDB;
```

**汇率换算**：USD ↔ HKD 换算在用户触发换汇时产生一笔 FX 交易记录，而非显示时实时计算。

---

## 10. 合规字段保留策略

| 记录类型 | 保存期限 | 监管依据 |
|----------|----------|----------|
| 账户记录（accounts 表） | 账户关闭后 6 年（港股）/ 5 年（美股 CIP） | AMLO / 31 CFR § 1023.220 |
| KYC 文件 | 账户关闭后 6 年 | AMLO / FINRA |
| 账户状态审计事件 | 7 年 | SEC Rule 17a-4 / FINRA |
| 制裁筛查记录 | 7 年 | BSA / AMLO |
| AML 筛查结果 | 7 年 | BSA / AMLO |
| CTR/SAR 关联记录 | 5 年 | FinCEN / JFIU |
| 税务表格（W-8BEN 等） | 账户关闭后 3 年（最短） | IRS 规定 |
| 账户关闭：软删除 | 不物理删除，仅标记 status=CLOSED | 所有上述要求 |

**实现要求**：
- 所有保留记录须为 append-only 或 WORM（Write Once Read Many）存储
- `accounts` 表的删除操作：通过 `account_status = CLOSED` 软删除，不物理删除
- `account_status_events` 表：数据库级别禁止 UPDATE/DELETE（CREATE USER with SELECT, INSERT only）

---

## 11. 待决策项

以下事项需产品和合规团队确认，然后再进入详细设计：

| # | 问题 | 影响范围 | 优先级 |
|---|------|----------|--------|
| 1 | MVP 是否支持联名账户（Joint）？联名账户的 KYC 需两个人都完成，增加开户摩擦 | 开户流程、KYC 模型 | High |
| 2 | MVP 是否支持机构账户（Corporate）？UBO 穿透流程复杂，合规审核时间长 | KYC 模型、AML | High |
| 3 | 是否在第一期支持 Margin 账户？ | Trading Engine 联动、风控 | High |
| 4 | 是否在第一期支持 FD（全权委托）账户？需要 SFC Type 9 牌照 | 牌照获取、授权模型 | Medium |
| 5 | PI（专业投资者）认定是否线上自助？还是纯人工审核？ | 开户流程 | Medium |
| 6 | KYC 文件核验用哪家第三方服务（如 Jumio、Onfido、iDenfy）？ | 开户流程、供应商 | High |
| 7 | 制裁筛查用哪家第三方服务（如 Dow Jones Risk & Compliance、Refinitiv）？ | AML 管道 | High |
| 8 | 港股非面对面开户的"指定银行"列表确定了吗？ | 开户流程 | High |

---

---

## 参考文献

本文档的设计结论来自两轮系统性调研，详细资料见 [`docs/references/ams-industry-research.md`](../../../docs/references/ams-industry-research.md)。下表列出各章节的主要出处。

### 监管法规（§1–§6、§10）

| 结论 | 出处 | Reference 章节 |
|------|------|----------------|
| 美股 KYC 必填字段（姓名、DOB、SSN 等） | USA PATRIOT Act §326、FINRA Rule 4512、31 CFR §1023.220 | §4 KYC/CIP 要求对比 |
| 港股 KYC 必填字段（HKID、地址证明等） | AMLO Cap. 615 Schedule 2、SFC Code of Conduct 2024年10月版 Para.5.1 | §4 KYC/CIP 要求对比 |
| UBO 穿透门槛 ≥25% | FinCEN 31 CFR §1010.230（美股）、AMLO Schedule 2（港股） | §4 KYC/CIP 要求对比 |
| 受信联络人（TCP）— 美股非机构账户须努力获取 | FINRA Rule 4512（2018年生效，2025年仍执行） | §4 KYC/CIP 要求对比 |
| 港股非面对面开户：指定银行转账 ≥ HK$10,000 | SFC《可接受的账户开立方式》 | §2 港股监管框架 §2.5 |
| W-8BEN 3年有效期、到期预扣30% FATCA | IRS Form W-8BEN Instructions | §4 KYC/CIP 要求对比 §4.3 |
| PEP 分类：中国内地官员属于 Non-HK PEP（强制EDD） | SFC AML/CFT 指引 2023年6月版、AMLO 2023修订 | §2 港股监管框架 §2.3 |
| PI 认定门槛（HK$800万）及年度更新 | SFO Cap. 571 Schedule 1 Part 1、Cap. 571D | §2 港股监管框架 §2.4 |
| 制裁筛查名单（OFAC SDN、UN UNSO/UNATMO） | BSA、UNSO Cap. 537 | §5 AML 合规对比 §5.1 |
| SAR：≥$5,000 触发，30天申报，严禁 Tipping-Off | 31 CFR §1023.320 | §1 美股监管框架 §1.5 |
| STR：JFIU STREAMS 2 平台（2026年2月启用） | JFIU 官方公告 | §8 监管动态 |
| PDT 规则 $25,000 仍有效（修订案未生效） | FINRA Rule 4210(f)(8)、FINRA RN 24-13 | §8 监管动态 |
| 合规记录保存期限（7年审计、6年KYC） | SEC Rule 17a-4、AMLO Cap. 615 Section 20 | §4 KYC/CIP 要求对比 |
| Margin 初始50%、维持25%、最低$2,000 | Regulation T、FINRA Rule 4210 | §1 美股监管框架 §1.3 |
| 港股 Margin 需 SFC Type 8 牌照 | SFC 证券孖展融资活动指引 | §2 港股监管框架 §1.2 |
| FD 全权委托需 SFC Type 9 牌照 | SFC Code of Conduct | §2 港股监管框架 §1.3 |
| SFC 风险问卷不得在短时间内反复修改 | SFC 2022年在线平台审查（Circular Ref 22EC52） | §2 港股监管框架 §2.3 |

### 行业标准（§9.1–§9.3）

| 结论 | 出处 | Reference 章节 |
|------|------|----------------|
| AccountOwnershipType 枚举（SIGL/JOIT/CORP/TRUS/CUST） | ISO 20022 acmt 消息族 | §9 行业标准数据模型 §9.1 |
| Party-Account 角色分离（OWNE/JOWN/AUTH/BENE/ACCS） | ISO 20022 acmt.001 AccountOpeningInstruction | §9 行业标准数据模型 §9.1 |
| 账户多维分类：枚举+JSON+关联表三层建模 | Berlin Group NextGenPSD2（usage/cashAccountType 正交）、Apache Fineract capabilities | §9 行业标准数据模型 §9.2；§12 设计模式总结 |
| 状态百位整数编码（100/200/300...预留子状态） | Apache Fineract m_savings_account status_enum | §10 开源实现参考 §10.2 |
| 生命周期时间戳完整记录（每节点存时间+操作人） | Apache Fineract m_savings_account 时间戳字段设计 | §10 开源实现参考 §10.2 |
| 账户状态的 RESTRICTED 子类型 | Alpaca Broker API account status 枚举 | §10 开源实现参考 §10.1 |
| 能力懒激活（达到门槛才开放权限） | Alpaca Broker API（净值达 $2,000 才激活 Margin） | §10 开源实现参考 §10.1 |

### Fintech 架构模式（§9.4–§9.8）

| 结论 | 出处 | Reference 章节 |
|------|------|----------------|
| 余额不直接存储，从分录（Entry）聚合推导 | Martin Fowler Analysis Patterns（Account/Entry/PostingRule）、Stripe Ledger、Monzo Ledger | §11 Fintech 架构分享 §11.1 §11.2 §11.4 |
| 冲正必须用 Reversal 模式（负数分录），不能修改原记录 | Martin Fowler Analysis Patterns（三种错误更正模式） | §11 Fintech 架构分享 §11.5 |
| LedgerAddress 多维度记账（避免不同用途资金混账） | Monzo Engineering Blog（2023年3月余额性能优化） | §11 Fintech 架构分享 §11.2 |
| 余额快照策略（每N条分录触发快照，避免性能退化） | Monzo（快照迁移解决 P99 延迟）、Event Sourcing 最佳实践 | §11 Fintech 架构分享 §11.2 |
| 购买力三层语义分字段（cash/unsettled/margin） | Robinhood 账户模型（buying_power/regt_buying_power/daytrading_buying_power） | §11 Fintech 架构分享 §11.4 |
| 三方自动核对（内部账本↔银行流水↔托管账户） | Stripe Data Quality Platform | §11 Fintech 架构分享 §11.1 |
| 多货币 Currency Pocket 子账户（USD/HKD 独立记账） | Revolut 多货币账户架构 | §11 Fintech 架构分享 §11.3 |
| 动态 KYC 旅程（可配置工作流，非硬编码步骤） | Ballerine 开源 KYC 引擎（YC 支持） | §10 开源实现参考 §10.3 |
| 双层账户：AMS 是受益所有权层，清算层是名义持有层 | CCASS HKSCC-NOMS、DTCC Cede & Co. 结构 | §9 行业标准数据模型 §9.1 |

---

*本文档为 AMS 金融业务模型的初始草稿。所有数据模型字段和状态机定义将在产品评审后进一步细化。*
