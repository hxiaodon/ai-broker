# AMS 域 PRD/Spec 合理性深度评审报告

**日期**: 2026-03-27
**评审人**: AMS Engineer
**范围**: KYC/AML 产品流程、账户财务模型、认证架构、跨服务边界、规范编织度

---

## 评审问题总表

| 类别 | 问题ID | 问题描述 | 当前规范位置 | 缺失信息 | 建议改进 | 优先级 |
|------|--------|--------|----------|--------|--------|------|
| 知识结构 | K1 | 移动端 PRD（02-kyc.md）与 AMS PRD（kyc-flow.md）的 KYC 流程定义重叠不清 | mobile/docs/prd/02-kyc.md（未读）vs services/ams/docs/prd/kyc-flow.md §4 | 缺少"各端的职责边界矩阵"；移动端 UI 流程与后端状态机的映射关系 | 创建跨域分工表：移动端负责 UI/UX → AMS 负责状态机/工作流 | High |
| 知识结构 | K2 | 行业调研说明 PI 认定是"每12个月更新"，但 account-financial-model.md 中 `pi_expires_at` 的续期提醒机制不清晰 | references/ams-industry-research.md §2.5 vs account-financial-model.md §6.5 / kyc-flow.md §9.3 | PI 续期逾期后的自动降级流程；系统是否自动扣减权限 vs 需人工干预 | 在 kyc-flow.md 新增"§9.4 PI 到期处理 SOP"，明确自动降级的触发条件和时间点 | High |
| 知识结构 | K3 | Sumsub + ComplyAdvantage 的分工边界：KYC 供应商 vs AML 供应商，但两者的"数据流交互"缺乏设计 | kyc-flow.md §1.3（Sumsub 选型）vs aml-compliance.md §1.3-1.4（ComplyAdvantage 选型） | Sumsub 是否有能力提供 PEP/不良媒体筛查？还是必须由 ComplyAdvantage 补充？重复筛查的成本 | 补充"§3.4 KYC+AML 供应商协同"：明确 Sumsub 的能力范围（仅文件核验+活体），PEP 和制裁筛查100%由 ComplyAdvantage 负责 | Medium |
| 技术可落地 | T1 | KYC 状态机（kyc-flow.md §5）中 `KYC_UNDER_REVIEW` → `KYC_MANUAL_REVIEW` vs → `SANCTIONS_SCREENING` 的优先级不明确：同时命中"AI 不确定"和"制裁名单"时的顺序 | kyc-flow.md §5.1-5.2（状态图），但无转换优先级定义 | 如果 Sumsub 同时返回 `rejectType: RETRY`（不确定）和 `matchedList: OFAC_SDN`（制裁命中），应该进入哪个状态？是否两个异常都要触发？ | 在 kyc-flow.md §5.2 新增"状态转换优先级规则"：制裁筛查（同步阻塞）优先于人工审核（异步），即使存在 AI 不确定也要先过制裁关 | High |
| 技术可落地 | T2 | W-8BEN 续签（kyc-flow.md §10）中"到期后冻结美股股息分配"的实现责任不清：AMS 只设置 flag 还是主动调用 Fund Transfer API？ | kyc-flow.md §10.3（冻结逻辑），aml-compliance.md §7.1（Fund Transfer 职责）| 谁来监听 `w8ben_expired` flag？Fund Transfer 是在分配时检查，还是 AMS 主动通知？如果 AMS 推送事件，应该是什么事件名和负载？ | 明确职责边界：AMS 负责设置 `dividend_hold = true` + 发布 Kafka event `ams.tax_form.expired`；Fund Transfer 消费此事件，在处理股息分配时检查该 flag | High |
| 技术可落地 | T3 | 联名账户 KYC（kyc-flow.md §7）的 MVP 建议"不包含"，但如果产品要求包含，当前 Spec 是否足以实施 | kyc-flow.md §7.1（建议不包含），§7.2（最小化设计） | 联名账户的 UX 流程如何?（先完成一方 KYC，再邀请二方？还是同时注册两个用户？）两方都需要生物认证吗？ | 在联名账户设计前，与 PM 确认开户 UX，然后补充"§7.3 联名账户开户流程"详述前后端协作步骤 | Medium |
| 技术可落地 | T4 | PEP 异步筛查失败重试（aml-compliance.md §4.3）的递退策略缺失 | aml-compliance.md §4.3 代码示例中只有 `json.Unmarshal(t.Payload(), &payload)` 但未详述 asynq 失败处理 | 重试次数、时间间隔、最终失败后的处理（继续激活账户 vs 标记为 PENDING_EDD vs 人工介入）| 补充"aml-compliance.md §4.4 PEP 筛查失败处理"：定义重试策略（max 3 次，exponential backoff 30s/2min/5min），最终失败转 PENDING_EDD 等待手工干预 | Medium |
| 技术可落地 | T5 | AML 供应商选型的"HK JFIU 国内指定名单覆盖"待决，但这影响整个 HK 用户的风险评估 | aml-compliance.md §3.1（待决策 #1）| ComplyAdvantage 的覆盖情况必须在合同谈判前明确，否则后续 AML 流程无法确定 | 补充"aml-compliance.md §3.2 HKJFIU 名单同步 SOP"：若 ComplyAdvantage 不覆盖，AMS 需建立独立任务每日从 JFIU 官网拉取名单并维护本地库 | High |
| 技术可落地 | T6 | CTR 申报职责（aml-compliance.md §7）是 Fund Transfer 的，但 AMS 应提供哪些接口数据支撑 CTR 申报 | aml-compliance.md §7.2（GetAMLStatus 接口）| Fund Transfer 调用 GetAMLStatus 时，是否需要额外的接口用于查询用户的 KYC 层级、账户创建日期等时间敏感的信息？接口是否需要返回 kyc_verified_at 用于计算"账户初期"风险期 | 补充"aml-compliance.md §7.4 CTR 申报数据接口"：定义 Fund Transfer 需要从 AMS 查询的完整字段清单（kyc_tier, account_created_at, aml_risk_score, jurisdiction 等）| Medium |
| 技术可落地 | T7 | PEP 筛查触发的 EDD 流程（aml-compliance.md §5.2）未定义 EDD 的具体步骤和 SLA | aml-compliance.md §4.1-4.3（PEP 筛查），但未链接到 EDD 工作流 | 非香港 PEP 的 EDD 流程包括哪些步骤？（财富来源证明、高管批准等）在 Admin Panel 中如何呈现？SLA 是多少？ | 新增"kyc-flow.md §11 EDD（强化尽职调查）工作流"：非香港 PEP 强制 EDD，包括上传财富来源证明、合规经理人工审核、高管批准三个阶段，总 SLA 10 个工作日 | High |
| 跨服务边界 | C1 | AMS 与 Fund Transfer 的 AML 职责分工存在"灰色地带"：结构性交易检测由 Fund Transfer 做，但何时应升级账户风险评分由谁决定 | aml-compliance.md §8.2-8.3（结构性交易检测属 Fund Transfer），§7.3（SAR 触发时反向通知 AMS） | 如果 Fund Transfer 检测到多笔 $3,000-$9,999 分散交易但尚未触发 SAR，是否应该通知 AMS 升级风险评分？还是仅在确认 SAR 触发时才通知？规则是什么 | 补充"aml-compliance.md §8.4 风险评分升级触发机制"：明确何时 Fund Transfer 应将 SAR 建议转化为 AMS 的风险升级（推荐：仅在 SAR 正式申报时升级 MEDIUM→HIGH，中间告警阶段不升级） | Medium |
| 跨服务边界 | C2 | Fund Transfer 的 CTR 申报（aml-compliance.md §7）需要知道用户的 KYC 等级来设置阈值，但接口契约不够清晰 | aml-compliance.md §7.1 表格说"Fund Transfer 负责 CTR 自动申报"，但调用 AMS 的 GetAMLStatus 是否包含 KYC 等级 | US CTR 和 HK CTR 的阈值不同（$10,000 vs HK$120,000），Fund Transfer 是否需要询问 AMS 该账户的 jurisdiction 字段？目前 GetAMLStatus RPC 未返回此字段 | 扩展"aml-compliance.md §7.2 GetAMLStatus RPC"：增加返回 `jurisdiction` 和 `kyc_tier` 字段，供 Fund Transfer 按不同市场/等级决定 CTR 申报阈值 | Medium |
| 跨服务边界 | C3 | JFIU STR 申报（aml-compliance.md §10）由"Fund Transfer 或独立合规服务"负责，但未明确由谁来写"哪个服务"的架构决策 | aml-compliance.md §10.2（STR XML 申报集成），§12（开放决策 #5） | 是否应该在 MVP 之前确定 STR 申报归属？如果由 Fund Transfer 做，其工作量是否过大？独立合规服务意味着需要新建一个微服务，这影响整体架构规划 | 升级为 High 优先级决策项：在 Fund Transfer Spec 中与 Product 共同确定 STR 申报服务归属，然后补充相应的跨服务事件契约 | High |
| 数据一致性 | D1 | account-financial-model.md 中账户状态机（§5.1）与 kyc-flow.md 中 KYC 状态机（§5.1）存在概念混淆 | account-financial-model.md §5.1（应用级账户状态），kyc-flow.md §5.1（KYC 工作流状态） | 两个状态机是否并行？还是 KYC 状态是账户状态的子集？`PENDING_EDD` 在哪个状态机中定义？account_financial_model 中未出现 | 明确两个状态机的层级关系：KYC 工作流状态（微观，仅在开户阶段 active）→ 账户生命周期状态（宏观，贯穿账户全生命期）；在 account-financial-model.md 中新增"§5.4 KYC 状态与账户状态的映射关系" | High |
| 数据一致性 | D2 | account-financial-model.md 中提到 `edd_required` 和 `edd_approved_by` 字段（§4.3），但 AML 字段与 KYC 工作流的衔接不清 | account-financial-model.md §8.1 accounts 表 edd_required / edd_approved_by，但未定义 EDD 的前置条件、触发时机、完成标志 | 非香港 PEP 的 `is_pep` 和 `edd_required` 的赋值时机是在 KYC 流程中还是 AML 筛查后？两个字段的生命周期如何管理 | 补充"account-financial-model.md §8.6 EDD 字段管理"：定义 EDD 的状态转换（NONE → REQUIRED → IN_PROGRESS → APPROVED），以及何时写入 `edd_approved_by` 和 `edd_approved_at` | Medium |
| 数据一致性 | D3 | 制裁筛查覆盖范围在多个文档中重复定义，且 HK JFIU 名单的覆盖有矛盾 | account-financial-model.md §4.2（制裁名单清单），aml-compliance.md §3.1-3.2（制裁筛查规格），kyc-flow.md §4.1-4.4（开户路径中的制裁筛查） | 三份文档中关于"HK 内部指定名单"的描述都是"待确认覆盖"，但这是关键的合规要求，不应该有歧义 | 在一份规范中集中定义制裁名单覆盖清单（建议放在 aml-compliance.md），其他文档引用而不重复定义；同时明确 JFIU 名单的采购和同步流程 | Medium |
| 决策清晰度 | O1 | kyc-flow.md §13 列出 7 个待决策项，但未指定"由谁在何时决策"、"决策对代码的影响有多大" | kyc-flow.md §13 | 决策项 #1（MVP 是否包含联名账户）直接影响状态机复杂度，但决策时间若在编码中期进行则会导致重构；需要决策优先级和 deadline | 补充决策治理流程：在 KYC 开发前的 **Planning Phase**，Product + Engineering + Compliance 同步确认所有 7 个决策项，为每一项标注 deadline 和 decision owner | High |
| 决策清晰度 | O2 | aml-compliance.md §12 的 7 个待决策项中，#4（制裁筛查 API 超时时的默认行为）是关键的合规风险决策，但文档中没有给出推荐值 | aml-compliance.md §3.2 代码中采用"超时默认通过"，但 §12 决策项 #4 问"默认通过 or 默认拒绝"，文档自相矛盾 | 代码已经选择了"默认通过"，但决策项仍在"待决策"，这意味着该决策尚未正式批准且可能被推翻 | 在 aml-compliance.md 中明确标注：制裁筛查超时 = 默认通过（原因：误报代价更高），此决策已确认，从待决策项中移除 | High |
| 监管合规 | R1 | W-8BEN 到期前 90 天推送续期提醒，但如果用户在第 89 天登录后忽视通知，实际上用户有机会在到期后才发现 | kyc-flow.md §10.2-10.3 | W-8BEN 续期是否应该强制引导？例如，在美股交易界面显示"税表待续期"的 banner，甚至锁定美股交易直到续期 | 补充强制引导机制：当 W-8BEN 进入"到期前 30 天"区间时，限制美股交易功能（提示续期），到期后冻结股息分配；详见 kyc-flow.md §10.4 | Medium |
| 监管合规 | R2 | PII 加密（.claude/rules/security-compliance.md 要求 AES-256-GCM），但 account-financial-model.md 的 account_kyc_profiles 表定义中，字段名被标记为 `_encrypted` 但实现细节缺失 | account-financial-model.md §8.2（表结构），security-compliance.md（加密要求） | 是否在应用层实现加密（推荐），还是依赖数据库透明加密？PII 字段的加密密钥管理策略是什么？ | 新增规范文件 "docs/specs/pii-encryption.md"（权威规范），定义：(1) 应用层 AES-256-GCM 加密；(2) 密钥存储于 AWS KMS；(3) 加密/解密的关键代码片段；(4) 脱敏规则（显示仅末4位等） | High |
| 监管合规 | R3 | SAR Tipping-off 防护（aml-compliance.md §6）在 API 层有隔离（/internal/compliance 路由），但 ORM 序列化层的自动过滤（struct tag `json:... perm:...`）采用自定义 marshaller，这增加了实现复杂度 | aml-compliance.md §6.3（物理隔离），§5.3（RBAC 权限）| 自定义 JSON marshaller 的实现成本和维护负担是否值得？还是改用更简单的方案（明确在代码注释中哪些字段不能序列化给客户）| 在 security-compliance.md 中强化 PII/SAR 字段脱敏规则：不采用复杂的动态 marshaller，而是在 HTTP 响应层显式构建 API 返回结构体（包含必要字段），让编译器检查 | High |
| 实现成本 | I1 | Sumsub Webhook 幂等处理（kyc-flow.md §3.3）为了应对多次触发的 `applicantReviewed` 事件，需要在应用层实现去重逻辑 | kyc-flow.md §3.3 代码示例 | 幂等处理是否应该在数据库层（unique constraint）还是应用层（检查已存在）？如果用 database constraint，约束条件是什么（account_id + sumsub_applicant_id）| 补充"kyc-flow.md §3.5 Sumsub Webhook 幂等性设计"：采用 idempotency key（sumsub_applicant_id）作为 unique key，Insert 失败则 SELECT 最后一条记录返回，不抛异常 | Low |
| 实现成本 | I2 | HK 银行转账验证（kyc-flow.md §6.2-6.3）涉及与 Fund Transfer 服务的异步交互，需要 Kafka 消息消费、回调、超时处理 | kyc-flow.md §6.2（流程图），但缺乏与 Fund Transfer 的具体 API 契约 | Fund Transfer 检测到入账后如何通知 AMS？是推送 Kafka event、直接 gRPC 回调还是轮询？72 小时超时后谁来清除临时状态 | 补充"kyc-flow.md §6.4 银行转账验证的 Fund Transfer 集成契约"：定义 Kafka event 名（`fund.transfer.hk_verification_deposit_detected`）、负载结构、重试策略、超时清理 job | Medium |
| 跨域协作 | X1 | 移动端 PRD（02-kyc.md）与 AMS 后端 PRD（kyc-flow.md）的开发依赖关系不明确 | mobile/docs/prd/02-kyc.md（未读），kyc-flow.md §4 | 前端界面如何与后端状态机同步？例如，用户上传文件后，UI 应该立即切换到"待审核"状态，还是等待后端推送？ | 创建"docs/contracts/mobile-ams-kyc.md"：明确 Flutter 与 AMS 的 KYC 流程集成契约，包括状态同步、Sumsub SDK 的 accessToken 获取、webhook 推送通知等 | High |
| 规范完整性 | P1 | 行业调研（references/ams-industry-research.md）关于"PI 认定"的信息与 kyc-flow.md §9 的设计有差异 | references/ams-industry-research.md §2.5（PI 门槛 HK$800万），kyc-flow.md §9.2（双轨制：自助+人工） | 行业调研说 PI 是"资产驱动"的，但流程设计中是"人工审核驱动"的；是否应该添加"自动 PI 认定"逻辑（资产超 HK$800万直接通过）| 在 kyc-flow.md §9 中补充"PI 自动认定逻辑"：若申报资产证明直接显示投资组合 ≥ HK$800万，系统可自动通过（仍需 1 个工作日待人工最终确认）；超过阈值的幅度越大，人工审核越快 | Medium |
| 规范完整性 | P2 | PEP 分类中，"前非香港 PEP"（已卸任）的实操处理在规范中缺失 | aml-compliance.md §4.1（PEP 分类表），但无"前非香港 PEP"的处理流程 | 当发现用户是"卸任的中国省级官员"时，AMS 应该如何处理？是否仍需 EDD？还是进行风险评估后决定 | 补充"aml-compliance.md §4.5 前非香港 PEP 处理流程"：标记为 `pep_type: FORMER_NON_HK_PEP`，进行"轻度风险评估"（例如，卸任距今时间、当前职位、资金来源），可豁免 EDD | Low |

---

## 前 5 个高优先级问题的具体改善方案

### 问题 1: KYC 状态机的状态转换优先级不明确（T1）

**问题描述**：
kyc-flow.md 第 5 节的状态机图中，`KYC_UNDER_REVIEW` 可能同时遭遇两个不同的事件触发：Sumsub 返回 `rejectType: RETRY`（AI 不确定）和 `matchedList: OFAC_SDN`（制裁命中）。规范中未明确这两个路径的优先级，可能导致实现时的争议和遗漏。

**当前规范缺陷**：
- 状态转换规则（表 5.2）中 `→ KYC_MANUAL_REVIEW` 和 `→ ACCOUNT_BLOCKED` 都是从 `KYC_UNDER_REVIEW` 出发，但无优先级定义
- Sumsub 单次 Webhook 回调中同时返回多个 rejectLabels 时的处理不清楚

**改善方案**（约 200 字）：

在 kyc-flow.md §5.2 中新增"状态转换优先级规则"小节，明确：

1. **同步路径优先**：制裁筛查（SANCTIONS_SCREENING）是**同步、阻塞、立即拒绝**的操作，优先级最高。若 KYC 自动核验同时返回"AI 不确定"和"制裁命中"，**立即进入 ACCOUNT_BLOCKED**，不进入人工审核。
2. **异步评估**：人工审核（KYC_MANUAL_REVIEW）属异步、补救路径，仅在"AI 不确定但未命中制裁"时触发。
3. **Webhook 处理**：在 `handleKYCReviewResult` 函数中，优先检查 `rejectLabels.contains("SANCTIONS_HIT")` 和 `matchedList` 字段，若存在立即转 BLOCKED；否则检查 `rejectType == RETRY` 转人工审核。

实现代码示例：
```go
if payload.ReviewResult.MatchedList != "" {
    // 优先路径：制裁命中
    h.kycService.BlockAccountForSanctions(ctx, accountID, payload.ReviewResult.MatchedList)
    return nil
}
if payload.ReviewResult.RejectType == "RETRY" {
    // 次优路径：AI 不确定
    h.kycService.TransitionToManualReview(ctx, accountID, payload.ReviewResult.RejectLabels)
    return nil
}
```

---

### 问题 2: W-8BEN 到期冻结逻辑的服务边界不清（T2）

**问题描述**：
kyc-flow.md 第 10 节规定"到期后冻结美股股息分配"，但未明确谁来执行这个冻结操作。AMS 是设置 flag 后等待 Fund Transfer 主动查询，还是主动推送事件？两个服务间的通信方式（RPC 还是 Kafka）未定义。

**当前规范缺陷**：
- kyc-flow.md §10.3 提到"将 Fund Transfer 读取 `dividend_hold` 字段"，但未说明数据同步机制
- aml-compliance.md §7 中未明确列出 Fund Transfer 需要从 AMS 查询的所有字段
- 没有时间敏感性要求（例如，是否需要实时查询，还是每次股息分配前查询一次）

**改善方案**（约 200 字）：

1. **职责清晰**：AMS 负责"检测和标记"，Fund Transfer 负责"检查和执行"。
   - AMS：每天定时任务（UTC 02:00）扫描 `tax_form_expires_at <= NOW()`，发布 Kafka 事件 `ams.tax_form.w8ben_expired`，同时设置 DB 字段 `dividend_hold = true`。
   - Fund Transfer：订阅此事件作为背景通知；在计算股息分配时，先查询 AMS gRPC `GetAccountTaxStatus(account_id)` 确认 `dividend_hold` 状态，若为 true 则冻结分配并计入日志。

2. **API 契约**：扩展 AMS 的 gRPC 服务新增接口：
   ```protobuf
   service TaxFormService {
     rpc GetAccountTaxStatus(GetAccountTaxStatusRequest) returns (GetAccountTaxStatusResponse);
   }

   message GetAccountTaxStatusResponse {
     string form_type = 1;       // W9 / W8BEN / W8BEN_E
     bool dividend_hold = 2;     // W-8BEN 已过期
     timestamp form_expires_at = 3;
   }
   ```

3. **Kafka 事件定义**：在 kyc-flow.md §10 中补充事件消息定义，包括 account_id、old_expiration_date、new_expiration_date、action_required（分配员工知道需要特殊处理）。

---

### 问题 3: 联名账户的 MVP 范围与设计缺乏可行性论证（T3）

**问题描述**：
kyc-flow.md §7.1 建议"MVP 不包含联名账户"，理由是"状态机复杂度翻倍、开户摩擦增加"。但规范中也提供了§7.2 最小化设计，暗示如果 PM 坚持要包含，技术方案是可行的。然而，缺少前端（Flutter）与后端的交互细节和用户体验设计。

**当前规范缺陷**：
- §7.2 的状态机设计只涵盖"KYC 层面"，未考虑"账户激活"后的联名持有人权限问题
- 没有明确联名账户的开户 UX（两人同时注册？还是一人邀请另一人？）
- 联名账户的出入金规则（两人都要同意？还是任一人可操作？）未定义

**改善方案**（约 200 字）：

**强烈建议 MVP 排除联名账户**。理由增强为：

1. **时间成本高**：UX 设计需跨团队讨论（Product、Mobile、Backend），估计 1 周；实现需 2-3 周；测试需 1 周。
2. **复杂交互点**：
   - 邀请机制：第一持有人注册账户 → 邀请第二持有人 → 第二持有人需完整 KYC → 账户解冻。期间第一持有人无法交易，影响转化率。
   - 权限冲突：两人同时下单、出入金、修改账户信息时的冲突处理。
   - 破产/离婚场景的账户分割。

3. **建议递进方案**：
   - **Phase 1（MVP）**：仅支持 INDIVIDUAL、CORPORATE。
   - **Phase 2（M1）**：单一联名账户支持，约束条件（两人都必须是香港/美国居民；任意一人可交易但出金需两人同意）。
   - **Phase 3**：多类型联名（JTWROS / TIC）、信托账户。

如若 PM 坚持 Phase 1 包含，需补充"docs/contracts/mobile-ams-joint-account.md"详述开户 UX、权限模型和错误场景。

---

### 问题 4: AML 供应商选型的关键决策（ComplyAdvantage HK 名单覆盖）未落实（T5）

**问题描述**：
aml-compliance.md §3.1 表中明确指出 ComplyAdvantage 对"HK JFIU 国内指定名单"的覆盖程度为"⚠️需确认"，但这是香港持证用户开户的**硬性要求**。规范中没有 Plan B（若 ComplyAdvantage 不覆盖，AMS 的备选方案）。

**当前规范缺陷**：
- 决策项 §12 #1 中提到"需在合同谈判时明确"，但未指定谁负责谈判、deadline、或降级处理方案
- 若 ComplyAdvantage 不覆盖，是否需要立即采购第二家供应商（LSEG World-Check）？还是建立本地 JFIU 名单同步机制？成本和工期都不同
- kyc-flow.md 中用户的制裁筛查流程依赖此决策，目前假设覆盖，但若未覆盖则整个 HK KYC 流程不合规

**改善方案**（约 200 字）：

1. **立即行动**：在 AML 供应商谈判之前，由 Compliance Officer 直接联系 ComplyAdvantage 确认 JFIU 名单覆盖情况。这是"Go/No-Go"决策，不能进入代码阶段而悬而未决。

2. **Plan A（推荐）**：若 ComplyAdvantage 覆盖 JFIU，则直接使用其 API 进行制裁筛查，简化架构。

3. **Plan B（备选）**：若 ComplyAdvantage 不覆盖，需在 AMS 中建立独立的 JFIU 名单同步和查询模块：
   - 每日 06:00 UTC 执行 fetch_jfiu_designated_list Job，从 JFIU 官网拉取名单
   - 存储于 MySQL 表 `designated_entities` 和 Redis（高频查询用）
   - 开户时调用本地查询接口 `LocalSanctionsService.SearchJFIU(name, nationality)`

4. **补充规范**：在 aml-compliance.md §3.3 新增"JFIU 名单本地同步 SOP"，含完整的 Job 定义、表结构、和回退策略。

---

### 问题 5: KYC 与账户生命周期状态机的概念混淆（D1）

**问题描述**：
account-financial-model.md §5.1 定义了账户的"应用级生命周期状态机"（APPLICATION_SUBMITTED → ACTIVE → CLOSED），而 kyc-flow.md §5.1 定义了"KYC 工作流状态机"（KYC_DOCUMENT_PENDING → KYC_UNDER_REVIEW → ACTIVE）。两个状态机有重叠、有继承、有并行的关系，但规范中未明确说明。

**当前规范缺陷**：
- account-financial-model.md 中出现"PENDING_EDD"状态，但该状态在 account_status 字段中的地位不清（是持续状态还是临时状态？）
- kyc-flow.md 中的"ACTIVE"状态与 account-financial-model.md 中的"ACTIVE"含义是否相同？
- 两个状态机何时并行？（开户阶段）何时序列化？（激活后）

**改善方案**（约 200 字）：

1. **层级关系澄清**：
   - **KYC 工作流状态**（Workflow Level）：仅在开户阶段活跃，从 KYC_DOCUMENT_PENDING 到 KYC_COMPLETED（或 KYC_REJECTED）。生命周期 = 几小时到几天。
   - **账户生命周期状态**（Application Level）：从 APPLICATION_SUBMITTED（注册）到 CLOSED（账户注销），跨越用户的整个生命周期。

2. **映射关系**：
   ```
   KYC Flow State        →  Account Lifecycle State
   --------------------------------------------------
   KYC_DOCUMENT_PENDING  →  APPLICATION_SUBMITTED / CIP_PENDING
   KYC_UNDER_REVIEW      →  CIP_IN_PROGRESS
   KYC_MANUAL_REVIEW     →  COMPLIANCE_REVIEW
   KYC_REJECTED          →  REJECTED（终态）
   [KYC_COMPLETED]       →  ACTIVE（激活成功）
   ACCOUNT_BLOCKED       →  ACTIVE + aml_flags.sanctioned（平行状态）
   PENDING_EDD           →  ACTIVE（功能受限）或 ACCOUNT_PENDING（未激活）
   ```

3. **字段梳理**：
   - `account_status`：生命周期状态（应用层，PRIMARY）
   - `kyc_status`：当前 KYC 工作流状态（派生、仅开户阶段有意义）
   - `aml_flags`：AML 状态集合（JSON，可包含 `sanctioned: true` 等，与 account_status 正交）

4. **补充规范**：在 account-financial-model.md §5.4 新增"KYC 与账户状态的关系图"，用泳道图详述两个状态机的演化过程和同步点。

---

## 建议后续行动

| 优先级 | 行动项 | 责任方 | 完成期限 |
|--------|--------|--------|---------|
| 高 | 确认 ComplyAdvantage 对 HKJFIU 名单的覆盖（Plan A/B 决策）| Compliance + Vendor Management | **立即（本周内）** |
| 高 | Product 与 Engineering 同步确认 kyc-flow.md §13 的 7 个决策项，标注 deadline 和 decision owner | Product Manager + AMS Engineer | **下周之前** |
| 高 | 补充"docs/contracts/mobile-ams-kyc.md"，定义 Flutter 与 AMS 后端的 KYC 流程集成契约 | Mobile Engineer + AMS Engineer | **Planning Phase** |
| 高 | 新增"docs/specs/pii-encryption.md"权威规范，定义 AES-256-GCM 加密、密钥管理、脱敏规则 | Security Engineer + AMS Engineer | **Design Phase** |
| 中 | 补充"aml-compliance.md §7.4 CTR 申报数据接口"，扩展 Fund Transfer 需要查询的 AMS 字段 | AMS Engineer + Fund Transfer Engineer | **Spec 完成前** |
| 中 | 在 kyc-flow.md 中补充"§10.4 W-8BEN 续期的强制引导"和"§11 EDD 工作流"设计 | AMS Engineer + Product | **Design Phase** |
| 中 | 确定 STR 申报归属（Fund Transfer 还是独立合规服务），补充相应的跨服务契约 | Product + Fund Transfer Engineer + Compliance | **Planning Phase** |
| 低 | 整合分散的"制裁名单覆盖范围"定义，集中在 aml-compliance.md，其他文档引用 | AMS Engineer | **Spec 迭代** |

---

## 总体评价

**优势**：
- 三份 Spec（account-financial-model.md、kyc-flow.md、aml-compliance.md）结构清晰，覆盖范围全面
- 供应商选型的决策矩阵详细，包含可量化的评分标准
- 与行业调研的对应关系充分，监管引用准确

**主要风险**：
1. **决策缺失导致设计不完整**：7 个 KYC 待决策 + 7 个 AML 待决策 = 14 个"假设"，任何一个翻车都会推倒后续设计
2. **跨服务边界模糊**：AMS ↔ Fund Transfer ↔ Trading Engine 的数据流和事件流定义不够精细，易导致实现时的不同步
3. **状态机层级混淆**：KYC 工作流、账户生命周期、AML 风险评分三套状态机没有明确的层级和映射关系，可能在代码中产生冗余或遗漏
4. **规范编织度低**：key concept（例如 PENDING_EDD）在多份文档中重复定义且定义不一致

**建议优先级顺序**：
1. **立即确认 ComplyAdvantage 覆盖情况**（合规 blocking）
2. **补齐决策项，指定 deadline 和 decision owner**（架构 blocking）
3. **明确跨服务边界和数据契约**（实现 blocking）
4. **整合重复定义的概念，建立单一权威规范**（维护性问题）

---

*评审完成日期：2026-03-27*
*评审范围：kyc-flow.md v0.1、aml-compliance.md v0.1、account-financial-model.md v0.2-draft、auth-architecture.md v0.1、ams-industry-research.md*
