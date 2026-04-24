import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/market_data_repository_impl.dart';
import '../data/websocket/quote_websocket_client.dart';
import '../domain/entities/stock_detail.dart';
import 'quote_websocket_notifier.dart';

part 'stock_detail_notifier.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StockDetailNotifier
// ─────────────────────────────────────────────────────────────────────────────

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
@riverpod
class StockDetailNotifier extends _$StockDetailNotifier {
  @override
  Future<StockDetail> build(String symbol) async {
    try {
      final startTime = DateTime.now();
      final repo = ref.read(marketDataRepositoryProvider);
      final detail = await repo.getStockDetail(symbol);

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.info('StockDetailNotifier: loaded $symbol in ${duration}ms');
      _setupLiveUpdates(symbol);

      return detail;
    } catch (e, stack) {
      AppLogger.error(
        'StockDetailNotifier: failed to load detail for $symbol',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ─── WS wiring ────────────────────────────────────────────────────────────

  void _setupLiveUpdates(String symbol) {
    // Capture notifier reference before onDispose — calling ref.read inside
    // onDispose triggers Riverpod's reentrancy assertion during container disposal.
    final wsNotifier = ref.read(quoteWebSocketProvider.notifier);
    ref.onDispose(() => wsNotifier.unsubscribe([symbol]));

    // Subscribe to WS when connected (handles reconnects).
    ref.listen(quoteWebSocketProvider, (_, wsState) {
      wsState.whenData((_) async {
        AppLogger.debug('StockDetailNotifier: subscribing $symbol to WS');
        await ref.read(quoteWebSocketProvider.notifier).subscribe([symbol]);
      });
    }, fireImmediately: true);

    // Patch state on every incoming quote update for this symbol.
    ref.listen(quoteUpdateProvider(symbol), (_, asyncUpdate) {
      asyncUpdate.whenData(_patchFromUpdate);
    });
  }

  void _patchFromUpdate(WsQuoteUpdate update) {
    final current = state.value;
    if (current == null) return;

    AppLogger.debug(
        'StockDetailNotifier: patch $symbol (${update.frameType.name})');
    state = AsyncData(_mergeWithUpdate(current, update));
  }

  /// Merges a [WsQuoteUpdate] into the current [StockDetail].
  ///
  /// SNAPSHOT / DELAYED — replaces all quote fields; fundamental fields
  /// (marketCap, peRatio, pbRatio, dividendYield, sharesOutstanding, avgVolume,
  /// week52High, week52Low, turnoverRate, exchange, sector, asOf) are preserved.
  /// TICK — only non-zero numeric fields are patched.
  StockDetail _mergeWithUpdate(StockDetail existing, WsQuoteUpdate update) {
    final ws = update.quote;

    if (update.frameType != WsFrameType.tick) {
      return existing.copyWith(
        price: ws.price,
        change: ws.change,
        changePct: ws.changePct,
        volume: ws.volume != 0 ? ws.volume : existing.volume,
        bid: ws.bid ?? existing.bid,
        ask: ws.ask ?? existing.ask,
        prevClose:
            ws.prevClose != Decimal.zero ? ws.prevClose : existing.prevClose,
        open: ws.open != Decimal.zero ? ws.open : existing.open,
        high: ws.high != Decimal.zero ? ws.high : existing.high,
        low: ws.low != Decimal.zero ? ws.low : existing.low,
        delayed: ws.delayed,
        marketStatus: ws.marketStatus,
        isStale: ws.isStale,
        staleSinceMs: ws.staleSinceMs,
      );
    }

    // TICK frame — only patch non-zero / changed fields.
    return existing.copyWith(
      price: ws.price != Decimal.zero ? ws.price : existing.price,
      change: ws.change != Decimal.zero ? ws.change : existing.change,
      changePct:
          ws.changePct != Decimal.zero ? ws.changePct : existing.changePct,
      volume: ws.volume != 0 ? ws.volume : existing.volume,
      bid: ws.bid ?? existing.bid,
      ask: ws.ask ?? existing.ask,
      marketStatus: ws.marketStatus,
      isStale: ws.isStale,
      staleSinceMs: ws.staleSinceMs,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// K-line provider
// ─────────────────────────────────────────────────────────────────────────────

/// Parameter object for the K-line provider family.
///
/// Identifies a single K-line dataset request: symbol + period + optional
/// date range. Immutable so it can be used as a provider family argument.
class KlineParams {
  const KlineParams({
    required this.symbol,
    required this.period,
    this.from,
    this.to,
    this.limit,
    this.cursor,
  });

  final String symbol;

  /// Must be one of: 1min, 5min, 15min, 30min, 60min, 1d, 1w, 1mo.
  final String period;

  /// ISO 8601 UTC start date (date-only for daily+, datetime for intraday).
  final String? from;

  /// ISO 8601 UTC end date. Defaults to now.
  final String? to;

  /// Maximum number of candles to return. Server default applies if null.
  final int? limit;

  /// Opaque pagination cursor from a prior [KlineResult.nextCursor].
  final String? cursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KlineParams &&
          symbol == other.symbol &&
          period == other.period &&
          from == other.from &&
          to == other.to &&
          limit == other.limit &&
          cursor == other.cursor;

  @override
  int get hashCode =>
      Object.hash(symbol, period, from, to, limit, cursor);
}
