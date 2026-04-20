# Trading 模块实现追踪 (trading.tracker.md)

**模块**: 交易（Trading）  
**状态**: 🟡 in_progress  
**Phase 1 进度**: 20 / 20

---

## 元信息

| 项目 | 链接 |
|------|------|
| PRD | [mobile/docs/prd/04-trading.md](../prd/04-trading.md) (v2.2) |
| 高保真原型 | [mobile/prototypes/04-trading/hifi/](../../prototypes/04-trading/hifi/) |
| API 合约 | [docs/contracts/trading-to-mobile.md](../../../docs/contracts/trading-to-mobile.md) (v2) |
| 总览仪表盘 | [mobile/docs/active-features.yaml](../active-features.yaml) |

**依赖的合约端点**：

| 端点 | 用途 | SLA |
|------|------|-----|
| POST /api/v1/orders | 提交订单（HMAC 签名 + 生物识别） | < 300ms (P95) |
| GET /api/v1/orders | 订单列表（状态/日期/市场筛选） | < 200ms (P95) |
| GET /api/v1/orders/:id | 订单详情（含成交明细） | < 100ms (P95) |
| DELETE /api/v1/orders/:id | 撤单（202 异步，结果 WebSocket 推送） | < 400ms (P95) |
| GET /api/v1/positions | 持仓列表（含实时市值与盈亏） | < 200ms (P95) |
| GET /api/v1/positions/:symbol | 持仓详情 + P&L | < 100ms (P95) |
| GET /api/v1/portfolio/summary | 投资组合概览 | < 150ms (P95) |
| **WebSocket** order.updated | 订单状态实时推送 | 事件驱动 |
| **WebSocket** position.updated | 持仓变更推送 | 事件驱动 |
| **WebSocket** portfolio.summary | 资产概览推送 | 5-10s 频率 |

---

## Phase 1 任务清单

> 状态标记：`[ ]` 待实现 · `[~]` 进行中 · `[x]` 已完成 · `[!]` 阻塞

### Domain 层（Entities & Repositories）

- [x] **T01** — `Order` entity（freezed）
  - 字段：orderId, symbol, market, side, orderType, status, qty, filledQty, limitPrice, avgFillPrice, validity, extendedHours, fees, createdAt, updatedAt
  - `OrderSide` enum: buy / sell
  - `OrderType` enum: market / limit
  - `OrderValidity` enum: day / gtc
  - `OrderStatus` enum: 9 状态（见 PRD §五）
  - `domain/entities/order.dart`

- [x] **T02** — `OrderFill` entity（freezed）
  - 字段：fillId, orderId, qty, price, exchange, filledAt
  - `domain/entities/order_fill.dart`

- [x] **T03** — `Position` entity（freezed）
  - 字段：symbol, market, qty, availableQty, avgCost, currentPrice, marketValue, unrealizedPnl, unrealizedPnlPct, todayPnl, todayPnlPct, pendingSettlement（含 settleDate）
  - `domain/entities/position.dart`

- [x] **T04** — `PortfolioSummary` entity（freezed）
  - 字段：totalEquity, cashBalance, marketValue, dayPnl, dayPnlPct, totalPnl, totalPnlPct, buyingPower, settledCash
  - `domain/entities/portfolio_summary.dart`

- [x] **T05** — `TradingRepository` interface
  - submitOrder / cancelOrder / getOrders / getOrderDetail / getPositions / getPositionDetail / getPortfolioSummary
  - `domain/repositories/trading_repository.dart`

### Data 层（Remote Data Source & Repository Impl）

- [x] **T06** — `HmacSigner` utility（core/security）
  - HMAC-SHA256 签名：method + path + timestamp + body hash
  - `core/security/hmac_signer.dart`

- [x] **T07** — `OrderModel` / `PositionModel` / `PortfolioSummaryModel` DTOs（freezed + json_serializable）
  - `data/remote/models/order_model.dart`
  - `data/remote/models/position_model.dart`
  - `data/remote/models/portfolio_summary_model.dart`

- [x] **T08** — `TradingRemoteDataSource`
  - 所有 REST 端点实现（含 HMAC 签名注入、connectivity 检查、429 重试）
  - `data/remote/trading_remote_data_source.dart`

- [x] **T09** — `TradingRepositoryImpl`
  - 薄委托层，DTO → domain 映射
  - Riverpod provider 注册
  - `data/trading_repository_impl.dart`

### Application 层（Providers & Notifiers）

- [x] **T10** — `OrderSubmitNotifier`（AsyncNotifier）
  - 状态：idle / submitting / success(orderId) / error
  - 生物识别触发 + HMAC 签名
  - `application/order_submit_notifier.dart`

- [x] **T11** — `OrdersNotifier`（AsyncNotifier）
  - 订单列表（按 status/date 筛选）
  - WebSocket `order.updated` 实时更新
  - `application/orders_notifier.dart`

- [x] **T12** — `PositionsProvider`（FutureProvider）
  - 持仓列表，WebSocket `position.updated` 增量更新
  - `application/positions_provider.dart`

- [x] **T13** — `PortfolioSummaryProvider`（FutureProvider）
  - 投资组合概览，WebSocket `portfolio.summary` 推送更新
  - `application/portfolio_summary_provider.dart`

- [x] **T14** — `TradingWsNotifier`（WebSocket 连接管理）
  - 连接 wss://.../ws/trading，订阅 order.updated / position.updated / portfolio.summary
  - 断线重连（指数退避）
  - `application/trading_ws_notifier.dart`

### Presentation 层（Screens & Widgets）

- [x] **T15** — `OrderEntryScreen`：委托下单页
  - 买入/卖出切换、订单类型、数量输入、有效期、盘前盘后开关
  - 费用预估展示
  - 动态风险提示（持仓占比 > 20%、大额弹窗、价格偏离警告）
  - 盘前盘后首次确认弹窗
  - 滑动确认 → 跳转确认页
  - `presentation/screens/order_entry_screen.dart`

- [x] **T16** — `OrderConfirmScreen`：订单确认页
  - 委托摘要展示
  - 生物识别触发（local_auth）
  - 最优执行披露 + PFOF 声明
  - 提交成功 → Toast + 跳转订单列表
  - `presentation/screens/order_confirm_screen.dart`

- [x] **T17** — `OrderListScreen`：订单管理页
  - 4 Tab：待成交 / 已成交 / 已撤销过期 / 全部
  - 订单卡片（含撤单按钮）
  - 订单详情展开（成交明细 + 费用 + 状态时间轴）
  - 撤单确认弹窗
  - `presentation/screens/order_list_screen.dart`

- [x] **T18** — `OrderCardWidget` + `OrderStatusBadge`
  - 状态颜色映射（见 PRD §五）
  - `presentation/widgets/order_card_widget.dart`

- [x] **T19** — `SlideToConfirmWidget`：滑动确认组件
  - 滑动解锁动画
  - `presentation/widgets/slide_to_confirm_widget.dart`

- [x] **T20** — 路由接入 + active-features.yaml 更新
  - `/trading/order` 路由参数：symbol, side, prefillQty
  - 更新 `active-features.yaml` 状态为 in_progress

---

## 验收标准

- [ ] `flutter analyze` 0 issues
- [ ] 所有 Decimal 字段使用 `package:decimal`，无 double
- [ ] 所有时间戳使用 UTC
- [ ] HMAC 签名覆盖所有 POST/DELETE 请求
- [ ] 生物识别确认覆盖下单流程
- [ ] 买入按钮固定绿色，卖出按钮固定红色（不随涨跌色偏好变化）
