// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CandleImpl _$$CandleImplFromJson(Map<String, dynamic> json) => _$CandleImpl(
  timestamp: DateTime.parse(json['timestamp'] as String),
  open: json['open'] as String,
  high: json['high'] as String,
  low: json['low'] as String,
  close: json['close'] as String,
  volume: (json['volume'] as num).toInt(),
  interval: json['interval'] as String? ?? '1D',
);

Map<String, dynamic> _$$CandleImplToJson(_$CandleImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'close': instance.close,
      'volume': instance.volume,
      'interval': instance.interval,
    };
