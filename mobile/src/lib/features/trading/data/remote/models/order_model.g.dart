// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderFeesModel _$OrderFeesModelFromJson(Map<String, dynamic> json) =>
    _OrderFeesModel(
      commission: json['commission'] as String,
      exchangeFee: json['exchange_fee'] as String,
      secFee: json['sec_fee'] as String,
      finraFee: json['finra_fee'] as String,
      total: json['total'] as String,
    );

Map<String, dynamic> _$OrderFeesModelToJson(_OrderFeesModel instance) =>
    <String, dynamic>{
      'commission': instance.commission,
      'exchange_fee': instance.exchangeFee,
      'sec_fee': instance.secFee,
      'finra_fee': instance.finraFee,
      'total': instance.total,
    };

_OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => _OrderModel(
  orderId: json['order_id'] as String,
  symbol: json['symbol'] as String,
  market: json['market'] as String,
  side: json['side'] as String,
  orderType: json['order_type'] as String,
  status: json['status'] as String,
  qty: (json['qty'] as num).toInt(),
  filledQty: (json['filled_qty'] as num).toInt(),
  limitPrice: json['limit_price'] as String?,
  avgFillPrice: json['avg_fill_price'] as String?,
  validity: json['validity'] as String,
  extendedHours: json['extended_hours'] as bool,
  fees: OrderFeesModel.fromJson(json['fees'] as Map<String, dynamic>),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$OrderModelToJson(_OrderModel instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'symbol': instance.symbol,
      'market': instance.market,
      'side': instance.side,
      'order_type': instance.orderType,
      'status': instance.status,
      'qty': instance.qty,
      'filled_qty': instance.filledQty,
      'limit_price': instance.limitPrice,
      'avg_fill_price': instance.avgFillPrice,
      'validity': instance.validity,
      'extended_hours': instance.extendedHours,
      'fees': instance.fees,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

_OrderFillModel _$OrderFillModelFromJson(Map<String, dynamic> json) =>
    _OrderFillModel(
      fillId: json['fill_id'] as String,
      orderId: json['order_id'] as String,
      qty: (json['qty'] as num).toInt(),
      price: json['price'] as String,
      exchange: json['exchange'] as String,
      filledAt: json['filled_at'] as String,
    );

Map<String, dynamic> _$OrderFillModelToJson(_OrderFillModel instance) =>
    <String, dynamic>{
      'fill_id': instance.fillId,
      'order_id': instance.orderId,
      'qty': instance.qty,
      'price': instance.price,
      'exchange': instance.exchange,
      'filled_at': instance.filledAt,
    };

_OrderDetailModel _$OrderDetailModelFromJson(Map<String, dynamic> json) =>
    _OrderDetailModel(
      order: OrderModel.fromJson(json['order'] as Map<String, dynamic>),
      fills: (json['fills'] as List<dynamic>)
          .map((e) => OrderFillModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderDetailModelToJson(_OrderDetailModel instance) =>
    <String, dynamic>{'order': instance.order, 'fills': instance.fills};
