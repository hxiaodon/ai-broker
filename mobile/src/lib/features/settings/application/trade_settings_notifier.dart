import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/trade_settings.dart';

part 'trade_settings_notifier.g.dart';

const _kOrderTypeKey = 'settings.trade.orderType';
const _kValidityKey = 'settings.trade.validity';
const _kConfirmMethodKey = 'settings.trade.confirmMethod';
const _kLargeOrderKey = 'settings.trade.largeOrderThreshold';
const _kPriceDevKey = 'settings.trade.priceDeviation';
const _kExtHoursKey = 'settings.trade.extendedHours';
const _kExtHoursRiskKey = 'settings.trade.extendedHoursRisk';

/// Manages trading preferences stored locally in SharedPreferences.
@Riverpod(keepAlive: true)
class TradeSettingsNotifier extends _$TradeSettingsNotifier {
  @override
  Future<TradeSettings> build() async {
    final p = await SharedPreferences.getInstance();
    return TradeSettings(
      defaultOrderType: DefaultOrderType.values.firstWhere(
        (e) => e.name == p.getString(_kOrderTypeKey),
        orElse: () => DefaultOrderType.limit,
      ),
      defaultValidity: DefaultOrderValidity.values.firstWhere(
        (e) => e.name == p.getString(_kValidityKey),
        orElse: () => DefaultOrderValidity.day,
      ),
      confirmationMethod: OrderConfirmationMethod.values.firstWhere(
        (e) => e.name == p.getString(_kConfirmMethodKey),
        orElse: () => OrderConfirmationMethod.slideAndBiometric,
      ),
      largeOrderThreshold: LargeOrderThreshold.values.firstWhere(
        (e) => e.name == p.getString(_kLargeOrderKey),
        orElse: () => LargeOrderThreshold.usd10000,
      ),
      priceDeviationWarning: PriceDeviationWarning.values.firstWhere(
        (e) => e.name == p.getString(_kPriceDevKey),
        orElse: () => PriceDeviationWarning.pct5,
      ),
      extendedHoursEnabled: p.getBool(_kExtHoursKey) ?? false,
      extendedHoursRiskAccepted: p.getBool(_kExtHoursRiskKey) ?? false,
    );
  }

  Future<void> saveSettings(TradeSettings updated) async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setString(_kOrderTypeKey, updated.defaultOrderType.name),
      p.setString(_kValidityKey, updated.defaultValidity.name),
      p.setString(_kConfirmMethodKey, updated.confirmationMethod.name),
      p.setString(_kLargeOrderKey, updated.largeOrderThreshold.name),
      p.setString(_kPriceDevKey, updated.priceDeviationWarning.name),
      p.setBool(_kExtHoursKey, updated.extendedHoursEnabled),
      p.setBool(_kExtHoursRiskKey, updated.extendedHoursRiskAccepted),
    ]);
    state = AsyncData(updated);
  }
}
