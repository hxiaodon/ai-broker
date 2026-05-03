import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/device_info_service.dart' as svc;
import '../../../core/auth/token_service.dart';
import '../../../core/config/environment_config.dart';
import '../../../core/network/authenticated_dio.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/security/hmac_signer.dart';
import '../../../core/security/nonce_service.dart';
import '../../../core/security/session_key_service.dart';
import '../domain/entities/account_status.dart';
import '../domain/entities/device_info.dart';
import '../domain/entities/notification_preferences.dart';
import '../domain/entities/user_profile.dart';
import '../domain/repositories/settings_repository.dart';
import 'remote/settings_remote_data_source.dart';

part 'settings_repository_impl.g.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required SettingsRemoteDataSource remote})
      : _remote = remote;

  final SettingsRemoteDataSource _remote;

  @override
  Future<UserProfile> getProfile() => _remote.getProfile();

  @override
  Future<AccountStatus> getAccountStatus() => _remote.getAccountStatus();

  @override
  Future<NotificationPreferences> getNotificationPreferences() =>
      _remote.getNotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) =>
      _remote.updateNotificationPreferences(prefs);

  @override
  Future<List<DeviceInfo>> getDevices() => _remote.getDevices();

  @override
  Future<void> revokeDevice({
    required String deviceId,
    required String bioToken,
    required String bioChallenge,
    required String bioTimestamp,
  }) =>
      _remote.revokeDevice(
        deviceId: deviceId,
        bioToken: bioToken,
        bioChallenge: bioChallenge,
        bioTimestamp: bioTimestamp,
      );

  @override
  Future<void> sendOtpToCurrentPhone() => _remote.sendOtpToCurrentPhone();

  @override
  Future<void> sendChangePhoneOtp({required String phone}) =>
      _remote.sendChangePhoneOtp(phone: phone);

  @override
  Future<void> verifyOldPhoneOtp({required String otpCode}) =>
      _remote.verifyOldPhoneOtp(otpCode: otpCode);

  @override
  Future<void> verifyNewPhoneAndUpdate({
    required String newPhone,
    required String otpCode,
  }) =>
      _remote.verifyNewPhoneAndUpdate(newPhone: newPhone, otpCode: otpCode);

  @override
  Future<void> lockAccount() => _remote.lockAccount();

  @override
  Future<void> checkDeactivationEligibility() =>
      _remote.checkDeactivationEligibility();

  @override
  Future<void> deactivateAccount({
    required String otpCode,
    required String idempotencyKey,
  }) =>
      _remote.deactivateAccount(otpCode: otpCode, idempotencyKey: idempotencyKey);
}

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final baseUrl = EnvironmentConfig.instance.amsBaseUrl;
  final dio = createAuthenticatedDio(baseUrl: baseUrl, tokenService: tokenSvc);
  return SettingsRepositoryImpl(
    remote: SettingsRemoteDataSource(
      dio: dio,
      connectivity: ref.watch(connectivityServiceProvider),
      signer: const HmacSigner(),
      sessionKeyService: ref.read(sessionKeyServiceProvider),
      nonceService: ref.read(nonceServiceProvider),
      deviceInfoService: ref.read(svc.deviceInfoServiceProvider),
    ),
  );
}
