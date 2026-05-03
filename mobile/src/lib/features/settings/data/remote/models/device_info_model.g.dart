// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceInfoModel _$DeviceInfoModelFromJson(Map<String, dynamic> json) =>
    _DeviceInfoModel(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      platform: json['platform'] as String,
      status: json['status'] as String,
      lastActiveAt: json['last_active_at'] as String,
      isCurrentDevice: json['is_current_device'] as bool? ?? false,
    );

Map<String, dynamic> _$DeviceInfoModelToJson(_DeviceInfoModel instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'device_name': instance.deviceName,
      'platform': instance.platform,
      'status': instance.status,
      'last_active_at': instance.lastActiveAt,
      'is_current_device': instance.isCurrentDevice,
    };
