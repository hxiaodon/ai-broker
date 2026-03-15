# AMS 行业调研参考资料

> 美港股券商账户管理服务（AMS）行业最佳实践与监管框架参考
>
> **调研日期**: 2026-03-15
> **覆盖范围**: 美股（SEC/FINRA/FinCEN）+ 港股（SFC/AMLO/JFIU）+ 开源实现 + 行业架构模式
> **信息来源**: 官方监管机构、学术文献、主要券商公开资料、开源社区

---

## 目录

1. [美股监管框架](#1-美股监管框架)
2. [港股监管框架](#2-港股监管框架)
3. [账户类型体系](#3-账户类型体系)
4. [KYC/CIP 要求对比](#4-kyccip-要求对比)
5. [AML 合规对比](#5-aml-合规对比)
6. [主要券商实践参考](#6-主要券商实践参考)
7. [跨境合规（FATCA/CRS）](#7-跨境合规fatcacrs)
8. [监管动态（2024-2026）](#8-监管动态2024-2026)
9. [行业标准数据模型](#9-行业标准数据模型)
10. [开源实现参考](#10-开源实现参考)
11. [主要 Fintech 架构分享](#11-主要-fintech-架构分享)
12. [账户系统设计模式总结](#12-账户系统设计模式总结)
13. [官方文件索引](#13-官方文件索引)

---

## 1. 美股监管框架

### 1.1 监管体系结构

```
USA PATRIOT Act § 326（联邦法律）
    └── Bank Secrecy Act (BSA) - 31 U.S.C. §§ 5311-5336
           └── 31 CFR § 1023.220 (Broker-Dealer CIP Rule)
                  ├── FINRA Rule 4512 (Client Account Info)
                  ├── FINRA Rule 4210 (Margin Requirements)
                  ├── FINRA Rule 2111 (Suitability)
                  └── SEC Rule 17a-3 (Records to be Made)
```

### 1.2 核心法规速查

| 规则 | 机构 | 核心内容 | 官方链接 |
|------|------|----------|----------|
| FINRA Rule 4512 | FINRA | 账户信息记录要求：姓名、地址、投资目标、风险承受能力；TCP受信联络人要求 | [链接](https://www.finra.org/rules-guidance/rulebooks/finra-rules/4512) |
| FINRA Rule 4210 | FINRA | 保证金要求：初始50%（Reg T）、维持25%；PDT规则 $25,000最低权益 | [链接](https://www.finra.org/rules-guidance/rulebooks/finra-rules/4210) |
| FINRA Rule 2111 | FINRA | 适合性规则：Reasonable-Basis、Customer-Specific、Quantitative三层义务 | [链接](https://www.finra.org/rules-guidance/rulebooks/finra-rules/2111) |
| SEC Rule 17a-3 | SEC/Cornell | 经纪商须创建的账户记录清单；保存期6年 | [链接](https://www.law.cornell.edu/cfr/text/17/240.17a-3) |
| FinCEN CDD Rule | FinCEN | UBO识别：持股≥25%的自然人 + 1名控制人；五大AML支柱 | [链接](https://www.fincen.gov/resources/statutes-and-regulations/cdd-final-rule) |
| 31 CFR § 1010.230 | FinCEN/Cornell | CDD Rule法规全文：受益所有人定义与核验要求 | [链接](https://www.law.cornell.edu/cfr/text/31/1010.230) |
| 31 CFR § 1023.320 | FinCEN/Cornell | 券商SAR申报规则：≥$5,000触发，30天内申报 | [链接](https://www.law.cornell.edu/cfr/text/31/1023.320) |
| Regulation T | 美联储 | 初始保证金50%；保证金账户最高2:1杠杆 | 12 CFR Part 220 |
| Reg BI | SEC | 最佳利益标准；Form CRS披露义务；2020年6月30日实施 | SEC Release 34-86031 |

### 1.3 FINRA Rule 4210 保证金要求详解

| 仓位类型 | FINRA最低维持保证金 | 行业惯例 |
|----------|---------------------|----------|
| 多头股票 | 当前市值 **25%** | 30-40%（多数券商） |
| 空头股票（≤$5/股） | $2.50/股 或 100% | — |
| 空头股票（>$5/股） | 当前市值 **30%** | — |
| 账户最低权益 | **$2,000** | — |
| PDT账户最低权益 | **$25,000** | — |

### 1.4 Reg T 与 Portfolio Margin 对比

| 维度 | Reg T Margin | Portfolio Margin |
|------|-------------|------------------|
| 监管工具 | Regulation T（美联储） | TIMS（OCC每晚计算） |
| 初始保证金 | 50% | 基于风险模型（通常更低） |
| 最低账户权益 | $2,000 | $110,000（IBKR等主要券商） |
| 杠杆上限 | 2:1 | 最高约6:1（视持仓风险） |
| 适用客户 | 所有保证金账户客户 | 有经验的投资者/机构 |

### 1.5 SAR/CTR 申报要求

**CTR（货币交易报告）**：
- 触发：单一营业日现金交易累计 **> $10,000**
- 申报时限：交易后 **15个日历日**内向 FinCEN 提交
- 注意：分拆交易（Structuring）规避CTR本身违法（BSA § 5324）

**SAR（可疑活动报告）**：
- 触发金额：涉及累计 **≥ $5,000**
- 触发条件：知悉/怀疑/有理由怀疑存在违法活动
- 申报时限：初次发现后 **30个日历日**（无法识别嫌疑人可延至60天）
- 保密：严禁向任何人（含当事客户）披露已提交SAR

**2025年10月 FinCEN 重要澄清**（[SAR FAQs October 2025](https://www.fincen.gov/system/files/2025-10/SAR-FAQs-October-2025.pdf)）：
- 不需要仅因交易接近$10,000就提交SAR
- 提交SAR后，不强制要求人工审查该账户
- 选择不提交SAR的决定无需记录在案（鼓励留存记录）

---

## 2. 港股监管框架

### 2.1 监管体系结构

```
SFO Cap. 571（证券及期货条例）
    ├── SFC Code of Conduct（操守准则，2024年10月版）
    │       ├── Para. 5.1: 可接受的账户开立方式
    │       └── Para. 5.2: 适合性评估
    └── AMLO Cap. 615（洗钱及恐怖分子资金筹集条例）
            ├── Schedule 2: CDD 法定要求
            └── SFC AML/CFT Guidelines（2023年6月版）

OSCO Cap. 455 / DTROP Cap. 405 → STR 申报义务
UNSO Cap. 537 → UN制裁执行
```

### 2.2 核心法规速查（香港）

| 规则 | 机构 | 核心内容 | 官方链接 |
|------|------|----------|----------|
| AMLO Cap. 615 | 香港立法会 | CDD义务（Schedule 2）、记录保存（Section 20）、STR（通过OSCO/DTROP触发） | [链接](https://www.elegislation.gov.hk/hk/cap615) |
| SFC Code of Conduct（2024年10月版） | SFC | Para 5.1 账户开立方式；Para 5.2 适合性评估 | [链接](https://www.sfc.hk/-/media/EN/assets/components/codes/files-current/web/codes/code-of-conduct-for-persons-licensed-by-or-registered-with-the-securities-and-futures-commission/Code_of_conduct-Oct-2024_Eng-with-Bookmark-Final.pdf) |
| SFC AML/CFT Guidelines（2023年6月版） | SFC | CDD、EDD、PEP筛查；2022年AMLO修订落实 | [链接](https://www.sfc.hk/en/Rules-and-standards/Anti-money-laundering-and-counter-financing-of-terrorism) |
| SFO Cap. 571 Schedule 1 Part 1 | 香港立法会 | 专业投资者（PI）定义；资产门槛HK$800万 | [链接](https://www.elegislation.gov.hk/hk/cap571) |
| SFC Securities Margin Financing Guidelines | SFC | 孖展融资活动指引；Type 8牌照要求 | [链接](https://www.sfc.hk/en/Rules-and-standards/Codes-and-guidelines/Guidelines/Guidelines-for-Securities-Margin-Financing-Activities) |
| SFC Acceptable Account Opening Approaches | SFC | 非面对面开户：银行转账≥HK$10,000验证；亲临；认证副本 | [链接](https://www.sfc.hk/en/Rules-and-standards/Account-opening/Acceptable-account-opening-approaches) |
| OSCO Cap. 455 Section 25A | 香港立法会 | STR法定义务；不申报罚款HK$50,000+3个月监禁 | [链接](https://www.elegislation.gov.hk/hk/cap455) |
| UNSO Cap. 537 | 香港立法会 | 违反UN制裁：罚款无上限+最高7年监禁 | [链接](https://www.elegislation.gov.hk/hk/cap537) |

### 2.3 PEP 分类（2023年6月1日修订后）

2023年AMLO修订重要变化：**将中国内地政府官员纳入"非香港PEP"类别**（原被视为"香港PEP"处理）。

| 类别 | 范围 | EDD要求 |
|------|------|---------|
| 非香港PEP | 外国政府+国际组织高级职位，**含中国内地** | 强制EDD + 高管批准 + 财富来源证明 |
| 香港PEP | 香港特区政府高级职位 | 风险评估后决定 |
| 国际组织PEP | 主要国际组织高级职位 | 风险评估后决定 |
| 前非香港PEP（新增） | 上述职位已卸任者 | 风险评估后可豁免 |

### 2.4 STR 申报平台：STREAMS 2（2026年2月2日启用）

JFIU 于2026年2月2日正式启用 STREAMS 2 系统，**原有电邮/传真/邮寄方式已停用**。

- 官网：[JFIU](https://www.jfiu.gov.hk/en/)
- 不申报 STR 的刑事责任：罚款 HK$50,000 + 最高3个月监禁
- 提交 STR 享有法定免责保护（OSCO Section 25A(2)）

### 2.5 专业投资者（PI）认定标准

| PI类别 | 投资组合门槛 | 总资产门槛 | 更新频率 |
|--------|-------------|-----------|---------|
| 个人（alone或与配偶/子女联名） | ≥ **HK$800万** | — | 每12个月 |
| 公司/合伙 | ≥ HK$800万 | ≥ HK$4,000万 | 每12个月 |
| 信托公司 | — | ≥ HK$4,000万 | 每12个月 |
| 机构（持牌金融机构等） | 无门槛 | 机构本身符合 | 每12个月 |

**PI豁免范围**：PI客户可豁免部分《操守准则》保护，但以下情况**仍须适合性评估**：
- 向个人PI提出建议或推销时
- 就"复杂产品"代客交易时

### 2.6 非面对面开户的三种合规方式

| 方式 | 要求 | 限制 |
|------|------|------|
| 指定银行账户转账 | 从客户名下香港持牌银行账户转入 ≥ HK$10,000 | 未来所有存取款须通过同一银行账户（同名账户原则） |
| 认证副本邮寄 | 由JP、执业律师、执业注册会计师、SFC持牌人等认证 | 认证人须亲眼见到原件 |
| 亲临开户 | 券商员工当面核验 | 须有受监督的合规程序 |

---

## 3. 账户类型体系

### 3.1 美股账户类型全览

| 类型 | 英文 | 核心特征 | KYC要求 |
|------|------|----------|---------|
| 个人账户 | Individual Account | 单一自然人；可设 Transfer on Death 受益人 | 标准CIP |
| 联名账户（共同继承） | JTWROS | 任一持有人去世，权益自动转移至生存方 | 每位持有人分别CIP |
| 联名账户（分权共有） | Tenants in Common | 各方可单独处置其份额，支持遗产规划 | 每位持有人分别CIP |
| 公司/机构账户 | Corporate Account | 需公司章程、董事会决议、UBO信息 | 实体CIP + UBO穿透 |
| 信托账户 | Trust Account | 需信托协议；受托人承担受信义务 | 受托人CIP + 信托文件 |
| 传统IRA | Traditional IRA | 税前供款，延税增长；59.5岁前提款有罚款 | 标准CIP + 税务申报 |
| Roth IRA | Roth IRA | 税后供款，免税增长；满足条件后免税提款 | 标准CIP + 税务申报 |
| 托管账户 | UGMA/UTMA Custodial | 为未成年人设立；监护人管理 | 监护人CIP + 受益人信息 |

### 3.2 港股账户类型全览

| 类型 | 英文 | 核心特征 | 牌照要求 |
|------|------|----------|---------|
| 个人现金账户 | Individual Cash Account | 全额资金，T+2结算 | SFC Type 1 |
| 个人孖展账户 | Individual Margin Account | 融资交易；须签风险披露 | SFC Type 1 + Type 8 |
| 联名账户 | Joint Account | 联名持有人均须KYC | SFC Type 1 |
| 公司账户 | Corporate Account | UBO穿透；公司章程等 | SFC Type 1 |
| 信托账户 | Trust Account | 信托协议；受托人核验 | SFC Type 1 |
| 全权委托账户 | Discretionary Account | 顾问代客操盘 | SFC Type 9（资产管理） |
| 汇总账户 | Omnibus Account | 中介以单一账户持有多底层客户 | SFC Appendix 6 规定 |
| 名义账户 | Nominee Account | 券商以自身名义持有客户证券 | 须披露安排 |

### 3.3 期权权限等级（美股）

| 等级 | 允许策略 | 典型审批要求 |
|------|----------|-------------|
| Level 0 | 无期权交易 | 默认 |
| Level 1 | Covered Call、Protective Put | 基本账户即可 |
| Level 2 | Level 1 + 买入看涨/看跌 | 一定经验、净资产 |
| Level 3 | Level 2 + 价差策略（Spread、蝶式、铁鹰） | Margin账户、较高净资产 |
| Level 4 | Level 3 + 裸式卖出（Naked Call/Put） | 多年经验、六位数以上账户 |

不同券商等级数量不同（IBKR 4级、Tastytrade 3级、Fidelity 5级）。

---

## 4. KYC/CIP 要求对比

### 4.1 个人账户 KYC 字段对比

| 字段 | 美股（CIP/FINRA） | 港股（AMLO/SFC） | 备注 |
|------|-----------------|-----------------|------|
| 法定全名 | ✅ 必填 | ✅ 必填 | 与证件完全一致 |
| 出生日期 | ✅ 必填（CIP） | ✅ 必填（AMLO） | — |
| 居住地址 | ✅ 必填（非P.O. Box） | ✅ 必填（非P.O. Box） | 港股需3个月内地址证明 |
| 国籍 | ✅ | ✅ | — |
| 身份证件号 | SSN/护照号 | HKID 或护照号 | 加密存储 |
| 税务识别号（TIN） | SSN/EIN | HK TIN = HKID号 | — |
| 税务居住地 | W-9/W-8BEN | CRS 自我声明 | 可能多个管辖区 |
| 职业/雇主 | ✅（Rule 4512） | ✅（SFC KYC） | — |
| 年收入 | ✅（Rule 4512） | ✅（SFC 适合性） | 枚举区间 |
| 净资产/流动净资产 | ✅（Rule 4512） | ✅（SFC 适合性） | 枚举区间 |
| 资金来源 | ✅（FinCEN CDD） | ✅（AMLO Schedule 2） | — |
| 投资目标 | ✅（Rule 4512） | ✅（SFC 适合性） | — |
| 投资经验 | ✅（Rule 4512） | ✅（SFC KYC） | — |
| 风险承受能力 | ✅（Rule 4512，Reg BI） | ✅（SFC 适合性问卷） | — |
| 受信联络人（TCP） | ✅ 应努力获取（非机构账户） | ❌ 不适用 | 美股特有 |
| PI 资产证明 | ❌ 不适用 | ✅ PI账户必填（每年更新） | 港股特有 |

### 4.2 机构账户 KYC 字段对比

| 字段 | 美股 | 港股 |
|------|------|------|
| 注册证书 | ✅ | ✅ |
| 公司章程 (M&A) | ✅ | ✅ |
| 董事会决议 | ✅ | ✅ |
| UBO列表（持股≥25%） | ✅（FinCEN CDD Rule） | ✅（AMLO Schedule 2）|
| 控制人（Controller，1名） | ✅（FinCEN CDD Rule） | 包含在UBO中 |
| 股权架构图 | ✅ | ✅ |
| 授权签署人 | ✅ | ✅ |
| SCR（重要控制人登记册）| ❌ | ✅（香港Companies Ordinance要求） |

### 4.3 税务表格体系（美股）

| 情形 | 表格 | 有效期 |
|------|------|--------|
| 美国公民/居民外星人 | **Form W-9** | 无固定期限（身份变更须更新） |
| 非居民外星人（个人） | **Form W-8BEN** | 3年（签署日至第3个公历年度末） |
| 外国实体 | **Form W-8BEN-E** | 3年（含FATCA第四章状态） |
| 外国中间人 | **Form W-8IMY** | 3年 |
| 关联美国收入 | **Form W-8ECI** | 3年 |

**W-8BEN 关键管理要点**：
- 到期前90天推送更新提醒
- 身份变更（成为美国居民）须30天内通知，更新为W-9
- 未更新：来自美国的相关付款预扣30%（FATCA预提税）

---

## 5. AML 合规对比

### 5.1 制裁筛查对比

| 维度 | 美股（OFAC） | 港股（AMLO/UN） |
|------|------------|----------------|
| 主要名单 | OFAC SDN List、Sectoral Sanctions、Non-SDN Lists | UN Sanctions（UNSO/UNATMO）、HK指定名单 |
| 更新频率 | 实时/每日 | 不定期（须监控SFC/JFIU通告） |
| 筛查时机 | 开户时 + 每日批量 | 开户时 + 每日批量 |
| 命中后 | 立即冻结，报告OFAC | 立即冻结，报告JFIU |
| 违规后果 | 民事罚款（最高数百万美元）+ 刑事追诉 | 罚款无上限 + 最高7年监禁（UNSO） |

### 5.2 可疑报告对比

| 维度 | 美股 SAR | 港股 STR |
|------|---------|---------|
| 法律依据 | 31 CFR § 1023.320 | OSCO Section 25A / DTROP Section 25A |
| 触发金额 | ≥ $5,000 | 无明确金额门槛（有可疑迹象即须报告） |
| 申报时限 | 30天（无嫌疑人可延至60天） | "尽快"（法规要求立即） |
| 申报平台 | FinCEN BSA E-Filing System | JFIU STREAMS 2（2026年2月启用） |
| 保密义务 | 严格保密（Tipping-Off违法） | 严格保密（泄露为刑事罪行） |
| 安全港 | ✅ 依规申报享免责保护 | ✅ OSCO Section 25A(2) |

### 5.3 大额现金报告对比

| 维度 | 美股 CTR | 港股（无直接对应，但有AMLO要求） |
|------|---------|--------------------------------|
| 门槛 | 单日 > $10,000 现金 | 无统一CTR制度，由AMLO整体监管 |
| 申报时限 | 交易后15个日历日 | N/A |
| 注意 | 分拆交易（Structuring）规避CTR属违法 | 通过持续监控和STR机制覆盖 |

---

## 6. 主要券商实践参考

### 6.1 Interactive Brokers (IBKR)

**账户类型支持**：Individual、Joint、IRA、Trust、Partnership、LLC、Corporation、Family Office

**开户特点**：
- 支持全球36个国家，28种货币
- 开户用时：1-3个工作日（流程相对复杂，文件要求严格）
- 线上开户，eKYC + 人工审核混合

**Margin 账户**：
- Reg T Margin：最低 $2,000
- Portfolio Margin：最低 NLV **$110,000**

**Prime Brokerage（IBPrime）**：
- 标准：最低 $1,000,000
- 含 DVP 场外执行：最低 $6,000,000

**期权权限**（IBKR 4级）：
- Level 1：Covered Writing
- Level 2：Level 1 + 买入期权
- Level 3：Level 2 + 价差
- Level 4：Level 3 + 裸期权

### 6.2 Charles Schwab（已整合TD Ameritrade）

**规模**：3,600万+活跃经纪账户，AUM $9.4万亿（2024年8月）

**账户类型**：Individual、Joint (JTWROS/TIC)、Traditional IRA、Roth IRA、SEP IRA、Solo 401(k)、Education Savings、Trust、Custodial

**重要变更**：Schwab Trader API 已于2024年5月推出（替代已停用的TD Ameritrade API），原TD Ameritrade API 于2024年5月10日关闭。

**开户特点**：线上开户用户体验好；thinkorswim 平台继承自TD Ameritrade。

### 6.3 富途证券（Futu，港股）

**SFC牌照**：AZT137（涵盖 Type 1/4/9 等多种牌照）

**开户方式**：
- 银行转账验证：从以下香港持牌银行转入 ≥ HK$10,000
  - 汇丰、恒生、中国银行（香港）、南洋商业、融创银行
  - 工银亚洲、永隆、渣打、中信银行国际、ZA Bank
- 或亲临总部（Admiralty）

**账户类型**：现金、孖展、现金管理（活期理财）、模拟账户

**孖展利率**：年息约6.8%，最高杠杆1:2

**内地客户限制（2024年趋势）**：已要求提供海外永久居留权证明（配合中国加强境外投资管控）

**PI管理**：须年度提交资产证明（投资组合月结单等）

### 6.4 老虎证券（Tiger Brokers，港股）

**SFC持牌**：香港SFC持牌

**开户特点**：
- 在线申请，1-2个工作日
- 内地居民须持有非内地身份文件
- 支持港股、美股、期货等

**账户类型**：现金账户、孖展账户、Cash Boost、模拟账户

### 6.5 eKYC 行业趋势（2024-2025）

- **核验时间**：从数天压缩至数分钟（AI文件识别 + 人脸识别 + 活体检测）
- **主要供应商**：Jumio、Onfido（已被 Entrust 收购）、iDenfy、Sumsub、Veriff
- **香港iAM Smart**：SFC 接受 iAM Smart 及 iAM Smart+ 作为身份验证工具（2023年起）
- **合规护城河**：具备企业级合规引擎的平台（制裁筛查 + AML监测 + CDD自动化）形成竞争壁垒

---

## 7. 跨境合规（FATCA/CRS）

### 7.1 FATCA（外国账户税收合规法案）

| 要素 | 美国侧 | 香港侧 |
|------|--------|--------|
| 适用日期 | 2014年7月1日 | 2014年7月1日在港生效 |
| 协议类型 | — | **Model 2 IGA**（机构直接向IRS申报，非政府间互换） |
| 申报义务 | IRS接收报告 | 港金融机构识别美国税务居民账户，向IRD→IRS申报 |
| 预扣税 | 30%（不合规机构） | 不合规机构的特定美国来源收入须预扣30% |
| 合规认证 | 每3年向IRS认证 | 注册+尽职调查+申报+预扣税四项义务 |

**实操要点**：
- 美国公民/绿卡持有人在港开户：券商须收集W-9表格
- 港券商须将账户信息报告至IRD，再由IRD转报IRS（Model 2）

### 7.2 CRS（共同申报准则）

| 要素 | 香港实施情况 |
|------|-------------|
| 法律基础 | 《税务（修订）（第3号）条例2016》（2016年6月30日生效） |
| 首次交换 | 2018年底 |
| 覆盖管辖区 | 原75个，2020年1月1日起扩至 **126个**（含多边税务行政互助公约成员） |
| 年度申报截止 | 每年 **5月31日**前就上一日历年向IRD提交 |
| 注册义务 | 首次持有可申报账户后 **3个月**内向IRD AEOI门户注册 |
| 自我声明保存 | 客户自我声明表格须保存 **6年** |

**2024年执法动态**：IRD 向SFC/IA持牌机构发出调查通知，要求未注册者填写问卷（21日内），不遵从罚款HK$10,000。

### 7.3 香港外汇情况

- 香港**无外汇管制**
- 但须遵守FATF Recommendation 16旅行规则（大额转账须传递汇款人/收款人信息）
- 虚拟资产转账：自2024年1月1日起，SFC对VASP实施旅行规则

---

## 8. 监管动态（2024-2026）

### 8.1 美股

| 时间 | 事件 | 影响 |
|------|------|------|
| 2024年5月 | 美股结算周期从T+2缩短至**T+1** | Cash账户的Unsettled Proceeds在T+1可用于再买入（但不可提现） |
| 2024年10月 | FINRA 发布 Regulatory Notice 24-13：启动PDT规则回顾性审查 | 约65份意见，多数呼吁废除$25,000门槛 |
| 2025-2026年 | FinCEN 2024-2026年发布授权例外救济：减轻CDD UBO重复收集负担 | 机构客户每次开新账户不再须重新识别UBO，只需首次关系建立时收集 |
| 2026年1月 | FINRA 提交PDT规则修订案至SEC：拟废除$25,000最低权益要求 | 修订案尚待SEC审批，**现行规则仍有效** |
| 2026年1月 | CTA（公司透明度法）与FinCEN BOI（受益所有人信息）申报相关进展 | FinCEN授权例外救济与CTA联动，法人须直接向FinCEN报告BOI |

**参考链接**：
- [FINRA RN 24-13 (PDT Review)](https://www.finra.org/rules-guidance/notices/24-13)
- [PDT规则修订案联邦公报（2026年1月）](https://www.federalregister.gov/documents/2026/01/14/2026-00519/self-regulatory-organizations-financial-industry-regulatory-authority-inc-notice-of-filing-of-a)
- [FinCEN SAR FAQs 2025年10月](https://www.fincen.gov/system/files/2025-10/SAR-FAQs-October-2025.pdf)

### 8.2 港股

| 时间 | 事件 | 影响 |
|------|------|------|
| 2023年6月1日 | SFC AML/CFT 指引更新生效：将中国内地PEP列为"非香港PEP"，须强制EDD | AMS须更新PEP筛查逻辑和分类 |
| 2024年10月 | SFC通函加强全权委托账户（FD）监管：宣布开展专题实地检查、提高罚则 | FD账户需额外合规资源 |
| 2024年 | 富途/老虎等限制内地居民开户：须提供海外永久居留证明 | 影响内地用户市场策略 |
| 2026年2月2日 | JFIU 启用 STREAMS 2 系统：取代原STR提交方式（停止接受电邮/传真/邮寄） | 系统须对接STREAMS 2 API或网页申报 |
| 2024年1月 | VASP旅行规则正式实施：SFC对虚拟资产服务提供者执行FATF Recommendation 16 | 本项目主要影响虚拟资产业务，参考用 |

**参考链接**：
- [SFC AML/CFT Guidelines 2023年版](https://www.sfc.hk/en/Rules-and-standards/Anti-money-laundering-and-counter-financing-of-terrorism)
- [SFC Code of Conduct 2024年10月版](https://www.sfc.hk/-/media/EN/assets/components/codes/files-current/web/codes/code-of-conduct-for-persons-licensed-by-or-registered-with-the-securities-and-futures-commission/Code_of_conduct-Oct-2024_Eng-with-Bookmark-Final.pdf)
- [JFIU STREAMS 2 官网](https://www.jfiu.gov.hk/en/)

---

## 9. 行业标准数据模型

### 9.1 ISO 20022 账户管理消息族（acmt）

ISO 20022 是国际金融消息标准，其 `acmt`（Account Management）业务域定义了账户全生命周期的数据模型。这是全球清算机构（SWIFT、DTCC、HKEX）和主要银行正在迁移的标准。

**acmt 消息族核心消息（与券商最相关）**：

| 消息 ID | 用途 | 对应我们的流程 |
|---------|------|----------------|
| `acmt.001` | AccountOpeningInstruction | 开户指令（机构侧发送）|
| `acmt.002` | AccountDetailsConfirmation | 开户确认回执 |
| `acmt.003` | AccountModificationInstruction | 账户信息变更 |
| `acmt.007` | AccountOpeningRequest | 开户请求（B端入口）|
| `acmt.010` | AccountRequestAcknowledgement | 开户受理确认 |
| `acmt.011` | AccountRequestRejection | 开户拒绝 |
| `acmt.019` | AccountClosingInstruction | 账户注销指令 |
| `acmt.023` | IdentificationVerificationRequest | KYC 身份核验请求 |
| `acmt.024` | IdentificationVerificationReport | KYC 身份核验结果 |

**AccountOwnershipType 完整枚举**（ISO 20022 标准，可直接用于我们的 `ownership_type` 字段）：

| 代码 | 名称 | 说明 |
|------|------|------|
| `SIGL` | Single | 个人独立账户 |
| `JOIT` | Joint | 联名账户（≥ 2 个持有人）|
| `CORP` | Corporate | 公司/机构账户 |
| `TRUS` | Trust | 信托账户 |
| `CUST` | Custodial | 托管账户（如未成年人账户）|
| `NACC` | Nominee | 名义持有账户（如 CCASS HKSCC-NOMS）|
| `MNOT` | Minor | 未成年人账户 |

**Party-Account 关系模型**（ISO 20022 核心思想）：

Party（当事方）和 Account（账户）是独立实体，通过 AccountPartyRole 关联。一个 Account 可有多个 Party，一个 Party 可持有多个 Account。

```
AccountPartyRole 枚举：
OWNE = AccountOwner（主所有人）
JOWN = JointOwner（联名所有人）
AUTH = AuthorisedPerson（FD账户授权操作人）
BENE = Beneficiary（IRA账户受益人）
ACCS = AccountServicer（账户服务机构/券商）
NOMI = Nominee（名义持有人，如CCASS中的HKSCC-NOMS）
```

**参考**：[ISO 20022 acmt 消息族](https://www.iotafinance.com/en/SWIFT-ISO20022-Business-area-acmt-Account-Management.html)

### 9.2 UK Open Banking 账户模型（OBAccount6）

UK Open Banking 的账户模型采用**通用标识二元组**（SchemeName + Identification），优雅解决了多标识类型问题：

```json
{
  "AccountId": "22289",
  "Status": "Enabled",
  "Currency": "GBP",
  "AccountType": "Personal",
  "AccountSubType": "CurrentAccount",
  "Account": [
    {
      "SchemeName": "UK.OBIE.SortCodeAccountNumber",
      "Identification": "80200110203345",
      "Name": "Mr Kevin Smith"
    },
    {
      "SchemeName": "UK.OBIE.IBAN",
      "Identification": "GB29NWBK60161331926819"
    }
  ]
}
```

**对我们的借鉴**：用户绑定的银行账号存储，可借鉴 `SchemeName + Identification` 二元组设计，支持多种标识类型（IBAN、HK 账号、银行编号等）不需要单独建字段。

**AccountStatus 枚举**：`Enabled / Disabled / Deleted / ProForma`（`ProForma` = 账户创建中/开户审核中，对应我们的 KYC_IN_PROGRESS 状态）

**参考**：[UK Open Banking OBAccount6 v3.1.10](https://openbankinguk.github.io/read-write-api-site3/v3.1.10/resources-and-data-models/aisp/Accounts.html)

### 9.3 FIX Protocol 账户字段

当我们的 Trading Engine 对接交易所时，订单消息中的账户信息需映射到 FIX 标准字段：

| FIX Tag | 字段名 | 取值 | 含义 |
|---------|--------|------|------|
| Tag 1 | Account | 内部账户号 | 报单归属账户 |
| Tag 581 | AccountType | 1 | 客户账户（散户）|
| Tag 581 | AccountType | 2 | 非客户侧（自营）|
| Tag 453 | NoPartyIDs | — | Party 列表（含 Clearing Firm、Introducing Broker）|

**FIX 5.0 Parties 机制**：通过 `PartyID/PartyRole` 重复组表达复杂账户角色（执行经纪商、清算机构、引入经纪商、受益所有人）。我们的 FD 账户场景下，FA 的身份需要通过 Party 机制在 FIX 报单中透传。

---

## 10. 开源实现参考

### 10.1 Alpaca Markets — API 券商账户模型（最接近我们目标）

Alpaca 是架构上最接近我们目标系统（美股 API 券商）的公开参考。

**账户状态枚举**（直接可借鉴）：

| 状态 | 含义 |
|------|------|
| `ONBOARDING` | 开户中 |
| `SUBMISSION_FAILED` | 提交失败 |
| `SUBMITTED` | 已提交待审 |
| `ACCOUNT_UPDATED` | 账户信息更新中 |
| `APPROVAL_PENDING` | 等待批准 |
| `ACTIVE` | 正常激活 |
| `REJECTED` | 被拒绝 |
| `RESTRICTED` | 受限（如 PDT，允许查看但限制操作）|
| `RESTRICTED_CLOSE_ONLY` | 只可平仓（严重违规）|
| `ACCOUNT_CLOSED` | 已关闭 |

**关键设计决策**：
- 账户默认开立为保证金账户，资产净值达 $2,000 后才激活杠杆功能（**能力懒激活**）
- B2B Broker API（管理终端用户账户）与 Trading API（终端用户使用）严格分离
- `buying_power` / `daytrading_buying_power` / `regt_buying_power` 分字段存储不同语义的购买力

**文档**：[Alpaca Broker API](https://docs.alpaca.markets/docs/about-broker-api) | [Go SDK](https://github.com/alpacahq/alpaca-trade-api-go)

### 10.2 Apache Fineract — 开源核心银行账户模型

Apache Fineract（原 Mifos X）是目前最成熟的开源核心银行系统，其账户设计有几个值得借鉴的模式：

**状态百位整数编码**（预留子状态扩展空间）：

```
100 = 提交待审（SUBMITTED_AND_PENDING_APPROVAL）
200 = 已批准（APPROVED）
300 = 活跃（ACTIVE）
400 = 转移中（TRANSFER_IN_PROGRESS）
600 = 已到期（MATURED）
700 = 已关闭（CLOSED）
```

**生命周期时间戳完整记录**：每个关键生命周期节点都存储时间戳和操作人：
- `submittedon_date` / `submitted_by_userid`
- `approvedon_date` / `approvedon_userid`
- `rejectedon_date` / `rejectedon_userid`
- `activatedon_date` / `activatedon_userid`
- `closedon_date` / `closedon_userid`

**产品-账户分离**：`SavingsProduct`（产品模板，定义规则） → `SavingsAccount`（产品实例，关联到具体客户）。我们可以借鉴：不同类型账户的业务规则（如保证金率、期权权限）配置在产品模板层，账户实例只存引用。

**余额物化策略**：`account_balance_derived` 是从分录 SUM 推导后物化的冗余字段（定期刷新），而非实时计算——性能和准确性的权衡。

**GitHub**：[apache/fineract](https://github.com/apache/fineract) | **文档**：[fineract.apache.org](https://fineract.apache.org/)

### 10.3 Ballerine — 开源 KYC 工作流引擎（YC 支持）

Ballerine 是目前 star 最高的开源 KYC/AML 工作流引擎，架构组成：

```
Ballerine 架构：
├── Workflow Engine    → 状态机驱动的 KYC 流程编排
├── Rule Engine        → 风险规则计算（AML 评分）
├── Case Management UI → 合规官人工审核 Dashboard
├── Plugin System      → 第三方服务接入（OFAC、人脸识别、OCR）
└── Headless SDK       → 前端 KYC 采集流（移动端可用）
```

**核心设计**：**动态 KYC 旅程**——基于用户实时风险分级调整 KYC 步骤，而非固定流程。这与我们"不同 KYC Tier 开放不同交易能力"需求高度契合。

**KYC 工作流节点**（可直接参考）：
```
DOCUMENT_UPLOAD → OCR_VERIFICATION → LIVENESS_CHECK
→ AML_SCREENING → [HIGH_RISK: EDD + HUMAN_REVIEW]
→ APPROVED / REJECTED
```

**2024 年动态**：已转向 AI-native 风控，支持 LLM 辅助的文件核验和欺诈检测。

**GitHub**：[ballerine-io/ballerine](https://github.com/ballerine-io/ballerine)

### 10.4 vnpy — 国内开源量化框架账户模型

vnpy 的 AccountData 是**实时状态快照**（非持久化），适合作为我们 Trading Engine 与 AMS 之间账户状态同步的参考设计：

```python
@dataclass
class AccountData:
    accountid: str        # 格式: "GATEWAY_MARKET"，如 "FUTU_HK"
    balance: float        # 总资产（含冻结）
    frozen: float         # 冻结资金
    available: float      # 可用资金 = balance - frozen（派生）
    vt_accountid: str     # 全局唯一键 = "{gateway_name}.{accountid}"
```

**对我们的启发**：Trading Engine 中的账户余额快照可以使用类似的三分法（total / frozen / available），通过 Kafka 事件推送给 AMS，而非 gRPC 同步查询——避免强耦合。

**GitHub**：[vnpy/vnpy](https://github.com/vnpy/vnpy)

---

## 11. 主要 Fintech 架构分享

### 11.1 Stripe Ledger — 不可变日志 + 双重记账

**来源**：[Stripe Engineering Blog — Ledger](https://stripe.com/blog/ledger-stripe-system-for-tracking-and-validating-money-movement)

**核心设计**：
- 所有资金移动建模为**不可变事件**，借贷平衡是系统不变量
- 规模：每天处理 50 亿事件，每笔支付产生平均 100 条 Ledger 事件
- **数据质量平台（DQ Platform）**：在 Ledger 之上构建主动检测资金流动问题的系统

**水管类比**（直接引用 Stripe）：
> 用双重记账验证资金流动，类似分析水流经过管道网络最终流入水库。稳定状态下，终端水库应该是满的，中间管道应该是空的。如果水被卡在管道里，就说明有问题。

**对我们的直接应用**：每笔出入金应产生多条 Ledger 事件（扣款中、清算中、结算完成），而不只是更新一个余额字段。需要构建类似 DQ Platform 的三方核对机制。

### 11.2 Monzo — LedgerAddress 多维度记账

**来源**：[Monzo Blog — Speeding up balance read time](https://monzo.com/blog/2023/04/28/speeding-up-our-balance-read-time-the-planning-phase)

**核心创新**：将账户余额拆分为多个 **LedgerAddress（账本地址）**：

```
LedgerAddress = (legal_entity, namespace, name, currency, account_id)

示例：
- ("Monzo Bank Ltd", "customer", "customer-facing-balance", "GBP", "acc_xxx")
- ("Monzo Bank Ltd", "customer", "unsettled-proceeds", "GBP", "acc_xxx")
```

**为什么这样设计**：不同用途的资金（可提现余额 vs 未结算款 vs 保证金抵押物）在不同 LedgerAddress 下独立记账，避免混账、便于审计。

**余额计算挑战**：随用户规模增长，余额查询（= 所有该地址分录之 SUM）性能线性退化。2023 年通过快照迁移解决 P99 延迟问题——提示我们从第一天就需要快照策略。

**架构规模**：1500+ 微服务，Apache Cassandra（每个服务独立 keyspace），关键路径 P99 延迟毫秒级。

### 11.3 Revolut — 多货币 Currency Pocket

**核心设计**：一个用户账户下有多个**货币子账户（Currency Pocket）**，每种货币独立记账。

- 汇率换算在用户确认换汇时产生 FX 交易记录（不在显示时实时计算）
- 规模（2023）：每月 4 亿笔交易，5000 万用户，36 种货币，160+ 国家

**对我们的借鉴**：虽然初期只有 USD 和 HKD，但应按多货币子账户架构设计，避免后期重构。

### 11.4 Robinhood — 购买力实时计算

**购买力的三层语义**（需要分字段存储，不能只有一个余额）：

| 字段 | 含义 | 计算公式 |
|------|------|----------|
| `cash_balance` | 现金余额 | 已结算现金 |
| `unsettled_proceeds` | 未结算收益 | 卖出但未到 T+1/T+2 |
| `daytrading_buying_power` | 日内交易购买力 | PDT 账户专有，4 倍规则 |
| `regt_buying_power` | Reg T 购买力 | 现金 + Margin 额度 - 未结算 - 挂单占用 |

**Ledger 是真实来源**：余额不直接更新，而是从不可变 Ledger 条目推导。购买力计算须快速且准确（直接决定用户能否下单）。

### 11.5 Martin Fowler Analysis Patterns — 会计模式

**来源**：[Fowler eaaDev — AccountingNarrative](https://martinfowler.com/eaaDev/AccountingNarrative.html) | [Accounting Patterns PDF](https://martinfowler.com/apsupp/accounting.pdf)

**核心会计模式三元组**：

```
BusinessEvent → PostingRule → AccountingTransaction
                                    │
                         ┌──────────┴──────────┐
                         ▼                     ▼
                   LedgerEntry(DR)       LedgerEntry(CR)
                         │                     │
                         ▼                     ▼
                      Account              Account
```

**三种错误更正模式**（合规上的重要区别）：

| 模式 | 操作方式 | GAAP 合规 | 适用场景 |
|------|---------|----------|---------|
| Replacement | 删除原记录，插入新记录 | **否** | 仅用于发现极快的内部错误 |
| Reversal | 以负数分录对冲原分录 | **是** | 主流，保留审计痕迹 |
| Difference | 仅记录差值分录 | **是** | 原凭证已关账时使用 |

**对我们的关键启示**：出入金撤销/冲正必须用 **Reversal 模式**（负数分录对冲），绝不能直接修改原分录。这是监管审计的硬性要求。

---

## 12. 账户系统设计模式总结

### 12.1 多维账户类型的三层建模策略

| 层次 | 存储方式 | 用途 | 示例 |
|------|---------|------|------|
| **强类型枚举** | MySQL ENUM/VARCHAR | 核心分类，可索引查询 | `ownership_type=JOIT`, `jurisdiction=HK` |
| **JSON 能力标记** | MySQL JSON + GIN索引 | 稀疏权限配置，随产品迭代 | `capabilities={"options_level":2}` |
| **关联表** | 独立表，外键关联 | 多对多关系 | `account_holders(account_id, user_id, role)` |

**适用边界**：
- 固定枚举：业务查询的主要过滤条件，需要强类型约束
- JSON 能力：账户权限随 KYC 推进动态开放，字段随产品演化
- 关联表：多持有人关系，需按用户反查所有账户

### 12.2 各方案借鉴价值矩阵

| 来源 | 最有价值的设计决策 | 对应我们的模块 |
|------|-----------------|---------------|
| ISO 20022 acmt | AccountOwnershipType 枚举标准 | `ownership_type` 字段 |
| ISO 20022 acmt | Party-Account 角色分离 | `account_holders` 表 |
| UK Open Banking | SchemeName+Identification 通用标识 | 用户银行账号存储设计 |
| UK Open Banking | ProForma 状态（创建中）| KYC_IN_PROGRESS 状态 |
| Fineract | 百位整数状态编码 | `account_status` 字段编码 |
| Fineract | 生命周期时间戳全记录 | 审计事件表设计 |
| Alpaca | 状态机的 RESTRICTED 子类型 | 账户受限状态设计 |
| Alpaca | 能力懒激活（达到门槛才开放） | Margin 账户权限开放时机 |
| Fowler | PostingRule + 分录不可变 | 出入金分录设计 |
| Fowler | Reversal 模式冲正 | 出入金撤销设计 |
| Stripe | DQ 三方核对平台 | 每日余额对账任务 |
| Monzo | LedgerAddress 多维度记账 | 多用途余额分维度存储 |
| Revolut | Currency Pocket 多货币子账户 | USD/HKD 子账户设计 |
| Robinhood | 购买力三层语义分字段 | 余额展示和风控计算 |
| Ballerine | 动态 KYC 旅程 | KYC 工作流设计 |
| vnpy | AccountData 三分法（total/frozen/available）| Trading Engine 余额快照 |

### 12.3 关键架构决策

1. **余额不直接存储**：从分录表聚合推导，定期物化到 `account_currency_pockets`（Fowler + Monzo + Stripe）
2. **状态机用百位编码**：预留中间值扩展（Fineract）
3. **账户类型用分层建模**：枚举 + JSON + 关联表（非单一字段或继承表）
4. **KYC 工作流可配置**：动态调整步骤，而非硬编码（Ballerine）
5. **冲正用 Reversal 模式**：绝不修改原分录（Fowler + 监管要求）
6. **多货币从第一天设计**：Currency Pocket 架构，避免后期重构（Revolut）
7. **余额快照策略**：每 N 条分录触发快照，避免历史积累导致余额查询退化（Monzo）

---

## 13. 官方文件索引

### 9.1 美国监管机构

| 文件 | 机构 | 链接 |
|------|------|------|
| FINRA Rule 4512 (Customer Account Info) | FINRA | [链接](https://www.finra.org/rules-guidance/rulebooks/finra-rules/4512) |
| FINRA Rule 4210 (Margin Requirements) | FINRA | [链接](https://www.finra.org/rules-guidance/rulebooks/finra-rules/4210) |
| FINRA Rule 2111 (Suitability) | FINRA | [链接](https://www.finra.org/rules-guidance/rulebooks/finra-rules/2111) |
| FINRA RN 24-13 (PDT Review 2024) | FINRA | [链接](https://www.finra.org/rules-guidance/notices/24-13) |
| FINRA 2025 Annual Regulatory Oversight Report - TCP | FINRA | [链接](https://www.finra.org/rules-guidance/guidance/reports/2025-finra-annual-regulatory-oversight-report/trusted-contact-persons) |
| SEC Rule 17a-3 (Records) | SEC/Cornell | [链接](https://www.law.cornell.edu/cfr/text/17/240.17a-3) |
| SEC AML Source Tool for Broker-Dealers | SEC | [链接](https://www.sec.gov/about/divisions-offices/division-trading-markets/broker-dealers/anti-money-laundering-aml-source-tool-broker-dealers) |
| SEC CIP Rule for Broker-Dealers (2003) | SEC | [链接](https://www.sec.gov/rules-regulations/2003/04/customer-identification-programs-broker-dealers) |
| FinCEN CDD Final Rule | FinCEN | [链接](https://www.fincen.gov/resources/statutes-and-regulations/cdd-final-rule) |
| FinCEN 31 CFR § 1010.230 (Beneficial Ownership) | FinCEN/Cornell | [链接](https://www.law.cornell.edu/cfr/text/31/1010.230) |
| FinCEN 31 CFR § 1023.320 (Broker-Dealer SAR) | FinCEN/Cornell | [链接](https://www.law.cornell.edu/cfr/text/31/1023.320) |
| FinCEN SAR FAQs October 2025 | FinCEN | [链接](https://www.fincen.gov/system/files/2025-10/SAR-FAQs-October-2025.pdf) |
| IRS Form W-8BEN Instructions | IRS | [链接](https://www.irs.gov/instructions/iw8ben) |
| IRS Form W-9 Instructions 2024 | IRS | [链接](https://www.irs.gov/pub/irs-pdf/iw9.pdf) |
| PDT Rule Amendment Federal Register 2026 | SEC/联邦公报 | [链接](https://www.federalregister.gov/documents/2026/01/14/2026-00519/self-regulatory-organizations-financial-industry-regulatory-authority-inc-notice-of-filing-of-a) |
| IBKR Account Guide | IBKR | [链接](https://www.interactivebrokers.com/en/accounts/account-guide.php) |
| Schwab Options Approval Levels | Schwab | [链接](https://help.streetsmart.schwab.com/pro/4.36/Content/Option_Approval_Levels.htm) |

### 9.2 香港监管机构

| 文件 | 机构 | 链接 |
|------|------|------|
| AMLO Cap. 615 | 香港立法会 | [链接](https://www.elegislation.gov.hk/hk/cap615) |
| SFO Cap. 571（含Schedule 1 PI定义） | 香港立法会 | [链接](https://www.elegislation.gov.hk/hk/cap571) |
| OSCO Cap. 455（含Section 25A STR义务） | 香港立法会 | [链接](https://www.elegislation.gov.hk/hk/cap455) |
| UNSO Cap. 537（UN制裁执行） | 香港立法会 | [链接](https://www.elegislation.gov.hk/hk/cap537) |
| SFC Code of Conduct 2024年10月版 | SFC | [链接](https://www.sfc.hk/-/media/EN/assets/components/codes/files-current/web/codes/code-of-conduct-for-persons-licensed-by-or-registered-with-the-securities-and-futures-commission/Code_of_conduct-Oct-2024_Eng-with-Bookmark-Final.pdf) |
| SFC AML/CFT Guidelines 2023年6月版 | SFC | [链接](https://www.sfc.hk/en/Rules-and-standards/Anti-money-laundering-and-counter-financing-of-terrorism) |
| SFC 可接受账户开立方式 | SFC | [链接](https://www.sfc.hk/en/Rules-and-standards/Account-opening/Acceptable-account-opening-approaches) |
| SFC 适合性要求 | SFC | [链接](https://www.sfc.hk/en/Rules-and-standards/Suitability-requirement) |
| SFC 证券孖展融资指引 | SFC | [链接](https://www.sfc.hk/en/Rules-and-standards/Codes-and-guidelines/Guidelines/Guidelines-for-Securities-Margin-Financing-Activities) |
| SFC 专业投资者 FAQs | SFC | [链接](https://www.sfc.hk/en/faqs/intermediaries/supervision/Anti-Money-Laundering-and-Counter-Financing-of-Terrorism/Anti-Money-Laundering-and-Counter-Financing-of-Terrorism) |
| SFC AML/CFT Circular 23EC21 | SFC | [链接](https://apps.sfc.hk/edistributionWeb/api/circular/openFile?lang=EN&refNo=23EC21) |
| HKMA AML/CFT法例及法定指引 | HKMA | [链接](https://www.hkma.gov.hk/eng/key-functions/banking/anti-money-laundering-and-counter-financing-of-terrorism/ordinances-statutory-guidelines/) |
| JFIU 官方网站 | JFIU | [链接](https://www.jfiu.gov.hk/en/) |
| JFIU STR FAQs | JFIU | [链接](https://www.jfiu.gov.hk/en/faq.html) |
| IRD AEOI（CRS/FATCA自动交换） | 香港税务局 | [链接](https://www.ird.gov.hk/eng/tax/dta_aeoi.htm) |
| IRD AEOI FAQs | 香港税务局 | [链接](https://www.ird.gov.hk/eng/faq/dta_aeoi.htm) |

---

### 13.3 开源项目与行业资料

| 资源 | 来源 | 链接 |
|------|------|------|
| Alpaca Broker API 文档 | Alpaca Markets | [链接](https://docs.alpaca.markets/docs/about-broker-api) |
| Alpaca Go SDK | GitHub | [链接](https://github.com/alpacahq/alpaca-trade-api-go) |
| Apache Fineract | Apache/GitHub | [链接](https://github.com/apache/fineract) |
| Ballerine KYC Engine | GitHub (YC) | [链接](https://github.com/ballerine-io/ballerine) |
| vnpy 量化框架 AccountData | GitHub | [链接](https://github.com/vnpy/vnpy/blob/master/vnpy/trader/object.py) |
| Stripe Ledger 架构博客 | Stripe Engineering | [链接](https://stripe.com/blog/ledger-stripe-system-for-tracking-and-validating-money-movement) |
| Monzo 余额性能优化博客 | Monzo Engineering | [链接](https://monzo.com/blog/2023/04/28/speeding-up-our-balance-read-time-the-planning-phase) |
| Martin Fowler 会计模式叙述 | martinfowler.com | [链接](https://martinfowler.com/eaaDev/AccountingNarrative.html) |
| Martin Fowler 会计模式 PDF | martinfowler.com | [链接](https://martinfowler.com/apsupp/accounting.pdf) |
| UK Open Banking OBAccount6 v3.1.10 | Open Banking UK | [链接](https://openbankinguk.github.io/read-write-api-site3/v3.1.10/resources-and-data-models/aisp/Accounts.html) |
| Berlin Group NextGenPSD2 AccountDetails | Berlin Group | [链接](https://open-banking.pass-consulting.com/json_AccountDetails.html) |
| ISO 20022 acmt 消息族列表 | iotafinance.com | [链接](https://www.iotafinance.com/en/SWIFT-ISO20022-Business-area-acmt-Account-Management.html) |
| FIX Protocol AccountType(581) 字典 | onixs.biz | [链接](https://www.onixs.biz/fix-dictionary/4.4/tagnum_581.html) |
| Fineract m_savings_account 表文档 | fineract.apache.org | [链接](https://fineract.apache.org/docs/database/tables/m_savings_account.html) |
| CCASS 投资者参与者操作指南 | HKEX | [链接](https://www.hkex.com.hk/Services/Settlement-and-Depository/Investor-Account-Services/Operating-Guide-for-Investor-Participants) |
| DTCC DTC 披露框架 | DTCC | [链接](https://www.dtcc.com/-/media/Files/Downloads/legal/policy-and-compliance/DTC_Disclosure_Framework.pdf) |
| Go Event Sourcing 实践 | oneuptime.com | [链接](https://oneuptime.com/blog/post/2026-01-07-go-event-sourcing/view) |
| adorsys xs2a NextGenPSD2 开源实现 | GitHub | [链接](https://github.com/adorsys/xs2a) |

---

*本文档基于截至2026年3月的公开官方文件及社区资料。监管规则可能随时更新，实施前请核查各监管机构官网最新版本。*
