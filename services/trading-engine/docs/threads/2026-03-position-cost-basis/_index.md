---
thread: position-pnl-cost-basis-method
type: lightweight
status: OPEN
priority: P1
opened_by: trading-engine-engineer
opened_date: 2026-03-27T16:10+08:00
resolved_date: null
incorporated_date: null
participants:
  - trading-engineer
  - product-manager
requires_input_from:
  - product-manager
affects_specs:
  - mobile/docs/prd/06-portfolio.md (§六.1)
  - services/trading-engine/docs/specs/domains/05-position-pnl.md
resolution: null
incorporated_commits: []
---

# 持仓成本基础方法：FIFO vs 加权均价 — 澄清需求

## 背景

`mobile/docs/prd/06-portfolio.md` §六.1 节标题为"平均成本计算（FIFO 原则）"，
但正文计算公式是加权均价（Weighted Average Cost）。两者是不同的方法，影响工程实现。

## 问题陈述

**节标题** (line 152):
```
### 6.1 平均成本计算（FIFO 原则）
```

**正文计算** (line 156-160):
```
新均价 = (原持仓 × 原均价 + 新买数量 × 成交价) / 新总持仓数量

示例：已持 100 股 @ $180，再买 50 股 @ $190，新均价 = (100×180 + 50×190) / 150 = **$183.33**
```

这个公式是**加权均价**，不是 FIFO。

## 两种方法的区别

| 维度 | FIFO（先进先出） | 加权均价 |
|------|-----------------|---------|
| **成本跟踪** | 每批次买入单独记录，卖出时按购买顺序匹配 | 所有持仓取单一均价，卖出不区分批次 |
| **示例** | 批次A: 100股@$180 / 批次B: 50股@$190 → 卖50股时卖出批次A的50股，成本$180 | 所有150股共用均价$183.33 → 卖50股时，成本也是$183.33 |
| **报税（US）** | IRS 允许，常用于个股核算 | IRS 允许，简化计算 |
| **实现复杂度** | 高（需维护批次链表） | 低（只维护单个均价） |
| **Wash Sale 跟踪** | 按批次跟踪最容易（知道每批何时买的） | 需额外逻辑 |

## 业务影响

- **用户报税**：两种方法可能导致不同的已实现 P&L 和税基
- **持仓详情展示**：FIFO 需要展示"成本基础构成"（多个批次），加权均价只需一个数字
- **成交历史表**：两种方法的 `cost_basis` 字段语义不同

## 需要 PM 确认

1. **交易所要求**：NYSE/NASDAQ/HKEX 是否对成本基础方法有规定？
2. **用户研究**：Phase 1 用户是否需要看到分批成本明细，还是一个均价足够？
3. **报税集成**：Phase 2 1099-B 报表会采用哪种方法？
4. **现有实现**：`tech spec 05-position-pnl.md` 或代码中是否已有倾向？

一旦确认，需要：
- 更新 `06-portfolio.md` §六.1 标题和正文保持一致
- 创建 `trading-engine/docs/prd/position-pnl.md` 明确规则
- 更新实现代码和数据库 schema（如果需要改动）
