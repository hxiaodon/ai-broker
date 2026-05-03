import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_settings.freezed.dart';

/// Default order type preference (PRD §8).
enum DefaultOrderType { limit, market }

/// Default time-in-force (PRD §8).
enum DefaultOrderValidity { day, gtc }

/// How the user confirms order submission.
enum OrderConfirmationMethod { slideAndBiometric, slideOnly }

/// Large-order alert threshold in USD.
enum LargeOrderThreshold {
  usd5000,
  usd10000,
  usd20000;

  Decimal get value => switch (this) {
        LargeOrderThreshold.usd5000 => Decimal.fromInt(5000),
        LargeOrderThreshold.usd10000 => Decimal.fromInt(10000),
        LargeOrderThreshold.usd20000 => Decimal.fromInt(20000),
      };
}

/// Price deviation warning threshold (%).
enum PriceDeviationWarning {
  pct3,
  pct5,
  pct10,
  disabled;

  Decimal? get value => switch (this) {
        PriceDeviationWarning.pct3 => Decimal.fromInt(3),
        PriceDeviationWarning.pct5 => Decimal.fromInt(5),
        PriceDeviationWarning.pct10 => Decimal.fromInt(10),
        PriceDeviationWarning.disabled => null,
      };
}

/// User's trading preferences — stored locally in SharedPreferences.
@freezed
abstract class TradeSettings with _$TradeSettings {
  const factory TradeSettings({
    @Default(DefaultOrderType.limit) DefaultOrderType defaultOrderType,
    @Default(DefaultOrderValidity.day) DefaultOrderValidity defaultValidity,
    @Default(OrderConfirmationMethod.slideAndBiometric)
    OrderConfirmationMethod confirmationMethod,
    @Default(LargeOrderThreshold.usd10000)
    LargeOrderThreshold largeOrderThreshold,
    @Default(PriceDeviationWarning.pct5)
    PriceDeviationWarning priceDeviationWarning,
    /// Whether extended-hours (pre/after-market) trading is enabled.
    /// First enable requires explicit risk disclosure confirmation.
    @Default(false) bool extendedHoursEnabled,
    /// Tracks whether user has already accepted extended-hours risk disclosure.
    @Default(false) bool extendedHoursRiskAccepted,
  }) = _TradeSettings;
}
