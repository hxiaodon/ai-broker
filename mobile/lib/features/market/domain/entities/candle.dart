import 'package:freezed_annotation/freezed_annotation.dart';

part 'candle.freezed.dart';
part 'candle.g.dart';

/// OHLCV candlestick data point for K-line charts.
///
/// All price fields are [String] to avoid floating-point precision loss.
@freezed
class Candle with _$Candle {
  const factory Candle({
    required DateTime timestamp,  // UTC, bar open time
    required String open,
    required String high,
    required String low,
    required String close,
    required int volume,
    @Default('1D') String interval, // '1m', '5m', '15m', '1h', '1D', '1W'
  }) = _Candle;

  factory Candle.fromJson(Map<String, dynamic> json) =>
      _$CandleFromJson(json);
}
