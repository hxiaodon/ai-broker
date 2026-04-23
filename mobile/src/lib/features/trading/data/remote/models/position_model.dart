import 'package:freezed_annotation/freezed_annotation.dart';

part 'position_model.freezed.dart';
part 'position_model.g.dart';

@freezed
abstract class PendingSettlementModel with _$PendingSettlementModel {
  const factory PendingSettlementModel({
    @JsonKey(name: 'qty') required int qty,
    @JsonKey(name: 'settle_date') required String settleDate,
  }) = _PendingSettlementModel;

  factory PendingSettlementModel.fromJson(Map<String, dynamic> json) =>
      _$PendingSettlementModelFromJson(json);
}

@freezed
abstract class PositionModel with _$PositionModel {
  const factory PositionModel({
    @JsonKey(name: 'symbol') required String symbol,
    @JsonKey(name: 'market') required String market,
    @JsonKey(name: 'quantity') required int qty,
    @JsonKey(name: 'settled_qty') required int availableQty,
    @JsonKey(name: 'avg_cost') required String avgCost,
    @JsonKey(name: 'current_price') required String currentPrice,
    @JsonKey(name: 'market_value') required String marketValue,
    @JsonKey(name: 'unrealized_pnl') required String unrealizedPnl,
    @JsonKey(name: 'unrealized_pnl_pct') required String unrealizedPnlPct,
    @JsonKey(name: 'today_pnl') required String todayPnl,
    @JsonKey(name: 'today_pnl_pct') required String todayPnlPct,
    @JsonKey(name: 'pending_settlements')
    @Default([])
    List<PendingSettlementModel> pendingSettlements,
  }) = _PositionModel;

  factory PositionModel.fromJson(Map<String, dynamic> json) =>
      _$PositionModelFromJson(json);
}
