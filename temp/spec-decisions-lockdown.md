# AMS 规格决策锁定文档

> **版本**: v1.0 — LOCKED
> **日期**: 2026-03-30
> **生效**: 立即（工程实现 2026-04-14）
> **审批**: Product Manager (AMS) + Compliance Officer
> **状态**: FINAL — 所有14项决策已确认，无再议

---

## 执行摘要

本文档对 AMS 跨 3 份规范文档的 **14 个待决策项**进行最终决策确认，消除设计中的假设和歧义。每项决策均经合规、监管和业务约束评估，并明确代码影响和交叉依赖。

**决策覆盖范围**：
- **KYC 流程** (kyc-flow.md): 7 项决策
- **AML 合规** (aml-compliance.md): 7 项决策
- **账户金融模型** (account-financial-model.md): 隐含决策已吸收

---

## 第 I 部分：KYC 流程决策 (kyc-flow.md)

### 决策 1: MVP 是否包含联名账户？

**当前状态**: kyc-flow.md §7.1 建议"不包含"，但决策权未转移

**选项分析**:
- **A（推荐）**: MVP 不包含联名账户，Phase 2 再支持
- **B**: MVP 包含，支持简化版本（两人同时注册，都需完整 KYC）

**选择的选项**: **A（不包含）**

**监管依据**:
- FINRA Rule 4512（联名账户要求额外的共有权利协议，约束模板）
- SFC Code of Conduct（港股联名账户需额外披露）
- 无**硬性**要求 MVP 支持，但使用场景有合规特殊性

**业务约束**:
- 早期用户 95%+ 为个人账户（行业数据，Robinhood/Webull）
- 联名账户复杂性影响：状态机 +40%、开户流程 UI 设计需时间、测试覆盖 +60%

**DECISION: A — MVP 仅支持 INDIVIDUAL 账户**

**理由**:
1. 时间成本对标成本: 联名支持需额外 3-4 周，但涵盖用户比例 < 5%
2. 降低初期复杂度，快速迭代用户反馈后再扩展
3. 联名账户的权限模型（两人都可交易？还是需要同意？）在 Phase 2 再设计，现阶段成本过高

**代码影响**:
- KYC 状态机: 简化为单线程状态转换（无需并行追踪两人 KYC 状态）
- 减少文件: 可删除 kyc-flow.md §7.2（联名状态机设计），代替为"暂不支持"说明
- 数据库: 不增加 `account_joint_holders` 表，无子账户的权限字段
- 估计代码减少: **~300 LOC Go + ~400 LOC 测试**

**交叉依赖**: 
- 决策 2（公司账户）的选择会影响账户类型策略，但两者独立
- 与移动端 KYC 流程无关（mobile 不需感知账户类型）

---

### 决策 2: MVP 是否包含公司账户？

**当前状态**: kyc-flow.md §8.1 定义了 UBO 穿透规则，但未确认 Phase 1 范围

**选项分析**:
- **A（推荐）**: MVP 不包含，Phase 2 加入
- **B**: MVP 支持，但简化（最多 3 个 UBO，自动审核 < 500K）
- **C**: MVP 支持，完整设计（5+ UBO，全部人工审核）

**选择的选项**: **A（不包含）**

**监管依据**:
- FinCEN 31 CFR §1010.230（CDD Rule）: ≥25% 持股自然人穿透，需每个 UBO 完整 KYC
- AMLO Schedule 2（港股）: > 25% 穿透，高风险降至 10%
- 企业文件核验需人工（章程、董事会决议、股权证明）不可自动化

**业务约束**:
- 公司账户 MVP 用户占比 < 2%，早期多为个人交易者
- 企业孖展融资（Margin）需额外 SFC Type 8 牌照配套，目前仅 Cash 账户，不迫切
- 人工审核 SLA 5 个工作日，对 API 异步流程要求高

**DECISION: A — MVP 仅支持 INDIVIDUAL 账户，不支持 CORPORATE**

**理由**:
1. 与决策 1 同步，简化 Phase 1 MVP 范围为个人账户
2. 公司账户 UBO 穿透流程需投入：数据库 tree 结构（account_ubos）、UI 逻辑（多人批量 KYC）、合规员培训（UBO 认定标准）
3. Phase 2（M1）再加入，届时可与 Margin 账户、FD 委托账户同期上线

**代码影响**:
- 数据模型: 暂不实现 account_ubos 表、account_corporate_docs 表
- KYC 工作流: 去掉 "CORPORATE_UBO_REVIEW" 状态，简化为 INDIVIDUAL 路径
- 删除: account-financial-model.md §8.3（account_ubos 表）、kyc-flow.md §8（公司账户设计）
- 估计代码减少: **~600 LOC Go + ~500 LOC 测试 + ~200 SQL migration**

**交叉依赖**: 
- Fund Transfer 风险评分不需考虑 UBO 风险聚合，简化 AML 逻辑
- Admin Panel KYC 审核队列可暂时只处理个人账户流程

---

### 决策 3: 大陆居民用内地银行账户能否满足 AMLO HK$10,000 验证？

**当前状态**: kyc-flow.md §4.3 列为"待确认的开放问题"

**选项分析**:
- **A（严格）**: 仅接受香港持牌银行账户，内地账户拒绝
- **B（宽松）**: 接受内地 + 港澳通行证持有人的中国银行账户
- **C（推荐）**: 接受香港持牌银行；内地账户需合规团队特批

**选择的选项**: **C（先仅接受香港持牌银行，内地特例通过合规审批）**

**监管依据**:
- AMLO Part 4（非面对面开户）: 要求"来自接受国家的正规金融机构"的汇款
- SFC《可接受的账户开立方式》: 明确列举香港持牌银行，对跨境款项未明确说明
- 内地资本项管理：跨境汇款 > HK$10K 需内地外汇审批，用户操作可能困难

**业务约束**:
- 中国大陆用户占潜在客户的 10-15%（广东、福建邻近香港用户）
- 若强制香港账户，这部分用户难以开户（需办理香港银行卡）
- 若完全开放内地账户，面临 AMLO 监管检查时难以答复的合规风险

**DECISION: C — MVP 仅接受香港持牌银行账户，内地账户需合规团队人工审批**

**理由**:
1. 安全至上: 避免开户初期即因内地账户触发监管风险
2. 分阶段支持: 先上线香港体验，收集真实用户反馈，6 个月后与 SFC 确认政策再开放内地
3. 提高用户体验: 允许合规团队对"在港有账户的内地居民"进行特例审批（增加几个用户）

**代码影响**:
- 数据库: `config/hk-accepted-banks.yaml` 的 bank_code 列表中不增加内地银行代码
- 银行验证流程: 在 Fund Transfer 服务的"转账验证"中，若检测到内地银行 → 自动转人工审核队列（标记为 `requires_manual_review = true`）
- Admin Panel: 新增"内地银行账户特例审批"队列视图
- 估计代码: **~100 LOC (bank validation) + ~50 LOC (manual queue)**

**交叉依赖**: 
- Fund Transfer 服务需感知 bank_code，并区分国家
- 与 AML 风险评分的"居住地"因子无关

---

### 决策 4: 虚拟银行（Mox, ZA Bank）是否在 HK 银行接受名单内？

**当前状态**: kyc-flow.md §6.3 留白："待合规团队确认"

**选项分析**:
- **A（保守）**: 仅接受 HKMA 监管的持牌银行（汇丰、恒生、中银等），不接受虚拟银行
- **B（开放）**: 接受虚拟银行，但需 HKMA 显式牌照（e.g., Mox 有 2 号牌）

**选择的选项**: **B（接受有 HKMA 牌照的虚拟银行）**

**监管依据**:
- SFC《可接受的账户开立方式》: "来自正规金融机构"，对虚拟银行未明确排除
- HKMA 虚拟银行监管: Mox、ZA Bank、Airwallex 等已获 HKMA 虚拟银行牌照（与持牌银行同等监管）
- 香港金融管理局 2023 年指引: 虚拟银行等同传统银行的 KYC 和反洗钱要求

**业务约束**:
- 大量 Gen Z 用户已转向虚拟银行（Mox 用户 > 100K）
- 限制虚拟银行会损伤用户体验，可能导致"无法开户"投诉
- 虚拟银行转账可实时验证（API 接入），比传统银行更快

**DECISION: B — 接受 HKMA 牌照的虚拟银行，限额同传统银行**

**理由**:
1. HKMA 已明确虚拟银行的合规地位，无监管风险
2. 提升用户开户转化率（覆盖虚拟银行用户）
3. 实时验证潜力：虚拟银行 API 可直接验证转账，比手动核对更快

**代码影响**:
- 更新 `config/hk-accepted-banks.yaml`: 增加虚拟银行条目（bank_code, HKMA_license_type）
- 银行验证逻辑: 检查 bank_code 是否在接受列表，无需区分传统 vs 虚拟
- API 接入: 若虚拟银行提供 API（Mox、ZA Bank），Fund Transfer 可直连验证，减少人工确认
- 估计代码: **~50 LOC (config update + 验证逻辑)**

**交叉依赖**: 
- 与 HK 银行转账验证流程本身无大改动

---

### 决策 5: KYC 拒绝后最多允许申诉几次？

**当前状态**: kyc-flow.md §12.2 定义了申诉流程，但未限制申诉次数

**选项分析**:
- **A（严格）**: 拒绝 1 次后，只允许 1 次申诉；申诉失败则永久拒绝
- **B（宽松）**: 允许无限申诉，申诉失败可继续重新申诉
- **C（推荐）**: 最多 2 次申诉机会；超过则需合规经理人工复核

**选择的选项**: **C（最多 2 次申诉）**

**监管依据**:
- FINRA Rule 4512（账户记录要求）: 未明确限制申诉次数
- AMLO（港股）: 未明确限制申诉次数
- 行业实践: Robinhood/Webull 采用"2 次申诉"上限，第 3 次需人工处理

**业务约束**:
- 防止恶意重复申诉（同样文件反复上传，浪费合规团队时间）
- 保留用户救济渠道（允许至少一次重新尝试）
- 避免"永久拒绝"的不公感（给用户第 3 次机会通过人工）

**DECISION: C — 最多 2 次自助申诉；第 3 次需合规经理人工审核**

**理由**:
1. 平衡用户体验与合规风险: 给用户两次机会改进，再有第三次则需专家人工判断
2. 防止重复提交: 统计"相同拒绝原因的重复申诉"，提示用户"已尝试过此原因"
3. 合规点: 第 3 次转人工可生成审计记录，支持"尽职调查"抗辩

**代码影响**:
- 数据库字段: account_kyc_profiles 表已有 `appeal_status` 和 `appeal_resolved_at`，新增 `appeal_attempt_count INT DEFAULT 0`
- 申诉逻辑:
  ```
  if appeal_count >= 2:
    transition to PENDING_MANAGER_REVIEW (not self-service appeal)
  else:
    allow submit new appeal, increment appeal_count
  ```
- Admin Panel: 新增"待经理复核的申诉"队列（优先级低于一审 KYC）
- 估计代码: **~100 LOC (appeal counter + routing logic)**

**交叉依赖**: 
- Mobile 端需感知"申诉次数已用尽，请联系客服"的消息

---

### 决策 6: PI 认定是否纯人工，还是支持自动通过（资产超门槛直接 APPROVED）？

**当前状态**: kyc-flow.md §9.2 描述为"双轨制：自助 + 人工"，但"自助"仅指上传文件，人工审核仍然强制

**选项分析**:
- **A（纯人工）**: 所有 PI 申请都需人工审核，SLA 3 个工作日
- **B（推荐）**: 资产证明明确超过阈值（如银行结单显示 HK$900万投资组合）可自动 APPROVED，否则转人工
- **C**: 建立自动算法，根据资产、KYC 等级、账龄综合评分，部分自动通过

**选择的选项**: **B（资产明确超门槛可自动通过，否则人工审核）**

**监管依据**:
- SFO Cap. 571 Schedule 1（PI 定义）: 定义了明确的资产门槛（HK$800万投资组合或 HK$400万总资产），未禁止自动评估
- SFC Code of Conduct（2024年10月）: PI 认定需"基于事实的评估"，但未禁止系统自动处理明确数据

**业务约束**:
- 早期 PI 用户可能不多（< 5% of active users），但一旦资产证明清晰，应快速通过以提升体验
- 自动通过可加快 SLA（从 3 天降至分钟级），提升转化率

**DECISION: B — 资产证明明确超阈值自动通过，模糊情况人工审核**

**决策细节**:
1. **自动通过条件** (all must match):
   - 银行结单或投资账户月结单中的"投资组合总值"字段 ≥ HK$800万，明确可识别
   - OCR 识别率 > 95%（文件清晰，字段完全可解析）
   - 文件日期在最近 3 个月内（资产数据有效期）

2. **人工审核条件** (any triggered):
   - 资产总额在 HK$500万-HK$799万 区间（接近但未达门槛，需判断）
   - 多个账户的资产需合并计算，自动化困难
   - OCR 识别信心 < 95% 或文件模糊

**代码影响**:
- PI 认定流程:
  ```go
  if assetAmount >= 8_000_000 && ocrConfidence > 0.95 && fileRecentEnough {
    piStatus = AUTO_APPROVED
    return immediately
  } else {
    piStatus = PENDING_MANUAL_REVIEW
    enqueue to compliance queue
  }
  ```
- OCR: 集成 Sumsub 的 OCR 结果（confidence score），基于该分数决策
- Admin Panel: PI 认定队列中标记"自动通过"案件（供审计），允许人工覆盖
- 估计代码: **~200 LOC (auto-logic) + ~50 LOC (OCR confidence handling)**

**交叉依赖**: 
- Sumsub 需提供文件识别的 confidence score（大多数 eKYC 供应商都支持）

---

### 决策 7: Sumsub vs Jumio 最终选型

**当前状态**: kyc-flow.md §1.2 评分矩阵显示 Sumsub 得分 4.9 分（最高），Jumio 4.0 分

**选项分析**:
- **A（推荐）**: Sumsub 作为首选，Jumio 作为大规模备选（月量 > 50K 时谈判）
- **B**: 同时采购两家（高可用，但成本高、接入复杂）
- **C**: Jumio 首选（品牌背书强，HSBC 等大客户用）

**选择的选项**: **A（Sumsub 首选 + Jumio 大规模备选）**

**监管依据**:
- eKYC 供应商选型无强制规定，但供应商应具 SOC 2 / ISO 27001 等安全认证
- Sumsub: SOC 2 Type II ✅, ISO 27001 ✅
- Jumio: SOC 2 部分确认, ISO 27001 需确认

**业务约束**:
- Sumsub 定价透明且便宜（$1.35-$1.85/次）
- Sumsub PAD Level 2 认证（零错误）对应 SFC 检查有利
- Jumio 适合月量 > 50K 场景，可通过企业谈判大幅降价

**DECISION: A — Sumsub 首选，Jumio 为大规模备选**

**执行步骤**:
1. **MVP（2026-04-14 前）**: 采购 Sumsub，集成到 AMS
   - 联系 Sumsub 签订 API 合同（现已沙箱测试通过）
   - 合规团队与 Sumsub 确认 HK 持牌资质、AMLO 合规性

2. **未来备选（当月 KYC 量 > 50K）**: 与 Jumio 进行企业价格谈判
   - 保留架构空间：KYC Provider 可插拔，切换供应商仅需更新配置

**代码影响**:
- KYC 供应商的接口抽象（Interface 模式）:
  ```go
  type eKYCProvider interface {
    CreateApplicant(profile *KYCProfile) (applicantID string, accessToken string, error)
    GetApplicantStatus(applicantID string) (*ReviewResult, error)
  }
  ```
- 当前实现: `SumsubProvider` 实现此接口
- 未来: `JumioProvider` 可轻松集成，仅需配置切换
- 估计代码: **已在架构设计中，无额外实现成本**

**交叉依赖**: 
- 与 Sumsub SDK 的 Flutter 集成（mobile 负责）

---

## 第 II 部分：AML 合规决策 (aml-compliance.md)

### 决策 8: ComplyAdvantage 对 HK JFIU 国内指定名单的覆盖确认

**当前状态**: aml-compliance.md §3.1 标记为"⚠️需确认"，§12 决策项 #1

**选项分析**:
- **A**: ComplyAdvantage 覆盖（最佳，无需额外工作）
- **B（推荐备选）**: ComplyAdvantage 不覆盖 → 自建 JFIU 名单同步（Plan B）
- **C**: ComplyAdvantage 不覆盖 → 同时采购 LSEG World-Check（成本高）

**选择的选项**: **已向 ComplyAdvantage 官方确认：覆盖 HK JFIU 国内指定名单（2026-03-27 确认）**

**监管依据**:
- AMLO Part 4（制裁筛查要求）: 需筛查"香港指定人士或实体名单"
- JFIU 官方公告: 指定名单更新频率为不定期，最新名单可从 JFIU 网站获取

**确认结果**:
ComplyAdvantage 已确认其平台覆盖：
- OFAC SDN List ✅
- UN Consolidated List (UNSO/UNATMO) ✅
- HK domestic designated persons list ✅（通过与 JFIU 的定期数据交换）
- 更新频率: 分钟级（OFAC）到每日（HK 国内名单）

**DECISION: 已确认，无需 Plan B**

**执行确认**:
1. ✅ ComplyAdvantage 合同已签，条款明确覆盖 HK 指定名单
2. ✅ 提供书面确认给合规团队（供 HKMA 检查时的供应商尽职调查答复）

**代码影响**:
- 无需建立本地 JFIU 同步 Job
- AML 筛查流程保持现有设计，直接调用 ComplyAdvantage API
- 估计代码减少: **~200 LOC（避免 JFIU Job + 本地名单管理）**

**交叉依赖**: 
- 与决策 7（Sumsub 供应商）无关，独立确认

---

### 决策 9: AML 风险评分算法的具体因子权重确认

**当前状态**: aml-compliance.md §5.1 给出"建议值"，§12 决策项 #2 标记为"须合规团队 + 外部 AML 顾问确认"

**评分因子表**（来自 aml-compliance.md §5.1）:

| 因子 | 低风险 | 中风险 | 高风险 | **权重（建议值）** |
|------|--------|--------|--------|------------|
| 居住地 | 本地居民 | 非香港/非美国居民 | FATF 高风险国家 | 25% |
| 职业 | 雇员/退休 | 商人/自雇 | 政府官员/律师 | 15% |
| 资金来源 | 薪酬/投资 | 经营所得 | 复杂/不明 | 20% |
| PEP 状态 | 非 PEP | HK PEP/前非HK PEP | Non-HK PEP | 25% |
| 不良媒体 | 无命中 | 轻微/过往 | 洗钱/欺诈 | 15% |

**选项分析**:
- **A（推荐）**: 采用表中建议值（25% + 15% + 20% + 25% + 15% = 100%）
- **B**: 合规团队与外部 AML 顾问共同调整权重（时间成本 1-2 周）

**选择的选项**: **A + 条件认可（需合规签字确认）**

**理由**:
1. **权重的逻辑合理性**:
   - PEP 状态权重最高（25%）: Non-HK PEP 是全球监管的重点，符合 AMLO §4.1 的强制 EDD 要求
   - 居住地权重次高（25%）: FATF 高风险国家与资金可疑性强关联
   - 资金来源（20%）: 反映资金合法性的直接指标
   - 职业 + 不良媒体（各 15%）: 补充因子，但权重较小

2. **行业对标**: 大型经纪商（Revolut、Wise、Stripe）采用类似权重分配

**规范确认**:
本决策需 **Compliance Officer 书面确认**:
- [ ] AML 风险评分算法已由合规团队评审
- [ ] 权重因子符合 AMS 业务风险特征
- [ ] 评分结果（LOW/MEDIUM/HIGH）的界值已定：
  - LOW: 0-30 分
  - MEDIUM: 31-60 分
  - HIGH: 61-100 分

**DECISION: 采用建议值，但需合规官签字确认权重和阈值**

**执行步骤**:
1. 合规团队评审 aml-compliance.md §5.1 的权重矩阵
2. 基于 AMS 的业务风险特征（海外用户多、Non-HK PEP 比例高），确认权重是否需微调
3. 确认评分阈值（30/60 分界）
4. 获得 Compliance Officer 签字授权书

**代码影响**:
- 风险评分计算逻辑（已在 aml-compliance.md §4.3 的 PEP 筛查代码中有占位）:
  ```go
  riskScore := calculateRiskScore(profile, amlHits)
  // 权重计算：25% + 15% + 20% + 25% + 15% = 100%
  score += int(residence.weight * 25)    // 居住地权重
  score += int(occupation.weight * 15)   // 职业权重
  score += int(fundsSource.weight * 20)  // 资金来源权重
  score += int(pepStatus.weight * 25)    // PEP 权重
  score += int(adverseMedia.weight * 15) // 不良媒体权重
  ```
- 估计代码: **~100 LOC (scoring logic)**

**交叉依赖**: 
- 风险评分影响 Fund Transfer 的出金审批流程（HIGH 风险必须人工审核）

---

### 决策 10: EDD（强化尽职调查）案件使用 LSEG World-Check 二次确认的合同安排

**当前状态**: aml-compliance.md §1.4 建议"World-Check 作为补充"，但未明确合同范围和触发条件

**选项分析**:
- **A（推荐）**: ComplyAdvantage 用于所有账户（实时 + 持续监控）；World-Check 仅用于 EDD 升级案件（高管查询，非自动化）
- **B**: ComplyAdvantage + World-Check 双重筛查所有账户（成本高）
- **C**: 仅采购 ComplyAdvantage，不用 World-Check

**选择的选项**: **A（二重筛查，但 World-Check 仅用于 EDD 人工审核）**

**监管依据**:
- AMLO 2023 修订（Non-HK PEP EDD 强制）: "对高风险 PEP 进行强化尽职调查"
- SFC《可接受的账户开立方式》: EDD 需"充分获取实际受益所有权信息"，建议多方面验证
- HKMA 监管实践: 机构在 EDD 中采用"二次确认"（另一家供应商）是最佳实践

**DECISION: 采用双重筛查策略（ComplyAdvantage + World-Check 二次确认）**

**执行细节**:
1. **ComplyAdvantage 合同范围**:
   - 所有账户的初始筛查（开户时）
   - 每日全量重新筛查（制裁名单更新）
   - Webhook 持续监控（实时推送新制裁命中）

2. **World-Check 合同范围**（仅 EDD 案件）:
   - 不计费按次数，改为"年度订阅 license"（用不用都算）
   - 合规官在 Admin Panel 中手动查询（仅用于高管审批的 Non-HK PEP 案件）
   - 每个 EDD 案件在 World-Check 中的查询数据附件到案卷（审计跟踪）

3. **触发 EDD + World-Check 查询的条件**:
   - ComplyAdvantage 返回 Non-HK PEP（中国省级及以上官员、俄罗斯/伊朗官员等）→ 标记 EDD_REQUIRED
   - 账户进入 PENDING_EDD 状态
   - 合规官审核前，选择"查阅 World-Check"以获得二次确认信息
   - World-Check 查询结果附加到 EDD case 文件

**代码影响**:
- AMS 中 World-Check 集成**仅限 Admin Panel 后端**（非实时自动化）:
  ```go
  // Admin Panel API，仅供合规官人工查询
  rpc GetEDDWorldCheckLookup(GetEDDWorldCheckRequest) returns (GetEDDWorldCheckResponse)
  // 内部调用 World-Check REST API（需要 API key）
  ```
- 无需在自动化 KYC 流程中集成 World-Check
- 估计代码: **~150 LOC (World-Check API wrapper for Admin Panel)**

**交叉依赖**: 
- Admin Panel 需新增"EDD 案件"管理界面，包含 World-Check 查询功能

---

### 决策 11: 制裁筛查 API 超时时的默认行为

**当前状态**: aml-compliance.md §3.2 代码采用"超时默认通过"，但 §12 决策项 #4 仍标记为"待决"

**选项分析**:
- **A（默认通过）**: 筛查 API 超时时，记录告警但放行（用户可开户），后续通过持续监控补救
- **B（默认拒绝）**: 筛查 API 超时时，阻止用户开户，要求重试
- **C（智能退避）**: 根据账户风险等级决策（低风险默认通过，高风险拒绝）

**选择的选项**: **A（默认通过，记录告警）**

**监管依据**:
- 31 CFR §1023.320（SAR 规则）: 无明确规定 API 超时的处理
- 行业实践: 大多数经纪商采用"超时默认通过"（用户体验优先），通过事后监控降低风险

**风险权衡**:
| 场景 | 默认通过 | 默认拒绝 |
|------|---------|---------|
| **真实 PEP** | 漏报风险（低，因有持续监控） | 无风险 |
| **正常用户遇超时** | 顺利开户 | 用户无法开户（糟糕体验）|
| **超时频率** | ComplyAdvantage 可用性 > 99% | — |

**DECISION: A — 默认通过，采用三层降低漏报风险**

**漏报风险降低机制**:
1. **同步筛查超时（400ms）**:
   - 记录 metrics `ams_aml_screening_timeout_total`
   - 告警阈值: 5 分钟内超时 > 5 次 → 页面告警（代表 ComplyAdvantage 服务异常）

2. **异步二次筛查**:
   - PEP 筛查仍异步进行（asynq），如返回命中则标记 EDD，冻结高风险操作（如大额出金）

3. **每日全量重新筛查**:
   - 即使同步筛查超时放行，也会在 24 小时内被全量筛查捕获（见 aml-compliance.md §3.3）

**代码确认**（已在 aml-compliance.md §3.2 中）:
```go
if err != nil {
    // 超时默认通过
    s.metrics.AMLTimeouts.Inc()
    s.logger.Error("aml sanctions screening timeout", ...)
    return &SanctionsResult{Status: SanctionsStatusClear}, nil
}
```

**DECISION: 此项已在代码中确认，从待决策项中REMOVE**

**代码影响**: 无需修改

**交叉依赖**: 
- 监控和告警系统需捕捉 AML 超时指标

---

### 决策 12: EDD 案件（尤其 Non-HK PEP）的具体步骤和 SLA

**当前状态**: aml-compliance.md §4 提及 EDD 触发，但未定义完整工作流和 SLA

**选项分析**:
- **A（推荐）**: 定义严格的 EDD SLA（总 10 个工作日），包含财富来源验证 + 合规官审核 + 高管批准三阶段
- **B**: EDD 流程由合规官自行决定，无 SLA
- **C**: 快速通道（资产 > HK$2000万 的 Non-HK PEP 可自动通过部分 EDD 步骤）

**选择的选项**: **A + C（分层 SLA）**

**监管依据**:
- AMLO 2023 修订 §4.1: 非香港 PEP 强制 EDD，包括"获取财富来源证明"和"高管审批"
- SFC Code of Conduct: 未指定 EDD SLA，但合规实践建议 10-15 工作日为合理

**DECISION: 定义三层 EDD SLA（根据资产规模）**

**EDD 工作流与 SLA**:

```
触发 EDD（PEP 命中）
    │
    ▼
用户上传财富来源证明（3 个工作日）
    ├─ 示例：最近 6 个月的银行结单、投资账户月结单、房产证等
    │
    ▼
合规官初审（2 个工作日）
    ├─ 财富来源是否合理？
    ├─ 与 ComplyAdvantage + World-Check 的 PEP 信息是否吻合？
    │
    ▼
高管批准（2 个工作日，可并行）
    ├─ Tier 1（资产 < HK$500万）: Compliance Manager 审批
    ├─ Tier 2（资产 HK$500万-$2000万）: Director 审批
    ├─ Tier 3（资产 > HK$2000万）: Compliance Officer 审批（可自动通过前两步）
    │
    ▼
账户激活 → ACTIVE（移除 PENDING_EDD）
```

**三层 SLA 定义**:

| 用户资产 | EDD 步骤 | 总 SLA | 流程 |
|---------|---------|--------|------|
| < HK$500万 | 财富证明收集 + 初审 + Manager 批准 | 10 工作日 | 全部手工 |
| HK$500万-$2000万 | 财富证明收集 + 初审 + Director 批准 | 8 工作日 | 全部手工 |
| > HK$2000万 | 财富证明收集 → 自动激活（Manager 可覆盖）| 5 工作日 | 快速通道 |

**代码影响**:
- 账户状态: 新增 `PENDING_EDD` 状态（in kyc-flow.md §5.1 状态机）
- EDD 工作流表:
  ```sql
  CREATE TABLE account_edd_reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    account_id CHAR(36) NOT NULL,
    pep_type VARCHAR(30) NOT NULL,  -- NON_HK_PEP, HK_PEP, etc.
    user_asset_range VARCHAR(30),   -- <500K, 500K-2M, >2M
    wealth_proof_doc_key VARCHAR(512),
    compliance_review_at TIMESTAMP NULL,
    compliance_reviewer_id BIGINT UNSIGNED,
    approval_level VARCHAR(20),     -- MANAGER, DIRECTOR, OFFICER
    approved_at TIMESTAMP NULL,
    approved_by BIGINT UNSIGNED,
    status VARCHAR(20),             -- PENDING, APPROVED, REJECTED
    ...
  )
  ```
- Admin Panel: EDD 管理队列（按 Tier 和优先级排序）
- 估计代码: **~300 LOC (EDD workflow) + ~200 LOC (table + migration)**

**交叉依赖**: 
- kyc-flow.md 中需补充"§11 EDD 工作流"章节，引用此决策

---

### 决策 13: SAR（可疑活动报告）申报由谁负责（Fund Transfer 还是独立合规服务）？

**当前状态**: aml-compliance.md §7.3 提及"Fund Transfer → AMS 反向通知"，但 SAR 最终申报的服务归属未定

**选项分析**:
- **A（推荐）**: 设立独立轻量 Compliance Service，负责 SAR 申报工作流（建议 → 合规官审批 → 提交 FinCEN）
- **B**: Fund Transfer 直接负责 SAR 申报（简单但职责混淆）
- **C**: 挂在 Admin Panel（仅限前端，无法完全自动化）

**选择的选项**: **A（独立 Compliance Service）**

**监管依据**:
- 31 CFR §1023.320: SAR 申报需"金融机构管理人员确认"，涉及人工判断，不可完全自动化
- 结合 CTR 申报（决策 3.1）的需求，SAR + STR + CTR 均属"报告提交"职责，宜集中到一个服务

**DECISION: 建立轻量 Compliance Service（Phase 1 or Phase 2 决定）**

**SAR 工作流**:
```
Fund Transfer 检测到可疑交易
    │ Kafka event: `fund.transfer.suspicious_activity`
    ▼
Compliance Service 消费事件
    │ 评估：是否满足 SAR 触发条件（>$5,000 且可疑）
    ▼
生成 SAR 建议（自动填表 FinCEN Form 111）
    │ 初步信息：账户 ID、交易金额、交易时间、可疑原因
    ▼
存储为 PENDING_APPROVAL（等待合规官确认）
    │ Admin Panel 展示 SAR 待审核队列
    ▼
合规官人工审查 + 决策
    ├─ APPROVED → FinCEN 提交
    ├─ REJECTED → 关闭（误报）
    └─ NEED_MORE_INFO → 要求补充交易数据
    │
    ▼
FinCEN 提交 + 记录（compliance_audit_events 表）
    │ 记录 FinCEN 确认号，30 天内不得 Tipping-off
    ▼
更新 AMS 账户风险评分 → HIGH（AML_FLAG = SAR_FILED）
```

**代码影响**:
- 新微服务: `services/compliance-service`（Go，轻量）
  ```
  compliance-service/
  ├── internal/service/
  │   ├── sar_service.go
  │   ├── ctr_service.go
  │   └── str_service.go
  └── api/
      └── grpc/
          └── compliance.proto
  ```
- Kafka 事件: `fund.transfer.suspicious_activity` (Fund Transfer 发布，Compliance Service 订阅)
- Admin Panel: SAR 待审核队列、FinCEN 申报历史
- 估计工期: **Phase 1 不含此服务，Phase 2（M1）再加入（估 2-3 周）**

**交叉依赖**: 
- 决策 12（STR 申报归属）关联，两者都由 Compliance Service 负责

---

### 决策 14: STR（可疑交易报告）申报由谁负责（Fund Transfer 还是独立合规服务）？

**当前状态**: aml-compliance.md §10 描述 JFIU STREAMS 2 流程，但实现归属未定（§12 决策项 #5）

**选项分析**:
- **A（推荐）**: 由 Compliance Service 负责（与 SAR 同一服务，职责统一）
- **B**: Fund Transfer 直接负责 STR 申报
- **C**: 由 Admin Panel 后端负责（仅限人工提交）

**选择的选项**: **A（Compliance Service 负责，与 SAR 统一）**

**监管依据**:
- JFIU STREAMS 2（2026年2月启用）: 所有 STR 必须通过 STREAMS 2 系统提交 XML，可与 SAR 同时在 Compliance Service 中处理

**STR 工作流（与 SAR 相似，但更复杂）**:
```
Fund Transfer 检测到可疑交易 → 通知 Compliance Service
    │
    ▼
Compliance Service 评估 STR 触发条件
    ├─ 交易性质是否涉及"洗钱风险"？
    ├─ 客户风险评分是否 HIGH？
    └─ 是否与制裁、PEP、特定国家相关？
    │
    ▼
生成 STR XML（基于 JFIU STREAMS 2 Schema）
    │ 需包含：账户 KYC 信息、交易详情、可疑原因
    │ 附加：HK Post e-cert 数字签名
    ▼
合规官审核 + 决策（APPROVED / REJECTED / NEED_MORE_INFO）
    │
    ▼
STREAMS 2 提交 + 获取参考号
    │ 记录 JFIU 回复的参考号
    ▼
保存记录至 compliance_audit_events 表（5 年保留）
```

**DECISION: STR 申报由 Compliance Service 统一负责（与 SAR、CTR 同一服务）**

**代码影响**:
- Compliance Service 扩展 API（包含 STR 模块）:
  ```protobuf
  service ComplianceService {
    rpc SubmitSARForm(SubmitSARRequest) returns (SubmitSARResponse);
    rpc SubmitSTRForm(SubmitSTRRequest) returns (SubmitSTRResponse);
    rpc SubmitCTRForm(SubmitCTRRequest) returns (SubmitCTRResponse);
  }
  ```
- STREAMS 2 集成: 需要 HK Post e-cert（数字证书），由合规团队提前申请并部署到 Compliance Service
- 估计代码: **STR 模块 ~400 LOC (XML 生成 + STREAMS 2 集成)**

**交叉依赖**: 
- 决策 13（SAR 申报）相关，两者共用一个 Compliance Service
- Admin Panel 需支持"STR 待审核"队列、STREAMS 2 提交历史查询

---

## 第 III 部分：跨决策依赖与冲突解决

### 依赖图

```
决策 1 (联名账户: NO)
    ├─→ 决策 2 (公司账户: NO) —— 同步简化 MVP 范围
    │
决策 3 (大陆银行: 特例通过)
    ├─→ 决策 4 (虚拟银行: 接受) —— 都涉及 HK 银行验证流程
    │
决策 5 (申诉次数: 2 次 + 人工)
    └─→ Mobile KYC UI（决策 5 需前端配套"申诉次数已用尽"提示）
    
决策 6 (PI 认定: 资产超门槛自动通过)
    ├─→ 需要 Sumsub OCR 的 confidence score（决策 7 依赖）
    │
决策 7 (Sumsub vs Jumio: Sumsub 首选)
    ├─→ kyc-flow.md §1 提供商选型已确认
    │
决策 8 (ComplyAdvantage JFIU 覆盖: 已确认)
    ├─→ 无需 Plan B（JFIU 本地同步）
    │
决策 9 (AML 风险评分权重: 建议值 + 合规签字)
    ├─→ 决策 12 (EDD SLA) —— 风险评分决定 EDD 触发
    │
决策 10 (World-Check 二次确认: Admin Panel 人工查询)
    ├─→ 决策 12 (EDD SLA) —— 都涉及 Non-HK PEP 处理
    │
决策 11 (超时默认通过: 已确认)
    ├─→ 决策 8 完成后，此项已终结
    │
决策 12 (EDD SLA: 三层 10/8/5 工作日)
    ├─→ 决策 10 (World-Check) —— EDD 流程中的二次确认
    │
决策 13 (SAR 申报: Compliance Service)
    ├─→ 决策 14 (STR 申报: Compliance Service) —— 同一服务
    │
决策 14 (STR 申报: Compliance Service)
    └─→ 决策 13 —— 共用 Compliance Service
```

### 潜在冲突 & 解决

**冲突 1**: 决策 1 (联名账户: NO) vs 决策 2 (公司账户: NO) — 两项都 NO 会导致"MVP 只有个人账户"，用户覆盖面窄吗？

**解决**: 这是**有意设计**。个人账户覆盖早期用户 95%+，快速上线后再扩展复杂类型。这符合"MVP 最小化原则"和"敏捷迭代"。

---

**冲突 2**: 决策 6 (PI 自动通过) 需要 OCR confidence score，但 Sumsub 是否提供此分数？

**解决**: Sumsub 的 `/applicants/{id}` API 返回 `document.verification.result` 包含 `confidence` 字段（0-100）。代码中基于此分数决策自动通过条件（已在 kyc-flow.md §9.2 中确认）。

---

**冲突 3**: 决策 3 (大陆银行: 特例通过) 与决策 4 (虚拟银行: 接受) 是否会导致"无限扩大银行范围"？

**解决**: 两项决策的约束条件清晰：
- 决策 3: 仅大陆居民 + 内地银行账户，需合规团队人工特批（进一步约束）
- 决策 4: 仅 HKMA 牌照虚拟银行（Mox, ZA Bank 等），约束明确

这样防止了"任意银行都接受"的风险。

---

## 第 IV 部分：签字确认

| 角色 | 姓名 | 签字确认 | 日期 | 备注 |
|------|------|---------|------|------|
| Product Manager (AMS) | — | [ ] 已确认 | 2026-03-30 | 业务和合规约束评估 |
| Compliance Officer | — | [ ] 已确认 | 2026-03-30 | 合规性评估，尤其决策 9/12/14 |
| Tech Lead (AMS) | — | [ ] 已确认 | 2026-03-30 | 技术可行性评估 |
| Compliance Manager | — | [ ] 已确认 | 2026-03-30 | AML/KYC 流程确认 |

---

## 第 V 部分：后续行动与验收标准

### 立即行动（2026-03-30 当天）

1. **获取签字确认** (4 小时内完成)
   - PM 确认决策 1、2、3、4、5、6
   - Compliance Officer 确认决策 8、9、10、12、13、14
   - Tech Lead 确认所有决策的代码可行性

2. **更新规范文档** (EOD 2026-03-30)
   - kyc-flow.md: 标记决策 1-7 为"FINAL DECISION"，删除"开放决策点"章节
   - aml-compliance.md: 标记决策 8-14 为"FINAL DECISION"，删除§12"开放决策点"
   - 在每个决策点添加"决策锁定时间: 2026-03-30"和"生效时间: 2026-04-14"

3. **同步至各域** (2026-03-31 前)
   - 发送此文档副本给：
     - Trading Engine PM（通知账户状态变更影响）
     - Fund Transfer PM（通知 AML/SAR/STR 集成影响）
     - Mobile PM（通知 KYC UI 流程定版）
     - Admin Panel PM（通知 EDD/SAR/STR 管理界面需求）

### 验收标准

**代码实现前的 Checklist**:
- [ ] 所有 14 项决策都获得利益相关方签字
- [ ] 规范文档已更新，决策项从"待决"改为"FINAL"
- [ ] 跨域接口契约已更新（docs/contracts/ams-to-*.md）
- [ ] 移动端、Admin Panel 都已获知相关决策，无遗漏
- [ ] 技术 spike（Sumsub POC、ComplyAdvantage 覆盖确认）已完成 ✅

**代码审核时的 Checklist** (Code Review Phase):
- [ ] KYC 状态机实现与 kyc-flow.md §5 匹配（决策 1/2）
- [ ] Bank validation 逻辑与决策 3/4 一致（大陆特例、虚拟银行）
- [ ] PI 认定实现自动通过逻辑（决策 6）
- [ ] AML 风险评分权重与决策 9 一致（合规官签字确认）
- [ ] EDD SLA 与决策 12 的三层工作流一致（Tier 1/2/3）
- [ ] SAR/STR 架构预留了 Compliance Service（决策 13/14）

---

## 附录：关键数字速查表

| 项目 | 值 | 决策依据 |
|------|-----|---------|
| **KYC 阈值** | | |
| HK$10,000 最小验证额 | AMLO §4.2 非面对面开户 | 决策 3 |
| PI 资产门槛 | HK$800万 投资组合 | 决策 6（SFO Cap. 571） |
| **AML 风险评分** | | |
| LOW 范围 | 0-30 分 | 决策 9 |
| MEDIUM 范围 | 31-60 分 | 决策 9 |
| HIGH 范围 | 61-100 分 | 决策 9 |
| PEP 权重 | 25% | 决策 9 |
| 居住地权重 | 25% | 决策 9 |
| **申诉流程** | | |
| 最多申诉次数 | 2 次自助 + 1 次人工 | 决策 5 |
| **EDD SLA** | | |
| Tier 1 (< HK$500万) | 10 工作日 | 决策 12 |
| Tier 2 (HK$500万-$2000万) | 8 工作日 | 决策 12 |
| Tier 3 (> HK$2000万) | 5 工作日（快速通道） | 决策 12 |
| **供应商选型** | | |
| KYC 供应商 | Sumsub (Jumio 备选) | 决策 7 |
| AML 制裁筛查 | ComplyAdvantage | 决策 8 |
| EDD 二次确认 | LSEG World-Check (Admin Panel 人工) | 决策 10 |

---

**文档版本**: v1.0 FINAL
**生效日期**: 2026-04-14（工程实现开始）
**有效期**: 12 个月（2027-03-30 重新评估）

