# [ARCHIVED] 移动端行情数据层实施方案

> **⚠️ 归档说明**
>
> **归档日期**: 2026-03-15
> **归档原因**:
> 1. 本文档基于 **KMP/Kotlin** 技术栈撰写（StateFlow、Koin、@Composable、ViewModelScope 等），项目已于 2026-03-13 切换至 **Flutter/Dart/Riverpod**，文档内容与当前技术栈完全不兼容。
> 2. 行情模块 PRD（PRD-03）尚未获得行情工程师的最终 approve，待 PRD 确定后由 mobile-engineer 基于 Flutter 技术栈重新输出实施方案。
>
> **后续替代文档**: Flutter 版本的行情数据层架构已在 `market/market-implementation-spec.md` §7-8 中完整描述（基于 Riverpod + Dio + WebSocket）。
>
> **参考入口**:
> - 当前技术栈: `docs/specs/mobile-flutter-tech-spec.md`
> - 行情实现规范: `docs/specs/market/market-implementation-spec.md`
> - 行情 PRD: `docs/prd/03-market.md`

---

## 概述

本文档记录了移动端行情模块数据层的完整实施方案，包括数据模型、API客户端、Repository、ViewModel以及UI集成。

## 已完成的工作

### 1. 数据模型层 (Domain Models)

创建了完整的行情数据模型：

**Stock.kt** - 股票基本信息
- 字段：symbol, name, nameCN, market, price, change, changePercent, marketCap, pe, pb, volume, timestamp
- 使用 BigDecimal 类型处理价格数据（符合金融编码标准）
- 定义了 Market 枚举（US/HK）和 StockCategory 枚举（自选/美股/港股/热门）

**Kline.kt** - K线数据
- 字段：timestamp, open, high, low, close, volume
- 定义了 KlineInterval 枚举（1m/5m/15m/30m/1h/1d/1w/1M）

**StockDetail.kt** - 股票详情
- 扩展字段：open, high, low, close, eps, dividend, high52w, low52w, avgVolume
- SearchResult - 搜索结果模型
- News - 新闻模型
- Financial - 财报数据模型

**WsMessage.kt** - WebSocket 消息
- Subscribe/Unsubscribe - 报价订阅控制
- SubscribeDepth/UnsubscribeDepth - 深度行情订阅控制
- Ping/Pong - 心跳机制
- Quote - 实时行情推送
- Depth - 深度行情推送（5档盘口）
- Trade - 逐笔成交推送
- Error - 错误消息
- QuoteData - 实时行情数据（使用 String 避免精度丢失），含扩展字段：bidPrice, askPrice, bidSize, askSize, open, high, low, prevClose, turnover, status(TradingStatus), session(MarketSession)

**Depth.kt** - 盘口/深度数据 *(2026-03-09 新增)*
- PriceLevel（price: String, volume, orderCount）
- OrderBook（symbol, market, bids, asks, timestamp）— 完整订单簿
- DepthData（symbol, bids, asks, timestamp）— WebSocket 推送载荷

**TradeRecord.kt** - 成交记录 *(2026-03-09 新增)*
- TradeSide 枚举（UNKNOWN, BUY, SELL）
- TradeRecord（symbol, price, volume, timestamp, tradeId, side）

**TradingStatus.kt** - 交易状态 *(2026-03-09 新增)*
- TradingStatus 枚举（UNKNOWN, PRE_MARKET, TRADING, LUNCH_BREAK, POST_MARKET, CLOSED, HALTED, SUSPENDED）
- MarketSession 枚举（UNKNOWN, PRE_MARKET, REGULAR, POST_MARKET, EXTENDED）

### 2. API 层

**ApiModels.kt** - API 通用模型
- ApiResponse<T> - 统一响应格式
- PagedResponse<T> - 分页响应
- ApiException - 异常类型（NetworkError, ServerError, Unauthorized, BadRequest, NotFound, Unknown）
- ApiResult<T> - 结果封装（Success/Error）

**MarketApiClient.kt** - 行情 API 客户端

实现了所有 REST API 接口：
- getStocks() - 获取股票列表（支持分类筛选、分页）
- getStockDetail() - 获取股票详情
- getKline() - 获取K线数据（支持多种周期、时间范围）
- getDepth() - 获取盘口深度数据（支持指定档位数，默认5档） *(2026-03-09 新增)*
- searchStocks() - 搜索股票
- getHotSearches() - 获取热门搜索
- getNews() - 获取新闻
- getFinancials() - 获取财报
- addToWatchlist() - 添加自选股
- removeFromWatchlist() - 删除自选股

特性：
- 使用 Ktor HttpClient
- 统一异常处理和映射
- safeApiCall 封装确保所有调用返回 ApiResult

### 3. WebSocket 层

**MarketWebSocketClient.kt** - 实时行情 WebSocket 客户端

核心功能：
- 连接管理（connect/disconnect）
- 报价订阅管理（subscribe/unsubscribe）
- 深度行情订阅管理（subscribeDepth/unsubscribeDepth）*(2026-03-09 新增)*
- 自动心跳（30秒间隔）
- 自动重连（最多5次，指数退避）
- 状态管理（DISCONNECTED/CONNECTING/CONNECTED/RECONNECTING/ERROR）
- 消息解析和分发（quote/depth/trade/pong/error）

数据流：
- state: StateFlow<WsState> - 连接状态
- quotes: SharedFlow<QuoteData> - 实时行情推送
- depth: SharedFlow<DepthData> - 深度行情推送 *(2026-03-09 新增)*
- trades: SharedFlow<TradeRecord> - 逐笔成交推送 *(2026-03-09 新增)*
- errors: SharedFlow<String> - 错误消息

特性：
- 断线自动重连
- 重连后自动恢复报价和深度订阅
- 心跳超时检测
- 线程安全

### 4. Repository 层

**MarketRepository.kt** - 数据仓库接口和实现

职责：
- 封装 API 客户端和 WebSocket 客户端
- 提供统一的数据访问接口
- 管理数据流

接口方法：
- REST API 方法（getStocks, getStockDetail, getKline, getDepth, searchStocks, getNews, getFinancials, addToWatchlist, removeFromWatchlist）
- WebSocket 方法（connectWebSocket, disconnectWebSocket, subscribeQuotes, unsubscribeQuotes, subscribeDepth, unsubscribeDepth）
- 数据流（wsState, realtimeQuotes, realtimeDepth, realtimeTrades, wsErrors）

### 5. ViewModel 层

**MarketViewModel.kt** - 行情页面 ViewModel

状态管理：
- MarketUiState（isLoading, stocks, selectedCategory, error, wsConnected）
- 使用 StateFlow 管理 UI 状态
- 使用 Map 缓存股票数据以支持实时更新

功能：
- loadStocks() - 加载股票列表
- refresh() - 刷新数据
- switchCategory() - 切换分类（自动取消旧订阅，订阅新数据）
- addToWatchlist() - 添加自选
- removeFromWatchlist() - 删除自选
- connectWebSocket() - 连接 WebSocket
- 自动订阅自选股实时行情
- 实时更新股票价格

**StockDetailViewModel.kt** - 股票详情 ViewModel

状态管理：
- StockDetailUiState（isLoading, stockDetail, klineData, selectedInterval, news, financials, error, isInWatchlist, selectedTab, orderBook, showMaLines, showVolume）
- StockDetailTab 枚举（KLINE, ORDER_BOOK, NEWS, FINANCIALS）

功能：
- loadStockDetail() - 加载股票详情
- loadKlineData() - 加载K线数据
- loadNews() - 加载新闻
- loadFinancials() - 加载财报
- switchInterval() - 切换K线周期
- selectTab() - 切换页面Tab（按需懒加载：深度/新闻/财报）*(2026-03-09 新增)*
- toggleWatchlist() - 添加/删除自选
- toggleMaLines() - 切换MA均线显示 *(2026-03-09 新增)*
- toggleVolume() - 切换成交量显示 *(2026-03-09 新增)*
- subscribeDepthUpdates() - 订阅深度行情实时更新 *(2026-03-09 新增)*
- 自动订阅当前股票实时行情
- onCleared() - 清理资源（取消报价和深度订阅）

### 6. UI 层集成

**MarketScreen.kt** - 行情页面（已更新）

改进：
- 集成 MarketViewModel
- 使用 collectAsState() 观察状态
- 显示加载状态、错误状态、空状态
- 支持下拉刷新
- 显示 WebSocket 连接状态（绿点指示器）
- Tab 切换自动加载对应分类数据
- 使用真实的 Stock 数据模型（替换了 Mock 数据）

**StockDetailScreen.kt** - 股票详情页面（增强）

功能：
- 顶部导航栏（返回、股票代码、自选按钮、价格提醒按钮）
- 价格区域（当前价、涨跌额、涨跌幅、带动画）
- K线图区域（支持多种周期切换、MA线/成交量开关）*(2026-03-09 增强)*
- TabRow 切换：盘口 | 新闻 | 财报 *(2026-03-09 新增)*
- 盘口Tab：基本信息 + 5档买卖盘口（OrderBookView）*(2026-03-09 新增)*
- 新闻Tab：新闻列表（带相对时间显示）
- 财报Tab：财务报告表格（季度/营收/净利润/EPS）*(2026-03-09 新增)*
- 底部交易按钮（买入/卖出）
- 集成 StockDetailViewModel
- 实时价格更新
- 资源清理（DisposableEffect）

**KlineChart.kt** - K线图组件 *(2026-03-09 重写)*

功能：
- KMP 兼容：全部使用 Compose DrawScope + TextMeasurer，无 android.graphics 依赖
- 缩放（0.5x-3x）、拖动、十字线、数据提示
- 成交量柱状图（底部 20%，color-coded by close vs open）
- MA均线叠加（MA5 蓝色/MA10 橙色/MA20 紫色）
- X轴时间标签（分时 HH:mm / 日K以上 MM/dd）
- Y轴价格标签
- 参数：showVolume, showMaLines, interval

**OrderBookView.kt** - 盘口组件 *(2026-03-09 新增)*

功能：
- 5档买卖盘口显示
- 卖盘（红色，从高到低）+ 价差行 + 买盘（绿色，从高到低）
- 每档显示：价格、成交量、委托笔数
- 成交量条形图（按比例填充）
- 价差指示器（绝对值 + 百分比）
- 空数据优雅处理

## 架构设计

### 数据流向

```
UI Layer (Compose)
    ↓ collectAsState()
ViewModel Layer (StateFlow)
    ↓ suspend functions
Repository Layer
    ↓
API Client (REST) + WebSocket Client
    ↓
Backend Services
```

### 实时数据流

```
Backend WebSocket
    ↓
MarketWebSocketClient
    ├── quotes: SharedFlow  ──→ StockDetailViewModel.observeRealtimeQuotes()
    ├── depth: SharedFlow   ──→ StockDetailViewModel.subscribeDepthUpdates()
    └── trades: SharedFlow  ──→ (reserved for future use)
    ↓
MarketRepository (delegates to WS client)
    ↓
ViewModel (filters by symbol, updates UiState)
    ↓
UI recomposes (price animation, order book update)
```

### 依赖注入

使用 Koin 进行依赖注入：

```kotlin
// 需要在 DI 模块中注册
single { MarketApiClient(get(), baseUrl = "https://api.example.com") }
single { MarketWebSocketClient(get(), wsUrl = "wss://api.example.com/ws", get()) }
single<MarketRepository> { MarketRepositoryImpl(get(), get()) }
viewModel { MarketViewModel(get()) }
viewModel { (symbol: String) -> StockDetailViewModel(get(), symbol) }
```

## 技术亮点

### 1. 类型安全的金融数据处理
- 所有价格字段使用 BigDecimal，避免浮点精度问题
- 符合 `.claude/rules/financial-coding-standards.md` 规范

### 2. 响应式架构
- 使用 Kotlin Flow 和 StateFlow
- UI 自动响应数据变化
- 单向数据流

### 3. 错误处理
- 统一的 ApiResult 封装
- 详细的异常类型
- UI 层友好的错误提示

### 4. WebSocket 可靠性
- 自动重连机制
- 心跳保活
- 订阅状态恢复
- 连接状态可观察

### 5. 性能优化
- 使用 Map 缓存股票数据，O(1) 查找
- LazyColumn 虚拟化列表
- 按需加载（新闻、财报）
- 资源自动清理

## 待完成工作

### P0 - 必须完成

1. **DI 模块配置**
   - 在 `shared/src/commonMain/kotlin/com/brokerage/core/di/` 创建 MarketModule.kt
   - 注册所有依赖

2. **HttpClient 配置**
   - 配置 baseUrl（从环境变量或配置文件读取）
   - 配置 JWT 认证拦截器
   - 配置超时时间

3. **WebSocket 认证**
   - 实现 token 获取逻辑
   - 在 MarketScreen 初始化时调用 connectWebSocket(token)

4. ~~**K线图组件**~~ ✅ 已完成 (2026-03-09)
   - ~~实现 KlineChart Composable（或集成第三方图表库）~~
   - ~~支持缩放、拖动~~
   - ~~显示十字线和数据提示~~
   - 已实现：KMP 兼容 Canvas 绘制、成交量柱状图、MA 均线叠加、X/Y 轴标签

5. **搜索页面**
   - 创建 SearchScreen.kt
   - 实现搜索输入、历史记录、搜索结果列表

### P1 - 重要功能

6. **下拉刷新**
   - 集成 SwipeRefresh 或 PullRefresh
   - 在 MarketScreen 和 StockDetailScreen 中实现

7. **缓存策略**
   - 实现本地缓存（SQLDelight 或 Room）
   - 离线数据支持
   - 缓存过期策略

8. **价格提醒**
   - 后端 API 实现（需要 backend-engineer）
   - 移动端设置界面
   - 推送通知集成

9. ~~**深度图**~~ ✅ 已完成 (2026-03-09)
   - ~~Level 2 数据接口（需要 backend-engineer）~~
   - ~~深度图 UI 组件~~
   - 已实现：5档盘口 OrderBookView、深度行情 WebSocket 订阅、REST 深度快照接口

### P2 - 优化项

10. **单元测试**
    - ViewModel 测试
    - Repository 测试
    - API Client 测试

11. **性能监控**
    - WebSocket 消息频率统计
    - API 响应时间监控
    - 内存使用监控

12. **错误上报**
    - 集成 Sentry 或 Firebase Crashlytics
    - 上报 API 错误和 WebSocket 错误

## 后端依赖

移动端数据层已完成，但依赖后端 Market Service 实现以下接口：

### REST API
- GET /api/v1/market/stocks
- GET /api/v1/market/stocks/:symbol
- GET /api/v1/market/kline/:symbol
- GET /api/v1/market/depth/:symbol?levels={n} *(2026-03-09 新增 — 盘口深度快照，默认5档)*
- GET /api/v1/market/search
- GET /api/v1/market/hot-searches
- GET /api/v1/market/news/:symbol
- GET /api/v1/market/financials/:symbol
- POST /api/v1/market/watchlist
- DELETE /api/v1/market/watchlist/:symbol

### WebSocket
- WS /api/v1/market/realtime
- 消息格式：subscribe, unsubscribe, ping, pong, quote, error
- subscribe_depth, unsubscribe_depth, depth, trade *(2026-03-09 新增)*

### 重要提醒
后端实现时务必使用 `shopspring/decimal.Decimal` 而非 `float64` 处理价格数据，符合金融编码标准。

## 测试建议

### 单元测试示例

```kotlin
class MarketViewModelTest {
    @Test
    fun `loadStocks should update uiState with stocks`() = runTest {
        // Given
        val mockRepository = mockk<MarketRepository>()
        coEvery { mockRepository.getStocks(any(), any(), any()) } returns
            ApiResult.Success(PagedResponse(total = 1, page = 1, pageSize = 20, items = listOf(mockStock)))

        val viewModel = MarketViewModel(mockRepository)

        // When
        viewModel.loadStocks(StockCategory.WATCHLIST)

        // Then
        assertEquals(1, viewModel.uiState.value.stocks.size)
        assertFalse(viewModel.uiState.value.isLoading)
    }
}
```

### 集成测试
- 使用 MockWebServer 模拟后端 API
- 测试 WebSocket 重连逻辑
- 测试实时数据更新流程

## 文件清单

### 新建文件

**Domain Models**
1. `mobile/shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/Stock.kt`
2. `mobile/shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/Kline.kt`
3. `mobile/shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/StockDetail.kt`
4. `mobile/shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/WsMessage.kt`
5. `mobile/shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/Depth.kt` *(2026-03-09 新增)*
6. `mobile/shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/TradeRecord.kt` *(2026-03-09 新增)*
7. `mobile/shared/src/commonMain/kotlin/com/brokerage/domain/marketdata/TradingStatus.kt` *(2026-03-09 新增)*

**Data Layer**
8. `mobile/shared/src/commonMain/kotlin/com/brokerage/data/api/ApiModels.kt`
9. `mobile/shared/src/commonMain/kotlin/com/brokerage/data/api/MarketApiClient.kt`
10. `mobile/shared/src/commonMain/kotlin/com/brokerage/data/websocket/MarketWebSocketClient.kt`
11. `mobile/shared/src/commonMain/kotlin/com/brokerage/data/repository/MarketRepository.kt`

**Presentation Layer**
12. `mobile/shared/src/commonMain/kotlin/com/brokerage/presentation/market/MarketViewModel.kt`
13. `mobile/shared/src/commonMain/kotlin/com/brokerage/presentation/market/StockDetailViewModel.kt`

**UI Layer**
14. `mobile/composeApp/src/commonMain/kotlin/com/brokerage/ui/screens/market/StockDetailScreen.kt`
15. `mobile/composeApp/src/commonMain/kotlin/com/brokerage/ui/components/OrderBookView.kt` *(2026-03-09 新增)*

### 修改文件
1. `mobile/composeApp/src/commonMain/kotlin/com/brokerage/ui/screens/market/MarketScreen.kt` - 集成 ViewModel，使用真实数据
2. `mobile/composeApp/src/commonMain/kotlin/com/brokerage/ui/components/KlineChart.kt` - KMP 兼容重写（Canvas + TextMeasurer） *(2026-03-09 重写)*
3. `mobile/shared/build.gradle.kts` - 移除 protobuf-kotlin 依赖 *(2026-03-09 修改)*

## 总结

移动端行情数据层已完整实现，包括：
- ✅ 完整的数据模型（符合金融编码标准）
- ✅ REST API 客户端（所有接口，含盘口深度）
- ✅ WebSocket 客户端（实时行情、深度行情、逐笔成交、自动重连）
- ✅ Repository 层（数据访问统一接口）
- ✅ ViewModel 层（状态管理、Tab 懒加载、深度订阅生命周期）
- ✅ UI 集成（MarketScreen、StockDetailScreen with Tabs）
- ✅ K线图组件（KMP 兼容 Canvas 绘制、MA 均线、成交量柱状图）
- ✅ 盘口组件（5档买卖盘口、价差指示器）
- ✅ 移除 protobuf-kotlin 依赖（JVM-only，改用手写模型 + JSON 序列化）

### 架构决策记录

- **No protobuf codegen in mobile** (2026-03-09)：protobuf-kotlin 是 JVM-only 依赖，会导致 iOS 构建失败。改为手写 Kotlin 数据模型（@Serializable），通过 JSON 序列化与后端通信。Proto 文件仍作为接口契约。
- **KlineChart KMP 重写** (2026-03-09)：原实现使用 android.graphics.Paint/Canvas（Android-only），重写为 Compose TextMeasurer + DrawScope，支持 Android + iOS。

下一步：
1. 配置 DI 模块
2. 实现搜索页面
3. 等待后端 Market Service 实现深度/成交接口
4. 集成测试

---
**创建时间**: 2026-03-07
**最后更新**: 2026-03-09
**作者**: Claude (Orchestrator)
**项目**: brokerage-trading-app-agents
**模块**: mobile/行情模块
