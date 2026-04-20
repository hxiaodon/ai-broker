// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kline_realtime_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages real-time K-line data for intraday (1min) charts.
///
/// ## State
/// `AsyncValue<List<Candle>>` — ordered list of 1-minute candles.
///
/// ## Lifecycle
/// 1. Initial load: REST API `getKline()` for historical candles
/// 2. Subscribe to WebSocket for real-time tick updates (1min period only)
/// 3. Aggregate ticks into candles using [CandleAggregator]
/// 4. Update last candle in-place or append new candle on minute boundary
///
/// ## Real-time updates (1min only)
/// - Subscribes to [quoteWebSocketProvider] when connected
/// - Listens to tick stream filtered by symbol
/// - Uses [CandleAggregator] to convert ticks → candles
/// - Updates state on each tick (optimistic UI)
///
/// ## Other periods (1d/1w/1mo)
/// - Static REST data only (no WebSocket subscription)
/// - Handled by [_klineDataProvider] in kline_chart_widget.dart
///
/// ## Memory management
/// - Limits candle history to 390 candles (1 trading day)
/// - Removes oldest candles when limit exceeded

@ProviderFor(KlineRealtimeNotifier)
final klineRealtimeProvider = KlineRealtimeNotifierFamily._();

/// Manages real-time K-line data for intraday (1min) charts.
///
/// ## State
/// `AsyncValue<List<Candle>>` — ordered list of 1-minute candles.
///
/// ## Lifecycle
/// 1. Initial load: REST API `getKline()` for historical candles
/// 2. Subscribe to WebSocket for real-time tick updates (1min period only)
/// 3. Aggregate ticks into candles using [CandleAggregator]
/// 4. Update last candle in-place or append new candle on minute boundary
///
/// ## Real-time updates (1min only)
/// - Subscribes to [quoteWebSocketProvider] when connected
/// - Listens to tick stream filtered by symbol
/// - Uses [CandleAggregator] to convert ticks → candles
/// - Updates state on each tick (optimistic UI)
///
/// ## Other periods (1d/1w/1mo)
/// - Static REST data only (no WebSocket subscription)
/// - Handled by [_klineDataProvider] in kline_chart_widget.dart
///
/// ## Memory management
/// - Limits candle history to 390 candles (1 trading day)
/// - Removes oldest candles when limit exceeded
final class KlineRealtimeNotifierProvider
    extends $AsyncNotifierProvider<KlineRealtimeNotifier, List<Candle>> {
  /// Manages real-time K-line data for intraday (1min) charts.
  ///
  /// ## State
  /// `AsyncValue<List<Candle>>` — ordered list of 1-minute candles.
  ///
  /// ## Lifecycle
  /// 1. Initial load: REST API `getKline()` for historical candles
  /// 2. Subscribe to WebSocket for real-time tick updates (1min period only)
  /// 3. Aggregate ticks into candles using [CandleAggregator]
  /// 4. Update last candle in-place or append new candle on minute boundary
  ///
  /// ## Real-time updates (1min only)
  /// - Subscribes to [quoteWebSocketProvider] when connected
  /// - Listens to tick stream filtered by symbol
  /// - Uses [CandleAggregator] to convert ticks → candles
  /// - Updates state on each tick (optimistic UI)
  ///
  /// ## Other periods (1d/1w/1mo)
  /// - Static REST data only (no WebSocket subscription)
  /// - Handled by [_klineDataProvider] in kline_chart_widget.dart
  ///
  /// ## Memory management
  /// - Limits candle history to 390 candles (1 trading day)
  /// - Removes oldest candles when limit exceeded
  KlineRealtimeNotifierProvider._({
    required KlineRealtimeNotifierFamily super.from,
    required KlineParams super.argument,
  }) : super(
         retry: null,
         name: r'klineRealtimeProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$klineRealtimeNotifierHash();

  @override
  String toString() {
    return r'klineRealtimeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  KlineRealtimeNotifier create() => KlineRealtimeNotifier();

  @override
  bool operator ==(Object other) {
    return other is KlineRealtimeNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$klineRealtimeNotifierHash() =>
    r'b8ad2d836bc913c513bf4a5a193878ccb8cfb8d6';

/// Manages real-time K-line data for intraday (1min) charts.
///
/// ## State
/// `AsyncValue<List<Candle>>` — ordered list of 1-minute candles.
///
/// ## Lifecycle
/// 1. Initial load: REST API `getKline()` for historical candles
/// 2. Subscribe to WebSocket for real-time tick updates (1min period only)
/// 3. Aggregate ticks into candles using [CandleAggregator]
/// 4. Update last candle in-place or append new candle on minute boundary
///
/// ## Real-time updates (1min only)
/// - Subscribes to [quoteWebSocketProvider] when connected
/// - Listens to tick stream filtered by symbol
/// - Uses [CandleAggregator] to convert ticks → candles
/// - Updates state on each tick (optimistic UI)
///
/// ## Other periods (1d/1w/1mo)
/// - Static REST data only (no WebSocket subscription)
/// - Handled by [_klineDataProvider] in kline_chart_widget.dart
///
/// ## Memory management
/// - Limits candle history to 390 candles (1 trading day)
/// - Removes oldest candles when limit exceeded

final class KlineRealtimeNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          KlineRealtimeNotifier,
          AsyncValue<List<Candle>>,
          List<Candle>,
          FutureOr<List<Candle>>,
          KlineParams
        > {
  KlineRealtimeNotifierFamily._()
    : super(
        retry: null,
        name: r'klineRealtimeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Manages real-time K-line data for intraday (1min) charts.
  ///
  /// ## State
  /// `AsyncValue<List<Candle>>` — ordered list of 1-minute candles.
  ///
  /// ## Lifecycle
  /// 1. Initial load: REST API `getKline()` for historical candles
  /// 2. Subscribe to WebSocket for real-time tick updates (1min period only)
  /// 3. Aggregate ticks into candles using [CandleAggregator]
  /// 4. Update last candle in-place or append new candle on minute boundary
  ///
  /// ## Real-time updates (1min only)
  /// - Subscribes to [quoteWebSocketProvider] when connected
  /// - Listens to tick stream filtered by symbol
  /// - Uses [CandleAggregator] to convert ticks → candles
  /// - Updates state on each tick (optimistic UI)
  ///
  /// ## Other periods (1d/1w/1mo)
  /// - Static REST data only (no WebSocket subscription)
  /// - Handled by [_klineDataProvider] in kline_chart_widget.dart
  ///
  /// ## Memory management
  /// - Limits candle history to 390 candles (1 trading day)
  /// - Removes oldest candles when limit exceeded

  KlineRealtimeNotifierProvider call(KlineParams params) =>
      KlineRealtimeNotifierProvider._(argument: params, from: this);

  @override
  String toString() => r'klineRealtimeProvider';
}

/// Manages real-time K-line data for intraday (1min) charts.
///
/// ## State
/// `AsyncValue<List<Candle>>` — ordered list of 1-minute candles.
///
/// ## Lifecycle
/// 1. Initial load: REST API `getKline()` for historical candles
/// 2. Subscribe to WebSocket for real-time tick updates (1min period only)
/// 3. Aggregate ticks into candles using [CandleAggregator]
/// 4. Update last candle in-place or append new candle on minute boundary
///
/// ## Real-time updates (1min only)
/// - Subscribes to [quoteWebSocketProvider] when connected
/// - Listens to tick stream filtered by symbol
/// - Uses [CandleAggregator] to convert ticks → candles
/// - Updates state on each tick (optimistic UI)
///
/// ## Other periods (1d/1w/1mo)
/// - Static REST data only (no WebSocket subscription)
/// - Handled by [_klineDataProvider] in kline_chart_widget.dart
///
/// ## Memory management
/// - Limits candle history to 390 candles (1 trading day)
/// - Removes oldest candles when limit exceeded

abstract class _$KlineRealtimeNotifier extends $AsyncNotifier<List<Candle>> {
  late final _$args = ref.$arg as KlineParams;
  KlineParams get params => _$args;

  FutureOr<List<Candle>> build(KlineParams params);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Candle>>, List<Candle>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Candle>>, List<Candle>>,
              AsyncValue<List<Candle>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
