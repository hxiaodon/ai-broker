import '../entities/candle.dart';
import '../entities/financials.dart';
import '../entities/mover_item.dart';
import '../entities/news_article.dart';
import '../entities/search_result.dart';
import '../entities/stock_detail.dart';
import '../entities/watchlist.dart';

/// Abstract repository interface for all market-data REST operations.
///
/// Callers receive domain entities. HTTP and mapping errors surface as
/// [AppException] subtypes — callers handle [NetworkException],
/// [ServerException], and [BusinessException] exhaustively.
///
/// Watchlist methods require an authenticated user (JWT via Dio interceptor);
/// the remaining methods accept optional auth (controls `delayed` flag).
abstract class MarketDataRepository {
  /// Batch-fetch quote snapshots for [symbols] (max 50 per call).
  ///
  /// Returns a map keyed by symbol — absent symbols are not included.
  Future<Map<String, dynamic>> getQuotes(List<String> symbols);

  /// Fetch K-line (OHLCV) data for [symbol] at [period] granularity.
  ///
  /// [period] must be one of: 1min, 5min, 15min, 30min, 60min, 1d, 1w, 1mo.
  /// [from] / [to] are ISO 8601 UTC strings (date only for 1min).
  /// Cursor-based pagination: pass [cursor] from a previous response's
  /// [KlineResult.nextCursor] to get the next page. Null on last page.
  Future<KlineResult> getKline({
    required String symbol,
    required String period,
    required String from,
    String? to,
    int? limit,
    String? cursor,
  });

  /// Search stocks by symbol, English/Chinese name, or Pinyin initials.
  ///
  /// [q] must be ≥ 1 character. [market] defaults to "US" (Phase 1 only).
  /// Returns results ordered by relevance (server-side scoring).
  Future<List<SearchResult>> searchStocks({
    required String q,
    String? market,
    int? limit,
  });

  /// Fetch top movers (gainers / losers / most-active).
  ///
  /// [type]: gainers | losers | most_active (server default if null).
  /// [market]: US | HK (server default if null).
  Future<List<MoverItem>> getMovers({String? type, String? market});

  /// Fetch full stock detail (quote + fundamentals) for [symbol].
  Future<StockDetail> getStockDetail(String symbol);

  /// Fetch recent news articles for [symbol], newest first.
  ///
  /// [page] starts at 1. [pageSize] max 50 (server default 10).
  Future<NewsResult> getNews(
    String symbol, {
    int page = 1,
    int pageSize = 10,
  });

  /// Fetch quarterly financials (last 4 quarters + next earnings date).
  Future<Financials> getFinancials(String symbol);

  // ─── Watchlist (requires JWT) ───────────────────────────────────────────

  /// Fetch the authenticated user's watchlist with latest quotes.
  ///
  /// Returns quotes in server-preserved symbol order.
  Future<Watchlist> getWatchlist();

  /// Add [symbol] to the authenticated user's watchlist.
  ///
  /// [market] must be "US" or "HK".
  Future<void> addToWatchlist({required String symbol, required String market});

  /// Remove [symbol] from the authenticated user's watchlist.
  Future<void> removeFromWatchlist(String symbol);
}

// ─────────────────────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────────────────────

/// Result of a K-line (candlestick) query.
class KlineResult {
  const KlineResult({
    required this.symbol,
    required this.period,
    required this.candles,
    required this.total,
    this.nextCursor,
  });

  final String symbol;
  final String period;
  final List<Candle> candles;
  final int total;

  /// Opaque cursor for fetching the next page; null on last page.
  final String? nextCursor;
}

/// Paginated news result.
class NewsResult {
  const NewsResult({
    required this.symbol,
    required this.articles,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final String symbol;
  final List<NewsArticle> articles;
  final int page;
  final int pageSize;
  final int total;
}
