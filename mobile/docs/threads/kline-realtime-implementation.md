# K线图实时更新实现记录

**日期：** 2026-04-16 ~ 2026-04-17  
**涉及文件：**
- `lib/features/market/application/kline_realtime_notifier.dart`
- `lib/features/market/domain/entities/candle_aggregator.dart`
- `lib/features/market/presentation/widgets/kline_chart_widget.dart`
- `lib/features/market/application/stock_detail_notifier.dart`
- `lib/shared/widgets/price/price_change_badge.dart`
- `mock-server/data.go`
- `test/features/market/domain/entities/candle_aggregator_test.dart`

---

## 背景

K线图原来使用 `FutureProvider.autoDispose` 只在初始化时加载一次历史数据，不接收 WebSocket 实时更新。用户在分时图页面看不到价格变化。

---

## 最终架构

```
KLineChartWidget
  ├─ 分时 (1min) → _IntradayChartView (ConsumerStatefulWidget)
  │     ├─ 初始加载: KlineRealtimeNotifier → REST API
  │     ├─ 实时更新: listenManual → _onCandlesUpdated
  │     │     └─ ChartSeriesController.updateDataSource (增量，无 rebuild)
  │     ├─ Info bar: ValueNotifier<_OhlcvInfo?> + ValueListenableBuilder
  │     └─ 十字线: ValueNotifier<({x, y})?> + ValueListenableBuilder
  └─ 日K/周K/月K → _ChartView (静态，FutureProvider)
```

**CandleAggregator：** 将 WebSocket tick 聚合成 1 分钟蜡烛
- 使用客户端 UTC 时间检测分钟边界
- Volume 直接使用 tick 的累计日成交量（不是增量）
- 跨分钟边界时返回完成的蜡烛，同时开始新蜡烛

---

## 试错过程（第一阶段：实时更新架构）

### 尝试 1：FutureProvider 中转（失败）

**方案：** 在 `_klineDataProvider` 里对 1min 周期 `ref.watch(klineRealtimeProvider)` 中转。

**问题：** `KlineRealtimeNotifier` 每秒更新状态 → `_klineDataProvider` 每秒重建 → `_ChartView` 每秒完整重建 → Syncfusion 图表每秒完整重绘，肉眼可见闪烁。

---

### 尝试 2：ref.listen 放在 build() 里（失败）

**问题：** `ref.listen` 在 `build()` 里，每次 `setState` 都重新注册一个新 listener。随着点击次数增加，listener 数量线性增长。tick 到来时所有 listener 同时触发，引发大量 `setState`，UI 线程被堵死，**十字线卡住不动**。

---

### 尝试 3：ref.listen 移到 didChangeDependencies（失败）

**问题 1：** `ref.listen` 在 `ConsumerStatefulWidget` 里只能在 `build()` 中调用，放在 `didChangeDependencies` 里会抛出 `No Directionality widget found` 异常，导致无限循环，进程卡死。

**问题 2：** `_trackballBehavior` 在 `didChangeDependencies` 里重建 → Syncfusion 重置内部触摸状态 → 十字线卡死。

---

### 尝试 4：listenManual + initState 初始化 behavior（部分成功）

**方案：**
- `_trackballBehavior` 移到 `initState`（只创建一次）
- 用 `ref.listenManual` 替代 `ref.listen`（可在 `didChangeDependencies` 安全调用）

**问题：** `_onCandlesUpdated` 里仍有 `setState(() {})` 每秒刷新 info bar，rebuild 期间 Syncfusion 的触摸事件处理被打断，切换时段后十字线仍会卡死。

---

### 最终方案：ValueNotifier 彻底消除 setState（成功）

**核心思路：** tick 更新路径上**零 setState**。

```dart
final _infoNotifier = ValueNotifier<_OhlcvInfo?>(null);
final _crosshairNotifier = ValueNotifier<({double x, double? y})?>(null);
```

tick 到来 → `ChartSeriesController.updateDataSource` + `_infoNotifier.value = ...`，零 rebuild。  
trackball 移动 → `_crosshairNotifier.value = ...` + `_infoNotifier.value = ...`，零 rebuild。  
**setState 只剩一处：** 初始数据加载完成时触发一次性渲染（`_chartReady = true`）。

---

## 试错过程（第二阶段：缩放后十字线卡死）

### 问题描述

缩放图表后，再点击十字线会卡死。

### 尝试 5：onChartTouchInteractionUp 清除十字线（失败）

**方案：** 在 `onChartTouchInteractionUp` 里清除 `_crosshairNotifier`。

**问题：** `onChartTouchInteractionUp` 在双指缩放时每次手指抬起都会触发（包括缩放中途一根手指先抬起）。清除十字线后 Syncfusion 内部 trackball 状态和我们的 overlay 不同步，下次点击卡死。

---

### 尝试 6：_isZooming flag + onZooming（部分成功）

**方案：** 用 `onZooming` 设置 `_isZooming = true`，`onChartTouchInteractionUp` 里判断 `!_isZooming` 才清除。

**问题：** `onZooming` 只在拖动缩放过程中触发，**双击缩放（`enableDoubleTapZooming`）不触发 `onZooming`**，所以双击缩放后 `_isZooming` 仍是 `false`，问题依旧。

---

### 最终方案：onZoomStart + Timer 同步（成功）

**关键发现：** Syncfusion 有两套缩放回调：
- `onZooming`：拖动缩放过程中持续触发
- `onZoomStart` / `onZoomEnd`：所有缩放操作（包括双击）的开始和结束

**方案：**
1. 用 `onZoomStart` 替代 `onZooming`，覆盖所有缩放类型
2. 缩放开始时立即清除十字线 overlay（避免显示错误位置）
3. 完全移除 `onChartTouchInteractionUp` 对十字线的干预
4. 用 `Timer(3200ms)` 与 Syncfusion 的 `hideDelay: 3000ms` 同步，trackball 消失后自动清除 overlay
5. `_onTrackballChanged` 里对 `xPosition` 做 null 检查（缩放期间可能为 null，强制解包会崩溃）

```dart
onZoomStart: (_) {
  _isZooming = true;
  if (_crosshairNotifier.value != null) _clearCrosshair();
},
onZoomEnd: (_) { _isZooming = false; },

// 在 _onTrackballChanged 里：
final xPos = point.xPosition;
if (xPos == null) return; // 缩放期间跳过

// 每次 trackball 更新重置 hide timer
_crosshairHideTimer?.cancel();
_crosshairHideTimer = Timer(const Duration(milliseconds: 3200), _clearCrosshair);
```

---

## 试错过程（第三阶段：数据和显示 Bug）

### Bug 1：_chartData 与 provider 不同步导致数据缺口

**现象：** 分时图运行一段时间后，图表数据线出现缺口，X 轴坐标异常跳变。

**原因：** `KlineRealtimeNotifier` 触发 390 上限裁剪时，`candles.length` 保持 390，但 `_chartData` 里的 `removeAt(0)` 和 `add()` 顺序导致 `_prevCandleCount` 与实际长度不同步，后续增量索引越界。

**修复：** 加同步检查——`_chartData.length != _prevCandleCount` 或 `newCount > _prevCandleCount + 1` 时走 `_fullReset()`。`_fullReset` 用 `setState` 触发完整重建（比 `updateDataSource(all indexes)` 在缩放状态下更安全）。

---

### Bug 2：自选股进入详情页再返回后停止实时更新

**现象：** 点击进入 AAPL 详情页，返回行情主页后，AAPL 的自选股价格不再更新。

**原因：** `StockDetailNotifier.onDispose` 调用了 `wsNotifier.unsubscribe([symbol])`。WebSocket 订阅**没有引用计数**，unsubscribe 会直接从共享订阅集合里移除该 symbol，导致 `WatchlistNotifier` 也收不到该 symbol 的 tick。

**修复：** 移除 `StockDetailNotifier.onDispose` 里的 `unsubscribe`。`StockDetailNotifier` 只负责监听 stream，不管理订阅生命周期。

---

### Bug 3：changePct 显示值放大 100 倍

**现象：** AAPL 显示 `-27%`，TSLA 显示 `+300%`，数值明显偏大。

**原因：** `Quote.changePct` 存储的是百分比形式（`1.33` = 1.33%），但 `PriceChangeBadge`、`_IndexCard`、`stock_detail_screen` 里都额外乘以了 `Decimal.fromInt(100)`，导致显示值放大 100 倍。

**修复：** 移除三处 `* Decimal.fromInt(100)`，同时修复 `decimal_extensions.dart` 里 `toPercentChange()` 的同样问题。

---

### Bug 4：DIA 的 changePct 永远不变

**现象：** DIA 的百分比永远显示 `-0.45%`，其他标的正常变化。

**原因：** DIA 价格约 38192，mock server 的 tick delta 固定为 ±0.5，`changePct = 0.5/38192*100 ≈ 0.0013%`，`%.2f` 格式化后是 `"0.00"`，被 `!= Decimal.zero` 过滤掉，每次都保留旧值。

**修复：** mock server 改为按价格比例生成 delta（`±0.5% of base price`），所有标的的 tick 幅度与价格量级匹配。

---

### Bug 5：mock server TICK 帧 changePct 语义错误

**现象：** 各标的的 changePct 随机跳动，不反映真实涨跌幅。

**原因：** `generateTickUpdate` 里 `change = delta`（单次 tick 的价格变化），`changePct = delta/price*100`，这是相对于当前价格的单次变化，不是相对于昨收的累计涨跌幅。

**修复：** 改为 `change = newPrice - prevClose`，`changePct = change/prevClose*100`，与行业标准一致（所有主流行情源推送的都是累计日涨跌幅）。

---

## 关键经验总结

### Riverpod listener 的正确用法

| 场景 | 正确做法 | 错误做法 |
|------|---------|---------|
| 在 `build()` 里监听 | `ref.listen(...)` | — |
| 在 `initState`/`didChangeDependencies` 里监听 | `ref.listenManual(...)` | `ref.listen(...)` |
| 只注册一次 | `_sub ??= ref.listenManual(...)` | `bool _registered` flag |
| 清理 | `dispose()` 里 `_sub?.close()` | 忘记 close |

### Syncfusion 图表的注意事项

- `TrackballBehavior` / `ZoomPanBehavior` 必须在 `initState` 里创建，整个生命周期内引用不变
- 任何 `setState` 都可能打断 Syncfusion 的触摸事件处理
- 实时数据更新用 `ChartSeriesController.updateDataSource`，不用 rebuild
- `onZooming` 只覆盖拖动缩放；`onZoomStart`/`onZoomEnd` 覆盖所有缩放类型（包括双击）
- `onChartTouchInteractionUp` 在双指缩放时也会触发，不能用来判断"单击结束"
- `TrackballArgs.chartPointInfo.xPosition` 在缩放/平移期间可能为 null，必须做 null 检查

### WebSocket 订阅的共享语义

WebSocket 订阅集合是**全局共享的，没有引用计数**。任何 notifier 调用 `unsubscribe` 都会影响所有监听该 symbol 的 notifier。只有"拥有"该 symbol 订阅的 notifier（如 WatchlistNotifier）才应该调用 unsubscribe。

### 高频更新场景的 UI 模式

```
高频数据源 (WebSocket tick, 1/s)
  ↓
命令式 API (ChartSeriesController.updateDataSource)  ← 图表增量更新，零 rebuild
  +
ValueNotifier → ValueListenableBuilder               ← 文字信息局部更新，零 rebuild
```

---

## 提交记录

| Commit | 说明 |
|--------|------|
| `e00f2e4` | feat: 初始实现 KlineRealtimeNotifier + CandleAggregator + 集成 |
| `38ce54e` | fix: ValueNotifier 模式彻底修复十字线卡死问题 |
| `b5ef240` | fix: cap _chartData at 390，修复内存审计发现的边界问题 |
| `8c43eee` | fix: changePct 语义错误、自选股返回后停止更新、_chartData 不同步 |
| `ec6f03e` | fix: changePct 显示放大 100 倍、DIA tick 幅度过小 |
| `03950d0` | fix: 缩放后十字线卡死，onZoomStart + Timer 同步方案 |

---

## 背景

K线图原来使用 `FutureProvider.autoDispose` 只在初始化时加载一次历史数据，不接收 WebSocket 实时更新。用户在分时图页面看不到价格变化。

---

## 最终架构

```
KLineChartWidget
  ├─ 分时 (1min) → _IntradayChartView (ConsumerStatefulWidget)
  │     ├─ 初始加载: KlineRealtimeNotifier → REST API
  │     ├─ 实时更新: listenManual → _onCandlesUpdated
  │     │     └─ ChartSeriesController.updateDataSource (增量，无 rebuild)
  │     ├─ Info bar: ValueNotifier<_OhlcvInfo?> + ValueListenableBuilder
  │     └─ 十字线: ValueNotifier<({x, y})?> + ValueListenableBuilder
  └─ 日K/周K/月K → _ChartView (静态，FutureProvider)
```

**CandleAggregator：** 将 WebSocket tick 聚合成 1 分钟蜡烛
- 使用客户端 UTC 时间检测分钟边界
- Volume 直接使用 tick 的累计日成交量（不是增量）
- 跨分钟边界时返回完成的蜡烛，同时开始新蜡烛

---

## 试错过程

### 尝试 1：FutureProvider 中转（失败）

**方案：** 在 `_klineDataProvider` 里对 1min 周期 `ref.watch(klineRealtimeProvider)` 中转。

```dart
final _klineDataProvider = FutureProvider.autoDispose.family<List<Candle>, KlineParams>(
  (ref, params) async {
    if (params.period == '1min') {
      return ref.watch(klineRealtimeProvider(params).future); // ❌
    }
    ...
  }
);
```

**问题：** `KlineRealtimeNotifier` 每秒更新状态 → `_klineDataProvider` 每秒重建 → `_ChartView` 每秒完整重建 → Syncfusion 图表每秒完整重绘，肉眼可见闪烁。

---

### 尝试 2：ref.listen 放在 build() 里（失败）

**方案：** 新建 `_IntradayChartView`，用 `ref.listen` 监听 provider，通过 `ChartSeriesController.updateDataSource` 做增量更新。

```dart
Widget build(BuildContext context) {
  ref.listen(klineRealtimeProvider(widget.params), (_, next) { // ❌
    next.whenData(_onCandlesUpdated);
  });
  ...
}
```

**问题：** `ref.listen` 在 `build()` 里，每次 `setState` 都重新注册一个新 listener。随着点击次数增加，listener 数量线性增长。tick 到来时所有 listener 同时触发 `_onCandlesUpdated`，引发大量 `setState`，UI 线程被堵死，**十字线卡住不动**。

---

### 尝试 3：ref.listen 移到 didChangeDependencies（失败）

**方案：** 用 `_listenerRegistered` flag 确保只注册一次。

```dart
bool _listenerRegistered = false;

void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_listenerRegistered) {
    _listenerRegistered = true;
    ref.listen(...); // ❌ ref.listen 不能在 didChangeDependencies 里调用
  }
  _trackballBehavior = TrackballBehavior(...); // ❌ 每次 setState 都重建
}
```

**问题 1：** `ref.listen` 在 `ConsumerStatefulWidget` 里只能在 `build()` 中调用，放在 `didChangeDependencies` 里会抛出 `No Directionality widget found` 异常，导致无限循环，进程卡死。

**问题 2：** `_trackballBehavior` 在 `didChangeDependencies` 里重建，`setState` 触发 rebuild → `didChangeDependencies` 执行 → `_trackballBehavior` 对象变了 → Syncfusion 重置内部触摸状态 → 十字线卡死。

---

### 尝试 4：listenManual + initState 初始化 behavior（部分成功）

**方案：**
- `_trackballBehavior` 移到 `initState`（只创建一次）
- 用 `ref.listenManual` 替代 `ref.listen`（可在 `didChangeDependencies` 安全调用）

```dart
void initState() {
  _trackballBehavior = TrackballBehavior(...); // ✅ 只创建一次
}

void didChangeDependencies() {
  _klineSubscription ??= ref.listenManual(...); // ✅ 只注册一次
}
```

**问题：** `_onCandlesUpdated` 里仍有 `setState(() {})` 每秒刷新 info bar。`setState` 触发 rebuild，rebuild 期间 Syncfusion 的触摸事件处理被打断。切换时段后再回到分时图，十字线仍会在一段时间后卡死。

---

### 最终方案：ValueNotifier 彻底消除 setState（成功）

**核心思路：** tick 更新路径上**零 setState**。

```dart
// 用 ValueNotifier 替代 setState 驱动的状态
final _infoNotifier = ValueNotifier<_OhlcvInfo?>(null);
final _crosshairNotifier = ValueNotifier<({double x, double? y})?>(null);
```

**tick 更新路径：**
```
tick 到来
  → _onCandlesUpdated()
  → ChartSeriesController.updateDataSource(updatedDataIndexes: [last])  // 增量更新图表
  → _infoNotifier.value = _buildInfoFromLatest()                        // 更新 info bar
  // 零 setState，零 rebuild
```

**trackball 移动路径：**
```
用户触摸
  → _onTrackballChanged()
  → _crosshairNotifier.value = (x: ..., y: ...)  // 更新十字线位置
  → _infoNotifier.value = _OhlcvInfo(...)         // 更新 info bar
  // 零 setState，零 rebuild
```

**UI 消费：**
```dart
// Info bar — 只在 ValueNotifier 变化时重建，不受 tick 影响
ValueListenableBuilder<_OhlcvInfo?>(
  valueListenable: _infoNotifier,
  builder: (_, info, __) => _OhlcvInfoBar(info: info, ...),
),

// 十字线 — 同上
ValueListenableBuilder<({double x, double? y})?>(
  valueListenable: _crosshairNotifier,
  builder: (_, pos, __) => pos != null ? _CrosshairOverlay(...) : SizedBox.shrink(),
),
```

**setState 只剩一处：** 初始数据加载完成时触发一次性渲染（`_chartReady = true`）。

---

## 关键经验

### 1. Riverpod listener 的正确用法

| 场景 | 正确做法 | 错误做法 |
|------|---------|---------|
| 在 `build()` 里监听 | `ref.listen(...)` | — |
| 在 `initState`/`didChangeDependencies` 里监听 | `ref.listenManual(...)` | `ref.listen(...)` |
| 只注册一次 | `_sub ??= ref.listenManual(...)` | `bool _registered` flag |
| 清理 | `dispose()` 里 `_sub?.close()` | 忘记 close |

### 2. Syncfusion 图表的 setState 敏感性

Syncfusion `SfCartesianChart` 对 widget rebuild 非常敏感：
- `TrackballBehavior` / `ZoomPanBehavior` 对象必须在 `initState` 里创建，整个生命周期内引用不变
- 任何 `setState` 都可能打断正在进行的触摸事件处理
- 实时数据更新应通过 `ChartSeriesController.updateDataSource` 而非 rebuild

### 3. 高频更新场景的 UI 模式

每秒更新的数据不应该驱动 `setState`。正确模式：

```
高频数据源 (WebSocket tick)
  ↓
命令式 API (ChartSeriesController.updateDataSource)  ← 图表增量更新
  +
ValueNotifier                                         ← 文字信息更新
  ↓
ValueListenableBuilder                                ← 局部重建，不影响图表
```

### 4. Volume 语义

WebSocket 推送的 `volume` 是**当日累计成交量**，不是分钟增量。直接赋值给蜡烛的 `v` 字段即可，无需累加。

---

## 提交记录

| Commit | 说明 |
|--------|------|
| `e00f2e4` | feat: 初始实现 KlineRealtimeNotifier + CandleAggregator + 集成 |
| `38ce54e` | fix: ValueNotifier 模式彻底修复十字线卡死问题 |
