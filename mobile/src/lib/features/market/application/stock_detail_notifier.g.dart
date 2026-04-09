// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the state for the `StockDetailScreen`.
///
/// ## State
/// `AsyncValue<StockDetail>` — quote + fundamental data for [symbol].
///
/// ## Initial data
/// Fetched via `GET /v1/market/stocks/{symbol}` ([MarketDataRepository.getStockDetail]).
///
/// ## Live updates
/// Subscribes to [quoteUpdateProvider] (filtered WS stream for this symbol).
/// Quote patches follow the same SNAPSHOT / TICK merge rules as [WatchlistNotifier]:
/// - SNAPSHOT / DELAYED → full quote-field replacement (fundamental fields preserved).
/// - TICK → only non-zero numeric fields patched.
///
/// ## WebSocket subscription
/// Subscribes this symbol to the WS when the connection is ready (via
/// `ref.listen(quoteWebSocketProvider, fireImmediately: true)`).
/// Unsubscribes on dispose (when the screen navigates away).
///
/// ## keepAlive
/// Not kept alive — disposed when `StockDetailScreen` unmounts, so the next
/// visit always fetches fresh fundamentals.

@ProviderFor(StockDetailNotifier)
final stockDetailProvider = StockDetailNotifierFamily._();

/// Manages the state for the `StockDetailScreen`.
///
/// ## State
/// `AsyncValue<StockDetail>` — quote + fundamental data for [symbol].
///
/// ## Initial data
/// Fetched via `GET /v1/market/stocks/{symbol}` ([MarketDataRepository.getStockDetail]).
///
/// ## Live updates
/// Subscribes to [quoteUpdateProvider] (filtered WS stream for this symbol).
/// Quote patches follow the same SNAPSHOT / TICK merge rules as [WatchlistNotifier]:
/// - SNAPSHOT / DELAYED → full quote-field replacement (fundamental fields preserved).
/// - TICK → only non-zero numeric fields patched.
///
/// ## WebSocket subscription
/// Subscribes this symbol to the WS when the connection is ready (via
/// `ref.listen(quoteWebSocketProvider, fireImmediately: true)`).
/// Unsubscribes on dispose (when the screen navigates away).
///
/// ## keepAlive
/// Not kept alive — disposed when `StockDetailScreen` unmounts, so the next
/// visit always fetches fresh fundamentals.
final class StockDetailNotifierProvider
    extends $AsyncNotifierProvider<StockDetailNotifier, StockDetail> {
  /// Manages the state for the `StockDetailScreen`.
  ///
  /// ## State
  /// `AsyncValue<StockDetail>` — quote + fundamental data for [symbol].
  ///
  /// ## Initial data
  /// Fetched via `GET /v1/market/stocks/{symbol}` ([MarketDataRepository.getStockDetail]).
  ///
  /// ## Live updates
  /// Subscribes to [quoteUpdateProvider] (filtered WS stream for this symbol).
  /// Quote patches follow the same SNAPSHOT / TICK merge rules as [WatchlistNotifier]:
  /// - SNAPSHOT / DELAYED → full quote-field replacement (fundamental fields preserved).
  /// - TICK → only non-zero numeric fields patched.
  ///
  /// ## WebSocket subscription
  /// Subscribes this symbol to the WS when the connection is ready (via
  /// `ref.listen(quoteWebSocketProvider, fireImmediately: true)`).
  /// Unsubscribes on dispose (when the screen navigates away).
  ///
  /// ## keepAlive
  /// Not kept alive — disposed when `StockDetailScreen` unmounts, so the next
  /// visit always fetches fresh fundamentals.
  StockDetailNotifierProvider._({
    required StockDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stockDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stockDetailNotifierHash();

  @override
  String toString() {
    return r'stockDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StockDetailNotifier create() => StockDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is StockDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stockDetailNotifierHash() =>
    r'cc19b47ad5374c7cd6a4de8ff27549fd29c01366';

/// Manages the state for the `StockDetailScreen`.
///
/// ## State
/// `AsyncValue<StockDetail>` — quote + fundamental data for [symbol].
///
/// ## Initial data
/// Fetched via `GET /v1/market/stocks/{symbol}` ([MarketDataRepository.getStockDetail]).
///
/// ## Live updates
/// Subscribes to [quoteUpdateProvider] (filtered WS stream for this symbol).
/// Quote patches follow the same SNAPSHOT / TICK merge rules as [WatchlistNotifier]:
/// - SNAPSHOT / DELAYED → full quote-field replacement (fundamental fields preserved).
/// - TICK → only non-zero numeric fields patched.
///
/// ## WebSocket subscription
/// Subscribes this symbol to the WS when the connection is ready (via
/// `ref.listen(quoteWebSocketProvider, fireImmediately: true)`).
/// Unsubscribes on dispose (when the screen navigates away).
///
/// ## keepAlive
/// Not kept alive — disposed when `StockDetailScreen` unmounts, so the next
/// visit always fetches fresh fundamentals.

final class StockDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          StockDetailNotifier,
          AsyncValue<StockDetail>,
          StockDetail,
          FutureOr<StockDetail>,
          String
        > {
  StockDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'stockDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages the state for the `StockDetailScreen`.
  ///
  /// ## State
  /// `AsyncValue<StockDetail>` — quote + fundamental data for [symbol].
  ///
  /// ## Initial data
  /// Fetched via `GET /v1/market/stocks/{symbol}` ([MarketDataRepository.getStockDetail]).
  ///
  /// ## Live updates
  /// Subscribes to [quoteUpdateProvider] (filtered WS stream for this symbol).
  /// Quote patches follow the same SNAPSHOT / TICK merge rules as [WatchlistNotifier]:
  /// - SNAPSHOT / DELAYED → full quote-field replacement (fundamental fields preserved).
  /// - TICK → only non-zero numeric fields patched.
  ///
  /// ## WebSocket subscription
  /// Subscribes this symbol to the WS when the connection is ready (via
  /// `ref.listen(quoteWebSocketProvider, fireImmediately: true)`).
  /// Unsubscribes on dispose (when the screen navigates away).
  ///
  /// ## keepAlive
  /// Not kept alive — disposed when `StockDetailScreen` unmounts, so the next
  /// visit always fetches fresh fundamentals.

  StockDetailNotifierProvider call(String symbol) =>
      StockDetailNotifierProvider._(argument: symbol, from: this);

  @override
  String toString() => r'stockDetailProvider';
}

/// Manages the state for the `StockDetailScreen`.
///
/// ## State
/// `AsyncValue<StockDetail>` — quote + fundamental data for [symbol].
///
/// ## Initial data
/// Fetched via `GET /v1/market/stocks/{symbol}` ([MarketDataRepository.getStockDetail]).
///
/// ## Live updates
/// Subscribes to [quoteUpdateProvider] (filtered WS stream for this symbol).
/// Quote patches follow the same SNAPSHOT / TICK merge rules as [WatchlistNotifier]:
/// - SNAPSHOT / DELAYED → full quote-field replacement (fundamental fields preserved).
/// - TICK → only non-zero numeric fields patched.
///
/// ## WebSocket subscription
/// Subscribes this symbol to the WS when the connection is ready (via
/// `ref.listen(quoteWebSocketProvider, fireImmediately: true)`).
/// Unsubscribes on dispose (when the screen navigates away).
///
/// ## keepAlive
/// Not kept alive — disposed when `StockDetailScreen` unmounts, so the next
/// visit always fetches fresh fundamentals.

abstract class _$StockDetailNotifier extends $AsyncNotifier<StockDetail> {
  late final _$args = ref.$arg as String;
  String get symbol => _$args;

  FutureOr<StockDetail> build(String symbol);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StockDetail>, StockDetail>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StockDetail>, StockDetail>,
              AsyncValue<StockDetail>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
