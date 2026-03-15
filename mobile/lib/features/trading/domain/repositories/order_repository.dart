import '../entities/order.dart';

/// Repository interface for trading operations.
abstract class OrderRepository {
  /// Submit a new order. [idempotencyKey] must be UUID v4 and unique per order.
  Future<Order> placeOrder({
    required String symbol,
    required OrderSide side,
    required OrderType type,
    required String quantity,
    String? limitPrice,
    String? stopPrice,
    required String idempotencyKey,
  });

  /// Cancel an open order.
  Future<void> cancelOrder(String orderId);

  /// Get order detail by ID.
  Future<Order> getOrder(String orderId);

  /// Get order history with optional pagination.
  Future<List<Order>> getOrderHistory({int page = 1, int pageSize = 20});

  /// Real-time order status stream (for order fill notifications).
  Stream<Order> subscribeToOrderUpdates();
}
