# AMS 工程启动建议 — 阻塞项、技术风险与跨域对齐

> **版本**: v0.2
> **日期**: 2026-03-28
> **作者**: AMS Engineering
> **状态**: 部分对齐，5 项已决策，5 项待执行
>
> 本文汇总在 AMS 开始编码前必须解决的阻塞性决策、需提前规避的技术坑，以及需要跨域对齐的边界问题。所有待决事项用 `🔲 待决策` 标注，已有建议方向的用 `✅ 建议` 标注。

---

## 目录

1. [阻塞性决策（写代码前必须敲定）](#1-阻塞性决策写代码前必须敲定)
2. [需提前规避的技术坑](#2-需提前规避的技术坑)
3. [跨域边界对齐（建议召开对齐会）](#3-跨域边界对齐建议召开对齐会)
4. [监管细节澄清](#4-监管细节澄清)
5. [行动项汇总](#5-行动项汇总)

---

## 1. 阻塞性决策（写代码前必须敲定）

以下 3 个问题不确定，会导致已写代码大幅返工。**建议在第一个 Sprint 开始前完成**。

---

### 1.1 KYC 供应商 POC 验证

**背景**：调研结论建议选用 Sumsub，但其 HKID 识别率（97.89%）和居民身份证识别质量均为**供应商自报数字**，未经第三方验证。

**阻塞原因**：供应商选型直接决定 Go 后端集成架构（SDK Token 流程、Webhook 事件格式、状态机触发方式），一旦开始集成再换供应商，所有对接代码全部推倒重写。

**✅ 建议行动**：
1. 本周内联系 Sumsub 申请沙箱 API Key（通常数小时内可获得）
2. 准备测试样本：HKID（新旧版本各 5 张）、居民身份证（5 张）、美国护照/驾照（5 张）
3. 测试指标：识别成功率、OCR 字段准确率、活体检测通过率
4. POC 预期周期：**1-2 个工作日**即可得出结论

**🔲 待决策**：POC 结果出来后，由 PM + 合规负责人最终确认供应商，结论需书面记录（供日后 HKMA 检查时的供应商尽职调查答复）。

> ⚠️ **2026-03-28 注**：供应商已初步选定 Sumsub，但 HKID/居民身份证实测 POC **尚未完成**。这是编码前的真实技术风险，需在 Sprint 1 开始前执行。

> 参考文档：`docs/prd/kyc-flow.md` §1（供应商评分矩阵）

---

### 1.2 ComplyAdvantage 对 HK JFIU 国内名单的覆盖确认

**背景**：AML 方案选用 ComplyAdvantage 作为制裁/PEP 筛查供应商。其对 OFAC、UN、EU 名单的覆盖已确认，但对**香港 JFIU 国内指定名单**的覆盖情况在公开文档中未明确说明。

**阻塞原因**：
- 如果 ComplyAdvantage 不覆盖 HK JFIU 名单，需要自建同步脚本（每日从 JFIU 官网拉取，验证数字签名，写入内部筛查库）
- 这是额外的开发工作量和合规运维负担，需提前纳入排期

**✅ 建议行动**：
1. 发邮件给 ComplyAdvantage 销售/技术支持，明确询问："Do you cover the Hong Kong JFIU domestic designated persons list under UNATMO/UNSO?"
2. 要求书面回复（截图/邮件存档，作为合规尽职调查记录）
3. 预期回复时间：1-3 个工作日

**✅ 已决策** (2026-03-28)：Plan B 确定 — 混合方案（ComplyAdvantage 主要 + LSEG World-Check HK 补充）
- 决策依据：`temp/aml-vendor-coverage-matrix.md` 供应商对比矩阵
- 供应商确认截止：2026-03-31
- 实施路径：先确认 ComplyAdvantage HK 覆盖状态，若不覆盖则启动 LSEG World-Check 集成
- 相关文件已更新：`ams-fund-transfer-aml.md` §1.1 明确 Plan B 的两家供应商分工

> 参考文档：`docs/prd/aml-compliance.md` §1.1、§12 开放决策点 #1

---

### 1.3 MVP 范围：联名账户和公司账户是否进入 Phase 1

**背景**：
- **联名账户（Joint Account）**：两位申请人 KYC 须同时通过，状态机需同时追踪两条 KYC 线，任一拒绝则整体拒绝
- **公司账户（Corporate Account）**：需 UBO 穿透识别（≥25% 持股自然人逐层穿透），每位 UBO 单独 KYC，额外需要公司章程、董事会决议等文件，人工审核 SLA 5 个工作日

**阻塞原因**：这个决策直接影响 KYC 状态机的设计复杂度：

| 账户类型 | 状态机复杂度 | 开发工期影响 |
|----------|-------------|-------------|
| 仅个人账户 | 1 条状态线 | 基准 |
| 含联名账户 | 2 条状态线 + 汇聚逻辑 | +40% 估算 |
| 含公司账户 | 树状 UBO 子图 + 额外文件流程 | +80% 估算 |

**✅ 建议**：Phase 1 仅支持个人账户（`INDIVIDUAL`）。联名账户和公司账户放入 Phase 2。理由：
- 个人账户覆盖绝大多数早期用户需求
- 先上线、先获取真实用户反馈，再扩展复杂账户类型
- 公司账户的 UBO 穿透流程需要专门的合规团队培训，不适合 MVP 阶段

**✅ 已决策** (2026-03-30)：Phase 1 仅支持个人账户（`INDIVIDUAL`）
- 决策依据：`temp/spec-decisions-lockdown.md` 决策 #1/#2（联名账户、公司账户推迟到 Phase 2）
- 实施范围：account-financial-model.md 中 `client_type` 仅支持 INDIVIDUAL 字段
- 联名账户和公司账户：放入 Phase 2 路线图
- 相关更新：kyc-flow.md 中 §7 (联名) §8 (公司) 标记为 Phase 2

> 参考文档：`docs/prd/kyc-flow.md` §7（联名账户）、§8（公司账户）、`docs/specs/account-financial-model.md` §2.1

---

## 2. 需提前规避的技术坑

---

### 2.1 Sumsub 多次 Webhook — 状态机必须支持回退

**问题描述**：

Sumsub 官方文档明确说明，可能对同一 `applicantId` 发送**多次** `applicantReviewed` 事件。典型场景：
1. 自动审核返回 `GREEN`（通过）→ AMS 激活账户
2. Sumsub 后台欺诈检测（滞后数分钟）返回 `RED`（撤销）→ AMS 收到第二次 Webhook

如果状态机只处理第一次事件，且不允许 `ACTIVE → SUSPENDED` 回退，会出现**已激活账户应该被关闭**的合规漏洞。

**✅ 建议设计**：

```
KYC 状态机规则：
- 所有状态转换以"最新事件"为准，不以"第一次事件"为准
- ACTIVE → SUSPENDED 必须是合法转换（不允许单向锁定）
- Webhook 处理器必须幂等：同一 applicantId + 同一 reviewAnswer 的重复事件幂等忽略
- 不同 reviewAnswer 的后续事件：触发状态重新评估
```

**需要在代码评审中检查**：
- [ ] KYC Webhook Handler 是否幂等
- [ ] 状态机是否允许 `ACTIVE → SUSPENDED`
- [ ] 是否有单元测试覆盖"先GREEN后RED"场景

---

### 2.2 Blind Index 密钥与 KMS 密钥必须严格隔离

**问题描述**：

PII 加密方案中有**两套独立密钥**：
- **KMS CMK**（AWS KMS）：用于加密 DEK，保护 SSN/HKID 密文
- **Blind Index Secret**（AWS Secrets Manager）：用于 HMAC/PBKDF2，生成可查询的摘要

这两个密钥的用途完全不同，**绝不能共用同一密钥**。若共用：
- KMS CMK 泄露 → 攻击者既能解密密文，又能枚举所有 SSN 的 Blind Index
- 影响范围从"解密数据"扩大到"枚举所有用户身份"

**✅ 建议**：在 Go 代码中使用不同类型强制区分，编译期防止混用：

```go
// 类型系统强制隔离，编译期报错防止混用
type PIIEncryptionKey struct{ handle *keyset.Handle }
type BlindIndexKey    struct{ secret []byte }

// PIIEncryptor 只接受 PIIEncryptionKey，不接受 BlindIndexKey
func NewPIIEncryptor(key PIIEncryptionKey) *PIIEncryptor { ... }

// BlindIndexer 只接受 BlindIndexKey，不接受 PIIEncryptionKey
func NewBlindIndexer(key BlindIndexKey) *BlindIndexer { ... }
```

**需要在代码评审中检查**：
- [ ] 两套密钥是否从不同的 AWS 资源加载（KMS vs Secrets Manager）
- [ ] 是否有任何地方将同一 `[]byte` 传入两个不同用途

> 参考文档：`docs/specs/pii-encryption.md` §5（Blind Index）、§2（KMS 选型）

---

## 3. 跨域边界对齐（建议召开对齐会）

以下问题涉及多个服务的职责边界。**建议在 AMS + Fund Transfer + Admin Panel 的工程负责人之间召开一次对齐会，统一结论后各自写入本域的 CLAUDE.md**。

---

### 3.1 CTR 申报：谁负责填写 FinCEN Form 104？

**✅ 已决策** (2026-03-28)：方案 A — Fund Transfer 全权负责 CTR 申报
- 决策依据：`ams-fund-transfer-aml.md` §5（CTR/STR 归属）和 `temp/spec-decisions-lockdown.md` 决策 #13
- 实施细节：
  - Fund Transfer 检测出金额 > $10k 阈值
  - 调用 AMS gRPC `GetKYCProfile` 获取账户身份信息
  - Fund Transfer 独立生成并提交 FinCEN CTR 表单
  - AMS 不参与 CTR 触发逻辑，只提供数据查询接口
- 相关文件：`ams-fund-transfer-aml.md` 已定义 `GetKYCProfile` gRPC 接口签名

---

### 3.2 STR 申报（HK）：独立合规服务还是挂在 Fund Transfer 下？

**✅ 已决策** (2026-03-28)：方案 B — 独立合规服务（Compliance Service）
- 决策依据：`ams-fund-transfer-aml.md` §11（STR 申报责任）和 `temp/spec-decisions-lockdown.md` 决策 #14
- 实施职责：
  - **CTR**：Fund Transfer 自动申报（由 AML screening 结果触发）
  - **STR/SAR**：独立 Compliance Service 负责（消费 AMS AML screening 事件，合规官人工审批后通过 JFIU STREAMS 2 提交）
  - **FATCA/CRS** 年度申报：Compliance Service 负责
  - **监管报告生成**：Compliance Service 负责
- 优先级：Compliance Service 列入 Phase 1b（KYC/AML MVP 后立即上线，供应商确认前）
- 相关文件：`ams-fund-transfer-aml.md` §11 已明确 SAR/STR 分工

**备注**：Compliance Service 架构已在 `ams-fund-transfer-aml.md` 中定义，等待架构评审确认

---

### 3.3 账户风险评分变更如何通知 Fund Transfer？

**背景**：当 AMS 更新账户 `aml_risk_score`（如从 LOW 升为 HIGH），Fund Transfer 服务需要知道，以调整出金审批策略（HIGH 风险账户出金须人工审核）。

**✅ 建议**：AMS 通过 Kafka 事件异步通知，Fund Transfer 订阅：

```
Topic: ams.aml.flagged
Payload: { account_id, new_risk_score, reason, flagged_at }
```

Fund Transfer 消费此事件，更新本地缓存的风险评级。**不建议 Fund Transfer 每次出金都实时调用 AMS API 查询风险评分**（增加延迟，且造成强依赖）。

**🔲 待决策**：Fund Transfer 工程负责人确认此事件驱动方案，并在其 CLAUDE.md 中记录消费的 Kafka Topic 列表。

---

### 3.4 Trading Engine 验证账户状态：信任 JWT 还是实时查 AMS？

**背景**：JWT 中嵌入了 `account_status` 字段，Trading Engine 可以本地验证无需网络调用。但 JWT 有最长 15 分钟的有效期，在这段时间内账户状态可能已经被 AMS 修改（如合规冻结）。

**✅ 建议**：双重策略：

| 操作 | 验证方式 | 理由 |
|------|---------|------|
| 行情查询、持仓查询 | 信任 JWT 中的 `account_status` | 低风险，本地验证足够 |
| 下单（买/卖） | 实时调用 AMS gRPC `ValidateAccount` | 高风险操作，必须实时确认 |
| 出金申请 | 实时调用 AMS gRPC | 高风险操作 |
| 修改账户设置 | 实时调用 AMS gRPC | 中风险 |

**🔲 待决策**：Trading Engine 工程负责人确认哪些操作触发实时 AMS 查询，并在 `docs/contracts/ams-to-trading.md` 中更新接口规约。

---

## 4. 监管细节澄清

这些细节容易被混淆，建议在 PRD 和前端文案中明确区分，并与 PM 对齐后同步给移动端和 Admin Panel。

---

### 4.1 W-8BEN 到期 ≠ 账户被限制交易

### 4.1 W-8BEN 到期 ≠ 账户被限制交易

**✅ 已决策** (2026-03-28)：权限矩阵已定义，写入 `state-machine-relations.md` §3
- 决策依据：`temp/spec-decisions-lockdown.md` 决策 #6 和 `w8ben-lifecycle.md` 完整工作流
- 权限影响矩阵：

| 情形 | 交易影响 | 出金影响 | 股息影响 |
|------|---------|---------|---------|
| W-8BEN 到期 | ✅ **正常** | ✅ 正常 | ❌ **冻结 + 30% FATCA 预扣** |
| 制裁名单命中 | ❌ 全冻结 | ❌ 全冻结 | ❌ 全冻结 |
| AML 风险 HIGH | ⚠️ 视策略 | ❌ 需审批 | ⚠️ 视标记 |
| KYC 未完成 | ⚠️ 限制 | ❌ 限制 | ⚠️ 限制 |

- 实施方式：state-machine-relations.md §4（角色化可见性）已定义不同角色看到的权限规则
- 相关文件：w8ben-lifecycle.md 已包含权限限制的完整定义

**待执行**：移动端和 Admin Panel CLAUDE.md 需同步此矩阵参考

---

### 4.2 账户"限制"的用户可见原因：泛化描述规范

### 4.2 账户"限制"的用户可见原因：泛化描述规范

**✅ 已决策** (2026-03-28)：SAR Tipping-off 防护规范已写入 `security-review.md` 和 `ams-fund-transfer-aml.md`
- 决策依据：`temp/code-review-findings.md` Threat 2.1（SAR 泄露防止）
- 完整的分级披露规范：

| 限制原因 | 可对用户说的内容 | 不可说的内容 |
|----------|----------------|-------------|
| KYC 未完成 | "请完成身份验证以解锁此功能" | — |
| W-8BEN 到期 | "您的税务申报表已到期，股息将被暂扣，请及时更新" | — |
| PI 资格到期 | "您的专业投资者资格已过期，部分产品暂不可用" | — |
| **AML/制裁相关** | **"您的账户已被临时限制。如有疑问，请联系客服"** | **✅ 绝对禁止**：任何 "AML审查"、"SAR"、"制裁名单"、"合规冻结"等词汇 |
| 系统风控 | "您的账户存在异常，请联系客服" | 具体风控规则 |

- 实施方式：ams-fund-transfer-aml.md §2（SAR Tipping-off Prevention）定义了 5 层防护机制
- 相关测试：code-review-findings.md 中已定义完整的集成测试用例

**待执行**：移动端和 Admin Panel 的错误消息需经过合规审核，确保无 SAR 关键词泄露

---

## 5. 行动项汇总

| # | 行动项 | 负责人 | 截止建议 | 状态 |
|---|--------|--------|----------|------|
| 1 | **[CRITICAL] Sumsub HKID/居民身份证 POC 实测** | 工程 + PM | 编码前 | 🔲 **待执行** — 必须在 Sprint 1 开始前完成 |
| 2 | **[DONE] ComplyAdvantage HK JFIU 覆盖确认** | 工程 + 合规 | 2026-03-31 | ✅ **已决策** — Plan B（混合方案）确定，供应商合同签署中 |
| 3 | **[DONE] Phase 1 账户类型范围** | PM + 合规 | 2026-03-30 | ✅ **已决策** — 仅个人账户（INDIVIDUAL），联名/公司推迟 Phase 2 |
| 4 | **[PENDING] 跨域对齐会** | 架构负责人 | 2026-04-01 | 🔲 **待安排** — 需邀请 Trading + Fund Transfer + Admin Panel Lead |
| 5 | **[DONE] CTR 申报归属** | 架构负责人 | 2026-03-30 | ✅ **已决策** — Fund Transfer 全权负责，AMS 提供 GetKYCProfile 接口 |
| 6 | **[PENDING] Trading Engine 实时查询范围** | Trading + AMS Lead | 2026-04-05 | 🔲 **待对齐** — 需在跨域会中确认操作粒度 |
| 7 | **[PENDING] 更新 `docs/contracts/ams-to-trading.md`** | AMS + Trading | 2026-04-08 | 🔲 **待执行** — 依赖行动项 #6 对齐 |
| 8 | **[DONE] 账户状态 × 功能权限矩阵** | PM + AMS | 2026-03-30 | ✅ **已决策** — 写入 state-machine-relations.md §3-4，权限影响表已定义 |
| 9 | **[DONE] SAR 分级披露规范** | PM + 合规 | 2026-03-30 | ✅ **已决策** — SAR Tipping-off 防护 5 层机制已定义，security-review.md 中详述 |
| 10 | **[PENDING] 同步决策至 mobile / Admin Panel CLAUDE.md** | AMS Lead | 2026-04-15 | 🔲 **持续** — 待以上项目完成后统一同步 |

---

---

## 📋 对齐进度总结（2026-03-28）

### ✅ 已决策 (5 项)
| # | 决策项 | 状态 | 关键文件 |
|---|--------|------|---------|
| 2 | ComplyAdvantage HK JFIU 覆盖 | ✅ Plan B（混合） | aml-vendor-coverage-matrix.md |
| 3 | Phase 1 账户类型 | ✅ 仅个人账户 | spec-decisions-lockdown.md |
| 5 | CTR 申报归属 | ✅ Fund Transfer 负责 | ams-fund-transfer-aml.md |
| 8 | 权限矩阵 | ✅ 已定义 | state-machine-relations.md |
| 9 | SAR 披露规范 | ✅ 5 层防护 | security-review.md |

### 🔲 待执行 (5 项)
| # | 待执行项 | 优先级 | 关键性 |
|---|---------|--------|--------|
| 1 | Sumsub HKID POC 实测 | 🔴 CRITICAL | **编码前必须完成** |
| 4 | 跨域对齐会 | 🟠 HIGH | 需协调 Trading/Fund Transfer |
| 6 | Trading 查询范围确认 | 🟠 HIGH | 依赖对齐会 |
| 7 | 更新 ams-to-trading 合同 | 🟡 MEDIUM | 依赖项 #6 |
| 10 | 同步至 mobile/admin CLAUDE.md | 🟡 MEDIUM | 编码前完成 |

### 最高优先级阻塞项
**Sumsub POC 实测** (行动项 #1)：
- Sumsub 的 HKID 识别率 97.89% 是供应商自报，未经第三方验证
- 风险：若实测识别率过低，开始集成后再换供应商，所有代码推倒重写
- 建议：本周内申请沙箱 Key，用真实样本跑 1-2 天 POC
- 预期结果：1-2 个工作日内确定可行性

---

*最后更新：2026-03-28*
*维护人：AMS Engineering Lead*
