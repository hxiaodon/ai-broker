import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../trading/data/remote/models/position_model.dart';
import 'trade_record_model.dart';

part 'position_detail_model.freezed.dart';
part 'position_detail_model.g.dart';

@freezed
abstract class PositionDetailModel with _$PositionDetailModel {
  const factory PositionDetailModel({
    @JsonKey(name: 'symbol') required String symbol,
    @JsonKey(name: 'company_name') required String companyName,
    @JsonKey(name: 'market') required String market,
    @JsonKey(name: 'sector') @Default('Other') String sector,
    @JsonKey(name: 'quantity') required int qty,
    @JsonKey(name: 'settled_qty') required int availableQty,
    @JsonKey(name: 'avg_cost') required String avgCost,
    @JsonKey(name: 'current_price') required String currentPrice,
    @JsonKey(name: 'market_value') required String marketValue,
    @JsonKey(name: 'unrealized_pnl') required String unrealizedPnl,
    @JsonKey(name: 'unrealized_pnl_pct') required String unrealizedPnlPct,
    @JsonKey(name: 'today_pnl') required String todayPnl,
    @JsonKey(name: 'today_pnl_pct') required String todayPnlPct,
    @JsonKey(name: 'realized_pnl') @Default('0') String realizedPnl,
    @JsonKey(name: 'cost_basis') required String costBasis,
    @JsonKey(name: 'wash_sale_status') @Default('clean') String washSaleStatus,
    @JsonKey(name: 'pending_settlements')
    @Default([])
    List<PendingSettlementModel> pendingSettlements,
    @JsonKey(name: 'recent_trades')
    @Default([])
    List<TradeRecordModel> recentTrades,
  }) = _PositionDetailModel;

  factory PositionDetailModel.fromJson(Map<String, dynamic> json) =>
      _$PositionDetailModelFromJson(json);
}
