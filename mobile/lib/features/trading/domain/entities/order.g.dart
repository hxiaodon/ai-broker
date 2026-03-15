// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
  orderId: json['orderId'] as String,
  symbol: json['symbol'] as String,
  side: $enumDecode(_$OrderSideEnumMap, json['side']),
  type: $enumDecode(_$OrderTypeEnumMap, json['type']),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  quantity: json['quantity'] as String,
  limitPrice: json['limitPrice'] as String?,
  stopPrice: json['stopPrice'] as String?,
  filledQuantity: json['filledQuantity'] as String?,
  avgFillPrice: json['avgFillPrice'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  filledAt:
      json['filledAt'] == null
          ? null
          : DateTime.parse(json['filledAt'] as String),
  market:
      $enumDecodeNullable(_$OrderMarketEnumMap, json['market']) ??
      OrderMarket.us,
  idempotencyKey: json['idempotencyKey'] as String?,
);

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'symbol': instance.symbol,
      'side': _$OrderSideEnumMap[instance.side]!,
      'type': _$OrderTypeEnumMap[instance.type]!,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'quantity': instance.quantity,
      'limitPrice': instance.limitPrice,
      'stopPrice': instance.stopPrice,
      'filledQuantity': instance.filledQuantity,
      'avgFillPrice': instance.avgFillPrice,
      'createdAt': instance.createdAt.toIso8601String(),
      'filledAt': instance.filledAt?.toIso8601String(),
      'market': _$OrderMarketEnumMap[instance.market]!,
      'idempotencyKey': instance.idempotencyKey,
    };

const _$OrderSideEnumMap = {OrderSide.buy: 'buy', OrderSide.sell: 'sell'};

const _$OrderTypeEnumMap = {
  OrderType.market: 'market',
  OrderType.limit: 'limit',
  OrderType.stopLimit: 'stopLimit',
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.partialFill: 'partialFill',
  OrderStatus.filled: 'filled',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.rejected: 'rejected',
};

const _$OrderMarketEnumMap = {OrderMarket.us: 'us', OrderMarket.hk: 'hk'};
