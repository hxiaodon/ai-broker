import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_record_model.freezed.dart';
part 'trade_record_model.g.dart';

@freezed
abstract class TradeRecordModel with _$TradeRecordModel {
  const factory TradeRecordModel({
    @JsonKey(name: 'trade_id') required String tradeId,
    @JsonKey(name: 'side') required String side,
    @JsonKey(name: 'quantity') required int qty,
    @JsonKey(name: 'price') required String price,
    @JsonKey(name: 'amount') required String amount,
    @JsonKey(name: 'fee') required String fee,
    @JsonKey(name: 'executed_at') required String executedAt,
    @JsonKey(name: 'wash_sale') @Default(false) bool washSale,
  }) = _TradeRecordModel;

  factory TradeRecordModel.fromJson(Map<String, dynamic> json) =>
      _$TradeRecordModelFromJson(json);
}
