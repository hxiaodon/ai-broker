import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/application/index_quotes_notifier.dart';
import 'package:trading_app/features/market/data/market_data_repository_impl.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';

import '../test_helpers/mock_market_data_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Simplified Index Quotes Tests (REST only)
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    AppLogger.init();
  });

  group('IndexQuotesNotifier - REST API', () {
    late ProviderContainer container;
    late MockMarketDataRepository mockRepo;

    setUp(() {
      mockRepo = MockMarketDataRepository();
      container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('T01: Loads index quotes from REST API', () async {
      // Arrange
      final mockQuotes = {
        'SPY': _createQuote('SPY', '521.44', '0.0082'),
        'QQQ': _createQuote('QQQ', '385.92', '0.0125'),
        'DIA': _createQuote('DIA', '381.80', '-0.0045'),
      };
      mockRepo.setMockQuotes(mockQuotes);

      // Act
      final state = await container.read(indexQuotesProvider.future);

      // Assert
      expect(state.length, 3);
      expect(state['SPY']?.symbol, 'SPY');
      expect(state['SPY']?.price, Decimal.parse('521.44'));
      expect(state['QQQ']?.symbol, 'QQQ');
      expect(state['DIA']?.symbol, 'DIA');

      print('✅ T01: REST load works');
    });

    test('T02: Returns empty map when no quotes available', () async {
      // Arrange
      mockRepo.setMockQuotes({});

      // Act
      final state = await container.read(indexQuotesProvider.future);

      // Assert
      expect(state.isEmpty, true);

      print('✅ T02: Empty state works');
    });

    test('T03: Handles partial quote availability', () async {
      // Arrange - only SPY available
      final mockQuotes = {
        'SPY': _createQuote('SPY', '521.44', '0.0082'),
      };
      mockRepo.setMockQuotes(mockQuotes);

      // Act
      final state = await container.read(indexQuotesProvider.future);

      // Assert
      expect(state.length, 1);
      expect(state['SPY']?.symbol, 'SPY');
      expect(state.containsKey('QQQ'), false);
      expect(state.containsKey('DIA'), false);

      print('✅ T03: Partial availability works');
    });

    test('T04: Preserves quote metadata', () async {
      // Arrange
      final mockQuotes = {
        'SPY': Quote(
          symbol: 'SPY',
          name: 'SPDR S&P 500 ETF',
          nameZh: 'S&P 500 指数基金',
          market: 'US',
          price: Decimal.parse('521.44'),
          change: Decimal.parse('4.22'),
          changePct: Decimal.parse('0.0082'),
          volume: 89234567,
          bid: Decimal.parse('521.42'),
          ask: Decimal.parse('521.46'),
          turnover: '46567890123.00',
          prevClose: Decimal.parse('517.22'),
          open: Decimal.parse('519.00'),
          high: Decimal.parse('523.50'),
          low: Decimal.parse('519.80'),
          marketCap: '450000000000.00',
          peRatio: '22.3',
          delayed: false,
          marketStatus: MarketStatus.regular,
          isStale: false,
          staleSinceMs: 0,
        ),
      };
      mockRepo.setMockQuotes(mockQuotes);

      // Act
      final state = await container.read(indexQuotesProvider.future);

      // Assert
      final spy = state['SPY']!;
      expect(spy.name, 'SPDR S&P 500 ETF');
      expect(spy.nameZh, 'S&P 500 指数基金');
      expect(spy.marketCap, '450000000000.00');
      expect(spy.peRatio, '22.3');

      print('✅ T04: Metadata preservation works');
    });

    test('T05: Returns empty map when repository returns empty', () async {
      // Arrange
      mockRepo.setMockQuotes({});

      // Act
      final state = await container.read(indexQuotesProvider.future);

      // Assert - should return empty map, not throw
      expect(state.isEmpty, true);
      expect(state.length, 0);

      print('✅ T05: Empty repository result works');
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────────────────────────────────────

Quote _createQuote(String symbol, String price, String changePct) {
  final priceDecimal = Decimal.parse(price);
  final changePctDecimal = Decimal.parse(changePct);
  final changeDecimal = priceDecimal * changePctDecimal;

  return Quote(
    symbol: symbol,
    name: '$symbol ETF',
    nameZh: '$symbol 指数基金',
    market: 'US',
    price: priceDecimal,
    change: changeDecimal,
    changePct: changePctDecimal,
    volume: 1000000,
    bid: priceDecimal - Decimal.parse('0.01'),
    ask: priceDecimal + Decimal.parse('0.01'),
    turnover: '${1000000 * 100}',
    prevClose: (priceDecimal / (Decimal.one + changePctDecimal))
        .toDecimal(scaleOnInfinitePrecision: 2),
    open: priceDecimal - Decimal.parse('1.00'),
    high: priceDecimal + Decimal.parse('2.00'),
    low: priceDecimal - Decimal.parse('2.00'),
    marketCap: '${1000000 * 1000}',
    peRatio: '22.5',
    delayed: false,
    marketStatus: MarketStatus.regular,
    isStale: false,
    staleSinceMs: 0,
  );
}
