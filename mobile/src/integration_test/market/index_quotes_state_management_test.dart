import 'package:flutter/foundation.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/application/index_quotes_notifier.dart';
import 'package:trading_app/features/market/application/quote_websocket_notifier.dart';
import 'package:trading_app/features/market/data/market_data_repository_impl.dart';
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';

import '../test_helpers/mock_market_data_repository.dart';
import '../test_helpers/mock_websocket_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Index Quotes State Management Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // Initialize logger for tests
  setUpAll(() {
    AppLogger.init();
  });

  group('IndexQuotesNotifier - State Management', () {
    late ProviderContainer container;
    late MockMarketDataRepository mockRepo;
    late MockWebSocketClient mockWsClient;

    setUp(() {
      mockRepo = MockMarketDataRepository();
      mockWsClient = MockWebSocketClient();

      container = ProviderContainer(
        overrides: [
          marketDataRepositoryProvider.overrideWithValue(mockRepo),
          wsClientFactoryProvider.overrideWithValue(
            (_) => mockWsClient,
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('T01: Initial load fetches index quotes from REST API', () async {
      // Arrange
      final mockQuotes = {
        'SPY': _createMockQuote('SPY', '521.44', '0.0082'),
        'QQQ': _createMockQuote('QQQ', '385.92', '0.0125'),
        'DIA': _createMockQuote('DIA', '381.80', '-0.0045'),
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

      debugPrint('✅ T01: Initial REST load works');
    });

    test('T02: Subscribes to WebSocket when connection is ready', () async {
      // Arrange
      final mockQuotes = {
        'SPY': _createMockQuote('SPY', '521.44', '0.0082'),
        'QQQ': _createMockQuote('QQQ', '385.92', '0.0125'),
        'DIA': _createMockQuote('DIA', '381.80', '-0.0045'),
      };
      mockRepo.setMockQuotes(mockQuotes);

      // Act - trigger initial load which will also trigger WS connection
      await container.read(indexQuotesProvider.future);

      // Wait for WebSocket connection and subscription to complete
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Assert - check that client connected and subscribed
      expect(mockWsClient.isConnected, true);
      expect(mockWsClient.subscribedSymbols, containsAll(['SPY', 'QQQ', 'DIA']));

      debugPrint('✅ T02: WebSocket subscription works');
    });

    test('T03: SNAPSHOT frame replaces quote data', () async {
      // Arrange
      final initialQuotes = {
        'SPY': _createMockQuote('SPY', '521.44', '0.0082'),
      };
      mockRepo.setMockQuotes(initialQuotes);

      await container.read(indexQuotesProvider.future);

      // Wait for WS connection
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Act - send SNAPSHOT frame with updated data
      final snapshotQuote = _createMockQuote('SPY', '522.50', '0.0102');
      mockWsClient.simulateQuoteUpdate(WsQuoteUpdate(
        frameType: WsFrameType.snapshot,
        symbol: 'SPY',
        quote: snapshotQuote,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert
      final state = container.read(indexQuotesProvider).value!;
      expect(state['SPY']?.price, Decimal.parse('522.50'));
      expect(state['SPY']?.changePct, Decimal.parse('0.0102'));

      debugPrint('✅ T03: SNAPSHOT frame updates work');
    });

    test('T04: TICK frame patches only changed fields', () async {
      // Arrange
      final initialQuotes = {
        'QQQ': _createMockQuote('QQQ', '385.92', '0.0125', volume: 1000000),
      };
      mockRepo.setMockQuotes(initialQuotes);

      await container.read(indexQuotesProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Act - send TICK frame with only price change
      final tickQuote = Quote(
        symbol: 'QQQ',
        name: '',
        nameZh: '',
        market: 'US',
        price: Decimal.parse('386.10'), // Changed
        change: Decimal.zero, // Not changed (zero value)
        changePct: Decimal.zero, // Not changed
        volume: 0, // Not changed
        bid: null,
        ask: null,
        turnover: '',
        prevClose: Decimal.zero,
        open: Decimal.zero,
        high: Decimal.zero,
        low: Decimal.zero,
        marketCap: '',
        peRatio: '',
        delayed: false,
        marketStatus: MarketStatus.regular,
        isStale: false,
        staleSinceMs: 0,
      );

      mockWsClient.simulateQuoteUpdate(WsQuoteUpdate(
        frameType: WsFrameType.tick,
        symbol: 'QQQ',
        quote: tickQuote,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert - price updated, but changePct and volume preserved
      final state = container.read(indexQuotesProvider).value!;
      expect(state['QQQ']?.price, Decimal.parse('386.10')); // Updated
      expect(state['QQQ']?.changePct, Decimal.parse('0.0125')); // Preserved
      expect(state['QQQ']?.volume, 1000000); // Preserved

      debugPrint('✅ T04: TICK frame patching works');
    });

    test('T05: DELAYED frame marks quote as delayed', () async {
      // Arrange
      final initialQuotes = {
        'DIA': _createMockQuote('DIA', '381.80', '-0.0045'),
      };
      mockRepo.setMockQuotes(initialQuotes);

      await container.read(indexQuotesProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Act - send DELAYED frame
      final delayedQuote = _createMockQuote('DIA', '381.50', '-0.0053', delayed: true);
      mockWsClient.simulateQuoteUpdate(WsQuoteUpdate(
        frameType: WsFrameType.delayed,
        symbol: 'DIA',
        quote: delayedQuote,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert
      final state = container.read(indexQuotesProvider).value!;
      expect(state['DIA']?.delayed, true);
      expect(state['DIA']?.price, Decimal.parse('381.50'));

      debugPrint('✅ T05: DELAYED frame handling works');
    });

    test('T06: Ignores updates for non-index symbols', () async {
      // Arrange
      final initialQuotes = {
        'SPY': _createMockQuote('SPY', '521.44', '0.0082'),
      };
      mockRepo.setMockQuotes(initialQuotes);

      await container.read(indexQuotesProvider.future);
      mockWsClient.simulateConnected(WsUserType.registered);

      final initialState = container.read(indexQuotesProvider).value!;

      // Act - send update for non-index symbol
      final otherQuote = _createMockQuote('AAPL', '175.50', '0.0120');
      mockWsClient.simulateQuoteUpdate(WsQuoteUpdate(
        frameType: WsFrameType.tick,
        symbol: 'AAPL',
        quote: otherQuote,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert - state unchanged
      final finalState = container.read(indexQuotesProvider).value!;
      expect(finalState, equals(initialState));
      expect(finalState.containsKey('AAPL'), false);

      debugPrint('✅ T06: Non-index symbol filtering works');
    });

    test('T07: Handles WebSocket connection errors gracefully', () async {
      // Arrange
      final mockQuotes = {
        'SPY': _createMockQuote('SPY', '521.44', '0.0082'),
      };
      mockRepo.setMockQuotes(mockQuotes);

      // Act
      await container.read(indexQuotesProvider.future);

      // Simulate connection error
      mockWsClient.simulateError(Exception('Connection failed'));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert - state still has initial data despite WS error
      final state = container.read(indexQuotesProvider).value!;
      expect(state['SPY']?.symbol, 'SPY');

      debugPrint('✅ T07: WebSocket error handling works');
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers
// ─────────────────────────────────────────────────────────────────────────────

Quote _createMockQuote(
  String symbol,
  String price,
  String changePct, {
  int volume = 1000000,
  bool delayed = false,
}) {
  return Quote(
    symbol: symbol,
    name: '$symbol ETF',
    nameZh: '$symbol 指数基金',
    market: 'US',
    price: Decimal.parse(price),
    change: Decimal.parse(price) * Decimal.parse(changePct),
    changePct: Decimal.parse(changePct),
    volume: volume,
    bid: Decimal.parse(price) - Decimal.parse('0.01'),
    ask: Decimal.parse(price) + Decimal.parse('0.01'),
    turnover: '${volume * 100}',
    prevClose: (Decimal.parse(price) / (Decimal.one + Decimal.parse(changePct))).toDecimal(scaleOnInfinitePrecision: 2),
    open: Decimal.parse(price) - Decimal.parse('1.00'),
    high: Decimal.parse(price) + Decimal.parse('2.00'),
    low: Decimal.parse(price) - Decimal.parse('2.00'),
    marketCap: '${volume * 1000}',
    peRatio: '22.5',
    delayed: delayed,
    marketStatus: MarketStatus.regular,
    isStale: false,
    staleSinceMs: 0,
  );
}
