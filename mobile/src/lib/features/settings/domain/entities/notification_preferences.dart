import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

/// Notification categories as defined in PRD §7.2 and AMS contract §4.
///
/// SecurityAlerts is MANDATORY — cannot be disabled (compliance requirement).
enum NotificationCategory {
  trading,
  funding,
  kyc,
  systemAnnouncements,
  /// Cannot be disabled — new device login, suspicious activity alerts
  securityAlerts,
}

/// Delivery channel for notifications.
enum NotificationChannel { push, sms, email }

/// User's notification preferences from GET /v1/notifications/preferences.
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required bool tradingEnabled,
    required bool fundingEnabled,
    required bool kycEnabled,
    required bool systemAnnouncementsEnabled,
    /// Always true — cannot be changed by user
    @Default(true) bool securityAlertsEnabled,
    required bool pushEnabled,
    required bool smsEnabled,
    required bool emailEnabled,
    /// "HH:mm" format, null = no quiet hours
    String? quietHoursStart,
    String? quietHoursEnd,
  }) = _NotificationPreferences;

  const NotificationPreferences._();

  bool isEnabled(NotificationCategory category) => switch (category) {
        NotificationCategory.trading => tradingEnabled,
        NotificationCategory.funding => fundingEnabled,
        NotificationCategory.kyc => kycEnabled,
        NotificationCategory.systemAnnouncements => systemAnnouncementsEnabled,
        NotificationCategory.securityAlerts => true, // always on
      };

  bool isMutable(NotificationCategory category) =>
      category != NotificationCategory.securityAlerts;
}
