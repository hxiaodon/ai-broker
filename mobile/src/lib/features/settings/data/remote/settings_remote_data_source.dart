import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/security/hmac_signer.dart';
import '../../../../core/security/nonce_service.dart';
import '../../../../core/security/session_key_service.dart';
import '../../../../core/auth/device_info_service.dart' as svc;
import '../../domain/entities/account_status.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/user_profile.dart';
import 'models/account_status_model.dart';
import 'models/device_info_model.dart';
import 'models/notification_preferences_model.dart';
import 'models/user_profile_model.dart';

/// Dio-based implementation of all Settings / Profile REST endpoints.
///
/// Endpoints called (AMS service):
///   GET  /v1/profile
///   GET  /v1/profile/account-status
///   GET  /v1/notifications/preferences
///   PUT  /v1/notifications/preferences
///   GET  /v1/auth/devices
///   DELETE /v1/auth/devices/{device_id}   (requires biometric headers)
///   POST /v1/auth/otp/send               (change phone — old + new number)
///   POST /v1/auth/phone/change           (finalize phone update)
///   POST /v1/account/lock                (emergency account lock)
///   GET  /v1/account/deactivation/eligibility
///   POST /v1/account/deactivate          (with OTP token)
class SettingsRemoteDataSource {
  SettingsRemoteDataSource({
    required Dio dio,
    required ConnectivityService connectivity,
    required HmacSigner signer,
    required SessionKeyService sessionKeyService,
    required NonceService nonceService,
    required svc.DeviceInfoService deviceInfoService,
  })  : _dio = dio,
        _connectivity = connectivity,
        _signer = signer,
        _sessionKeyService = sessionKeyService,
        _nonceService = nonceService,
        _deviceInfoService = deviceInfoService;

  final Dio _dio;
  final ConnectivityService _connectivity;
  final HmacSigner _signer;
  final SessionKeyService _sessionKeyService;
  final NonceService _nonceService;
  final svc.DeviceInfoService _deviceInfoService;

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<UserProfile> getProfile() async {
    await _checkConnectivity();
    const path = '/v1/profile';
    final headers = await _buildGetHeaders(path);
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: headers),
      );
      return UserProfileModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getProfile');
    }
  }

  Future<AccountStatus> getAccountStatus() async {
    await _checkConnectivity();
    const path = '/v1/profile/account-status';
    final headers = await _buildGetHeaders(path);
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: headers),
      );
      return AccountStatusModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getAccountStatus');
    }
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<NotificationPreferences> getNotificationPreferences() async {
    await _checkConnectivity();
    const path = '/v1/notifications/preferences';
    final headers = await _buildGetHeaders(path);
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: headers),
      );
      return NotificationPreferencesModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getNotificationPreferences');
    }
  }

  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    await _checkConnectivity();
    const path = '/v1/notifications/preferences';
    final body = jsonEncode(NotificationPreferencesModel.fromDomain(prefs).toJson());
    final headers = await _buildMutatingHeaders(
      method: 'PUT',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: headers),
      );
      return NotificationPreferencesModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'updateNotificationPreferences');
    }
  }

  // ─── Devices ──────────────────────────────────────────────────────────────

  Future<List<DeviceInfo>> getDevices() async {
    await _checkConnectivity();
    const path = '/v1/auth/devices';
    final headers = await _buildGetHeaders(path);
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: headers),
      );
      final items = resp.data!['devices'] as List<dynamic>? ?? [];
      return items
          .map((e) => DeviceInfoModel.fromJson(e as Map<String, dynamic>).toDomain())
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getDevices');
    }
  }

  Future<void> revokeDevice({
    required String deviceId,
    required String bioToken,
    required String bioChallenge,
    required String bioTimestamp,
    required String idempotencyKey,
  }) async {
    await _checkConnectivity();
    final path = '/v1/auth/devices/$deviceId';
    final headers = await _buildMutatingHeaders(
      method: 'DELETE',
      path: path,
      bodyJson: '',
      idempotencyKey: idempotencyKey,
    );
    headers['X-Biometric-Token'] = bioToken;
    headers['X-Bio-Challenge'] = bioChallenge;
    headers['X-Bio-Timestamp'] = bioTimestamp;
    try {
      await _dio.delete<void>(path, options: Options(headers: headers));
      AppLogger.info('revokeDevice success: $deviceId');
    } on DioException catch (e) {
      throw _mapDioError(e, 'revokeDevice');
    }
  }

  // ─── Change Phone ─────────────────────────────────────────────────────────

  /// Sends OTP to the authenticated user's current phone (server derives from JWT).
  /// Used as step 1 of the change-phone flow (PRD §6.3).
  Future<void> sendOtpToCurrentPhone() async {
    await _checkConnectivity();
    const path = '/v1/auth/otp/send';
    final body = jsonEncode({'purpose': 'VERIFY_CURRENT_PHONE'});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
    } on DioException catch (e) {
      throw _mapDioError(e, 'sendOtpToCurrentPhone');
    }
  }

  Future<void> sendChangePhoneOtp({required String phone}) async {
    await _checkConnectivity();
    const path = '/v1/auth/otp/send';
    final body = jsonEncode({'phone': phone, 'purpose': 'CHANGE_PHONE'});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
    } on DioException catch (e) {
      throw _mapDioError(e, 'sendChangePhoneOtp');
    }
  }

  Future<void> verifyOldPhoneOtp({required String otpCode}) async {
    await _checkConnectivity();
    const path = '/v1/auth/phone/verify-old';
    final body = jsonEncode({'otp_code': otpCode});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
    } on DioException catch (e) {
      throw _mapDioError(e, 'verifyOldPhoneOtp');
    }
  }

  Future<void> verifyNewPhoneAndUpdate({
    required String newPhone,
    required String otpCode,
  }) async {
    await _checkConnectivity();
    const path = '/v1/auth/phone/change';
    final body = jsonEncode({'new_phone': newPhone, 'otp_code': otpCode});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
      AppLogger.info('verifyNewPhoneAndUpdate success');
    } on DioException catch (e) {
      throw _mapDioError(e, 'verifyNewPhoneAndUpdate');
    }
  }

  // ─── Account Lock ─────────────────────────────────────────────────────────

  Future<void> lockAccount() async {
    await _checkConnectivity();
    const path = '/v1/account/lock';
    final body = jsonEncode(<String, dynamic>{});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
      AppLogger.info('lockAccount success');
    } on DioException catch (e) {
      throw _mapDioError(e, 'lockAccount');
    }
  }

  // ─── Account Deactivation ─────────────────────────────────────────────────

  Future<void> checkDeactivationEligibility() async {
    await _checkConnectivity();
    const path = '/v1/account/deactivation/eligibility';
    final headers = await _buildGetHeaders(path);
    try {
      await _dio.get<void>(path, options: Options(headers: headers));
    } on DioException catch (e) {
      throw _mapDioError(e, 'checkDeactivationEligibility');
    }
  }

  Future<void> sendOtpForDeactivation() async {
    await _checkConnectivity();
    const path = '/v1/auth/otp/send';
    final body = jsonEncode({'purpose': 'DEACTIVATE_ACCOUNT'});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
    } on DioException catch (e) {
      throw _mapDioError(e, 'sendOtpForDeactivation');
    }
  }

  Future<void> deactivateAccount({
    required String otpCode,
    required String idempotencyKey,
  }) async {
    await _checkConnectivity();
    const path = '/v1/account/deactivate';
    final body = jsonEncode({'otp_code': otpCode});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: idempotencyKey,
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
      AppLogger.info('deactivateAccount success');
    } on DioException catch (e) {
      throw _mapDioError(e, 'deactivateAccount');
    }
  }

  // ─── Biometric login management ──────────────────────────────────────────

  Future<void> sendOtpForBiometricDisable() async {
    await _checkConnectivity();
    const path = '/v1/auth/otp/send';
    final body = jsonEncode({'purpose': 'DISABLE_BIOMETRIC_LOGIN'});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
    } on DioException catch (e) {
      throw _mapDioError(e, 'sendOtpForBiometricDisable');
    }
  }

  Future<void> disableBiometricLogin({required String otpCode}) async {
    await _checkConnectivity();
    const path = '/v1/auth/security/biometric/disable';
    final body = jsonEncode({'otp_code': otpCode});
    final headers = await _buildMutatingHeaders(
      method: 'POST',
      path: path,
      bodyJson: body,
      idempotencyKey: const Uuid().v4(),
    );
    try {
      await _dio.post<void>(path, data: body, options: Options(headers: headers));
      AppLogger.info('disableBiometricLogin success');
    } on DioException catch (e) {
      throw _mapDioError(e, 'disableBiometricLogin');
    }
  }

  // ─── Header builders ──────────────────────────────────────────────────────

  Future<Map<String, String>> _buildGetHeaders(String path) async {
    final sessionKey = await _sessionKeyService.getSessionKey();
    final nonce = await _nonceService.fetchNonce();
    final deviceId = await _deviceInfoService.getDeviceId();
    return _signer.buildHeaders(
      secret: sessionKey.secret,
      keyId: sessionKey.keyId,
      method: 'GET',
      path: path,
      nonce: nonce,
      deviceId: deviceId,
    );
  }

  Future<Map<String, String>> _buildMutatingHeaders({
    required String method,
    required String path,
    required String bodyJson,
    required String idempotencyKey,
  }) async {
    final sessionKey = await _sessionKeyService.getSessionKey();
    final nonce = await _nonceService.fetchNonce();
    final deviceId = await _deviceInfoService.getDeviceId();
    final sigHeaders = _signer.buildHeaders(
      secret: sessionKey.secret,
      keyId: sessionKey.keyId,
      method: method,
      path: path,
      nonce: nonce,
      deviceId: deviceId,
      body: bodyJson,
    );
    return {
      'Content-Type': 'application/json',
      ...sigHeaders,
      if (idempotencyKey.isNotEmpty) 'Idempotency-Key': idempotencyKey,
    };
  }

  // ─── Connectivity + Error mapping ─────────────────────────────────────────

  Future<void> _checkConnectivity() async {
    if (!await _connectivity.isConnected) {
      throw const NetworkException(message: 'No internet connection');
    }
  }

  AppException _mapDioError(DioException e, String op) {
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;
    final msg = body is Map ? body['message'] as String? : null;
    final errorCode = body is Map ? body['error_code'] as String? : null;
    // Log status + error code only — never log e.message (may contain PII from request data)
    AppLogger.warning('$op failed: status=$statusCode code=${errorCode ?? e.type.name}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: '$op timed out', cause: e);
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerException(statusCode: statusCode, message: msg ?? 'Server error');
    }
    if (statusCode == 422) {
      return ValidationException(message: msg ?? 'Validation failed');
    }
    if (statusCode == 409) {
      return BusinessException(
        errorCode: errorCode ?? 'CONFLICT',
        message: msg ?? 'Conflict',
      );
    }
    if (statusCode != null && statusCode >= 400) {
      return BusinessException(
        errorCode: errorCode ?? 'CLIENT_ERROR',
        message: msg ?? 'Request failed',
      );
    }
    return NetworkException(message: '$op failed: ${e.message}', cause: e);
  }
}
