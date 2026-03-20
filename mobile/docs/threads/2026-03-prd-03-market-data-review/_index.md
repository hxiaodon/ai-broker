---
thread: prd-03-market-data-review
type: heavyweight
status: RESOLVED
priority: P0
opened_by: market-data-engineer
opened_date: 2026-03-14T10:00+08:00
resolved_date: 2026-03-20T00:00+08:00
resolved_by: product-manager
participants:
  - market-data-engineer
  - product-manager
requires_input_from: []
affects_specs:
  - mobile/docs/prd/03-market.md
  - mobile/prototypes/market.html
  - mobile/prototypes/stock-detail.html
  - mobile/prototypes/search.html
resolution: |
  所有问题已在 PRD-03 v2.2（2026-03-20）中解决：
  - C1: 访客延迟行情改为"每5秒推送一次全局快照"语义，已补充到 §6.1
  - C2: Watchlist 上限统一为 100 只，已更新 §6.3
  - H1: 分时K线明确仅含常规时段（09:30–16:00，约390条），已更新 §5.2
  - H2: 明确 Phase 1 仅提供 Level 1（bid/ask），Level 2 推至 Phase 2，已更新 §5.2
  - H3: 换手率字段及计算口径（成交量/流通股数）已补充至 §5.2
  - H4: 新闻数据源标记为 P2，不阻塞 Phase 1 开发
  - H5: WebSocket unsubscribe/心跳已移至工程师技术规格文档，PRD 不需定义
  - H6: HALTED（交易暂停）状态已加入 §5.2 交易时段表
  - M1: DDL 已从 PRD 移除（归入工程师文档）
  - M2: 搜索 debounce 300ms 及最少字符规则已补充至 §5.3
  - M3: Redis 缓存策略已移至工程师文档
  - M4: 热门/涨幅/跌幅为顶层 Tab，交互形式已明确
  - M5: API 统一包装格式归入 docs/contracts/ 跨域契约
  原型 prototypes/03-market/stock-detail.html 同步更新：补充换手率/成交额字段，新增 HALTED 开发状态切换器
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
