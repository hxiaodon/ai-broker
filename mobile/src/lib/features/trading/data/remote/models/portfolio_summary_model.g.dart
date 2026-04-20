// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PortfolioSummaryModel _$PortfolioSummaryModelFromJson(
  Map<String, dynamic> json,
) => _PortfolioSummaryModel(
  totalEquity: json['total_equity'] as String,
  cashBalance: json['cash_balance'] as String,
  marketValue: json['market_value'] as String,
  dayPnl: json['day_pnl'] as String,
  dayPnlPct: json['day_pnl_pct'] as String,
  totalPnl: json['total_pnl'] as String,
  totalPnlPct: json['total_pnl_pct'] as String,
  buyingPower: json['buying_power'] as String,
  settledCash: json['settled_cash'] as String,
);

Map<String, dynamic> _$PortfolioSummaryModelToJson(
  _PortfolioSummaryModel instance,
) => <String, dynamic>{
  'total_equity': instance.totalEquity,
  'cash_balance': instance.cashBalance,
  'market_value': instance.marketValue,
  'day_pnl': instance.dayPnl,
  'day_pnl_pct': instance.dayPnlPct,
  'total_pnl': instance.totalPnl,
  'total_pnl_pct': instance.totalPnlPct,
  'buying_power': instance.buyingPower,
  'settled_cash': instance.settledCash,
};
