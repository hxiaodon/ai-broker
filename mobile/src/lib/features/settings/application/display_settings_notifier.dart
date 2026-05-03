import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/theme/trading_color_scheme.dart';
import '../domain/entities/display_settings.dart';

part 'display_settings_notifier.g.dart';

const _kColorSchemeKey = 'settings.colorScheme';

/// Manages display preferences (colour scheme) stored in SharedPreferences.
///
/// keepAlive: display settings affect the whole app and must survive navigation.
@Riverpod(keepAlive: true)
class DisplaySettingsNotifier extends _$DisplaySettingsNotifier {
  @override
  Future<DisplaySettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kColorSchemeKey);
    final scheme = raw != null
        ? TradingColorScheme.fromString(raw)
        : TradingColorScheme.greenUp;
    return DisplaySettings(colorScheme: scheme);
  }

  Future<void> setColorScheme(TradingColorScheme scheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kColorSchemeKey, scheme.name);
    state = AsyncData(DisplaySettings(colorScheme: scheme));
  }
}
