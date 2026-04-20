import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
abstract class OrderFeesModel with _$OrderFeesModel {
  const factory OrderFeesModel({
    @JsonKey(name: 'commission') required String commission,
    @JsonKey(name: 'exchange_fee') required String exchangeFee,
    @JsonKey(name: 'sec_fee') required String secFee,
    @JsonKey(name: 'finra_fee') required String finraFee,
    @JsonKey(name: 'total') required String total,
  }) = _OrderFeesModel;

  factory OrderFeesModel.fromJson(Map<String, dynamic> json) =>
      _$OrderFeesModelFromJson(json);
}

@freezed
abstract class OrderModel with _$OrderModel {
  const factory OrderModel({
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'symbol') required String symbol,
    @JsonKey(name: 'market') required String market,
    @JsonKey(name: 'side') required String side,
    @JsonKey(name: 'order_type') required String orderType,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'qty') required int qty,
    @JsonKey(name: 'filled_qty') required int filledQty,
    @JsonKey(name: 'limit_price') String? limitPrice,
    @JsonKey(name: 'avg_fill_price') String? avgFillPrice,
    @JsonKey(name: 'validity') required String validity,
    @JsonKey(name: 'extended_hours') required bool extendedHours,
    @JsonKey(name: 'fees') required OrderFeesModel fees,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
}

@freezed
abstract class OrderFillModel with _$OrderFillModel {
  const factory OrderFillModel({
    @JsonKey(name: 'fill_id') required String fillId,
    @JsonKey(name: 'order_id') required String orderId,
    @JsonKey(name: 'qty') required int qty,
    @JsonKey(name: 'price') required String price,
    @JsonKey(name: 'exchange') required String exchange,
    @JsonKey(name: 'filled_at') required String filledAt,
  }) = _OrderFillModel;

  factory OrderFillModel.fromJson(Map<String, dynamic> json) =>
      _$OrderFillModelFromJson(json);
}

@freezed
abstract class OrderDetailModel with _$OrderDetailModel {
  const factory OrderDetailModel({
    @JsonKey(name: 'order') required OrderModel order,
    @JsonKey(name: 'fills') required List<OrderFillModel> fills,
  }) = _OrderDetailModel;

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailModelFromJson(json);
}
