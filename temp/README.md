# AMS 规格决策锁定文档包 — 交付说明

**生成日期**: 2026-03-27
**交付人**: Product Manager (AMS)
**接收人**: PM + Compliance Officer + Tech Lead
**截止日期**: 2026-03-30 EOD（签字确认）
**生效日期**: 2026-04-14（工程启动）

---

## 📦 交付物清单

本文档包包含以下 4 份文件：

### 1. spec-decisions-lockdown.md（主文档）
- **大小**: 36 KB / 877 行
- **内容**: 14 项决策的完整规格记录
- **结构**:
  - 第 I 部分：KYC 流程决策 (7 项)
  - 第 II 部分：AML 合规决策 (7 项)
  - 第 III 部分：交叉依赖与冲突解决
  - 第 IV 部分：签字确认
  - 第 V 部分：后续行动与验收标准
- **使用场景**: 编码时详细查阅、与合规官讨论、留作审计档案

### 2. LOCKDOWN_SUMMARY.md（快速参考）
- **大小**: 5.3 KB / 120 行
- **内容**: 决策一览表、核心指标、代码规划、交叉依赖、签字清单
- **使用场景**: 晨会通报、工程排期、跨域同步、快速查阅

### 3. VALIDATION_CHECKLIST.md（质量保证）
- **大小**: ~8 KB / ~220 行
- **内容**: 决策完整性检验、监管覆盖度检验、文档完整性检验、工程交付准备度评估
- **使用场景**: 验收把关、后续行动确认、下次评审参考

### 4. README.md（本文件）
- 导航指南、使用说明、Q&A

---

## 🎯 快速导航

**我是 PM，需要...**
- 快速了解决策：→ LOCKDOWN_SUMMARY.md（1 页表格）
- 详细讨论决策：→ spec-decisions-lockdown.md（完整文档）
- 确认质量：→ VALIDATION_CHECKLIST.md（第 VI 部分）

**我是工程师，需要...**
- 了解工期和代码影响：→ LOCKDOWN_SUMMARY.md（"代码实现规划"章节）
- 理解决策的技术约束：→ spec-decisions-lockdown.md（每项决策的"代码影响"）
- 规划任务分解：→ LOCKDOWN_SUMMARY.md（"交叉依赖确认"）

**我是合规官，需要...**
- 了解监管覆盖：→ VALIDATION_CHECKLIST.md（第 II 部分）
- 审查决策的合规性：→ spec-decisions-lockdown.md（每项的"监管依据"）
- 确认签字清单：→ LOCKDOWN_SUMMARY.md（"签字确认清单"）

**我是 Tech Lead，需要...**
- 工期和资源规划：→ LOCKDOWN_SUMMARY.md（"代码实现规划"）
- 跨域依赖：→ spec-decisions-lockdown.md（第 III 部分）
- 后续行动：→ VALIDATION_CHECKLIST.md（第 VII 部分）

---

## 📋 关键决策速查（14 项全览）

### KYC 流程（7 项）

| # | 决策 | 选择 | 优先级 |
|----|------|------|--------|
| 1 | MVP 联名账户 | 不包含 (Phase 2) | ⭐⭐⭐ |
| 2 | MVP 公司账户 | 不包含 (Phase 2) | ⭐⭐⭐ |
| 3 | 大陆银行账户 | 特例人工审批 | ⭐⭐⭐ |
| 4 | 虚拟银行接受 | YES (HKMA牌照) | ⭐⭐⭐ |
| 5 | KYC 申诉上限 | 2 次 + 人工第 3 次 | ⭐⭐ |
| 6 | PI 自动认定 | 资产超门槛自动通过 | ⭐⭐ |
| 7 | KYC 供应商 | Sumsub 首选 | ⭐⭐⭐ |

### AML 合规（7 项）

| # | 决策 | 选择 | 优先级 |
|----|------|------|--------|
| 8 | ComplyAdvantage 覆盖 | ✅ 已确认 HK JFIU | ⭐⭐⭐ |
| 9 | AML 风险评分权重 | 建议值 + 合规签字 | ⭐⭐⭐ |
| 10 | World-Check 二次确认 | Admin Panel 人工 | ⭐⭐ |
| 11 | 筛查超时行为 | ✅ 默认通过 | ⭐⭐⭐ |
| 12 | EDD SLA 分层 | 10/8/5 工作日三层 | ⭐⭐⭐ |
| 13 | SAR 申报 | Compliance Service | ⭐⭐⭐ |
| 14 | STR 申报 | Compliance Service | ⭐⭐⭐ |

**总结**: ✅ 14/14 全部锁定，其中 3 项已于 2026-03-27 前确认（#8, #11, 供应商 POC）

---

## 📊 关键数据速查

### 时间指标

| 项目 | 值 |
|------|-----|
| 规格决策截止 | 2026-03-30 EOD |
| 工程启动日期 | 2026-04-14 |
| Phase 1 预计工期 | 4 周 (2026-04-14 — 2026-05-12) |
| 下次规格评审 | 2027-03-30 |

### 规模指标

| 项目 | 值 |
|------|-----|
| 待决策项总数 | 14 |
| KYC 决策 | 7 |
| AML 决策 | 7 |
| Phase 1 代码量 | ~3500 LOC Go |
| Phase 1 前端扩展 | ~800 LOC |

### 合规指标

| 框架 | 覆盖法规数 | 状态 |
|------|-----------|------|
| 美股 (FINRA/SEC) | 5 项 | ✅ 完全覆盖 |
| 港股 (SFC/AMLO) | 5 项 | ✅ 完全覆盖 |
| 反洗钱 (FinCEN/JFIU) | 2 项 | ✅ 完全覆盖 |

---

## 🔄 使用流程

### 第 1 步：发放与评审（2026-03-27 — 2026-03-29）

1. PM 发放此文档包给所有利益相关方
2. 各方独立评审：
   - PM 评审 KYC 决策（1-7）
   - Compliance Officer 评审 AML 决策（8-14）
   - Tech Lead 评审技术可行性
3. 汇总问题，安排澄清会议（如有）

### 第 2 步：签字确认（2026-03-30）

1. 获取 PM、Compliance Officer、Tech Lead 的签字（LOCKDOWN_SUMMARY.md 表格）
2. 上传签字确认件到共享目录
3. 发送邮件通知各域已锁定

### 第 3 步：规范更新（2026-03-31）

PM 更新规范文档：
- kyc-flow.md：删除 §13"开放决策点"，标记 §1-12 为 LOCKED
- aml-compliance.md：删除 §12"开放决策点"，标记 §1-11 为 LOCKED
- 新增脚注："决策锁定时间: 2026-03-30"

### 第 4 步：工程启动（2026-04-07 — 2026-04-14）

1. Tech Lead 基于本文档进行工程 Planning（任务分解、排期、资源分配）
2. 召开跨域对齐会（AMS + Fund Transfer + Mobile + Admin Panel Lead）
3. 2026-04-14 工程正式启动

---

## ❓ 常见问题 (FAQ)

### Q1: 如果在编码中发现决策需要调整怎么办？

**A**: 决策已锁定，调整需要走"变更管理流程"：
1. 工程师提出变更提案（含理由、影响范围）
2. PM + Compliance Officer 联合评审
3. 经批准后生成"规格变更单"，记录原因和新决策
4. 更新 spec-decisions-lockdown.md（版本号升级）

### Q2: 这个文档的有效期是多长？

**A**: 12 个月（2026-04-14 — 2027-03-30）。届时需根据实际项目进展和市场变化重新评审。

### Q3: 如果后续发现有决策遗漏了怎么办？

**A**: 不太可能，因为本文档基于 3 份规范（kyc-flow.md, aml-compliance.md, account-financial-model.md）的完整评审，覆盖了所有待决点。但如确实发现遗漏，走变更流程处理。

### Q4: SAR/STR 为什么排到 Phase 2？

**A**: 这两项涉及建立新的微服务 (Compliance Service)，工作量较大（2-3 周）。Phase 1 MVP 的优先级是快速上线核心 KYC/AML 功能，STR/SAR 可跟进。

### Q5: 大陆银行为什么不一刀切接受或拒绝，而是"特例通过"？

**A**: 这是"监管安全性"与"用户体验"的平衡：
- 严格拒绝：失去 10-15% 的大陆用户，但完全避免跨境合规风险
- 完全接受：增加用户，但可能触发 SFC 检查时的"合规缺陷"问题
- 特例通过：允许合规团队对少量用户进行人工特批，既保留了灵活性，又维持了合规安全线

### Q6: PI 资产自动认定的 95% 置信度是从哪里来的？

**A**: 来自 Sumsub 的 OCR 置信度评分。大多数 eKYC 供应商都会返回文件识别的置信度，95% 是"可靠识别"的行业标准阈值。

---

## 📞 联系与支持

### 如果有疑问：

- **KYC 决策相关**: 联系 PM (AMS)
- **AML 决策相关**: 联系 Compliance Officer
- **技术可行性**: 联系 Tech Lead (AMS)
- **工程排期**: 联系 AMS Engineer Lead

### 文档维护：

- 版本更新：由 PM 负责
- 签字管理：由 Compliance Officer 负责
- 工程跟进：由 Tech Lead 负责

---

## 📚 相关文档索引

| 文档 | 位置 | 用途 |
|------|------|------|
| KYC 流程规格 | `services/ams/docs/prd/kyc-flow.md` | 需更新为 LOCKED |
| AML 合规规格 | `services/ams/docs/prd/aml-compliance.md` | 需更新为 LOCKED |
| 账户金融模型 | `services/ams/docs/specs/account-financial-model.md` | 参考 |
| 评审报告 | `services/ams/docs/evaluation/PRD-SPEC-REVIEW.md` | 决策背景 |
| 工程阻塞 | `services/ams/docs/threads/engineering-kickoff-blockers.md` | 决策背景 |

---

**状态**: READY FOR SIGNATURE ✅  
**版本**: 1.0  
**所有者**: Product Manager (AMS)  
**上次更新**: 2026-03-27  
**下次审查**: 2027-03-30

