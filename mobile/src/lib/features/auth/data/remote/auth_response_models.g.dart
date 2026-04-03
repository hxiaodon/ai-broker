// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SendOtpResponse _$SendOtpResponseFromJson(Map<String, dynamic> json) =>
    _SendOtpResponse(
      requestId: json['request_id'] as String,
      phoneNumber: json['phone_number'] as String,
      deliveryMethod: json['delivery_method'] as String,
      expiresInSeconds: (json['expires_in_seconds'] as num).toInt(),
      retryAfterSeconds: (json['retry_after_seconds'] as num).toInt(),
    );

Map<String, dynamic> _$SendOtpResponseToJson(_SendOtpResponse instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'phone_number': instance.phoneNumber,
      'delivery_method': instance.deliveryMethod,
      'expires_in_seconds': instance.expiresInSeconds,
      'retry_after_seconds': instance.retryAfterSeconds,
    };

_VerifyOtpExistingUserResponse _$VerifyOtpExistingUserResponseFromJson(
  Map<String, dynamic> json,
) => _VerifyOtpExistingUserResponse(
  status: json['status'] as String,
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresInSeconds: (json['expires_in_seconds'] as num).toInt(),
  accountId: json['account_id'] as String,
  accountStatus: json['account_status'] as String,
  requestId: json['request_id'] as String?,
  deviceInfo: json['device_info'] == null
      ? null
      : DeviceInfoDto.fromJson(json['device_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VerifyOtpExistingUserResponseToJson(
  _VerifyOtpExistingUserResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'expires_in_seconds': instance.expiresInSeconds,
  'account_id': instance.accountId,
  'account_status': instance.accountStatus,
  'request_id': instance.requestId,
  'device_info': instance.deviceInfo,
};

_VerifyOtpNewUserResponse _$VerifyOtpNewUserResponseFromJson(
  Map<String, dynamic> json,
) => _VerifyOtpNewUserResponse(
  status: json['status'] as String,
  requestId: json['request_id'] as String,
  phoneNumber: json['phone_number'] as String,
  nextStep: json['next_step'] as String,
  expiresInSeconds: (json['expires_in_seconds'] as num).toInt(),
);

Map<String, dynamic> _$VerifyOtpNewUserResponseToJson(
  _VerifyOtpNewUserResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'request_id': instance.requestId,
  'phone_number': instance.phoneNumber,
  'next_step': instance.nextStep,
  'expires_in_seconds': instance.expiresInSeconds,
};

_VerifyOtpErrorResponse _$VerifyOtpErrorResponseFromJson(
  Map<String, dynamic> json,
) => _VerifyOtpErrorResponse(
  errorCode: json['error_code'] as String,
  message: json['message'] as String,
  remainingAttempts: (json['remaining_attempts'] as num?)?.toInt(),
  lockoutUntil: json['lockout_until'] as String?,
);

Map<String, dynamic> _$VerifyOtpErrorResponseToJson(
  _VerifyOtpErrorResponse instance,
) => <String, dynamic>{
  'error_code': instance.errorCode,
  'message': instance.message,
  'remaining_attempts': instance.remainingAttempts,
  'lockout_until': instance.lockoutUntil,
};

_RefreshTokenResponse _$RefreshTokenResponseFromJson(
  Map<String, dynamic> json,
) => _RefreshTokenResponse(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresInSeconds: (json['expires_in_seconds'] as num).toInt(),
  deviceStatus: json['device_status'] as String,
);

Map<String, dynamic> _$RefreshTokenResponseToJson(
  _RefreshTokenResponse instance,
) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'expires_in_seconds': instance.expiresInSeconds,
  'device_status': instance.deviceStatus,
};

_RegisterBiometricResponse _$RegisterBiometricResponseFromJson(
  Map<String, dynamic> json,
) => _RegisterBiometricResponse(
  deviceId: json['device_id'] as String,
  biometricType: json['biometric_type'] as String,
  registeredAt: json['registered_at'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$RegisterBiometricResponseToJson(
  _RegisterBiometricResponse instance,
) => <String, dynamic>{
  'device_id': instance.deviceId,
  'biometric_type': instance.biometricType,
  'registered_at': instance.registeredAt,
  'status': instance.status,
};

_VerifyBiometricResponse _$VerifyBiometricResponseFromJson(
  Map<String, dynamic> json,
) => _VerifyBiometricResponse(
  operation: json['operation'] as String,
  verified: json['verified'] as bool,
  verificationToken: json['verification_token'] as String,
);

Map<String, dynamic> _$VerifyBiometricResponseToJson(
  _VerifyBiometricResponse instance,
) => <String, dynamic>{
  'operation': instance.operation,
  'verified': instance.verified,
  'verification_token': instance.verificationToken,
};

_DeviceInfoDto _$DeviceInfoDtoFromJson(Map<String, dynamic> json) =>
    _DeviceInfoDto(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      osType: json['os_type'] as String,
      loginTime: json['login_time'] as String,
      status: json['status'] as String,
      lastActivityTime: json['last_activity_time'] as String?,
      locationCountry: json['location_country'] as String?,
      locationCity: json['location_city'] as String?,
      isCurrentDevice: json['is_current_device'] as bool?,
      biometricRegistered: json['biometric_registered'] as bool?,
      biometricType: json['biometric_type'] as String?,
    );

Map<String, dynamic> _$DeviceInfoDtoToJson(_DeviceInfoDto instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'device_name': instance.deviceName,
      'os_type': instance.osType,
      'login_time': instance.loginTime,
      'status': instance.status,
      'last_activity_time': instance.lastActivityTime,
      'location_country': instance.locationCountry,
      'location_city': instance.locationCity,
      'is_current_device': instance.isCurrentDevice,
      'biometric_registered': instance.biometricRegistered,
      'biometric_type': instance.biometricType,
    };

_DevicesListResponse _$DevicesListResponseFromJson(Map<String, dynamic> json) =>
    _DevicesListResponse(
      devices: (json['devices'] as List<dynamic>)
          .map((e) => DeviceInfoDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DevicesListResponseToJson(
  _DevicesListResponse instance,
) => <String, dynamic>{'devices': instance.devices};

_RevokeDeviceResponse _$RevokeDeviceResponseFromJson(
  Map<String, dynamic> json,
) => _RevokeDeviceResponse(
  deviceId: json['device_id'] as String,
  status: json['status'] as String,
  kickedAt: json['kicked_at'] as String,
  notificationStatus: json['notification_status'] as String?,
);

Map<String, dynamic> _$RevokeDeviceResponseToJson(
  _RevokeDeviceResponse instance,
) => <String, dynamic>{
  'device_id': instance.deviceId,
  'status': instance.status,
  'kicked_at': instance.kickedAt,
  'notification_status': instance.notificationStatus,
};

_AmsErrorResponse _$AmsErrorResponseFromJson(Map<String, dynamic> json) =>
    _AmsErrorResponse(
      errorCode: json['error_code'] as String,
      message: json['message'] as String,
      retryAfterSeconds: (json['retry_after_seconds'] as num?)?.toInt(),
      remainingAttempts: (json['remaining_attempts'] as num?)?.toInt(),
      lockoutUntil: json['lockout_until'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AmsErrorResponseToJson(_AmsErrorResponse instance) =>
    <String, dynamic>{
      'error_code': instance.errorCode,
      'message': instance.message,
      'retry_after_seconds': instance.retryAfterSeconds,
      'remaining_attempts': instance.remainingAttempts,
      'lockout_until': instance.lockoutUntil,
      'details': instance.details,
    };
