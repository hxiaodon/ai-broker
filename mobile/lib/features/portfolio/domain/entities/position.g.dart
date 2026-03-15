// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PositionImpl _$$PositionImplFromJson(Map<String, dynamic> json) =>
    _$PositionImpl(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as String,
      avgCostPrice: json['avgCostPrice'] as String,
      marketValue: json['marketValue'] as String,
      unrealizedPnl: json['unrealizedPnl'] as String,
      unrealizedPnlPercent: json['unrealizedPnlPercent'] as String,
      totalCost: json['totalCost'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      market: json['market'] as String? ?? 'US',
    );

Map<String, dynamic> _$$PositionImplToJson(_$PositionImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'quantity': instance.quantity,
      'avgCostPrice': instance.avgCostPrice,
      'marketValue': instance.marketValue,
      'unrealizedPnl': instance.unrealizedPnl,
      'unrealizedPnlPercent': instance.unrealizedPnlPercent,
      'totalCost': instance.totalCost,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'market': instance.market,
    };
