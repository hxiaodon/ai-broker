# K线图实时更新实现记录

**日期：** 2026-04-16  
**涉及文件：**
- `lib/features/market/application/kline_realtime_notifier.dart`
- `lib/features/market/domain/entities/candle_aggregator.dart`
- `lib/features/market/presentation/widgets/kline_chart_widget.dart`
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
