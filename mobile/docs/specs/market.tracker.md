# Market 模块实现追踪 (market.tracker.md)

**模块**: 行情（Market）  
**状态**: 🟡 in_progress  
**Phase 1 进度**: 20 / 22

---

## 元信息

| 项目 | 链接 |
|------|------|
| PRD | [mobile/docs/prd/03-market.md](../prd/03-market.md) (v2.3) |
| 高保真原型 | [docs/prd/prototypes/03-market/](../../prd/prototypes/03-market/index.html) |
| API 合约 | [docs/contracts/market-data-to-mobile.md](../../../docs/contracts/market-data-to-mobile.md) (v1.1) |
| 权威规范 | [services/market-data/docs/specs/](../../../services/market-data/docs/specs/) (market-api-spec v2.0, websocket-spec v2.1, market-data-system v2.1) |
| 总览仪表盘 | [mobile/docs/active-features.yaml](../active-features.yaml) |

**依赖的合约端点**：

| 端点 | 用途 | SLA |
|------|------|-----|
| GET /v1/market/quotes | 批量行情快照（最多50只） | < 200ms (P99) |
| GET /v1/market/kline | K线数据（8个时间周期） | < 200ms (P99, Redis); < 500ms (MySQL) |
| GET /v1/market/search | 股票搜索（symbol/名称/拼音） | < 300ms (P99) |
| GET /v1/market/movers | 涨跌幅榜/热门榜 | < 500ms (P99) |
| GET /v1/market/stocks/{symbol} | 股票详情（基本面/财报） | < 500ms (P99) |
| GET /v1/market/news/{symbol} | 相关新闻 | < 500ms (P99) |
| GET /v1/market/financials/{symbol} | 财报数据 | < 500ms (P99) |
| GET /v1/watchlist | 获取自选股列表（含最新报价） | < 300ms (P99) |
| POST /v1/watchlist | 添加自选（symbol + market） | < 200ms (P99) |
| DELETE /v1/watchlist/{symbol} | 删除自选 | < 200ms (P99) |
| **WebSocket** quote.realtime | 实时报价推送（注册用户）/ T-15min延迟快照（访客，每5s） | < 500ms (P99, 端到端) |

---

## Phase 1 任务清单

> 状态标记：`[ ]` 待实现 · `[~]` 进行中 · `[x]` 已完成 · `[!]` 阻塞

### Presentation 层（Screens & Widgets）

- [x] **T01** — `MarketHomeScreen`：行情首页（4 tabs + 搜索栏 + 大盘指数）
  - Tab 栏：自选 | 热门 | 涨幅榜 | 跌幅榜（港股 Tab 显示"敬请期待"占位）
  - 顶部 `DelayedQuoteBanner`（访客）
  - 大盘指数横向滚动卡片（SPY/QQQ/DIA，从 watchlistProvider 取实时价格）
  - `presentation/screens/market_home_screen.dart`

- [x] **T02** — `WatchlistTab` widget：自选股列表
  - 股票卡片（StockRowTile）含延迟徽标
  - 加载/错误/空状态 skeleton
  - 空状态"去搜索添加"引导按钮
  - 访客编辑 → 登录引导 Sheet
  - `presentation/widgets/watchlist_tab.dart`

- [x] **T03** — `MoversTab` widget + `moversProvider`：涨跌幅榜/热门榜
  - `moversProvider(type:, market:)` FutureProvider.family
  - 加载/错误/空状态 skeleton
  - `presentation/widgets/movers_tab.dart` + `application/movers_provider.dart`

- [x] **T04** — `StockDetailScreen`：股票详情页
  - 导航栏（symbol + 收藏按钮 ⭐，访客触发登录 Sheet）
  - 价格英雄区（price/change/changePct/session，MarketStatusIndicator）
  - K线图区域（KLineChartWidget，见 T05）
  - 今日行情数据网格（今开/昨收/最高/最低/成交量/成交额/买一价/卖一价）
  - 基本面数据网格（市值/PE/PB/股息率/52周高低/换手率/板块）
  - 买入/卖出按钮（暂停交易时 disabled；访客触发登录 Sheet）
  - StaleQuoteWarningBanner（is_stale + staleSinceMs ≥ 5000）
  - 加载 skeleton + 错误重试
  - `presentation/screens/stock_detail_screen.dart`

- [x] **T05** — `KLineChartWidget`：K线图表（Syncfusion 占位）
  - 时间轴选择器：分时 / 1W / 1M / 3M / 1Y / All
  - `_klineDataProvider(KlineParams)` FutureProvider.family 拉取 K 线数据
  - Syncfusion TODO 注释（含完整实现规格：CandleSeries + ColumnSeries + CrosshairBehavior + ZoomPan）
  - 当前显示 sparkline 占位符 + 条数提示
  - `presentation/widgets/kline_chart_widget.dart`

- [x] **T06** — `SearchScreen`：全局搜索
  - 3 状态：empty（历史 + 热门）/ results / no-results
  - 300ms debounce 通过 searchProvider 驱动
  - 搜索历史行（含单条删除、一键清空）
  - 访客模式结果显示"延迟"(D) 徽标
  - `presentation/screens/search_screen.dart`

- [x] **T07** — `DelayedQuoteBanner`：访客模式延迟提示横幅
  - 监听 `authProvider`，`guest` 状态时显示，其余自动隐藏
  - 点击跳转登录页
  - `presentation/widgets/delayed_quote_banner.dart`

- [x] **T08** — `MarketStatusIndicator`：市场状态指示器
  - 5种状态 chip（盘前/盘中/盘后/休市/暂停交易）+ 颜色编码
  - `presentation/widgets/market_status_indicator.dart`

- [x] **T09** — `StaleQuoteWarningBanner`：陈旧行情警告横幅
  - 黄色背景 + 警告图标
  - `StockDetail.showStaleWarning` 控制显示
  - `presentation/widgets/stale_quote_warning_banner.dart`

> **Shared widget**: `StockRowTile` (`presentation/widgets/stock_row_tile.dart`) — 自选/榜单/搜索结果共用行组件，含 symbol badge / rank 模式 / delayed 徽标

### Application 层（State Management）

- [x] **T10** — `QuoteWebSocketNotifier` + `quoteUpdateProvider`：WebSocket 实时报价流
  - `AsyncNotifier<WsUserType>`（`keepAlive: true`），管理 `QuoteWebSocketClient` 生命周期
  - 持久 broadcast stream（`_outputController`），跨重连保持流稳定
  - 连接管理：`wsClientFactoryProvider` 可注入工厂，便于测试
  - 双轨推送：注册用户实时TICK/SNAPSHOT / 访客T-15min DELAYED（共享同一 quoteStream）
  - 自动重连：指数退避（1/2/4s），最多3次，超限后 `AsyncError`
  - Pause/Resume：`pause()` 关闭 WS 保存 subscriptions；`resume()` 重连并重新订阅
  - `subscribe()`：自动分批（每50个），保留已订阅 symbols 用于重连后重订阅
  - `reauthWithToken()`：guest→registered 升级或 JWT 续期
  - `quoteUpdateProvider(symbol)`：`StreamProvider.family`，过滤单个 symbol 更新
  - ✅ 单元测试：`test/features/market/application/quote_websocket_notifier_test.dart`（19 tests, all passing）

- [x] **T11** — `WatchlistNotifier`：自选股状态管理
  - `AsyncNotifier<List<Quote>>`（`keepAlive: true`），订阅 `watchlistRepositoryProvider`
  - Live WS 报价 patch：SNAPSHOT/DELAYED = 全字段替换（保留静态 metadata）；TICK = 仅更新非零数值字段
  - 通过 `_subscribeWhenReady` + `ref.listen(quoteWebSocketProvider, fireImmediately: true)` 处理 WS 重连后自动重订阅
  - `add()`：调用 repo + WS 订阅 + `ref.invalidateSelf()`；100只限制抛 `ValidationException`
  - `remove()`：调用 repo + `unsubscribe` + `ref.invalidateSelf()`
  - `reorder()`：调用 repo + 乐观更新（无需重载）
  - `importGuestItems()`：逐条导入，静默跳过失败项，完成后刷新
  - ✅ 单元测试：`test/features/market/application/watchlist_notifier_test.dart`（15 tests, all passing）

- [x] **T12** — `StockDetailNotifier`：股票详情状态
  - `@riverpod` (autoDispose) family notifier `build(String symbol)` → `AsyncValue<StockDetail>`
  - Initial load via `MarketDataRepository.getStockDetail(symbol)`
  - Live WS patches via `ref.listen(quoteUpdateProvider(symbol), ...)` — same SNAPSHOT/TICK merge rules as `WatchlistNotifier`
  - WS subscription: subscribe on build (via `ref.listen(quoteWebSocketProvider, fireImmediately: true)`); unsubscribe on dispose
  - `KlineParams` value object added for future `klineProvider` family
  - ✅ 单元测试：`test/features/market/application/stock_detail_notifier_test.dart`（9 tests, all passing）

- [x] **T13** — `SearchNotifier`：搜索状态管理
  - `Notifier<SearchState>`（同步 build，防抖通过 `dart:async` Timer 实现）
  - `SearchState` (`@freezed`): query / results / hotStocks / history / isLoading / error
  - 防抖（300ms），stale-query guard 防止过期结果覆盖
  - 搜索历史管理（SharedPreferences，最近10条，去重，最新在前）
  - 热门股从 `getMovers(type: 'most_active', market: 'US')` 加载；失败静默处理
  - 最少输入字符检查（ASCII ≥1，含非ASCII字符 ≥2）
  - `sharedPreferencesProvider` 可注入（测试可 override）
  - ✅ 单元测试：`test/features/market/application/search_notifier_test.dart`（23 tests, all passing）

### Data 层（Repository / DataSource）

- [x] **T14** — `MarketDataRepository`（abstract）+ `MarketDataRepositoryImpl`
  - 接口：`getQuotes` / `getKline` / `searchStocks` / `getMovers` / `getStockDetail` / `getNews` / `getFinancials`
  - 实现：调用 MarketDataRemoteDataSource
  - 错误转换：HTTP 错误 → Domain 层异常

- [x] **T15** — `MarketDataRemoteDataSource`（Dio）
  - 实现上述7个 REST API 端点调用
  - 请求/响应模型（freezed + json_serializable）
  - DTO → Entity 映射（价格字段 string → Decimal）
  - 认证：可选 JWT（访客 vs 注册用户）
  - 限流处理：429 错误重试（Retry-After header）

- [x] **T16** — `QuoteWebSocketClient`：WebSocket 客户端
  - 连接生命周期：connect → auth → subscribe → receive → unsubscribe → close
  - 消息级认证（5s内发送auth消息，否则服务端关闭连接）
  - 订阅管理（最多50 symbols，超限返回错误）
  - 心跳（30s ping，60s无活动服务端关闭）
  - Protobuf 解析（WsQuoteFrame，frame_type: SNAPSHOT/TICK/DELAYED）
  - Token 续期（reauth，无需断开连接）
  - 访客升级为注册用户（reauth后自动切换实时流）
  - 错误处理：4001-4004 关闭码
  - ✅ 单元测试：`test/features/market/data/websocket/quote_websocket_client_test.dart`（34 tests, all passing）

- [x] **T17** — `WatchlistRepository`（abstract）+ `WatchlistRepositoryImpl`
  - 接口：`getWatchlist` / `addToWatchlist` / `removeFromWatchlist` / `reorderWatchlist`
  - 本地缓存（Hive `market_watchlist` box）+ 服务端同步（注册用户）
  - 访客模式：仅本地存储，quotes 通过 REST `/v1/market/quotes` 获取
  - reorderWatchlist：local-only（服务端无排序接口）
  - `WatchlistLocalDataSource`：Hive JSON 序列化，存储 symbol+market 有序列表
  - ✅ 单元测试：`watchlist_local_datasource_test.dart`（8 tests）+ `watchlist_repository_impl_test.dart`（19 tests）

- [x] **T18** — `QuoteLocalCache`：行情本地缓存
  - Hive key-value 存储（`market_quotes` + `market_kline` 两个 box）
  - 缓存策略：最新报价缓存5分钟，K线缓存1小时
  - 离线模式：`getQuoteStale` / `getKlineStale` 返回过期缓存供离线展示
  - 序列化：QuoteDto / CandleDto JSON（json_serializable 生成）
  - ✅ 单元测试：`quote_local_cache_test.dart`（19 tests，含 TTL 过期 + stale 降级）

### Cross-Cutting Concerns

- [x] **T19** — Route Guards：访客模式限制
  - 自选股收藏按钮：`_WatchlistToggleButton` 检测 guest → `showLoginGuidanceSheet(context, trigger: '添加自选')`
  - 买入/卖出按钮：`_ActionButtons` 检测 guest → `showLoginGuidanceSheet(context, trigger: '买入/卖出')`
  - 访客编辑自选：`WatchlistTab` onEditTap → `showLoginGuidanceSheet(context, trigger: '编辑自选股')`
  - 访客直接导航 `/trading/order`（deep link）→ `_redirect` 重定向至 `/auth/login`
  - 市场路由（MarketHomeScreen / StockDetailScreen / SearchScreen）已接入 `app_router.dart`，替换所有 _Placeholder
  - `core/routing/app_router.dart`

- [x] **T20** — Error Handling：网络错误与异常场景
  - WebSocket 断线重连：已在 T10 `QuoteWebSocketNotifier`（指数退避，最多3次）
  - REST API 错误：各 widget 已有 error 状态 + `ErrorView(onRetry:)` 回调
  - Stale Quote 警告：`StaleQuoteWarningBanner`（T09）+ `StockDetail.showStaleWarning`（T12）
  - 搜索无结果（US 范围）：`_NoResultsView` 显示"未找到与 '$query' 相关的股票"
  - **搜索港股标的**：`SearchState.isHkQuery`（1-5位纯数字 or 含中文字符）→ `_NoResultsView` 显示"港股行情即将开放，您可先浏览美股行情"
  - 股票停牌（HALTED）：`_ActionButtons` 检测 `isHalted` → 买入/卖出按钮 `onPressed: null`（disabled）
  - `application/search_notifier.dart` + `presentation/screens/search_screen.dart`

- [~] **T21** — Performance：K线图渲染与列表滚动优化
  - K线图 Syncfusion 优化：延迟至 T05 Syncfusion 正式接入后实施
  - WebSocket 高频更新 RxDart throttle：延迟至负载测试后按需接入
  - ListView：当前使用 `ListView.separated`（Phase 1 数据量可接受）
  - 内存泄漏检测：延迟至集成测试阶段

- [x] **T22** — Data Models：Domain Entities + DTOs
  - Domain Entities（纯Dart，不依赖框架）：
    - `Quote`（symbol/price/change/change_pct/volume/bid/ask/market_status/is_stale/delayed）
    - `Candle`（t/o/h/l/c/v/n）
    - `StockDetail`（quote + fundamentals + financials）
    - `SearchResult`（symbol/name/name_zh/market/price/change_pct）
    - `Watchlist`（List<Quote>）
  - DTOs（freezed + json_serializable）：
    - `QuoteDto` / `CandleDto` / `StockDetailDto` / `SearchResultDto`
  - Mappers：DTO → Entity（价格字段 string → Decimal）

---

## 验收标准

直接引用自 PRD-03 §九，全部 check-off 后方可进入 code review：

- [ ] 行情页日活比例：登录用户日均打开行情页 ≥ 2 次（埋点统计）
- [ ] K线图加载速度：切换时间轴 ≤ 1 秒展示数据
- [ ] 搜索到详情转化：搜索 → 点击结果进入详情 ≥ 60%（漏斗分析）
- [ ] 自选股添加率：注册用户 7 日内添加至少 1 只自选股 ≥ 50%
- [ ] 行情 → 买入跳转率：股票详情页 → 点击买入/卖出 ≥ 15%
- [ ] 访客模式所有价格旁显示"延迟 15 分钟"标识（SEC 合规）
- [ ] WebSocket 断线自动重连，成功后恢复实时更新
- [ ] Stale Quote 警告（stale_since_ms ≥ 5000）正确显示
- [ ] 所有错误场景有明确的中文用户提示，无白屏或静默失败
- [ ] `flutter analyze` 0 issues
- [ ] `flutter test` 所有单元测试通过
- [ ] 集成测试：WebSocket 连接 → 订阅 → 接收推送 → 退订 → 关闭
- [ ] 性能测试：100+ symbols 并发 WebSocket 更新，帧率 ≥ 55 FPS
- [ ] 内存泄漏检测：行情页反复进入/退出，无内存泄漏
- [ ] `security-engineer` review 通过（WebSocket 认证、证书固定）
- [ ] `code-reviewer` review 通过
- [ ] **[生产上线前置]** Polygon.io Poly.feed+ 授权已完成（PM + Legal 确认），方可发布生产环境

---

## 设计决策日志

> 记录实现过程中非显而易见的决策，防止未来重复讨论。

| 日期 | 决策 | 原因 |
|------|------|------|
| 2026-04-04 | K线时间轴映射：PRD"分时/5日/1月/3月/1年/全部" → API"1min/5min/1d/1d/1d/1d" | PRD 描述的是用户视角时间范围，API period 参数是K线周期；"分时"=当日1min K线，"5日"=近5日1min K线，"1月/3月/1年/全部"=日K线，通过 from/to 参数控制范围 |
| 2026-04-04 | WebSocket 使用 Protobuf 二进制帧而非 JSON | 行情推送高频（tick级），Protobuf 相比 JSON 减少约 3-4x payload，降低移动端解析 CPU 开销和弱网延迟（见 websocket-spec v2.1 §消息帧类型约定） |
| 2026-04-04 | 访客自选股本地临时存储（Hive），不同步服务端 | PM 确认：访客 Watchlist 仅本地 Hive 存储，登录后提示"是否导入访客自选股"（调用 POST /v1/watchlist 批量添加） |
| 2026-04-04 | Stale Quote 前端显示阈值 5000ms，而非 API is_stale=true 的 1000ms | 交易引擎使用 1s 阈值拒绝市价单（风控严格）；前端展示宽容度更高，5s 内陈旧数据保持正常显示，≥5s 才显示警告横幅（见 market-api-spec §1.7） |
| 2026-04-04 | 大盘指数使用 ETF 代理（SPY/QQQ/DIA），UI 标注"追踪 XXX" | 合规要求：S&P 500/Nasdaq-100/DJIA 指数数据需单独授权，Phase 1 使用 ETF 替代，零额外成本（见 market-data-system §0.3） |

---

## Open Questions / 阻塞项

| # | 问题 | 阻塞任务 | 负责人 | 状态 |
|---|------|---------|--------|------|
| 1 | Polygon.io Poly.feed+ 授权是否已完成？当前使用标准 API Key 向用户展示行情违反服务条款 | T16 | PM + Legal | ✅ **不阻塞开发**，阻塞生产上线，已转交 PM + Legal 跟进 |
| 2 | 换手率计算所需的"流通股数"数据源是否已接入 Polygon.io Fundamental API？ | T04 | market-data-engineer | ✅ **已解决**：服务端预计算 `turnover_rate` 字段直接返回，移动端无需关心数据源 |
| 3 | 中文公司名与拼音搜索的 Top 1000 美股数据是否已准备？ | T06 / T13 | market-data-engineer | ✅ **不阻塞开发**：接口合约已定，先用英文数据联调，最终验收时确认中文/拼音结果 |
| 4 | 访客升级为注册用户后，WebSocket reauth 是否需要重新订阅 symbols？ | T16 | market-data-engineer | ✅ **已明确**：不需要重新订阅。websocket-spec v2.1 §Step5：服务端自动将连接切换至 LiveQuoteGroup 并推送 SNAPSHOT 帧 |
| 5 | K线图"分时"显示范围是否仅常规交易时段（09:30-16:00 ET），还是包含盘前盘后？ | T05 | PM | ✅ **已明确**：仅常规交易时段（09:30–16:00 ET，约 390 根），API 直接返回，客户端无需过滤（market-api-spec §4.6） |

---

## 技术债务与 Phase 2 规划

| 项目 | 描述 | 优先级 |
|------|------|--------|
| Level 2 深度盘口 | Phase 1 仅展示 Level 1（买一价/卖一价），Level 2（5/10/20档）Phase 2 规划 | P2 |
| 港股行情 | Phase 1 港股 Tab 显示"敬请期待"，Phase 2 接入 HKEX OMD | P2 |
| 行情警报（价格提醒） | Phase 1 不实现，Phase 2 规划 | P3 |
| 期权链 | Phase 1 不实现，Phase 2 规划 | P3 |
| 股票对比 | Phase 1 不实现，Phase 2 规划 | P3 |
| 自选股分组 | Phase 1 单一列表，Phase 2 支持自定义分组 | P3 |
| 财报日历深度数据 | Phase 1 基础财务数据，Phase 2 深度财报分析 | P3 |

---

## 参考资源

| 资源 | 路径 |
|------|------|
| Auth 模块实现参考 | [mobile/docs/specs/auth.tracker.md](auth.tracker.md) |
| Flutter 技术规格 | [mobile/docs/specs/shared/mobile-flutter-tech-spec.md](shared/mobile-flutter-tech-spec.md) |
| JSBridge 规范 | [mobile/docs/specs/shared/10-jsbridge-spec.md](shared/10-jsbridge-spec.md) |
| H5 vs Native 决策 | [mobile/docs/specs/shared/h5-vs-native-decision.md](shared/h5-vs-native-decision.md) |
| 金融编码规范 | [.claude/rules/financial-coding-standards.md](../../../.claude/rules/financial-coding-standards.md) |
| 安全合规规范 | [.claude/rules/security-compliance.md](../../../.claude/rules/security-compliance.md) |
| 行情数据行业研究 | [docs/references/market-data-industry-research.md](../../../docs/references/market-data-industry-research.md) |
