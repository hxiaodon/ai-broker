// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_request_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SendOtpRequest _$SendOtpRequestFromJson(Map<String, dynamic> json) =>
    _SendOtpRequest(
      phoneNumber: json['phone_number'] as String,
      deliveryMethod: json['delivery_method'] as String? ?? 'SMS',
      captchaToken: json['captcha_token'] as String?,
    );

Map<String, dynamic> _$SendOtpRequestToJson(_SendOtpRequest instance) =>
    <String, dynamic>{
      'phone_number': instance.phoneNumber,
      'delivery_method': instance.deliveryMethod,
      'captcha_token': instance.captchaToken,
    };

_VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    _VerifyOtpRequest(
      requestId: json['request_id'] as String,
      otpCode: json['otp_code'] as String,
      phoneNumber: json['phone_number'] as String,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(_VerifyOtpRequest instance) =>
    <String, dynamic>{
      'request_id': instance.requestId,
      'otp_code': instance.otpCode,
      'phone_number': instance.phoneNumber,
    };

_RefreshTokenRequest _$RefreshTokenRequestFromJson(Map<String, dynamic> json) =>
    _RefreshTokenRequest(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$RefreshTokenRequestToJson(
  _RefreshTokenRequest instance,
) => <String, dynamic>{'refresh_token': instance.refreshToken};

_RegisterBiometricRequest _$RegisterBiometricRequestFromJson(
  Map<String, dynamic> json,
) => _RegisterBiometricRequest(
  biometricType: json['biometric_type'] as String,
  deviceFingerprint: json['device_fingerprint'] as String,
  deviceName: json['device_name'] as String?,
);

Map<String, dynamic> _$RegisterBiometricRequestToJson(
  _RegisterBiometricRequest instance,
) => <String, dynamic>{
  'biometric_type': instance.biometricType,
  'device_fingerprint': instance.deviceFingerprint,
  'device_name': instance.deviceName,
};

_VerifyBiometricRequest _$VerifyBiometricRequestFromJson(
  Map<String, dynamic> json,
) => _VerifyBiometricRequest(
  operation: json['operation'] as String,
  deviceFingerprint: json['device_fingerprint'] as String?,
);

Map<String, dynamic> _$VerifyBiometricRequestToJson(
  _VerifyBiometricRequest instance,
) => <String, dynamic>{
  'operation': instance.operation,
  'device_fingerprint': instance.deviceFingerprint,
};

_LogoutRequest _$LogoutRequestFromJson(Map<String, dynamic> json) =>
    _LogoutRequest(reason: json['reason'] as String? ?? 'USER_INITIATED');

Map<String, dynamic> _$LogoutRequestToJson(_LogoutRequest instance) =>
    <String, dynamic>{'reason': instance.reason};
