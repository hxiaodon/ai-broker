import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';

Order _makeOrder({
  OrderStatus status = OrderStatus.pending,
  int qty = 100,
  int filledQty = 0,
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
      validity: OrderValidity.day,
      extendedHours: false,
      fees: OrderFees(
        commission: Decimal.parse('0.99'),
        exchangeFee: Decimal.parse('0.03'),
        secFee: Decimal.parse('0.01'),
        finraFee: Decimal.parse('0.005'),
        total: Decimal.parse('1.035'),
      ),
      createdAt: DateTime.utc(2026, 4, 15, 9, 30),
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
}
