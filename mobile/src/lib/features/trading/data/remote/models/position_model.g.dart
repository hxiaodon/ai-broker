// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingSettlementModel _$PendingSettlementModelFromJson(
  Map<String, dynamic> json,
) => _PendingSettlementModel(
  qty: (json['qty'] as num).toInt(),
  settleDate: json['settle_date'] as String,
);

Map<String, dynamic> _$PendingSettlementModelToJson(
  _PendingSettlementModel instance,
) => <String, dynamic>{'qty': instance.qty, 'settle_date': instance.settleDate};

_PositionModel _$PositionModelFromJson(Map<String, dynamic> json) =>
    _PositionModel(
      symbol: json['symbol'] as String,
      market: json['market'] as String,
      qty: (json['qty'] as num).toInt(),
      availableQty: (json['available_qty'] as num).toInt(),
      avgCost: json['avg_cost'] as String,
      currentPrice: json['current_price'] as String,
      marketValue: json['market_value'] as String,
      unrealizedPnl: json['unrealized_pnl'] as String,
      unrealizedPnlPct: json['unrealized_pnl_pct'] as String,
      todayPnl: json['today_pnl'] as String,
      todayPnlPct: json['today_pnl_pct'] as String,
      pendingSettlements:
          (json['pending_settlements'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PendingSettlementModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PositionModelToJson(_PositionModel instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'market': instance.market,
      'qty': instance.qty,
      'available_qty': instance.availableQty,
      'avg_cost': instance.avgCost,
      'current_price': instance.currentPrice,
      'market_value': instance.marketValue,
      'unrealized_pnl': instance.unrealizedPnl,
      'unrealized_pnl_pct': instance.unrealizedPnlPct,
      'today_pnl': instance.todayPnl,
      'today_pnl_pct': instance.todayPnlPct,
      'pending_settlements': instance.pendingSettlements,
    };
