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

  group('Position.availableQty — unsettled constraint (PRD-06 §6.2)', () {
    test('availableQty equals qty when fully settled', () {
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
      expect(pos.availableQty, pos.qty);
    });

    test('availableQty is less than qty when shares are pending settlement', () {
      // 50 shares bought today (T+1 unsettled) → availableQty = 50, not 100
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
          PendingSettlement(qty: 50, settleDate: DateTime.utc(2026, 5, 7)),
        ],
      );
      expect(pos.availableQty, lessThan(pos.qty));
      expect(pos.availableQty, 50);
    });

    test('availableQty is zero when all shares are unsettled', () {
      final pos = Position(
        symbol: 'TSLA',
        market: 'US',
        qty: 200,
        availableQty: 0,
        avgCost: Decimal.parse('200.00'),
        currentPrice: Decimal.parse('210.00'),
        marketValue: Decimal.parse('42000.00'),
        unrealizedPnl: Decimal.parse('2000.00'),
        unrealizedPnlPct: Decimal.parse('5.00'),
        todayPnl: Decimal.parse('1000.00'),
        todayPnlPct: Decimal.parse('2.44'),
        pendingSettlements: [
          PendingSettlement(qty: 200, settleDate: DateTime.utc(2026, 5, 7)),
        ],
      );
      expect(pos.availableQty, 0);
      expect(pos.availableQty, lessThanOrEqualTo(pos.qty));
    });
  });
}
