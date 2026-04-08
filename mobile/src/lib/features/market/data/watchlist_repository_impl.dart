import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/token_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entities/watchlist.dart';
import '../domain/repositories/watchlist_repository.dart';
import 'local/watchlist_local_datasource.dart';
import 'mappers/market_mappers.dart';
import 'remote/market_remote_data_source.dart';
import 'remote/market_response_models.dart';

part 'watchlist_repository_impl.g.dart';

const _kMarketBaseUrl = String.fromEnvironment(
  'MARKET_BASE_URL',
  defaultValue: 'https://api-staging.trading.example.com',
);

/// Production [WatchlistRepository] implementation.
///
/// Guest mode  — [TokenService.getAccessToken] returns null/empty.
///   All CRUD is local-only (Hive).  Quotes are fetched from REST for display.
///
/// Registered mode — a valid access token is present.
///   CRUD is mirrored to the market-data server.  The server's symbol order is
///   authoritative; [getWatchlist] syncs it back to the local mirror.
///   [reorderWatchlist] is local-only (no server endpoint exists).
class WatchlistRepositoryImpl implements WatchlistRepository {
  WatchlistRepositoryImpl({
    required MarketRemoteDataSource remote,
    required WatchlistLocalDataSource local,
    required TokenService tokenService,
  })  : _remote = remote,
        _local = local,
        _tokenService = tokenService;

  final MarketRemoteDataSource _remote;
  final WatchlistLocalDataSource _local;
  final TokenService _tokenService;

  // ─── Auth helper ──────────────────────────────────────────────────────────

  Future<bool> _isRegistered() async {
    final token = await _tokenService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ─── WatchlistRepository ──────────────────────────────────────────────────

  @override
  Future<Watchlist> getWatchlist() async {
    if (await _isRegistered()) {
      AppLogger.debug('WatchlistRepo: getWatchlist (registered)');
      final dto = await _remote.getWatchlist();
      // Server order is authoritative — sync it back to local.
      await _syncLocalFromServer(dto);
      return dto.toWatchlist();
    } else {
      AppLogger.debug('WatchlistRepo: getWatchlist (guest)');
      return _guestWatchlist();
    }
  }

  @override
  Future<void> addToWatchlist({
    required String symbol,
    required String market,
  }) async {
    if (await _isRegistered()) {
      AppLogger.debug('WatchlistRepo: addToWatchlist $symbol (registered)');
      await _remote.addToWatchlist(symbol: symbol, market: market);
    } else {
      AppLogger.debug('WatchlistRepo: addToWatchlist $symbol (guest)');
    }
    // Always update local mirror / guest list.
    final items = await _local.getItems();
    if (!items.any((e) => e.symbol == symbol)) {
      items.add(WatchlistItem(symbol: symbol, market: market));
      await _local.saveItems(items);
    }
  }

  @override
  Future<void> removeFromWatchlist(String symbol) async {
    if (await _isRegistered()) {
      AppLogger.debug('WatchlistRepo: removeFromWatchlist $symbol (registered)');
      await _remote.removeFromWatchlist(symbol);
    } else {
      AppLogger.debug('WatchlistRepo: removeFromWatchlist $symbol (guest)');
    }
    final items = await _local.getItems();
    items.removeWhere((e) => e.symbol == symbol);
    await _local.saveItems(items);
  }

  @override
  Future<void> reorderWatchlist(List<String> orderedSymbols) async {
    // Server has no reorder endpoint — local-only for both guest and registered.
    AppLogger.debug('WatchlistRepo: reorderWatchlist ${orderedSymbols.length} symbols');
    final items = await _local.getItems();
    final itemMap = {for (final item in items) item.symbol: item};
    final reordered = orderedSymbols
        .where(itemMap.containsKey)
        .map((s) => itemMap[s]!)
        .toList();
    await _local.saveItems(reordered);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Fetch quotes for locally-stored symbols (guest mode).
  Future<Watchlist> _guestWatchlist() async {
    try {
      AppLogger.debug('WatchlistRepo: _guestWatchlist START');

      final items = await _local.getItems();
      AppLogger.debug('WatchlistRepo: _guestWatchlist got ${items.length} items');
      if (items.isEmpty) {
        AppLogger.debug('WatchlistRepo: no items, returning empty list');
        return const [];
      }

      // Fetch quotes in batches of 50 (REST limit).
      final symbols = items.map((e) => e.symbol).toList();
      AppLogger.debug('WatchlistRepo: fetching quotes for symbols: $symbols');
      final Watchlist result = [];
      for (var i = 0; i < symbols.length; i += 50) {
        final batch = symbols.sublist(
          i,
          (i + 50).clamp(0, symbols.length),
        );
        AppLogger.debug('WatchlistRepo: calling getQuotes with batch: $batch');
        try {
          final dto = await _remote.getQuotes(batch);
          AppLogger.debug('WatchlistRepo: got response with ${dto.quotes.length} quotes');
          final quoteMap = dto.quotes;
          // Preserve local order.
          for (final sym in batch) {
            if (quoteMap.containsKey(sym)) {
              result.add(quoteMap[sym]!.toDomain());
            }
          }
        } catch (e, stack) {
          AppLogger.error('WatchlistRepo: getQuotes failed for batch $batch: $e', error: e, stackTrace: stack);
          rethrow;
        }
      }
      AppLogger.debug('WatchlistRepo: returning ${result.length} quotes');
      return result;
    } catch (e, stack) {
      AppLogger.error('WatchlistRepo: _guestWatchlist failed: $e', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Overwrite the local mirror with the server-authoritative symbol list.
  Future<void> _syncLocalFromServer(WatchlistResponseDto dto) async {
    final items = dto.symbols.map((s) {
      final market = dto.quotes[s]?.market ?? 'US';
      return WatchlistItem(symbol: s, market: market);
    }).toList();
    await _local.saveItems(items);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
WatchlistRepository watchlistRepository(Ref ref) {
  final dio = DioClient.create(baseUrl: _kMarketBaseUrl);
  final tokenService = ref.watch(tokenServiceProvider);
  return WatchlistRepositoryImpl(
    remote: MarketRemoteDataSource(dio),
    local: WatchlistLocalDataSource(),
    tokenService: tokenService,
  );
}
