---
thread: trading-domain-prd-missing
type: heavyweight
status: OPEN
priority: P0
opened_by: trading-engine-engineer
opened_date: 2026-03-27T16:00+08:00
resolved_date: null
incorporated_date: null
participants:
  - trading-engine-engineer
  - product-manager
requires_input_from:
  - product-manager
affects_specs:
  - mobile/docs/prd/04-trading.md
  - mobile/docs/prd/06-portfolio.md
  - services/trading-engine/docs/prd/order-lifecycle.md      # 待创建
  - services/trading-engine/docs/prd/risk-rules.md           # 待创建
  - services/trading-engine/docs/prd/settlement.md           # 待创建
  - services/trading-engine/docs/prd/position-pnl.md        # 待创建
resolution: null
incorporated_commits: []
continues: null
continued_by: null
---

# 交易域 Domain PRD 缺失 + Surface PRD 混入 Domain 内容

## 背景

对 `mobile/docs/prd/04-trading.md`（v2.1）和 `mobile/docs/prd/06-portfolio.md`（v2.1）进行了 PRD review，
对照 `docs/SPEC-ORGANIZATION.md` 的规范发现以下严重问题。

## 核心问题

`services/trading-engine/docs/prd/` 目录为**完全空目录** — 交易域的所有业务规则目前混在 Surface PRD 里，
违反"Domain PRD 跟着实现者走"的铁律。

## 对话摘要

1. **trading-engineer 提出** (01): P0 结构性问题 — Domain PRD 缺失 + Surface PRD 混入详情
```
