import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/market/domain/entities/candle_aggregator.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';

void main() {
  group('CandleAggregator', () {
    late CandleAggregator aggregator;

    setUp(() {
      aggregator = CandleAggregator();
    });

    test('first tick initializes candle', () {
      final tick = _createTick(
        price: Decimal.parse('100.50'),
        volume: 1000,
      );

      final result = aggregator.processTick(tick);

      expect(result.isCompleted, false);
      expect(aggregator.currentCandle, isNotNull);
      expect(aggregator.currentCandle!.o, Decimal.parse('100.50'));
      expect(aggregator.currentCandle!.h, Decimal.parse('100.50'));
      expect(aggregator.currentCandle!.l, Decimal.parse('100.50'));
      expect(aggregator.currentCandle!.c, Decimal.parse('100.50'));
      expect(aggregator.currentCandle!.v, 1000);
      expect(aggregator.currentCandle!.n, 1);
    });

    test('same minute updates OHLCV', () {
      // First tick
      aggregator.processTick(_createTick(
        price: Decimal.parse('100.00'),
        volume: 1000,
      ));

      // Wait a bit to stay in same minute
      // Second tick (higher)
      aggregator.processTick(_createTick(
        price: Decimal.parse('101.50'),
        volume: 1500,
      ));

      // Third tick (lower)
      final result = aggregator.processTick(_createTick(
        price: Decimal.parse('99.50'),
        volume: 2000,
      ));

      expect(result.isCompleted, false);
      final candle = aggregator.currentCandle!;
      expect(candle.o, Decimal.parse('100.00')); // Open unchanged
      expect(candle.h, Decimal.parse('101.50')); // High tracked
      expect(candle.l, Decimal.parse('99.50'));  // Low tracked
      expect(candle.c, Decimal.parse('99.50'));  // Close = last price
      expect(candle.v, 2000); // Volume = cumulative
      expect(candle.n, 3); // Trade count
    });

    test('high/low correctly track extremes', () {
      aggregator.processTick(_createTick(
        price: Decimal.parse('100.00'),
        volume: 1000,
      ));

      // Higher
      aggregator.processTick(_createTick(
        price: Decimal.parse('102.00'),
        volume: 1100,
      ));

      // Lower
      aggregator.processTick(_createTick(
        price: Decimal.parse('98.00'),
        volume: 1200,
      ));

      // Middle
      aggregator.processTick(_createTick(
        price: Decimal.parse('100.50'),
        volume: 1300,
      ));

      final candle = aggregator.currentCandle!;
      expect(candle.h, Decimal.parse('102.00'));
      expect(candle.l, Decimal.parse('98.00'));
      expect(candle.c, Decimal.parse('100.50'));
    });

    test('volume is cumulative daily volume', () {
      aggregator.processTick(_createTick(
        price: Decimal.parse('100.00'),
        volume: 1000,
      ));

      aggregator.processTick(_createTick(
        price: Decimal.parse('100.50'),
        volume: 1500, // Cumulative (not delta)
      ));

      aggregator.processTick(_createTick(
        price: Decimal.parse('101.00'),
        volume: 2200, // Cumulative
      ));

      expect(aggregator.currentCandle!.v, 2200);
    });

    test('reset clears aggregator state', () {
      aggregator.processTick(_createTick(
        price: Decimal.parse('100.00'),
        volume: 1000,
      ));

      expect(aggregator.currentCandle, isNotNull);

      aggregator.reset();

      expect(aggregator.currentCandle, isNull);
    });
  });
}

Quote _createTick({
  required Decimal price,
  required int volume,
}) {
  return Quote(
    symbol: 'AAPL',
    name: 'Apple Inc.',
    nameZh: '苹果公司',
    market: 'US',
    price: price,
    change: Decimal.zero,
    changePct: Decimal.zero,
    volume: volume,
    bid: price,
    ask: price,
    turnover: '0',
    prevClose: Decimal.parse('100.00'),
    open: Decimal.parse('100.00'),
    high: price,
    low: price,
    marketCap: '0',
    peRatio: '0',
    delayed: false,
    marketStatus: MarketStatus.regular,
    isStale: false,
    staleSinceMs: 0,
  );
}
