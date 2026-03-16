import '../entities/quote.dart';
import '../entities/candle.dart';

/// Repository interface for market data operations.
abstract class QuoteRepository {
  /// Real-time quote stream for a single symbol.
  Stream<Quote> subscribeToQuote(String symbol);

  /// Real-time quote stream for multiple symbols (watchlist).
  Stream<Map<String, Quote>> subscribeToWatchlist(List<String> symbols);

  /// Fetch historical candlestick data.
  Future<List<Candle>> getCandles({
    required String symbol,
    required String interval,
    DateTime? from,
    DateTime? to,
  });

  /// Search for stocks by query string.
  Future<List<Map<String, String>>> searchStocks(String query);

  /// Unsubscribe from a symbol's real-time feed.
  Future<void> unsubscribeFromQuote(String symbol);
}
