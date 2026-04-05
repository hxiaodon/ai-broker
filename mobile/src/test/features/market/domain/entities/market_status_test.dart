import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';

void main() {
  group('MarketStatus.fromApi', () {
    test('parses all valid API values', () {
      expect(MarketStatus.fromApi('REGULAR'), MarketStatus.regular);
      expect(MarketStatus.fromApi('PRE_MARKET'), MarketStatus.preMarket);
      expect(MarketStatus.fromApi('AFTER_HOURS'), MarketStatus.afterHours);
      expect(MarketStatus.fromApi('CLOSED'), MarketStatus.closed);
      expect(MarketStatus.fromApi('HALTED'), MarketStatus.halted);
    });

    test('unknown string falls back to closed (safe default)', () {
      expect(MarketStatus.fromApi(''), MarketStatus.closed);
      expect(MarketStatus.fromApi('UNKNOWN'), MarketStatus.closed);
      expect(MarketStatus.fromApi('regular'), MarketStatus.closed); // case-sensitive
    });
  });

  group('MarketStatus.isTradingActive', () {
    test('returns true for active trading sessions', () {
      expect(MarketStatus.regular.isTradingActive, isTrue);
      expect(MarketStatus.preMarket.isTradingActive, isTrue);
      expect(MarketStatus.afterHours.isTradingActive, isTrue);
    });

    test('returns false for non-trading states', () {
      expect(MarketStatus.closed.isTradingActive, isFalse);
      expect(MarketStatus.halted.isTradingActive, isFalse);
    });
  });
}
