import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../domain/entities/trade_settings.dart';

part 'trade_settings_notifier.g.dart';

const _kOrderTypeKey = 'settings.trade.orderType';
const _kValidityKey = 'settings.trade.validity';
// confirmationMethod stored in SecureStorage (security-sensitive field)
const _kConfirmMethodSecureKey = 'settings.trade.confirmMethod';
const _kLargeOrderKey = 'settings.trade.largeOrderThreshold';
const _kPriceDevKey = 'settings.trade.priceDeviation';
const _kExtHoursKey = 'settings.trade.extendedHours';
const _kExtHoursRiskKey = 'settings.trade.extendedHoursRisk';

/// Manages trading preferences.
/// Non-sensitive fields stored in SharedPreferences; [confirmationMethod]
/// stored in flutter_secure_storage to prevent tampering on rooted devices.
@Riverpod(keepAlive: true)
class TradeSettingsNotifier extends _$TradeSettingsNotifier {
  @override
  Future<TradeSettings> build() async {
    final p = await SharedPreferences.getInstance();
    final ss = ref.read(secureStorageServiceProvider);
    // Read confirmationMethod from SecureStorage; fall back to SharedPreferences
    // for users migrating from a previous install that stored it there.
    final confirmMethodStr =
        await ss.read(_kConfirmMethodSecureKey) ?? p.getString(_kConfirmMethodSecureKey);
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
        (e) => e.name == confirmMethodStr,
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
    final ss = ref.read(secureStorageServiceProvider);
    // confirmationMethod goes to SecureStorage
    await ss.write(_kConfirmMethodSecureKey, updated.confirmationMethod.name);
    await Future.wait([
      p.setString(_kOrderTypeKey, updated.defaultOrderType.name),
      p.setString(_kValidityKey, updated.defaultValidity.name),
      p.setString(_kLargeOrderKey, updated.largeOrderThreshold.name),
      p.setString(_kPriceDevKey, updated.priceDeviationWarning.name),
      p.setBool(_kExtHoursKey, updated.extendedHoursEnabled),
      p.setBool(_kExtHoursRiskKey, updated.extendedHoursRiskAccepted),
    ]);
    state = AsyncData(updated);
  }
}
