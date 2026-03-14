---
thread: prd-03-market-data-review
type: heavyweight
status: OPEN
priority: P0
opened_by: market-data-engineer
opened_date: 2026-03-14T10:00+08:00
participants:
  - market-data-engineer
requires_input_from:
  - product-manager
affects_specs:
  - mobile/docs/prd/03-market.md
  - mobile/prototypes/market.html
  - mobile/prototypes/stock-detail.html
  - mobile/prototypes/search.html
resolution: null
continues: null
---

# PRD-03 行情模块 — Market Data Engineer 技术评审

## 评审范围

- PRD: `mobile/docs/prd/03-market.md` (v1.1, 2026-03-13)
- 原型: `mobile/prototypes/market.html`, `stock-detail.html`, `search.html`
- 对照: `.claude/rules/financial-coding-standards.md`, `.claude/rules/security-compliance.md`, `services/market-data/CLAUDE.md`

## 评审结论

PRD-03 v1.1 整体质量较高，WebSocket 认证协议（v1.1 新增）、K 线分页限制、symbols 上限等关键点已有覆盖。但仍存在 **2 项 CRITICAL**、**6 项 HIGH**、**5 项 MEDIUM**、**3 项 LOW** 问题需要 PM 确认后修订。

## 问题汇总

| 级别 | 编号 | 标题 | 需要回复方 |
|------|------|------|-----------|
| CRITICAL | C1 | 访客延迟行情实现方案有内存风险 | PM + market-data-engineer |
| CRITICAL | C2 | Watchlist 数量上限三处矛盾 | PM |
| HIGH | H1 | 分钟 K 线"当日全量"可能超 500 条上限 | PM |
| HIGH | H2 | 盘口深度(Order Book)接口未定义 | PM |
| HIGH | H3 | 换手率字段 API 定义缺失 | PM |
| HIGH | H4 | 新闻数据源"待定"影响开发排期 | PM |
| HIGH | H5 | WebSocket 缺少 unsubscribe 和心跳协议定义 | PM |
| HIGH | H6 | market_status 枚举缺少 HALTED 状态 | PM |
| MEDIUM | M1 | 数据模型 DDL 使用 PostgreSQL 方言，项目规定用 MySQL | PM |
| MEDIUM | M2 | 搜索 debounce 策略和拼音搜索性能未明确 | PM |
| MEDIUM | M3 | Redis 访客延迟行情缓存策略语义不清 | PM + market-data-engineer |
| MEDIUM | M4 | 美股 Tab 子分类切换交互未明确 | PM + ui-designer |
| MEDIUM | M5 | API 响应是否需要统一包装格式 | PM |
| LOW | L1 | stock-detail.html 原型缺少关键显示元素 | ui-designer |
| LOW | L2 | market.html 颜色方案与 PRD 默认设置不一致 | ui-designer |
| LOW | L3 | search.html 空状态提示不完整 | ui-designer |

详见 `01-market-data-engineer-review.md`。
