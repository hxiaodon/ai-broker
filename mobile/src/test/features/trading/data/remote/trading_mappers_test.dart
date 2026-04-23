import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/trading/data/remote/models/order_model.dart';
import 'package:trading_app/features/trading/data/remote/models/position_model.dart';
import 'package:trading_app/features/trading/data/remote/models/portfolio_summary_model.dart';
import 'package:trading_app/features/trading/data/remote/trading_mappers.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

OrderFeesModel _feesModel() => const OrderFeesModel(
      commission: '0.99',
      exchangeFee: '0.03',
      secFee: '0.01',
      finraFee: '0.005',
      total: '1.035',
    );

OrderModel _orderModel({
  String side = 'buy',
  String orderType = 'limit',
  String status = 'PENDING',
  String? limitPrice = '150.2500',
  String? avgFillPrice,
}) =>
    OrderModel(
      orderId: 'ord-001',
      symbol: 'AAPL',
      market: 'US',
      side: side,
      orderType: orderType,
      status: status,
      qty: 100,
      filledQty: 40,
      limitPrice: limitPrice,
      avgFillPrice: avgFillPrice,
      validity: 'day',
      extendedHours: true,
      fees: _feesModel(),
      createdAt: '2026-04-15T09:30:00.000Z',
      updatedAt: '2026-04-15T09:31:00.000Z',
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── OrderModel → Order ─────────────────────────────────────────────────────
  group('OrderModelMapper.toDomain', () {
    test('maps all scalar fields', () {
      final order = _orderModel().toDomain();
      expect(order.orderId, 'ord-001');
      expect(order.symbol, 'AAPL');
      expect(order.market, 'US');
      expect(order.qty, 100);
      expect(order.filledQty, 40);
      expect(order.extendedHours, isTrue);
    });

    test('converts limitPrice and avgFillPrice to Decimal', () {
      final order =
          _orderModel(limitPrice: '150.2500', avgFillPrice: '150.3000')
              .toDomain();
      expect(order.limitPrice, Decimal.parse('150.2500'));
      expect(order.avgFillPrice, Decimal.parse('150.3000'));
    });

    test('nullable limitPrice and avgFillPrice', () {
      final order =
          _orderModel(limitPrice: null, avgFillPrice: null).toDomain();
      expect(order.limitPrice, isNull);
      expect(order.avgFillPrice, isNull);
    });

    test('timestamps are UTC', () {
      final order = _orderModel().toDomain();
      expect(order.createdAt.isUtc, isTrue);
      expect(order.updatedAt.isUtc, isTrue);
      expect(order.createdAt, DateTime.utc(2026, 4, 15, 9, 30));
    });

    // ── Side parsing ──
    test('parses buy side', () {
      expect(_orderModel(side: 'buy').toDomain().side, OrderSide.buy);
    });

    test('parses sell side', () {
      expect(_orderModel(side: 'sell').toDomain().side, OrderSide.sell);
    });

    // ── OrderType parsing ──
    test('parses market order type', () {
      expect(
          _orderModel(orderType: 'market').toDomain().orderType, OrderType.market);
    });

    test('parses limit order type', () {
      expect(
          _orderModel(orderType: 'limit').toDomain().orderType, OrderType.limit);
    });

    // ── Status parsing (all 9) ──
    final statusCases = {
      'RISK_CHECKING': OrderStatus.riskChecking,
      'PENDING': OrderStatus.pending,
      'PARTIALLY_FILLED': OrderStatus.partiallyFilled,
      'FILLED': OrderStatus.filled,
      'CANCELLED': OrderStatus.cancelled,
      'PARTIALLY_FILLED_CANCELLED': OrderStatus.partiallyFilledCancelled,
      'EXPIRED': OrderStatus.expired,
      'REJECTED': OrderStatus.rejected,
      'EXCHANGE_REJECTED': OrderStatus.exchangeRejected,
    };

    for (final entry in statusCases.entries) {
      test('parses status ${entry.key}', () {
        expect(
          _orderModel(status: entry.key).toDomain().status,
          entry.value,
        );
      });
    }

    test('unknown status defaults to rejected', () {
      expect(
        _orderModel(status: 'UNKNOWN_STATUS').toDomain().status,
        OrderStatus.rejected,
      );
    });

    // ── Validity parsing ──
    test('parses day validity', () {
      final order = _orderModel().toDomain();
      expect(order.validity, OrderValidity.day);
    });

    test('parses gtc validity', () {
      final model = OrderModel(
        orderId: 'ord-002',
        symbol: 'TSLA',
        market: 'US',
        side: 'buy',
        orderType: 'limit',
        status: 'PENDING',
        qty: 10,
        filledQty: 0,
        validity: 'gtc',
        extendedHours: false,
        fees: _feesModel(),
        createdAt: '2026-04-15T09:30:00.000Z',
        updatedAt: '2026-04-15T09:30:00.000Z',
      );
      expect(model.toDomain().validity, OrderValidity.gtc);
    });
  });

  // ── OrderFeesModel → OrderFees ─────────────────────────────────────────────
  group('OrderFeesModelMapper.toDomain', () {
    test('converts all fee strings to Decimal', () {
      final fees = _feesModel().toDomain();
      expect(fees.commission, Decimal.parse('0.99'));
      expect(fees.exchangeFee, Decimal.parse('0.03'));
      expect(fees.secFee, Decimal.parse('0.01'));
      expect(fees.finraFee, Decimal.parse('0.005'));
      expect(fees.total, Decimal.parse('1.035'));
    });
  });

  // ── OrderFillModel → OrderFill ─────────────────────────────────────────────
  group('OrderFillModelMapper.toDomain', () {
    test('converts fill model to domain', () {
      const model = OrderFillModel(
        fillId: 'fill-001',
        orderId: 'ord-001',
        qty: 50,
        price: '150.3000',
        exchange: 'NASDAQ',
        filledAt: '2026-04-15T09:31:00.000Z',
      );
      final fill = model.toDomain();
      expect(fill.fillId, 'fill-001');
      expect(fill.price, Decimal.parse('150.3000'));
      expect(fill.filledAt.isUtc, isTrue);
      expect(fill.filledAt, DateTime.utc(2026, 4, 15, 9, 31));
    });
  });

  // ── PositionModel → Position ───────────────────────────────────────────────
  group('PositionModelMapper.toDomain', () {
    test('converts all Decimal fields', () {
      const model = PositionModel(
        symbol: 'AAPL',
        market: 'US',
        qty: 100,
        availableQty: 80,
        avgCost: '150.2500',
        currentPrice: '155.0000',
        marketValue: '15500.0000',
        unrealizedPnl: '475.0000',
        unrealizedPnlPct: '3.16',
        todayPnl: '200.0000',
        todayPnlPct: '1.31',
      );
      final pos = model.toDomain();
      expect(pos.avgCost, Decimal.parse('150.2500'));
      expect(pos.currentPrice, Decimal.parse('155.0000'));
      expect(pos.marketValue, Decimal.parse('15500.0000'));
      expect(pos.unrealizedPnl, Decimal.parse('475.0000'));
      expect(pos.unrealizedPnlPct, Decimal.parse('3.16'));
      expect(pos.todayPnl, Decimal.parse('200.0000'));
      expect(pos.todayPnlPct, Decimal.parse('1.31'));
    });

    test('converts pending settlements with UTC dates', () {
      const model = PositionModel(
        symbol: 'AAPL',
        market: 'US',
        qty: 100,
        availableQty: 50,
        avgCost: '150.2500',
        currentPrice: '155.0000',
        marketValue: '15500.0000',
        unrealizedPnl: '475.0000',
        unrealizedPnlPct: '3.16',
        todayPnl: '200.0000',
        todayPnlPct: '1.31',
        pendingSettlements: [
          PendingSettlementModel(qty: 50, settleDate: '2026-04-16T00:00:00.000Z'),
        ],
      );
      final pos = model.toDomain();
      expect(pos.pendingSettlements, hasLength(1));
      expect(pos.pendingSettlements.first.settleDate.isUtc, isTrue);
    });

    test('negative P&L values', () {
      const model = PositionModel(
        symbol: 'TSLA',
        market: 'US',
        qty: 50,
        availableQty: 50,
        avgCost: '250.0000',
        currentPrice: '240.0000',
        marketValue: '12000.0000',
        unrealizedPnl: '-500.0000',
        unrealizedPnlPct: '-4.00',
        todayPnl: '-200.0000',
        todayPnlPct: '-1.64',
      );
      final pos = model.toDomain();
      expect(pos.unrealizedPnl, Decimal.parse('-500.0000'));
      expect(pos.todayPnlPct, Decimal.parse('-1.64'));
    });
  });

  // ── PortfolioSummaryModel → PortfolioSummary ───────────────────────────────
  group('PortfolioSummaryModelMapper.toDomain', () {
    test('converts all fields to Decimal', () {
      const model = PortfolioSummaryModel(
        totalEquity: '100000.00',
        cashBalance: '50000.00',
        marketValue: '50000.00',
        dayPnl: '1200.50',
        dayPnlPct: '1.22',
        totalPnl: '5000.00',
        totalPnlPct: '5.26',
        buyingPower: '75000.00',
        unsettledCash: '45000.00',
      );
      final summary = model.toDomain();
      expect(summary.totalEquity, Decimal.parse('100000.00'));
      expect(summary.cashBalance, Decimal.parse('50000.00'));
      expect(summary.dayPnl, Decimal.parse('1200.50'));
      expect(summary.buyingPower, Decimal.parse('75000.00'));
      expect(summary.unsettledCash, Decimal.parse('45000.00'));
    });
  });
}
