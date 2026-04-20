import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/trading/domain/entities/position.dart';

void main() {
  group('Position', () {
    test('all monetary fields are Decimal', () {
      final pos = Position(
        symbol: 'AAPL',
        market: 'US',
        qty: 100,
        availableQty: 80,
        avgCost: Decimal.parse('150.25'),
        currentPrice: Decimal.parse('155.00'),
        marketValue: Decimal.parse('15500.00'),
        unrealizedPnl: Decimal.parse('475.00'),
        unrealizedPnlPct: Decimal.parse('3.16'),
        todayPnl: Decimal.parse('200.00'),
        todayPnlPct: Decimal.parse('1.31'),
      );
      expect(pos.avgCost, isA<Decimal>());
      expect(pos.currentPrice, isA<Decimal>());
      expect(pos.marketValue, isA<Decimal>());
      expect(pos.unrealizedPnl, isA<Decimal>());
    });

    test('pendingSettlements defaults to empty list', () {
      final pos = Position(
        symbol: 'AAPL',
        market: 'US',
        qty: 100,
        availableQty: 100,
        avgCost: Decimal.parse('150.25'),
        currentPrice: Decimal.parse('155.00'),
        marketValue: Decimal.parse('15500.00'),
        unrealizedPnl: Decimal.parse('475.00'),
        unrealizedPnlPct: Decimal.parse('3.16'),
        todayPnl: Decimal.parse('200.00'),
        todayPnlPct: Decimal.parse('1.31'),
      );
      expect(pos.pendingSettlements, isEmpty);
    });

    test('pendingSettlements with T+1 settlement', () {
      final pos = Position(
        symbol: 'AAPL',
        market: 'US',
        qty: 100,
        availableQty: 50,
        avgCost: Decimal.parse('150.25'),
        currentPrice: Decimal.parse('155.00'),
        marketValue: Decimal.parse('15500.00'),
        unrealizedPnl: Decimal.parse('475.00'),
        unrealizedPnlPct: Decimal.parse('3.16'),
        todayPnl: Decimal.parse('200.00'),
        todayPnlPct: Decimal.parse('1.31'),
        pendingSettlements: [
          PendingSettlement(
            qty: 50,
            settleDate: DateTime.utc(2026, 4, 16),
          ),
        ],
      );
      expect(pos.pendingSettlements, hasLength(1));
      expect(pos.pendingSettlements.first.qty, 50);
      expect(pos.pendingSettlements.first.settleDate.isUtc, isTrue);
    });
  });
}
