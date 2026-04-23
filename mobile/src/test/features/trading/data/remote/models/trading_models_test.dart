import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/trading/data/remote/models/order_model.dart';
import 'package:trading_app/features/trading/data/remote/models/position_model.dart';
import 'package:trading_app/features/trading/data/remote/models/portfolio_summary_model.dart';

// ─── Fixtures ────────────────────────────────────────────────────────────────

Map<String, dynamic> _orderFeesJson() => {
      'commission': '0.99',
      'exchange_fee': '0.03',
      'sec_fee': '0.01',
      'finra_fee': '0.005',
      'total': '1.035',
    };

Map<String, dynamic> _orderJson({
  String status = 'PENDING',
  String? limitPrice = '150.2500',
  String? avgFillPrice,
}) =>
    {
      'order_id': 'ord-001',
      'symbol': 'AAPL',
      'market': 'US',
      'side': 'buy',
      'order_type': 'limit',
      'status': status,
      'qty': 100,
      'filled_qty': 0,
      'limit_price': limitPrice,
      'avg_fill_price': avgFillPrice,
      'validity': 'day',
      'extended_hours': false,
      'fees': _orderFeesJson(),
      'created_at': '2026-04-15T09:30:00.000Z',
      'updated_at': '2026-04-15T09:30:00.000Z',
    };

Map<String, dynamic> _orderFillJson() => {
      'fill_id': 'fill-001',
      'order_id': 'ord-001',
      'qty': 50,
      'price': '150.3000',
      'exchange': 'NASDAQ',
      'filled_at': '2026-04-15T09:31:00.000Z',
    };

Map<String, dynamic> _positionJson() => {
      'symbol': 'AAPL',
      'market': 'US',
      'quantity': 100,
      'settled_qty': 80,
      'avg_cost': '150.2500',
      'current_price': '155.0000',
      'market_value': '15500.0000',
      'unrealized_pnl': '475.0000',
      'unrealized_pnl_pct': '3.16',
      'today_pnl': '200.0000',
      'today_pnl_pct': '1.31',
      'pending_settlements': [
        {'qty': 20, 'settle_date': '2026-04-16T00:00:00.000Z'},
      ],
    };

Map<String, dynamic> _portfolioSummaryJson() => {
      'total_equity': '100000.00',
      'cash_balance': '50000.00',
      'total_market_value': '50000.00',
      'day_pnl': '1200.50',
      'day_pnl_pct': '1.22',
      'cumulative_pnl': '5000.00',
      'cumulative_pnl_pct': '5.26',
      'buying_power': '75000.00',
      'unsettled_cash': '45000.00',
    };

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── OrderModel ─────────────────────────────────────────────────────────────
  group('OrderModel.fromJson', () {
    test('parses complete order', () {
      final model = OrderModel.fromJson(_orderJson());
      expect(model.orderId, 'ord-001');
      expect(model.symbol, 'AAPL');
      expect(model.market, 'US');
      expect(model.side, 'buy');
      expect(model.orderType, 'limit');
      expect(model.status, 'PENDING');
      expect(model.qty, 100);
      expect(model.filledQty, 0);
      expect(model.limitPrice, '150.2500');
      expect(model.avgFillPrice, isNull);
      expect(model.validity, 'day');
      expect(model.extendedHours, isFalse);
      expect(model.createdAt, '2026-04-15T09:30:00.000Z');
    });

    test('parses nullable limitPrice and avgFillPrice', () {
      final model = OrderModel.fromJson(
        _orderJson(limitPrice: null, avgFillPrice: '150.3000'),
      );
      expect(model.limitPrice, isNull);
      expect(model.avgFillPrice, '150.3000');
    });

    test('parses fees sub-object', () {
      final fees = OrderModel.fromJson(_orderJson()).fees;
      expect(fees.commission, '0.99');
      expect(fees.exchangeFee, '0.03');
      expect(fees.total, '1.035');
    });
  });

  // ── OrderFillModel ─────────────────────────────────────────────────────────
  group('OrderFillModel.fromJson', () {
    test('parses fill', () {
      final model = OrderFillModel.fromJson(_orderFillJson());
      expect(model.fillId, 'fill-001');
      expect(model.orderId, 'ord-001');
      expect(model.qty, 50);
      expect(model.price, '150.3000');
      expect(model.exchange, 'NASDAQ');
    });
  });

  // ── OrderDetailModel ───────────────────────────────────────────────────────
  group('OrderDetailModel.fromJson', () {
    test('parses order + fills', () {
      final json = {
        'order': _orderJson(status: 'FILLED'),
        'fills': [_orderFillJson()],
      };
      final detail = OrderDetailModel.fromJson(json);
      expect(detail.order.status, 'FILLED');
      expect(detail.fills, hasLength(1));
      expect(detail.fills.first.fillId, 'fill-001');
    });

    test('empty fills list', () {
      final json = {
        'order': _orderJson(),
        'fills': <Map<String, dynamic>>[],
      };
      final detail = OrderDetailModel.fromJson(json);
      expect(detail.fills, isEmpty);
    });
  });

  // ── PositionModel ──────────────────────────────────────────────────────────
  group('PositionModel.fromJson', () {
    test('parses position with pending settlements', () {
      final model = PositionModel.fromJson(_positionJson());
      expect(model.symbol, 'AAPL');
      expect(model.qty, 100);
      expect(model.availableQty, 80);
      expect(model.avgCost, '150.2500');
      expect(model.pendingSettlements, hasLength(1));
      expect(model.pendingSettlements.first.qty, 20);
    });

    test('defaults pendingSettlements to empty', () {
      final json = _positionJson()..remove('pending_settlements');
      final model = PositionModel.fromJson(json);
      expect(model.pendingSettlements, isEmpty);
    });
  });

  // ── PortfolioSummaryModel ──────────────────────────────────────────────────
  group('PortfolioSummaryModel.fromJson', () {
    test('parses all fields', () {
      final model = PortfolioSummaryModel.fromJson(_portfolioSummaryJson());
      expect(model.totalEquity, '100000.00');
      expect(model.cashBalance, '50000.00');
      expect(model.buyingPower, '75000.00');
      expect(model.unsettledCash, '45000.00');
    });
  });
}
