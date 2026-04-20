import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';

enum OrderSide { buy, sell }

enum OrderType { market, limit }

enum OrderValidity { day, gtc }

enum OrderStatus {
  riskChecking,
  pending,
  partiallyFilled,
  filled,
  cancelled,
  partiallyFilledCancelled,
  expired,
  rejected,
  exchangeRejected,
}

@freezed
abstract class OrderFees with _$OrderFees {
  const factory OrderFees({
    required Decimal commission,
    required Decimal exchangeFee,
    required Decimal secFee,
    required Decimal finraFee,
    required Decimal total,
  }) = _OrderFees;
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String orderId,
    required String symbol,
    required String market,
    required OrderSide side,
    required OrderType orderType,
    required OrderStatus status,
    required int qty,
    required int filledQty,
    Decimal? limitPrice,
    Decimal? avgFillPrice,
    required OrderValidity validity,
    required bool extendedHours,
    required OrderFees fees,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Order;

  const Order._();

  int get remainingQty => qty - filledQty;

  bool get isCancellable =>
      status == OrderStatus.pending || status == OrderStatus.partiallyFilled;
}
