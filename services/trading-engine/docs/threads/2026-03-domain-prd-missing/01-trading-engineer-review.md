---
seq: 01
author_role: trading-engine-engineer
date: 2026-03-27T16:00+08:00
action: RAISE_ISSUE
---

# 交易域 Domain PRD 缺失 + Surface PRD 内容错位审查报告

## 背景

本次 review 覆盖 `mobile/docs/prd/04-trading.md`（v2.1）、`mobile/docs/prd/06-portfolio.md`（v2.1）
以及相关契约文件，对照 `docs/SPEC-ORGANIZATION.md` 规范进行结构审查。

---

## CRITICAL-1: `trading-engine/docs/prd/` 目录为空

当前 `services/trading-engine/docs/prd/` 下无任何文件。
按规范，以下 Domain PRD 文件**必须存在**：

| 文件名 | 应包含内容 |
|--------|-----------|
| `order-lifecycle.md` | 订单状态机完整转换矩阵、各类型订单规则（市价/限价/DAY/GTC）、幂等性要求 |
| `risk-rules.md` | PDT 规则计算逻辑与阈值、买入力公式、持仓集中度规则、Reg SHO |
| `settlement.md` | T+1（US）/ T+2（HK）清结算规则、未结算资金冻结逻辑 |
| `position-pnl.md` | 成本基础计算方法（加权均价 vs FIFO）、已实现/未实现 P&L 定义、Wash Sale 识别规则 |

**影响**：没有 Domain PRD，tech spec（`docs/specs/domains/`）缺少上游需求文档，
Spec-PRD 追溯链断裂，工程实现无法追溯到业务决策。

---

## CRITICAL-2: Surface PRD 混入大量 Domain PRD 内容

### `04-trading.md` 中属于 Domain PRD 的内容

| 章节 | 问题 | 应迁移至 |
|------|------|---------|
| §五 订单状态生命周期（完整状态图） | Mobile 工程师只需要用户可见状态名和颜色，不需要完整状态转换矩阵 | `order-lifecycle.md` |
| §九 PDT 规则（完整的 FINRA Rule 4210 业务逻辑） | PDT 计算逻辑是交易引擎实现，不是前端关心的 | `risk-rules.md` |
| §六.2 市价单价格保护 Collar（±5%/±3%规则） | Collar 是交易引擎的风控参数，前端仅需展示提示文案 | `risk-rules.md` |
| §十一 合规要求（SEC Reg NMS Rule 606、FINRA Rule 4210 规则本体） | 监管合规规则是后端实现责任，前端只需要知道"最优执行披露"要展示在确认页 | `order-lifecycle.md` + `risk-rules.md` |

### `06-portfolio.md` 中属于 Domain PRD 的内容

| 章节 | 问题 | 应迁移至 |
|------|------|---------|
| §六.1 平均成本计算公式（含 FIFO 原则说明） | 成本基础方法是后端计算逻辑，前端只需要展示结果 | `position-pnl.md` |
| §六.2 已结算 vs 未结算股数的业务规则（含 Free-riding Violation 说明） | T+1 约束是交易引擎和结算系统的责任，前端只需要知道"可卖数量 = 已结算数量" | `settlement.md` |
| §七 合规要求中的 Wash Sale Rule 逻辑 | 识别规则是后端逻辑；前端只需要知道何时展示 ⚠️ 标记 | `position-pnl.md` |

---

## CRITICAL-3: 两个 Surface PRD 缺少必要 frontmatter

`04-trading.md` 和 `06-portfolio.md` 均缺少以下 frontmatter，违反规范 §"技术 Spec 引用规范"：

```yaml
# 应有但缺失的 frontmatter
---
type: surface-prd
domain_prd:
  - services/trading-engine/docs/prd/order-lifecycle.md
  - services/trading-engine/docs/prd/risk-rules.md
revisions:
  - rev: 1
    date: 2026-03-15T00:00+08:00
    author: product-manager
    summary: "初始版本"
---
```

没有 frontmatter，AI agent 在跨域查找时无法通过机器可读方式发现关联的 Domain PRD。

---

## 次要问题（P1-P2，供 PM 参考）

### P1: `06-portfolio.md` §六.1 标题/内容不一致

节标题是"FIFO 原则"，但正文计算公式是**加权平均成本法（Weighted Average Cost）**。
两者是不同的成本基础方法：

- **FIFO**：先进先出，每次卖出匹配最早买入的批次
- **加权均价**：所有持仓取均价，卖出不区分批次

`tech spec 05-position-pnl.md` 对应的实现必须以其中一种为准。
建议在 Domain PRD `position-pnl.md` 中明确。

### P2: 订单状态用户可见名称 vs 内部枚举无映射文档

Surface PRD 的用户状态（待提交/风控检查中/已提交/待成交…）与
tech spec 的内部枚举（CREATED/VALIDATED/RISK_APPROVED/PENDING/OPEN…）没有映射关系文档。
Mobile 工程师需要知道 "风控检查中" 对应哪些内部状态才能正确处理 WebSocket 事件。

### P2: 市价单 Collar 规则未在任何 Domain PRD 或契约中声明

`04-trading.md` §六.2 提到"±5%（常规）/ ±3%（盘前盘后）保护区间"，
但这个参数未出现在 `trading-to-mobile` 契约，也没有对应的 Domain PRD 规则。
如果参数变化，前端文案需要同步，目前没有机制保证同步。

### P2: GTC 90 天上限法律确认 pending（PRD §十四 已标注）

属于法务阻断风险，建议 PM 跟进并在 Domain PRD 中写明最终确认结论。

---

## 需要 PM 回复

- [ ] **product-manager**: 确认以上 Domain PRD 内容分类是否正确；主导创建 `trading-engine/docs/prd/` 下各 Domain PRD 文件；Surface PRD 中对应章节改为引用 Domain PRD
- [ ] **product-manager**: 澄清 §六.1 成本基础方法 — 是 FIFO 还是加权均价？（影响工程实现）
- [ ] **product-manager**: GTC 90 天上限的法律确认进度
