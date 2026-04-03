import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response_models.freezed.dart';
part 'auth_response_models.g.dart';

/// POST /v1/auth/otp/send — 200 OK response
@freezed
abstract class SendOtpResponse with _$SendOtpResponse {
  const factory SendOtpResponse({
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    @JsonKey(name: 'delivery_method') required String deliveryMethod,
    @JsonKey(name: 'expires_in_seconds') required int expiresInSeconds,
    @JsonKey(name: 'retry_after_seconds') required int retryAfterSeconds,
  }) = _SendOtpResponse;

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$SendOtpResponseFromJson(json);
}

/// POST /v1/auth/otp/verify — 200 OK response (existing user)
@freezed
abstract class VerifyOtpExistingUserResponse with _$VerifyOtpExistingUserResponse {
  const factory VerifyOtpExistingUserResponse({
    required String status,
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'expires_in_seconds') required int expiresInSeconds,
    @JsonKey(name: 'account_id') required String accountId,
    @JsonKey(name: 'account_status') required String accountStatus,
    @JsonKey(name: 'request_id') String? requestId,
    @JsonKey(name: 'device_info') DeviceInfoDto? deviceInfo,
  }) = _VerifyOtpExistingUserResponse;

  factory VerifyOtpExistingUserResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpExistingUserResponseFromJson(json);
}

/// POST /v1/auth/otp/verify — 200 OK response (new user)
@freezed
abstract class VerifyOtpNewUserResponse with _$VerifyOtpNewUserResponse {
  const factory VerifyOtpNewUserResponse({
    required String status,
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    @JsonKey(name: 'next_step') required String nextStep,
    @JsonKey(name: 'expires_in_seconds') required int expiresInSeconds,
  }) = _VerifyOtpNewUserResponse;

  factory VerifyOtpNewUserResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpNewUserResponseFromJson(json);
}

/// POST /v1/auth/otp/verify — 401 error response
@freezed
abstract class VerifyOtpErrorResponse with _$VerifyOtpErrorResponse {
  const factory VerifyOtpErrorResponse({
    @JsonKey(name: 'error_code') required String errorCode,
    required String message,
    @JsonKey(name: 'remaining_attempts') int? remainingAttempts,
    @JsonKey(name: 'lockout_until') String? lockoutUntil,
  }) = _VerifyOtpErrorResponse;

  factory VerifyOtpErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpErrorResponseFromJson(json);
}

/// POST /v1/auth/token/refresh — 200 OK response
@freezed
abstract class RefreshTokenResponse with _$RefreshTokenResponse {
  const factory RefreshTokenResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'expires_in_seconds') required int expiresInSeconds,
    @JsonKey(name: 'device_status') required String deviceStatus,
  }) = _RefreshTokenResponse;

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenResponseFromJson(json);
}

/// POST /v1/auth/biometric/register — 201 response
@freezed
abstract class RegisterBiometricResponse with _$RegisterBiometricResponse {
  const factory RegisterBiometricResponse({
    @JsonKey(name: 'device_id') required String deviceId,
    @JsonKey(name: 'biometric_type') required String biometricType,
    @JsonKey(name: 'registered_at') required String registeredAt,
    required String status,
  }) = _RegisterBiometricResponse;

  factory RegisterBiometricResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterBiometricResponseFromJson(json);
}

/// POST /v1/auth/biometric/verify — 200 response
@freezed
abstract class VerifyBiometricResponse with _$VerifyBiometricResponse {
  const factory VerifyBiometricResponse({
    required String operation,
    required bool verified,
    @JsonKey(name: 'verification_token') required String verificationToken,
  }) = _VerifyBiometricResponse;

  factory VerifyBiometricResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyBiometricResponseFromJson(json);
}

/// Device DTO used inside verify OTP response
@freezed
abstract class DeviceInfoDto with _$DeviceInfoDto {
  const factory DeviceInfoDto({
    @JsonKey(name: 'device_id') required String deviceId,
    @JsonKey(name: 'device_name') required String deviceName,
    @JsonKey(name: 'os_type') required String osType,
    @JsonKey(name: 'login_time') required String loginTime,
    required String status,
    @JsonKey(name: 'last_activity_time') String? lastActivityTime,
    @JsonKey(name: 'location_country') String? locationCountry,
    @JsonKey(name: 'location_city') String? locationCity,
    @JsonKey(name: 'is_current_device') bool? isCurrentDevice,
    @JsonKey(name: 'biometric_registered') bool? biometricRegistered,
    @JsonKey(name: 'biometric_type') String? biometricType,
  }) = _DeviceInfoDto;

  factory DeviceInfoDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoDtoFromJson(json);
}

/// GET /v1/auth/devices — 200 response
@freezed
abstract class DevicesListResponse with _$DevicesListResponse {
  const factory DevicesListResponse({
    required List<DeviceInfoDto> devices,
  }) = _DevicesListResponse;

  factory DevicesListResponse.fromJson(Map<String, dynamic> json) =>
      _$DevicesListResponseFromJson(json);
}

/// DELETE /v1/auth/devices/{id} — 200 response
@freezed
abstract class RevokeDeviceResponse with _$RevokeDeviceResponse {
  const factory RevokeDeviceResponse({
    @JsonKey(name: 'device_id') required String deviceId,
    required String status,
    @JsonKey(name: 'kicked_at') required String kickedAt,
    @JsonKey(name: 'notification_status') String? notificationStatus,
  }) = _RevokeDeviceResponse;

  factory RevokeDeviceResponse.fromJson(Map<String, dynamic> json) =>
      _$RevokeDeviceResponseFromJson(json);
}

/// AMS error response body
@freezed
abstract class AmsErrorResponse with _$AmsErrorResponse {
  const factory AmsErrorResponse({
    @JsonKey(name: 'error_code') required String errorCode,
    required String message,
    @JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds,
    @JsonKey(name: 'remaining_attempts') int? remainingAttempts,
    @JsonKey(name: 'lockout_until') String? lockoutUntil,
    Map<String, dynamic>? details,
  }) = _AmsErrorResponse;

  factory AmsErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$AmsErrorResponseFromJson(json);
}
