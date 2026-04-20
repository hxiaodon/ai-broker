import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_fill.freezed.dart';

@freezed
abstract class OrderFill with _$OrderFill {
  const factory OrderFill({
    required String fillId,
    required String orderId,
    required int qty,
    required Decimal price,
    required String exchange,
    required DateTime filledAt,
  }) = _OrderFill;
}
