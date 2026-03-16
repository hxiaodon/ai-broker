// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$QuoteImpl _$$QuoteImplFromJson(Map<String, dynamic> json) => _$QuoteImpl(
  symbol: json['symbol'] as String,
  lastPrice: json['lastPrice'] as String,
  change: json['change'] as String,
  changePercent: json['changePercent'] as String,
  open: json['open'] as String,
  high: json['high'] as String,
  low: json['low'] as String,
  prevClose: json['prevClose'] as String,
  volume: (json['volume'] as num).toInt(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  market: json['market'] as String? ?? 'US',
);

Map<String, dynamic> _$$QuoteImplToJson(_$QuoteImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'lastPrice': instance.lastPrice,
      'change': instance.change,
      'changePercent': instance.changePercent,
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'prevClose': instance.prevClose,
      'volume': instance.volume,
      'timestamp': instance.timestamp.toIso8601String(),
      'market': instance.market,
    };
