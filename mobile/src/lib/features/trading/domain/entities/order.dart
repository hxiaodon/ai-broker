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

  const OrderFees._();

  /// Verifies the API-returned total equals the sum of fee components.
  /// A mismatch indicates a mapper or backend serialization bug.
  bool get isTotalConsistent =>
      total == commission + exchangeFee + secFee + finraFee;
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

  /// GTC orders expire 90 calendar days after creation (PRD-04 §6.4).
  /// Returns null for DAY orders.
  DateTime? get gtcExpiresAt => validity == OrderValidity.gtc
      ? createdAt.add(const Duration(days: 90))
      : null;

  /// Days remaining until GTC expiry. Null for DAY orders or already-expired orders.
  int? get daysUntilGtcExpiry {
    final exp = gtcExpiresAt;
    if (exp == null) return null;
    final days = exp.difference(DateTime.now().toUtc()).inDays;
    return days >= 0 ? days : null;
  }

  /// True when a GTC order expires within 3 days (triggers pre-expiry notification).
  bool get isGtcExpiringIn3Days {
    final days = daysUntilGtcExpiry;
    return days != null && days <= 3;
  }

  /// True when a GTC order expires today or tomorrow (urgent notification).
  bool get isGtcExpiringIn1Day {
    final days = daysUntilGtcExpiry;
    return days != null && days <= 1;
  }
}
