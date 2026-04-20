import 'package:decimal/decimal.dart';

import '../entities/order.dart';
import '../entities/order_fill.dart';
import '../entities/portfolio_summary.dart';
import '../entities/position.dart';

abstract class TradingRepository {
  Future<Order> submitOrder({
    required String symbol,
    required String market,
    required OrderSide side,
    required OrderType orderType,
    required int qty,
    Decimal? limitPrice,
    required OrderValidity validity,
    required bool extendedHours,
    required String idempotencyKey,
    required String biometricToken,
  });

  Future<void> cancelOrder(String orderId);

  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? market,
  });

  Future<(Order, List<OrderFill>)> getOrderDetail(String orderId);

  Future<List<Position>> getPositions();

  Future<Position> getPositionDetail(String symbol);

  Future<PortfolioSummary> getPortfolioSummary();
}
