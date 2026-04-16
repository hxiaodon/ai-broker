import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/repositories/market_data_repository.dart';

/// Mock Market Data Repository for testing
///
/// Only implements getQuotes() and getQuote() - other methods throw UnimplementedError
class MockMarketDataRepository implements MarketDataRepository {
  Map<String, Quote> _mockQuotes = {};

  void setMockQuotes(Map<String, Quote> quotes) {
    _mockQuotes = quotes;
  }

  @override
  Future<Map<String, Quote>> getQuotes(List<String> symbols) async {
    final result = <String, Quote>{};
    for (final symbol in symbols) {
      if (_mockQuotes.containsKey(symbol)) {
        result[symbol] = _mockQuotes[symbol]!;
      }
    }
    return result;
  }

  @override
  Future<Quote> getQuote(String symbol) async {
    if (_mockQuotes.containsKey(symbol)) {
      return _mockQuotes[symbol]!;
    }
    throw Exception('Quote not found: $symbol');
  }

  void reset() {
    _mockQuotes = {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
