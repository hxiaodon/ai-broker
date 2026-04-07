import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../data/local/watchlist_local_datasource.dart';
import '../data/watchlist_repository_impl.dart';
import '../data/websocket/quote_websocket_client.dart';
import '../domain/entities/quote.dart';
import '../domain/repositories/watchlist_repository.dart';
import 'quote_websocket_notifier.dart';

part 'watchlist_notifier.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Maximum number of symbols in a watchlist (per PRD §3 business rules).
const _kMaxWatchlistSize = 100;

// ─────────────────────────────────────────────────────────────────────────────
// WatchlistNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Manages the user's watchlist and provides real-time quote updates.
///
/// ## State
/// `AsyncValue<List<Quote>>` — the ordered list of quotes for all watchlist
/// symbols. Initial data is fetched from [WatchlistRepository]; subsequent
/// updates are streamed from [QuoteWebSocketNotifier].
///
/// ## Dual-mode (guest / registered)
/// The underlying [WatchlistRepository] transparently handles both modes.
/// This notifier only needs to orchestrate WS subscriptions.
///
/// ## Live updates
/// Quote patches arrive from the WS stream ([quoteWebSocketProvider]):
/// - SNAPSHOT / DELAYED → full field replacement (preserves static metadata)
/// - TICK → only non-zero numeric fields are patched
///
/// ## 100-symbol limit
/// [add] throws [ValidationException] when the current count is ≥ 100.
///
/// ## Guest → registered import
/// Call [importGuestItems] after login to sync the guest local list to the
/// server. The UI is responsible for prompting the user.
@Riverpod(keepAlive: true)
class WatchlistNotifier extends _$WatchlistNotifier {
  StreamSubscription<WsQuoteUpdate>? _quoteSubscription;

  @override
  Future<List<Quote>> build() async {
    ref.onDispose(() => _quoteSubscription?.cancel());

    final repo = ref.watch(watchlistRepositoryProvider);
    final watchlist = await repo.getWatchlist();

    // Set up live WS patch stream once we have data.
    if (watchlist.isNotEmpty) {
      _subscribeWhenReady(watchlist.map((q) => q.symbol).toList());
      _attachQuoteStream();
    }

    return watchlist;
  }

  // ─── WS wiring ────────────────────────────────────────────────────────────

  /// Listens to [quoteWebSocketProvider] and subscribes to WS symbols when
  /// the connection is ready. Re-subscribes on reconnect automatically.
  void _subscribeWhenReady(List<String> symbols) {
    ref.listen(quoteWebSocketProvider, (_, wsState) {
      wsState.whenData((_) async {
        final current = state.value;
        if (current == null || current.isEmpty) return;
        final toSubscribe = current.map((q) => q.symbol).toList();
        AppLogger.debug(
            'WatchlistNotifier: subscribing ${toSubscribe.length} symbols to WS');
        await ref
            .read(quoteWebSocketProvider.notifier)
            .subscribe(toSubscribe);
      });
    }, fireImmediately: true);
  }

  /// Attaches a listener on the WS quote broadcast stream to patch state.
  void _attachQuoteStream() {
    _quoteSubscription?.cancel();
    final wsNotifier = ref.read(quoteWebSocketProvider.notifier);
    _quoteSubscription = wsNotifier.quoteStream.listen(_patchQuote);
  }

  void _patchQuote(WsQuoteUpdate update) {
    final current = state.value;
    if (current == null) return;
    final idx = current.indexWhere((q) => q.symbol == update.symbol);
    if (idx == -1) return; // symbol not in watchlist

    final patched = List<Quote>.from(current);
    patched[idx] = _mergeWithUpdate(patched[idx], update);
    state = AsyncData(patched);
  }

  /// Merges a [WsQuoteUpdate] into an existing [Quote].
  ///
  /// SNAPSHOT / DELAYED — replaces all market-data fields; static metadata
  /// (name, nameZh, marketCap, peRatio) is preserved from the REST-loaded quote.
  /// TICK — only non-zero numeric fields are patched.
  Quote _mergeWithUpdate(Quote existing, WsQuoteUpdate update) {
    final ws = update.quote;

    if (update.frameType != WsFrameType.tick) {
      // Full data replacement for SNAPSHOT or DELAYED frames.
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

  // ─── Public CRUD API ──────────────────────────────────────────────────────

  /// Add [symbol] to the watchlist.
  ///
  /// Throws [ValidationException] if the watchlist already has 100 symbols.
  Future<void> add({required String symbol, required String market}) async {
    final count = state.value?.length ?? 0;
    if (count >= _kMaxWatchlistSize) {
      throw const ValidationException(message: '自选股最多 $_kMaxWatchlistSize 只');
    }

    AppLogger.debug('WatchlistNotifier: add $symbol ($market)');
    final repo = ref.read(watchlistRepositoryProvider);
    await repo.addToWatchlist(symbol: symbol, market: market);

    // Subscribe the new symbol in WS if connected.
    final wsState = ref.read(quoteWebSocketProvider);
    if (wsState.hasValue) {
      await ref
          .read(quoteWebSocketProvider.notifier)
          .subscribe([symbol]);
    }

    // Refresh from repository (preserves server ordering).
    ref.invalidateSelf();
  }

  /// Remove [symbol] from the watchlist.
  Future<void> remove(String symbol) async {
    AppLogger.debug('WatchlistNotifier: remove $symbol');
    final repo = ref.read(watchlistRepositoryProvider);
    await repo.removeFromWatchlist(symbol);

    ref.read(quoteWebSocketProvider.notifier).unsubscribe([symbol]);

    ref.invalidateSelf();
  }

  /// Persist a new symbol order without fetching fresh quote data from the
  /// server.
  ///
  /// Immediately reorders the in-memory state so the UI update is instant.
  Future<void> reorder(List<String> orderedSymbols) async {
    AppLogger.debug('WatchlistNotifier: reorder ${orderedSymbols.length}');
    final repo = ref.read(watchlistRepositoryProvider);
    await repo.reorderWatchlist(orderedSymbols);

    // Apply ordering optimistically to the current state without a full reload.
    final current = state.value;
    if (current != null) {
      final symbolMap = {for (final q in current) q.symbol: q};
      final reordered = orderedSymbols
          .where(symbolMap.containsKey)
          .map((s) => symbolMap[s]!)
          .toList();
      state = AsyncData(reordered);
    }
  }

  /// Import [symbols] from the guest watchlist into the server after login.
  ///
  /// Silently skips symbols that are already in the watchlist or that fail.
  /// After import, the state is refreshed from the server.
  ///
  /// The UI is responsible for checking whether import is needed (via
  /// [pendingGuestSymbols]) and prompting the user.
  Future<void> importGuestItems(
    List<WatchlistItem> guestItems,
  ) async {
    AppLogger.info(
        'WatchlistNotifier: importing ${guestItems.length} guest items');
    final repo = ref.read(watchlistRepositoryProvider);
    for (final item in guestItems) {
      try {
        await repo.addToWatchlist(symbol: item.symbol, market: item.market);
      } on Object catch (e) {
        AppLogger.warning(
            'WatchlistNotifier: failed to import ${item.symbol}: $e');
      }
    }
    ref.invalidateSelf();
  }
}
