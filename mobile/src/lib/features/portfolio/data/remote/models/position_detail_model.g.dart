// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PositionDetailModel _$PositionDetailModelFromJson(Map<String, dynamic> json) =>
    _PositionDetailModel(
      symbol: json['symbol'] as String,
      companyName: json['company_name'] as String,
      market: json['market'] as String,
      sector: json['sector'] as String? ?? 'Other',
      qty: (json['quantity'] as num).toInt(),
      availableQty: (json['settled_qty'] as num).toInt(),
      avgCost: json['avg_cost'] as String,
      currentPrice: json['current_price'] as String,
      marketValue: json['market_value'] as String,
      unrealizedPnl: json['unrealized_pnl'] as String,
      unrealizedPnlPct: json['unrealized_pnl_pct'] as String,
      todayPnl: json['today_pnl'] as String,
      todayPnlPct: json['today_pnl_pct'] as String,
      realizedPnl: json['realized_pnl'] as String? ?? '0',
      costBasis: json['cost_basis'] as String,
      washSaleStatus: json['wash_sale_status'] as String? ?? 'clean',
      pendingSettlements:
          (json['pending_settlements'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PendingSettlementModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      recentTrades:
          (json['recent_trades'] as List<dynamic>?)
              ?.map((e) => TradeRecordModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PositionDetailModelToJson(
  _PositionDetailModel instance,
) => <String, dynamic>{
  'symbol': instance.symbol,
  'company_name': instance.companyName,
  'market': instance.market,
  'sector': instance.sector,
  'quantity': instance.qty,
  'settled_qty': instance.availableQty,
  'avg_cost': instance.avgCost,
  'current_price': instance.currentPrice,
  'market_value': instance.marketValue,
  'unrealized_pnl': instance.unrealizedPnl,
  'unrealized_pnl_pct': instance.unrealizedPnlPct,
  'today_pnl': instance.todayPnl,
  'today_pnl_pct': instance.todayPnlPct,
  'realized_pnl': instance.realizedPnl,
  'cost_basis': instance.costBasis,
  'wash_sale_status': instance.washSaleStatus,
  'pending_settlements': instance.pendingSettlements,
  'recent_trades': instance.recentTrades,
};
