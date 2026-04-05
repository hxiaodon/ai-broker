import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'candle.freezed.dart';

/// Single OHLCV candlestick for K-line chart rendering.
///
/// All price fields use [Decimal] — never float (financial-coding-standards §Rule 1).
/// Field names match the API candles[i] response (market-api-spec §4.3).
@freezed
abstract class Candle with _$Candle {
  const factory Candle({
    /// Candle open time (UTC). Represents the start of the period.
    required DateTime t,

    /// Opening price.
    required Decimal o,

    /// Highest price in the period.
    required Decimal h,

    /// Lowest price in the period.
    required Decimal l,

    /// Closing price.
    required Decimal c,

    /// Trade volume (shares).
    required int v,

    /// Number of trades in the period.
    required int n,
  }) = _Candle;
}
