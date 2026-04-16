import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/market_data_repository_impl.dart';
import '../data/websocket/quote_websocket_client.dart';
import '../domain/entities/quote.dart';
import 'quote_websocket_notifier.dart';

part 'index_quotes_notifier.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IndexQuotesNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
///
/// ## Lifecycle
/// - Initial load: REST API batch fetch
/// - Live updates: WebSocket TICK/SNAPSHOT frames
///
/// ## WebSocket integration
/// Automatically subscribes to index symbols when WebSocket is connected.
/// Updates are patched into state in real-time.
@Riverpod(keepAlive: true)
class IndexQuotesNotifier extends _$IndexQuotesNotifier {
  static const _indexSymbols = ['SPY', 'QQQ', 'DIA'];

  StreamSubscription<WsQuoteUpdate>? _quoteSubscription;

  @override
  Future<Map<String, Quote>> build() async {
    ref.onDispose(() => _quoteSubscription?.cancel());

    final repo = ref.watch(marketDataRepositoryProvider);

    AppLogger.debug('IndexQuotesNotifier: fetching ${_indexSymbols.length} index quotes');

    try {
      // Initial REST fetch
      final batch = await repo.getQuotes(_indexSymbols);
      final quotes = <String, Quote>{};

      for (final entry in batch.entries) {
        if (entry.value is Quote) {
          quotes[entry.key] = entry.value as Quote;
        }
      }

      AppLogger.info('IndexQuotesNotifier: loaded ${quotes.length} index quotes');

      // Set up WebSocket live updates
      _subscribeWhenReady();
      _attachQuoteStream();

      return quotes;
    } catch (e, stack) {
      AppLogger.error(
        'IndexQuotesNotifier: failed to load index quotes',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ─── WebSocket wiring ─────────────────────────────────────────────────────

  /// Subscribe to WebSocket when connection is ready.
  void _subscribeWhenReady() {
    // Try to subscribe immediately if already connected
    final wsState = ref.read(quoteWebSocketProvider);
    wsState.whenData((_) async {
      AppLogger.debug('IndexQuotesNotifier: subscribing to WS for index symbols (immediate)');
      await ref.read(quoteWebSocketProvider.notifier).subscribe(_indexSymbols);
    });

    // Also listen for future connection state changes
    ref.listen(quoteWebSocketProvider, (_, wsState) {
      wsState.whenData((_) async {
        AppLogger.debug('IndexQuotesNotifier: subscribing to WS for index symbols (listener)');
        await ref
            .read(quoteWebSocketProvider.notifier)
            .subscribe(_indexSymbols);
      });
    }, fireImmediately: false);
  }

  /// Attach listener to WebSocket quote stream.
  void _attachQuoteStream() {
    _quoteSubscription?.cancel();
    final wsNotifier = ref.read(quoteWebSocketProvider.notifier);
    _quoteSubscription = wsNotifier.quoteStream.listen(_patchQuote);
  }

  void _patchQuote(WsQuoteUpdate update) {
    final current = state.value;
    if (current == null) return;

    // Only process updates for index symbols
    if (!_indexSymbols.contains(update.symbol)) return;

    final existing = current[update.symbol];
    if (existing == null) return;

    final patched = Map<String, Quote>.from(current);
    patched[update.symbol] = _mergeWithUpdate(existing, update);
    state = AsyncData(patched);
  }

  /// Merge WebSocket update into existing quote.
  Quote _mergeWithUpdate(Quote existing, WsQuoteUpdate update) {
    final ws = update.quote;

    if (update.frameType != WsFrameType.tick) {
      // Full data replacement for SNAPSHOT or DELAYED frames
      return existing.copyWith(
        price: ws.price,
        change: ws.change,
        changePct: ws.changePct,
        volume: ws.volume != 0 ? ws.volume : existing.volume,
        bid: ws.bid ?? existing.bid,
        ask: ws.ask ?? existing.ask,
        prevClose: ws.prevClose != Decimal.zero ? ws.prevClose : existing.prevClose,
        open: ws.open != Decimal.zero ? ws.open : existing.open,
        high: ws.high != Decimal.zero ? ws.high : existing.high,
        low: ws.low != Decimal.zero ? ws.low : existing.low,
        delayed: ws.delayed,
        marketStatus: ws.marketStatus,
        isStale: ws.isStale,
        staleSinceMs: ws.staleSinceMs,
      );
    }

    // TICK frame — only patch non-zero / changed fields
    return existing.copyWith(
      price: ws.price != Decimal.zero ? ws.price : existing.price,
      change: ws.change != Decimal.zero ? ws.change : existing.change,
      changePct: ws.changePct != Decimal.zero ? ws.changePct : existing.changePct,
      volume: ws.volume != 0 ? ws.volume : existing.volume,
      bid: ws.bid ?? existing.bid,
      ask: ws.ask ?? existing.ask,
      marketStatus: ws.marketStatus,
      isStale: ws.isStale,
      staleSinceMs: ws.staleSinceMs,
    );
  }
}
