---
type: tracker
module: portfolio
phase: 1
started: 2026-04-24
status: complete
---

# Portfolio 模块 Phase 1 实现跟踪

> **PRD**: [docs/prd/06-portfolio.md](../prd/06-portfolio.md)
> **合约**: [docs/contracts/trading-to-mobile.md](../../../docs/contracts/trading-to-mobile.md) § 持仓 / P&L
> **HiFi 原型**: [prototypes/06-portfolio/hifi/](../../prototypes/06-portfolio/hifi/)

---

## 架构决策

> **复用 Trading 模块数据层**：`PositionsNotifier`、`PortfolioSummaryNotifier`、`TradingWsNotifier` 已在 trading 模块实现（WS `position.updated` / `portfolio.summary` 增量更新），Portfolio 模块**直接 watch**，不重复数据层。
>
> Portfolio 模块新增：`PositionDetail` 单只持仓详情 + 交易记录、派生 `SectorAllocationProvider` + `PnlRankingProvider`，以及全部 screens/widgets。

---

## 任务列表

### Domain 层

- [x] **T01** — `PositionDetail` entity
  - symbol, companyName, sector, qty, availableQty, avgCost, currentPrice, marketValue
  - unrealizedPnl/Pct, todayPnl/Pct, realizedPnl, costBasis
  - washSaleStatus, pendingSettlements, recentTrades
  - `domain/entities/position_detail.dart`

- [x] **T02** — `TradeRecord` entity
  - tradeId, side (BUY/SELL), qty, price, amount, fee, settledAt, washSale flag
  - `domain/entities/trade_record.dart`

- [x] **T03** — `SectorAllocation` entity
  - sector (GICS 名称), marketValue, weight (0-1 Decimal)
  - `domain/entities/sector_allocation.dart`

- [x] **T04** — `PortfolioRepository` interface
  - `getPositionDetail(String symbol) → Future<PositionDetail>`
  - `domain/repositories/portfolio_repository.dart`

### Data 层

- [x] **T05** — `PositionDetailModel` + `TradeRecordModel`（freezed + json_serializable）
  - JSON key mapping：`company_name`, `sector`, `realized_pnl`, `cost_basis`, `wash_sale_status`, `recent_trades`
  - `data/remote/models/position_detail_model.dart`

- [x] **T06** — `PortfolioRemoteDataSource`
  - `getPositionDetail(symbol)` → GET `/api/v1/positions/{symbol}`
  - `data/remote/portfolio_remote_data_source.dart`

- [x] **T07** — `PortfolioRepositoryImpl`（Riverpod Provider）
  - `data/portfolio_repository_impl.dart`

### Application 层

- [x] **T08** — `PositionDetailProvider`（FutureProvider + autoDispose）
  - 参数：symbol（family）
  - Watch `positionsNotifierProvider` 获取 WS 增量更新同一 symbol
  - `application/position_detail_provider.dart`

- [x] **T09** — `SectorAllocationProvider`（Provider，派生）
  - 从 `positionsNotifierProvider` 派生，按 sector 聚合 marketValue
  - `application/sector_allocation_provider.dart`

- [x] **T10** — `PnlRankingProvider`（Provider，派生）
  - 从 `positionsNotifierProvider` 派生，按 unrealizedPnl 绝对值排序
  - `application/pnl_ranking_provider.dart`

### Presentation 层

- [x] **T11** — `PortfolioScreen`（主 Tab 页）
  - Tab：持仓列表 / 分析
  - 顶部 `AssetSummaryCard`
  - 持仓列表 + 排序切换（市值/浮亏/今日涨跌/添加时间）
  - 空状态分支（无持仓无现金 / 无持仓有现金）
  - `presentation/screens/portfolio_screen.dart`

- [x] **T12** — `AssetSummaryCard` widget
  - 深色渐变背景：总资产（mono 字体 3xl）
  - 今日盈亏 / 累计盈亏（颜色跟随正负）
  - 可用现金 / 待结算（含 `?` 图标弹出 T+1 说明）
  - `presentation/widgets/asset_summary_card.dart`

- [x] **T13** — `PositionListCard` widget
  - 股票代码 + 公司名 + 持股数 + 均价 + 市值 + 浮盈亏 + 今日涨跌 + 占比
  - 集中度预警横幅（> 30% 触发）
  - 快捷 [买入] [卖出] 按钮（跳转 OrderEntryScreen）
  - `presentation/widgets/position_list_card.dart`

- [x] **T14** — 空状态 widgets
  - `EmptyPortfolioWidget`（无持仓无现金：引导入金 + 浏览行情）
  - `CashOnlyPortfolioWidget`（有现金无持仓：显示可用余额 + 引导买入）
  - `presentation/widgets/empty_portfolio_widget.dart`

- [x] **T15** — `PositionDetailScreen`
  - 持仓概览（数量/均价/市值/盈亏）
  - 成本基础 + 已实现盈亏
  - Wash Sale 标注（conditionally）
  - 本仓交易记录列表（`TradeRecord`）
  - 结算信息（已结算/待结算股数 + 结算日）
  - `presentation/screens/position_detail_screen.dart`

- [x] **T16** — `PortfolioAnalysisScreen`
  - 板块分布：横向进度条 + 百分比（GICS 板块）
  - P&L 排行：按浮亏绝对值排序的持仓列表
  - `presentation/screens/portfolio_analysis_screen.dart`

- [x] **T17** — `SectorAllocationBar` + `PnlRankingItem` widgets
  - `SectorAllocationBar`：板块名 + 宽度动画进度条 + 百分比
  - `PnlRankingItem`：排名 + 代码 + 浮亏金额/百分比
  - `presentation/widgets/sector_allocation_bar.dart`
  - `presentation/widgets/pnl_ranking_item.dart`

- [x] **T18** — 路由接入 + active-features.yaml 更新
  - `/portfolio`（主 Tab）
  - `/portfolio/position/:symbol`（持仓详情）
  - 更新 `active-features.yaml` phase1_tasks

---

## 验收标准

- [x] `flutter analyze` 0 issues (0 errors, 全量通过)
- [x] 所有 Decimal 字段使用 `package:decimal`，无 double
- [x] 所有时间戳使用 UTC
- [x] 集中度预警 > 30% 触发横幅
- [x] 待结算说明弹窗（T+1）正确展示
- [x] Wash Sale 标注条件渲染（后端 `wash_sale_status == "flagged"`）
- [x] 空状态三个分支（无持仓无现金 / 有现金无持仓 / 有持仓）全部覆盖
