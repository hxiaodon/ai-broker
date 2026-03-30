# AMS 规格决策锁定 — 快速参考表

**生成日期**: 2026-03-30
**覆盖范围**: 14 项待决策项（7 KYC + 7 AML）
**状态**: ALL ITEMS LOCKED — 可立即进入编码阶段

---

## 决策一览表（快速查询）

| # | 决策项 | 规范 | 选项 | 优先级 | 代码影响 LOC | 依赖 |
|----|--------|------|------|--------|-----------|-----|
| 1 | MVP 联名账户 | kyc-flow.md | NO (Phase 2) | High | -300 | — |
| 2 | MVP 公司账户 | kyc-flow.md | NO (Phase 2) | High | -600 | 与决策1同步 |
| 3 | 大陆银行账户 | kyc-flow.md | 特例人工审批 | High | +100 | — |
| 4 | 虚拟银行接受 | kyc-flow.md | YES (HKMA牌照) | High | +50 | 决策3协作 |
| 5 | KYC申诉上限 | kyc-flow.md | 2次 + 人工第3次 | Medium | +100 | — |
| 6 | PI自动认定 | kyc-flow.md | 资产超门槛自动通过 | Medium | +200 | Sumsub OCR |
| 7 | KYC供应商 | kyc-flow.md | Sumsub首选 | High | 0 (架构) | — |
| 8 | AML制裁名单覆盖 | aml-compliance.md | 已确认✅ ComplyAdvantage | High | 0 (已确认) | — |
| 9 | AML风险评分权重 | aml-compliance.md | 建议值+合规签字 | High | +100 | 决策12关联 |
| 10 | World-Check二次确认 | aml-compliance.md | Admin Panel人工查询 | Medium | +150 | 决策12关联 |
| 11 | 筛查超时行为 | aml-compliance.md | 默认通过✅ | High | 0 (已确认) | — |
| 12 | EDD SLA分层 | aml-compliance.md | 10/8/5天三层 | High | +300 | 决策9/10关联 |
| 13 | SAR申报 | aml-compliance.md | Compliance Service | High | Phase 2* | 决策14关联 |
| 14 | STR申报 | aml-compliance.md | Compliance Service | High | Phase 2* | 决策13关联 |

*注: 决策13/14属"架构决策"，Phase 1 MVP不含Compliance Service，留作Phase 2（M1）。

---

## 核心指标速查

### KYC 流程指标
- **MVP 账户类型**: 仅 INDIVIDUAL
- **HK银行验证额**: HK$10,000（AMLO要求）
- **虚拟银行**: 接受HKMA牌照（Mox、ZA Bank）
- **大陆银行**: 特例通过（合规团队人工）
- **KYC拒绝申诉**: 最多2次自助 + 1次人工第3次
- **PI自动认定**: 资产≥HK$800万 + OCR信心度>95% 且文件≤3个月

### AML 指标
- **制裁筛查**: ComplyAdvantage（分钟级更新，含HK JFIU）
- **PEP筛查**: ComplyAdvantage异步（asynq，3次重试）
- **风险评分**:
  - LOW (0-30分): 自动批准出金
  - MEDIUM (31-60分): 人工审核出金
  - HIGH (61-100分): 触发EDD + 限制操作
- **EDD SLA分层**:
  - Tier 1 (资产<HK$500万): 10工作日
  - Tier 2 (资产HK$500万-$2000万): 8工作日
  - Tier 3 (资产>HK$2000万): 5工作日 + 快速通道
- **World-Check**: 仅EDD案件的人工二次确认（Admin Panel）
- **筛查超时**: 默认通过 + 告警 + 24h全量重新筛查补救

---

## 代码实现规划

### Phase 1 MVP (2026-04-14 启动)

**KYC 模块 (~1500 LOC)**:
- 删除: 联名账户、公司账户的状态机（-900 LOC）
- 新增: 申诉计数器、PI自动认定、大陆银行特例队列 (+500 LOC)
- 修改: 银行名单管理支持虚拟银行 (+50 LOC)

**AML 模块 (~1200 LOC)**:
- 无新增（制裁覆盖已确认）
- 实现: AML风险评分权重计算、EDD工作流三层SLA、World-Check Admin Panel API

**Admin Panel 扩展 (~800 LOC)**:
- 新增: EDD待审核队列（Tier分层）、申诉管理队列、World-Check查询界面

**总计**: ~3500 LOC Go + ~800 LOC 前端

**工期**: 4周（2026-04-14 — 2026-05-11）

### Phase 2 (M1) — 待定

- 联名账户支持（2-3周）
- 公司账户+UBO穿透（3-4周）
- 独立Compliance Service（CTR+SAR+STR, 2周）

---

## 交叉依赖确认

### 无冲突✅
- 决策1/2并行（联名+公司同时排除）
- 决策3/4协作（大陆银行+虚拟银行）
- 决策13/14共用Compliance Service（Phase 2同期）

### 依赖项确认
- 决策6 (PI自动认定) → 需Sumsub提供OCR confidence score（已验证✅）
- 决策9 (AML权重) → 需合规官签字确认（待执行）
- 决策12 (EDD SLA) → 需与决策9/10协调（决策9完成后可推进）

---

## 签字确认清单

### 必须在2026-03-30 EOD前完成

| 角色 | 确认项 | 签字 | 日期 |
|------|--------|------|------|
| PM (AMS) | 决策1-7 (KYC范围/供应商/流程) | [ ] | — |
| Compliance Officer | 决策8-14 (AML/SAR/STR) | [ ] | — |
| Tech Lead | 所有决策的代码可行性评审 | [ ] | — |
| Fund Transfer Lead | 决策3/4/12对出金流程的影响评估 | [ ] | — |
| Mobile Lead | 决策1-6对KYC UI的影响评估 | [ ] | — |

---

## 立即行动清单（2026-03-30）

- [ ] 本文档传送至各域负责人
- [ ] 获取上表所有签字（4小时内）
- [ ] 更新规范文档：kyc-flow.md, aml-compliance.md 的"决策项"从OPEN变LOCKED
- [ ] 生成跨服务契约更新清单（docs/contracts/ams-to-trading.md, ams-to-fund.md）
- [ ] AMS工程启动Planning: 排期、任务分解、依赖关系确认
- [ ] 工程编码启动: 2026-04-14

---

## 参考文档

- 完整决策文档: `/temp/spec-decisions-lockdown.md` (877行)
- KYC规范: `services/ams/docs/prd/kyc-flow.md`
- AML规范: `services/ams/docs/prd/aml-compliance.md`
- 账户模型: `services/ams/docs/specs/account-financial-model.md`
- 评审报告: `services/ams/docs/evaluation/PRD-SPEC-REVIEW.md`
- 工程阻塞: `services/ams/docs/threads/engineering-kickoff-blockers.md`

---

**状态**: LOCKED ✅
**版本**: 1.0
**生效**: 2026-04-14
**有效期**: 12个月（2027-03-30重评）

