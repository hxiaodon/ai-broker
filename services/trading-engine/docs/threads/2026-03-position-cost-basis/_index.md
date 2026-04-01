---
thread: position-pnl-cost-basis-method
type: lightweight
status: RESOLVED
priority: P1
opened_by: trading-engineer
opened_date: 2026-03-27T16:10+08:00
resolved_date: 2026-03-30T18:00+08:00
incorporated_date: 2026-03-30T18:00+08:00
participants:
  - trading-engineer
  - product-manager
requires_input_from: []
affects_specs:
  - mobile/docs/prd/06-portfolio.md §6.1 ✅
  - services/trading-engine/docs/prd/position-pnl.md §1 ✅
resolution: |
  **RESOLVED**（2026-03-30）

  ✅ PM 决策：采用加权均价法（Weighted Average Cost）
  ✅ 适用范围：Phase 1（美股）和 Phase 2（港股）
  ✅ 业务依据：实现简洁、税务合规、用户友好、美港股统一

  文档更新：
  - position-pnl.md §1.1：改为确定方案 + 4 点业务依据
  - position-pnl.md §1.4：PM 决策说明 + 未来升级路径（Phase 3 支持 FIFO）
  - 06-portfolio.md §6.1：移除"待澄清"，改为 PM 确认方案

  代码影响：无需改动现有实现（已采用加权均价法）

incorporated_commits:
  - 443caeb (docs(prd): PM clarification — cost basis method)
---

# 持仓成本基础方法：FIFO vs 加权均价 — RESOLVED

## 问题回顾

`mobile/docs/prd/06-portfolio.md` §6.1 的标题说"FIFO 原则"，但正文计算是加权均价法。
两者是不同的会计方法，需要澄清。

## PM 决策（2026-03-30）

### 选定方案：加权均价法

**采用加权均价法（Weighted Average Cost）计算成本基础**，适用于：
- ✅ Phase 1（美股）
- ✅ Phase 2（港股）

### 4 点业务依据

1. **实现简洁** — 仅维护单个均价值，无需复杂批次链表，符合 MVP 快速交付要求
2. **税务合规** — IRS 明确允许加权均价法用于美国报税，无额外税务复杂性
3. **用户体验** — 用户理解直观，持仓均价即实际均价
4. **美港股统一** — Phase 1 和 Phase 2 都采用同一方法，避免用户困惑

### 未来升级路径

如 Phase 2 需要更精细的成本管理或用户要求个性化选择，可在 Phase 3 支持 FIFO 或用户自选。
预计工作量：20-25 人天

---

## 文档更新 ✅

### position-pnl.md

- **§1.1 新增** — "确定方案：加权均价法"，明确列出 4 点业务依据
- **§1.4 更新** — "PM 决策说明（已确认）"，补充未来升级路径

### 06-portfolio.md

- **§6.1 修改** — 移除"待澄清"标记，改为"PM 确认方案"说明
- **脚注** — 指向 Domain PRD position-pnl.md §1.1

---

## 代码影响

✅ **无需改动** — 现有实现已采用加权均价法，决策与代码一致

---

## 后续行动

- [x] PM 确认方案
- [x] 更新 Domain PRD
- [x] 更新 Surface PRD
- [ ] 待法务确认 GTC 90 天上限（相关但不阻断）

此 Thread 已完全解决。
