import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderSide { buy, sell }
enum OrderType { market, limit, stopLimit }
enum OrderStatus { pending, partialFill, filled, cancelled, rejected }
enum OrderMarket { us, hk }

/// Trading order entity.
///
/// All price and quantity fields use [String] for JSON transmission.
/// Convert to [Decimal] for display and calculations.
@freezed
class Order with _$Order {
  const factory Order({
    required String orderId,
    required String symbol,
    required OrderSide side,
    required OrderType type,
    required OrderStatus status,
    required String quantity,         // e.g. "100" (whole shares)
    String? limitPrice,               // Required for limit/stopLimit orders
    String? stopPrice,                // Required for stopLimit orders
    String? filledQuantity,
    String? avgFillPrice,
    required DateTime createdAt,      // UTC
    DateTime? filledAt,               // UTC
    @Default(OrderMarket.us) OrderMarket market,
    String? idempotencyKey,           // UUID v4, required for submission
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) =>
      _$OrderFromJson(json);
}
