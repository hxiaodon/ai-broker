import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/../../../shared/theme/trading_color_scheme.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

/// User preferences persisted via SharedPreferences.
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default(TradingColorScheme.greenUp) TradingColorScheme colorScheme,
    @Default('zh') String language,             // 'zh' or 'en'
    @Default(true) bool biometricEnabled,
    @Default(true) bool orderFillNotifications,
    @Default(true) bool fundTransferNotifications,
    @Default(true) bool priceAlertNotifications,
    @Default('USD') String defaultCurrency,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}
