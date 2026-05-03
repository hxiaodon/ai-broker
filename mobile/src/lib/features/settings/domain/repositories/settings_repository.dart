import '../entities/account_status.dart';
import '../entities/device_info.dart';
import '../entities/notification_preferences.dart';
import '../entities/user_profile.dart';

abstract interface class SettingsRepository {
  Future<UserProfile> getProfile();

  Future<AccountStatus> getAccountStatus();

  Future<NotificationPreferences> getNotificationPreferences();

  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  );

  Future<List<DeviceInfo>> getDevices();

  Future<void> revokeDevice({
    required String deviceId,
    required String bioToken,
    required String bioChallenge,
    required String bioTimestamp,
  });

  /// Sends OTP to the user's **current** (old) phone — server derives phone from JWT.
  Future<void> sendOtpToCurrentPhone();

  Future<void> sendChangePhoneOtp({required String phone});

  Future<void> verifyOldPhoneOtp({required String otpCode});

  Future<void> verifyNewPhoneAndUpdate({
    required String newPhone,
    required String otpCode,
  });

  Future<void> lockAccount();

  Future<void> checkDeactivationEligibility();

  Future<void> deactivateAccount({
    required String otpCode,
    required String idempotencyKey,
  });
}
