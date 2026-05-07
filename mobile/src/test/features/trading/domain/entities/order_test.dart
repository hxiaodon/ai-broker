import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';

Order _makeOrder({
  OrderStatus status = OrderStatus.pending,
  int qty = 100,
  int filledQty = 0,
  OrderValidity validity = OrderValidity.day,
  DateTime? createdAt,
}) =>
    Order(
      orderId: 'ord-001',
      symbol: 'AAPL',
      market: 'US',
      side: OrderSide.buy,
      orderType: OrderType.limit,
      status: status,
      qty: qty,
      filledQty: filledQty,
      limitPrice: Decimal.parse('150.25'),
      avgFillPrice: null,
      validity: validity,
      extendedHours: false,
      fees: OrderFees(
        commission: Decimal.parse('0.99'),
        exchangeFee: Decimal.parse('0.03'),
        secFee: Decimal.parse('0.01'),
        finraFee: Decimal.parse('0.005'),
        total: Decimal.parse('1.035'),
      ),
      createdAt: createdAt ?? DateTime.utc(2026, 4, 15, 9, 30),
      updatedAt: DateTime.utc(2026, 4, 15, 9, 30),
    );

void main() {
  group('Order.remainingQty', () {
    test('full qty when nothing filled', () {
      expect(_makeOrder(qty: 100, filledQty: 0).remainingQty, 100);
    });

    test('partial fill', () {
      expect(_makeOrder(qty: 100, filledQty: 40).remainingQty, 60);
    });

    test('fully filled', () {
      expect(_makeOrder(qty: 100, filledQty: 100).remainingQty, 0);
    });
  });

  group('Order.isCancellable', () {
    test('pending is cancellable', () {
      expect(_makeOrder(status: OrderStatus.pending).isCancellable, isTrue);
    });

    test('partiallyFilled is cancellable', () {
      expect(
        _makeOrder(status: OrderStatus.partiallyFilled).isCancellable,
        isTrue,
      );
    });

    for (final status in [
      OrderStatus.filled,
      OrderStatus.cancelled,
      OrderStatus.partiallyFilledCancelled,
      OrderStatus.expired,
      OrderStatus.rejected,
      OrderStatus.exchangeRejected,
      OrderStatus.riskChecking,
    ]) {
      test('$status is NOT cancellable', () {
        expect(_makeOrder(status: status).isCancellable, isFalse);
      });
    }
  });

  group('OrderFees uses Decimal', () {
    test('total is Decimal, not double', () {
      final fees = _makeOrder().fees;
      expect(fees.total, isA<Decimal>());
      expect(fees.commission, isA<Decimal>());
    });
  });

  group('OrderFees.isTotalConsistent', () {
    test('consistent when total equals sum of components', () {
      // 0.99 + 0.03 + 0.01 + 0.005 = 1.035
      final fees = OrderFees(
        commission: Decimal.parse('0.99'),
        exchangeFee: Decimal.parse('0.03'),
        secFee: Decimal.parse('0.01'),
        finraFee: Decimal.parse('0.005'),
        total: Decimal.parse('1.035'),
      );
      expect(fees.isTotalConsistent, isTrue);
    });

    test('inconsistent when total does not match sum of components', () {
      final fees = OrderFees(
        commission: Decimal.parse('0.99'),
        exchangeFee: Decimal.parse('0.03'),
        secFee: Decimal.parse('0.01'),
        finraFee: Decimal.parse('0.005'),
        total: Decimal.parse('2.00'), // wrong
      );
      expect(fees.isTotalConsistent, isFalse);
    });

    test('consistent when all fees are zero', () {
      final fees = OrderFees(
        commission: Decimal.zero,
        exchangeFee: Decimal.zero,
        secFee: Decimal.zero,
        finraFee: Decimal.zero,
        total: Decimal.zero,
      );
      expect(fees.isTotalConsistent, isTrue);
    });

    test('default order fees from _makeOrder are consistent', () {
      expect(_makeOrder().fees.isTotalConsistent, isTrue);
    });
  });

  group('Order timestamps are UTC', () {
    test('createdAt and updatedAt are UTC', () {
      final order = _makeOrder();
      expect(order.createdAt.isUtc, isTrue);
      expect(order.updatedAt.isUtc, isTrue);
    });
  });

  group('OrderSide enum', () {
    test('has buy and sell', () {
      expect(OrderSide.values, containsAll([OrderSide.buy, OrderSide.sell]));
    });
  });

  group('OrderStatus enum', () {
    test('has all 9 statuses per PRD', () {
      expect(OrderStatus.values, hasLength(9));
    });
  });

  group('Order.gtcExpiresAt / GTC 90-day expiry (PRD-04 §6.4)', () {
    test('DAY order has no expiry', () {
      final order = _makeOrder(validity: OrderValidity.day);
      expect(order.gtcExpiresAt, isNull);
      expect(order.daysUntilGtcExpiry, isNull);
      expect(order.isGtcExpiringIn3Days, isFalse);
      expect(order.isGtcExpiringIn1Day, isFalse);
    });

    test('GTC order expires exactly 90 days after createdAt', () {
      final created = DateTime.utc(2026, 1, 1, 9, 30);
      final order = _makeOrder(validity: OrderValidity.gtc, createdAt: created);
      expect(order.gtcExpiresAt, DateTime.utc(2026, 4, 1, 9, 30));
    });

    test('GTC order with 45 days remaining is NOT expiring soon', () {
      final created = DateTime.now().toUtc().subtract(const Duration(days: 45));
      final order = _makeOrder(validity: OrderValidity.gtc, createdAt: created);
      expect(order.isGtcExpiringIn3Days, isFalse);
      expect(order.isGtcExpiringIn1Day, isFalse);
      expect(order.daysUntilGtcExpiry, greaterThan(3));
    });

    test('GTC order with 2 days remaining triggers 3-day notification', () {
      final created = DateTime.now().toUtc().subtract(const Duration(days: 88));
      final order = _makeOrder(validity: OrderValidity.gtc, createdAt: created);
      expect(order.isGtcExpiringIn3Days, isTrue);
    });

    test('GTC order with 0 days remaining triggers 1-day notification', () {
      final created = DateTime.now().toUtc().subtract(const Duration(days: 89, hours: 23));
      final order = _makeOrder(validity: OrderValidity.gtc, createdAt: created);
      expect(order.isGtcExpiringIn1Day, isTrue);
    });

    test('GTC order past 90 days has null daysUntilGtcExpiry', () {
      final created = DateTime.now().toUtc().subtract(const Duration(days: 91));
      final order = _makeOrder(validity: OrderValidity.gtc, createdAt: created);
      expect(order.daysUntilGtcExpiry, isNull);
      expect(order.isGtcExpiringIn3Days, isFalse);
    });
  });
}
