import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/entities/notification_preferences.dart';

part 'notification_preferences_model.freezed.dart';
part 'notification_preferences_model.g.dart';

@freezed
abstract class NotificationPreferencesModel
    with _$NotificationPreferencesModel {
  const factory NotificationPreferencesModel({
    @JsonKey(name: 'trading_enabled') @Default(true) bool tradingEnabled,
    @JsonKey(name: 'funding_enabled') @Default(true) bool fundingEnabled,
    @JsonKey(name: 'kyc_enabled') @Default(true) bool kycEnabled,
    @JsonKey(name: 'system_announcements_enabled')
    @Default(true)
    bool systemAnnouncementsEnabled,
    @JsonKey(name: 'push_enabled') @Default(true) bool pushEnabled,
    @JsonKey(name: 'sms_enabled') @Default(false) bool smsEnabled,
    @JsonKey(name: 'email_enabled') @Default(true) bool emailEnabled,
    @JsonKey(name: 'quiet_hours_start') String? quietHoursStart,
    @JsonKey(name: 'quiet_hours_end') String? quietHoursEnd,
  }) = _NotificationPreferencesModel;

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesModelFromJson(json);

  const NotificationPreferencesModel._();

  NotificationPreferences toDomain() => NotificationPreferences(
        tradingEnabled: tradingEnabled,
        fundingEnabled: fundingEnabled,
        kycEnabled: kycEnabled,
        systemAnnouncementsEnabled: systemAnnouncementsEnabled,
        pushEnabled: pushEnabled,
        smsEnabled: smsEnabled,
        emailEnabled: emailEnabled,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
      );

  static NotificationPreferencesModel fromDomain(
    NotificationPreferences prefs,
  ) =>
      NotificationPreferencesModel(
        tradingEnabled: prefs.tradingEnabled,
        fundingEnabled: prefs.fundingEnabled,
        kycEnabled: prefs.kycEnabled,
        systemAnnouncementsEnabled: prefs.systemAnnouncementsEnabled,
        pushEnabled: prefs.pushEnabled,
        smsEnabled: prefs.smsEnabled,
        emailEnabled: prefs.emailEnabled,
        quietHoursStart: prefs.quietHoursStart,
        quietHoursEnd: prefs.quietHoursEnd,
      );
}
