import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_request_models.freezed.dart';
part 'auth_request_models.g.dart';

/// POST /v1/auth/otp/send — request body
@freezed
abstract class SendOtpRequest with _$SendOtpRequest {
  const factory SendOtpRequest({
    @JsonKey(name: 'phone_number') required String phoneNumber,
    @JsonKey(name: 'delivery_method') @Default('SMS') String deliveryMethod,
    @JsonKey(name: 'captcha_token') String? captchaToken,
  }) = _SendOtpRequest;

  factory SendOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$SendOtpRequestFromJson(json);
}

/// POST /v1/auth/otp/verify — request body
@freezed
abstract class VerifyOtpRequest with _$VerifyOtpRequest {
  const factory VerifyOtpRequest({
    @JsonKey(name: 'request_id') required String requestId,
    @JsonKey(name: 'otp_code') required String otpCode,
    @JsonKey(name: 'phone_number') required String phoneNumber,
  }) = _VerifyOtpRequest;

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestFromJson(json);
}

/// POST /v1/auth/token/refresh — request body
@freezed
abstract class RefreshTokenRequest with _$RefreshTokenRequest {
  const factory RefreshTokenRequest({
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _RefreshTokenRequest;

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
}

/// POST /v1/auth/biometric/register — request body
@freezed
abstract class RegisterBiometricRequest with _$RegisterBiometricRequest {
  const factory RegisterBiometricRequest({
    @JsonKey(name: 'biometric_type') required String biometricType,
    @JsonKey(name: 'device_fingerprint') required String deviceFingerprint,
    @JsonKey(name: 'device_name') String? deviceName,
  }) = _RegisterBiometricRequest;

  factory RegisterBiometricRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterBiometricRequestFromJson(json);
}

/// POST /v1/auth/biometric/verify — request body
@freezed
abstract class VerifyBiometricRequest with _$VerifyBiometricRequest {
  const factory VerifyBiometricRequest({
    required String operation,
    @JsonKey(name: 'device_fingerprint') String? deviceFingerprint,
  }) = _VerifyBiometricRequest;

  factory VerifyBiometricRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyBiometricRequestFromJson(json);
}

/// POST /v1/auth/logout — request body
@freezed
abstract class LogoutRequest with _$LogoutRequest {
  const factory LogoutRequest({
    @Default('USER_INITIATED') String reason,
  }) = _LogoutRequest;

  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      _$LogoutRequestFromJson(json);
}
