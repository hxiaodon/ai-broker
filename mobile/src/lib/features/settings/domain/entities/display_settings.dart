import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../shared/theme/trading_color_scheme.dart';

part 'display_settings.freezed.dart';

/// App display preferences — stored locally in SharedPreferences.
@freezed
abstract class DisplaySettings with _$DisplaySettings {
  const factory DisplaySettings({
    /// Colour scheme for price gains/losses; default greenUp for CN+86 users
    @Default(TradingColorScheme.greenUp) TradingColorScheme colorScheme,
  }) = _DisplaySettings;
}
