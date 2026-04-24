// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TradeRecordModel _$TradeRecordModelFromJson(Map<String, dynamic> json) =>
    _TradeRecordModel(
      tradeId: json['trade_id'] as String,
      side: json['side'] as String,
      qty: (json['quantity'] as num).toInt(),
      price: json['price'] as String,
      amount: json['amount'] as String,
      fee: json['fee'] as String,
      executedAt: json['executed_at'] as String,
      washSale: json['wash_sale'] as bool? ?? false,
    );

Map<String, dynamic> _$TradeRecordModelToJson(_TradeRecordModel instance) =>
    <String, dynamic>{
      'trade_id': instance.tradeId,
      'side': instance.side,
      'quantity': instance.qty,
      'price': instance.price,
      'amount': instance.amount,
      'fee': instance.fee,
      'executed_at': instance.executedAt,
      'wash_sale': instance.washSale,
    };
