import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/market_data_repository_impl.dart';
import '../data/websocket/quote_websocket_client.dart';
import '../domain/entities/candle.dart';
import '../domain/entities/candle_aggregator.dart';
import 'quote_websocket_notifier.dart';
import 'stock_detail_notifier.dart';

part 'kline_realtime_notifier.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _defaultFrom(String period) {
  final now = DateTime.now().toUtc();
  final d = switch (period) {
    '1min' || '5min' || '15min' || '30min' || '60min' =>
      now.subtract(const Duration(days: 1)),
    '1d' => now.subtract(const Duration(days: 365 * 5)),
    '1w' => now.subtract(const Duration(days: 365 * 10)),
    _ => now.subtract(const Duration(days: 365)),
  };
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// KlineRealtimeNotifier
// ─────────────────────────────────────────────────────────────────────────────

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
@Riverpod(keepAlive: true)
class KlineRealtimeNotifier extends _$KlineRealtimeNotifier {
  StreamSubscription<WsQuoteUpdate>? _quoteSubscription;
  CandleAggregator? _aggregator;
  String? _currentSymbol;

  static const _maxCandles = 390; // 1 trading day (09:30-16:00 ET)

  @override
  Future<List<Candle>> build(KlineParams params) async {
    ref.onDispose(() {
      _quoteSubscription?.cancel();
      if (_currentSymbol != null) {
        _unsubscribeFromWs(_currentSymbol!);
      }
    });

    _currentSymbol = params.symbol;

    try {
      // 1. Load initial historical data from REST API
      final repo = ref.read(marketDataRepositoryProvider);
      final result = await repo.getKline(
        symbol: params.symbol,
        period: params.period,
        from: params.from ?? _defaultFrom(params.period),
        to: params.to,
        limit: params.limit,
        cursor: params.cursor,
      );

      final candles = result.candles;
      AppLogger.info(
          'KlineRealtimeNotifier: loaded ${candles.length} candles for ${params.symbol} (${params.period})');

      // 2. Enable real-time updates for 1min period only
      if (params.period == '1min') {
        _setupRealtimeUpdates(params.symbol);
      }

      return candles;
    } catch (e, stack) {
      AppLogger.error(
        'KlineRealtimeNotifier: failed to load candles for ${params.symbol}',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ─── Real-time updates ────────────────────────────────────────────────────

  void _setupRealtimeUpdates(String symbol) {
    _aggregator = CandleAggregator();

    // Subscribe to WebSocket when connected
    _subscribeWhenReady(symbol);

    // Attach listener to tick stream
    _attachTickStream(symbol);
  }

  void _subscribeWhenReady(String symbol) {
    // Try to subscribe immediately if already connected
    final wsState = ref.read(quoteWebSocketProvider);
    wsState.whenData((_) async {
      AppLogger.debug(
          'KlineRealtimeNotifier: subscribing $symbol to WS (immediate)');
      await ref.read(quoteWebSocketProvider.notifier).subscribe([symbol]);
    });

    // Also listen for future connection state changes
    ref.listen(quoteWebSocketProvider, (_, wsState) {
      wsState.whenData((_) async {
        AppLogger.debug(
            'KlineRealtimeNotifier: subscribing $symbol to WS (listener)');
        await ref.read(quoteWebSocketProvider.notifier).subscribe([symbol]);

        // Reset aggregator on reconnect
        _aggregator?.reset();
      });
    }, fireImmediately: false);
  }

  void _attachTickStream(String symbol) {
    _quoteSubscription?.cancel();

    final wsNotifier = ref.read(quoteWebSocketProvider.notifier);
    _quoteSubscription = wsNotifier.quoteStream
        .where((update) => update.symbol == symbol)
        .listen(_onTick);
  }

  void _onTick(WsQuoteUpdate update) {
    final current = state.value;
    if (current == null || _aggregator == null) return;

    final result = _aggregator!.processTick(update.quote);

    if (result.isCompleted) {
      // Minute boundary crossed — append new candle
      final completed = result.candle!;
      AppLogger.debug(
          'KlineRealtimeNotifier: completed candle at ${completed.t} (${update.symbol})');

      var updated = [...current, completed];

      // Limit history to max candles
      if (updated.length > _maxCandles) {
        updated = updated.sublist(updated.length - _maxCandles);
      }

      state = AsyncData(updated);
    } else {
      // Update last candle in-place
      if (current.isEmpty) {
        // No historical candles yet — create first candle
        final firstCandle = _aggregator!.currentCandle;
        if (firstCandle != null) {
          state = AsyncData([firstCandle]);
        }
        return;
      }

      final lastCandle = _aggregator!.currentCandle;
      if (lastCandle == null) return;

      final updated = [...current];
      updated[updated.length - 1] = lastCandle;
      state = AsyncData(updated);
    }
  }

  void _unsubscribeFromWs(String symbol) {
    AppLogger.debug('KlineRealtimeNotifier: unsubscribing $symbol from WS');
    ref.read(quoteWebSocketProvider.notifier).unsubscribe([symbol]);
  }
}
