// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_preferences_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationPreferencesModel _$NotificationPreferencesModelFromJson(
  Map<String, dynamic> json,
) => _NotificationPreferencesModel(
  tradingEnabled: json['trading_enabled'] as bool? ?? true,
  fundingEnabled: json['funding_enabled'] as bool? ?? true,
  kycEnabled: json['kyc_enabled'] as bool? ?? true,
  systemAnnouncementsEnabled:
      json['system_announcements_enabled'] as bool? ?? true,
  pushEnabled: json['push_enabled'] as bool? ?? true,
  smsEnabled: json['sms_enabled'] as bool? ?? false,
  emailEnabled: json['email_enabled'] as bool? ?? true,
  quietHoursStart: json['quiet_hours_start'] as String?,
  quietHoursEnd: json['quiet_hours_end'] as String?,
);

Map<String, dynamic> _$NotificationPreferencesModelToJson(
  _NotificationPreferencesModel instance,
) => <String, dynamic>{
  'trading_enabled': instance.tradingEnabled,
  'funding_enabled': instance.fundingEnabled,
  'kyc_enabled': instance.kycEnabled,
  'system_announcements_enabled': instance.systemAnnouncementsEnabled,
  'push_enabled': instance.pushEnabled,
  'sms_enabled': instance.smsEnabled,
  'email_enabled': instance.emailEnabled,
  'quiet_hours_start': instance.quietHoursStart,
  'quiet_hours_end': instance.quietHoursEnd,
};
