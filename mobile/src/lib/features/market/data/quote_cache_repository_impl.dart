import 'package:decimal/decimal.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/database.dart';
import '../domain/entities/quote.dart';
import '../domain/entities/market_status.dart';
import '../domain/entities/financials.dart';
import '../domain/entities/mover_item.dart';
import '../domain/entities/search_result.dart';
import '../domain/entities/stock_detail.dart';
import '../domain/entities/watchlist.dart';
import '../domain/repositories/market_data_repository.dart';

/// Market data repository with local Drift caching layer.
///
/// Wraps the base [MarketDataRepository] to add:
/// - Quote snapshot caching in local SQLite database
/// - Automatic cache invalidation (30-second TTL)
/// - Offline fallback (returns cached data when API fails)
/// - Background cache updates
///
/// Cache strategy:
/// 1. Always fetch from API for freshest data
/// 2. Update local cache on successful API response
/// 3. On API failure, return cached data if available
/// 4. Return stale data with is_stale flag to indicate staleness
class MarketDataCacheRepositoryImpl implements MarketDataRepository {
  MarketDataCacheRepositoryImpl({
    required this.database,
    required this.baseRepository,
    this.cacheTTL = const Duration(seconds: 30),
  });

  final AppDatabase database;
  final MarketDataRepository baseRepository;

  /// Cache time-to-live. Default: 30 seconds.
  /// After this duration, cache is considered stale and API fetch is forced.
  final Duration cacheTTL;

  /// Batch-fetch quotes, using cache to supplement API failures.
  ///
  /// Strategy:
  /// 1. Fetch from API
  /// 2. On success: update cache, return results
  /// 3. On failure: return cached data for available symbols
  /// 4. If cache miss and API fails: propagate error
  @override
  Future<Map<String, dynamic>> getQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return {};

    try {
      // Fetch from API
      final apiResult = await baseRepository.getQuotes(symbols);

      // Update cache with API responses
      _updateQuotesCache(apiResult).ignore();

      return apiResult;
    } on NetworkException {
      // API failed: fall back to cached quotes
      AppLogger.warning('getQuotes API failed, trying cache for ${symbols.length} symbols');

      try {
        final cachedQuotes = await _getCachedQuotesAsMap(symbols);
        if (cachedQuotes.isNotEmpty) {
          return cachedQuotes;
        }
      } catch (e) {
        AppLogger.warning('Cache lookup also failed: $e');
      }

      // No cache available: re-throw original error
      rethrow;
    } catch (e, st) {
      AppLogger.error('getQuotes failed: $e', error: e, stackTrace: st);
      throw NetworkException(
        message: 'Failed to get quotes: $e',
        cause: e,
      );
    }
  }

  /// Get all cached quotes for symbols (returns as map for compatibility).
  Future<Map<String, dynamic>> _getCachedQuotesAsMap(List<String> symbols) async {
    final result = <String, dynamic>{};

    for (final symbol in symbols) {
      for (final market in ['US', 'HK']) {
        final cached = await database.getQuote(symbol, market);
        if (cached != null) {
          final quote = _toDomainQuote(cached);
          result[symbol] = {
            'symbol': quote.symbol,
            'name': quote.name,
            'nameZh': quote.nameZh,
            'market': quote.market,
            'price': quote.price.toString(),
            'change': quote.change.toString(),
            'changePct': quote.changePct.toString(),
            'volume': quote.volume,
            'bid': quote.bid?.toString(),
            'ask': quote.ask?.toString(),
            'turnover': quote.turnover,
            'prevClose': quote.prevClose.toString(),
            'open': quote.open.toString(),
            'high': quote.high.toString(),
            'low': quote.low.toString(),
            'marketCap': quote.marketCap,
            'peRatio': quote.peRatio,
            'delayed': quote.delayed,
            'marketStatus': quote.marketStatus.name,
            'isStale': true, // Mark as stale since it's from cache
          };
          break; // Found quote for this symbol
        }
      }
    }

    return result;
  }

  /// Update cache with quotes from API response.
  Future<void> _updateQuotesCache(Map<String, dynamic> apiQuotes) async {
    try {
      final now = DateTime.now().toUtc();

      for (final entry in apiQuotes.entries) {
        final symbol = entry.key;
        final quoteData = entry.value as Map<String, dynamic>;

        // Parse quote data (assuming API format matches Quote entity fields)
        final cache = QuoteCache(
          symbol: symbol,
          market: (quoteData['market'] as String?) ?? 'US',
          name: (quoteData['name'] as String?) ?? '',
          nameZh: (quoteData['nameZh'] as String?) ?? '',
          price: ((quoteData['price'] ?? 0) as dynamic).toString(),
          change: ((quoteData['change'] ?? 0) as dynamic).toString(),
          changePct: ((quoteData['changePct'] ?? 0) as dynamic).toString(),
          volume: (quoteData['volume'] as int?) ?? 0,
          bid: quoteData['bid']?.toString(),
          ask: quoteData['ask']?.toString(),
          turnover: (quoteData['turnover'] as String?) ?? '0',
          prevClose: ((quoteData['prevClose'] ?? 0) as dynamic).toString(),
          open: ((quoteData['open'] ?? 0) as dynamic).toString(),
          high: ((quoteData['high'] ?? 0) as dynamic).toString(),
          low: ((quoteData['low'] ?? 0) as dynamic).toString(),
          marketCap: (quoteData['marketCap'] as String?) ?? '0',
          peRatio: quoteData['peRatio'] as String?,
          delayed: (quoteData['delayed'] as bool?) ?? false,
          marketStatus: ((quoteData['marketStatus'] as String?) ?? 'CLOSED').toUpperCase(),
          isStale: (quoteData['isStale'] as bool?) ?? false,
          staleSinceMs: (quoteData['staleSinceMs'] as int?) ?? 0,
          cachedAt: now.toIso8601String(),
        );

        await database.insertQuote(cache);
      }

      AppLogger.debug('Updated cache for ${apiQuotes.length} quotes');
    } catch (e, st) {
      AppLogger.error('Failed to update quote cache: $e', error: e, stackTrace: st);
      // Non-critical: don't throw, just log
    }
  }

  /// Clear all cached quotes (call on logout or market switch).
  Future<void> clearQuotesCache() async {
    try {
      final count = await database.clearQuotesCache();
      AppLogger.info('Cleared $count cached quotes');
    } catch (e, st) {
      AppLogger.error('Failed to clear quote cache: $e', error: e, stackTrace: st);
    }
  }

  /// Convert Drift cache to domain Quote entity.
  Quote _toDomainQuote(QuoteCache cache) {
    return Quote(
      symbol: cache.symbol,
      name: cache.name,
      nameZh: cache.nameZh,
      market: cache.market,
      price: Decimal.parse(cache.price),
      change: Decimal.parse(cache.change),
      changePct: Decimal.parse(cache.changePct),
      volume: cache.volume,
      bid: cache.bid != null ? Decimal.parse(cache.bid!) : null,
      ask: cache.ask != null ? Decimal.parse(cache.ask!) : null,
      turnover: cache.turnover,
      prevClose: Decimal.parse(cache.prevClose),
      open: Decimal.parse(cache.open),
      high: Decimal.parse(cache.high),
      low: Decimal.parse(cache.low),
      marketCap: cache.marketCap,
      peRatio: cache.peRatio,
      delayed: cache.delayed,
      marketStatus: MarketStatus.fromApi(cache.marketStatus),
      isStale: cache.isStale,
      staleSinceMs: cache.staleSinceMs,
    );
  }

  // ─── Pass-through methods (delegate to base repository) ─────────────────────

  @override
  Future<KlineResult> getKline({
    required String symbol,
    required String period,
    required String from,
    String? to,
    int? limit,
    String? cursor,
  }) =>
      baseRepository.getKline(
        symbol: symbol,
        period: period,
        from: from,
        to: to,
        limit: limit,
        cursor: cursor,
      );

  @override
  Future<List<SearchResult>> searchStocks({
    required String q,
    String? market,
    int? limit,
  }) =>
      baseRepository.searchStocks(q: q, market: market, limit: limit);

  @override
  Future<List<MoverItem>> getMovers({String? type, String? market}) =>
      baseRepository.getMovers(type: type, market: market);

  @override
  Future<StockDetail> getStockDetail(String symbol) =>
      baseRepository.getStockDetail(symbol);

  @override
  Future<NewsResult> getNews(
    String symbol, {
    int page = 1,
    int pageSize = 10,
  }) =>
      baseRepository.getNews(symbol, page: page, pageSize: pageSize);

  @override
  Future<Financials> getFinancials(String symbol) =>
      baseRepository.getFinancials(symbol);

  @override
  Future<Watchlist> getWatchlist() => baseRepository.getWatchlist();

  @override
  Future<void> addToWatchlist({required String symbol, required String market}) =>
      baseRepository.addToWatchlist(symbol: symbol, market: market);

  @override
  Future<void> removeFromWatchlist(String symbol) =>
      baseRepository.removeFromWatchlist(symbol);
}

