import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_summary_model.freezed.dart';
part 'portfolio_summary_model.g.dart';

@freezed
abstract class PortfolioSummaryModel with _$PortfolioSummaryModel {
  const factory PortfolioSummaryModel({
    @JsonKey(name: 'total_equity') required String totalEquity,
    @JsonKey(name: 'cash_balance') required String cashBalance,
    @JsonKey(name: 'total_market_value') required String marketValue,
    @JsonKey(name: 'day_pnl') required String dayPnl,
    @JsonKey(name: 'day_pnl_pct') required String dayPnlPct,
    @JsonKey(name: 'cumulative_pnl') required String totalPnl,
    @JsonKey(name: 'cumulative_pnl_pct') required String totalPnlPct,
    @JsonKey(name: 'buying_power') required String buyingPower,
    @JsonKey(name: 'unsettled_cash') required String unsettledCash,
  }) = _PortfolioSummaryModel;

  factory PortfolioSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$PortfolioSummaryModelFromJson(json);
}
