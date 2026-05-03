import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/settings_repository_impl.dart';
import '../domain/entities/notification_preferences.dart';

part 'notification_preferences_notifier.g.dart';

/// Manages user notification preferences (remote read/write).
@riverpod
class NotificationPreferencesNotifier
    extends _$NotificationPreferencesNotifier {
  @override
  Future<NotificationPreferences> build() =>
      ref.watch(settingsRepositoryProvider).getNotificationPreferences();

  Future<void> toggle({
    required NotificationCategory category,
    required bool enabled,
  }) async {
    if (state is! AsyncData<NotificationPreferences>) return;
    final current = state.requireValue;
    if (!current.isMutable(category)) return; // securityAlerts are non-mutable

    final updated = switch (category) {
      NotificationCategory.trading => current.copyWith(tradingEnabled: enabled),
      NotificationCategory.funding => current.copyWith(fundingEnabled: enabled),
      NotificationCategory.kyc => current.copyWith(kycEnabled: enabled),
      NotificationCategory.systemAnnouncements =>
        current.copyWith(systemAnnouncementsEnabled: enabled),
      NotificationCategory.securityAlerts => current, // no-op
    };

    final prev = state;
    state = AsyncData(updated);
    try {
      final saved = await ref
          .read(settingsRepositoryProvider)
          .updateNotificationPreferences(updated);
      state = AsyncData(saved);
    } on Object catch (e) {
      AppLogger.warning('toggleNotification failed: $e');
      state = prev;
      rethrow;
    }
  }

  Future<void> toggleChannel({
    required NotificationChannel channel,
    required bool enabled,
  }) async {
    if (state is! AsyncData<NotificationPreferences>) return;
    final current = state.requireValue;

    final updated = switch (channel) {
      NotificationChannel.push => current.copyWith(pushEnabled: enabled),
      NotificationChannel.sms => current.copyWith(smsEnabled: enabled),
      NotificationChannel.email => current.copyWith(emailEnabled: enabled),
    };

    final prev = state;
    state = AsyncData(updated);
    try {
      final saved = await ref
          .read(settingsRepositoryProvider)
          .updateNotificationPreferences(updated);
      state = AsyncData(saved);
    } on Object catch (e) {
      AppLogger.warning('toggleChannel failed: $e');
      state = prev;
      rethrow;
    }
  }
}
