import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import 'auth_request_models.dart';
import 'auth_response_models.dart';

/// Remote data source for AMS authentication endpoints.
///
/// Calls:
///   POST /v1/auth/otp/send
///   POST /v1/auth/otp/verify
///   POST /v1/auth/token/refresh
///   POST /v1/auth/biometric/register
///   POST /v1/auth/biometric/verify
///   POST /v1/auth/logout
///   GET  /v1/auth/devices
///   DELETE /v1/auth/devices/{device_id}
///
/// All requests include X-Device-ID header (injected by [AuthInterceptor]).
/// Sensitive endpoints include Idempotency-Key.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// POST /v1/auth/otp/send
  Future<SendOtpResponse> sendOtp({
    required SendOtpRequest request,
    required String idempotencyKey,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/otp/send',
        data: request.toJson(),
        options: Options(
          headers: {
            'Idempotency-Key': idempotencyKey,
            'X-Device-ID': deviceId,
          },
        ),
      );
      AppLogger.info('Auth: OTP sent successfully (region=${request.region})');
      return SendOtpResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioException(e, 'sendOtp', context: {'region': request.region});
    }
  }

  /// POST /v1/auth/otp/verify
  Future<Map<String, dynamic>> verifyOtp({
    required VerifyOtpRequest request,
    required String idempotencyKey,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/otp/verify',
        data: request.toJson(),
        options: Options(
          headers: {
            'Idempotency-Key': idempotencyKey,
            'X-Device-ID': deviceId,
          },
        ),
      );
      AppLogger.info('Auth: OTP verified successfully');
      return response.data!;
    } on DioException catch (e) {
      throw _mapDioException(e, 'verifyOtp');
    }
  }

  /// POST /v1/auth/token/refresh
  Future<RefreshTokenResponse> refreshToken({
    required RefreshTokenRequest request,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/token/refresh',
        data: request.toJson(),
        options: Options(
          headers: {'X-Device-ID': deviceId},
        ),
      );
      AppLogger.info('Auth: token refresh succeeded');
      return RefreshTokenResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioException(e, 'refreshToken');
    }
  }

  /// POST /v1/auth/biometric/register
  Future<RegisterBiometricResponse> registerBiometric({
    required RegisterBiometricRequest request,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/biometric/register',
        data: request.toJson(),
        options: Options(
          headers: {'X-Device-ID': deviceId},
        ),
      );
      AppLogger.info('Auth: biometric registered successfully');
      return RegisterBiometricResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioException(e, 'registerBiometric');
    }
  }

  /// POST /v1/auth/biometric/verify
  Future<VerifyBiometricResponse> verifyBiometric({
    required VerifyBiometricRequest request,
    required String biometricSignature,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/v1/auth/biometric/verify',
        data: request.toJson(),
        options: Options(
          headers: {
            'X-Device-ID': deviceId,
            'X-Biometric-Verified': biometricSignature,
          },
        ),
      );
      AppLogger.debug('Auth: biometric verified');
      return VerifyBiometricResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioException(e, 'verifyBiometric');
    }
  }

  /// POST /v1/auth/logout
  Future<void> logout({
    required String deviceId,
    String? biometricSignature,
  }) async {
    try {
      final headers = <String, String>{'X-Device-ID': deviceId};
      if (biometricSignature != null) {
        headers['X-Biometric-Verified'] = biometricSignature;
      }
      await _dio.post<dynamic>(
        '/v1/auth/logout',
        data: const LogoutRequest().toJson(),
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      // Logout should not block local cleanup even if server fails
      AppLogger.warning(
        'Logout server call failed — proceeding with local cleanup',
        error: e,
      );
    }
  }

  /// GET /v1/auth/devices
  Future<DevicesListResponse> getDevices({required String deviceId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/auth/devices',
        options: Options(
          headers: {'X-Device-ID': deviceId},
        ),
      );
      return DevicesListResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioException(e, 'getDevices');
    }
  }

  /// DELETE /v1/auth/devices/{device_id}
  Future<RevokeDeviceResponse> revokeDevice({
    required String targetDeviceId,
    required String currentDeviceId,
    required String biometricSignature,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/v1/auth/devices/$targetDeviceId',
        options: Options(
          headers: {
            'X-Device-ID': currentDeviceId,
            'X-Biometric-Verified': biometricSignature,
          },
        ),
      );
      return RevokeDeviceResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioException(e, 'revokeDevice');
    }
  }

  AppException _mapDioException(
    DioException e,
    String operation, {
    Map<String, dynamic>? context,
  }) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Try to extract AMS error code from body
    String? errorCode;
    String? message;
    int? remainingAttempts;
    DateTime? lockoutUntil;

    if (data is Map<String, dynamic>) {
      try {
        final err = AmsErrorResponse.fromJson(data);
        errorCode = err.errorCode;
        message = err.message;
        remainingAttempts = err.remainingAttempts;
        if (err.lockoutUntil != null) {
          lockoutUntil = DateTime.tryParse(err.lockoutUntil!)?.toUtc();
        }
      } catch (_) {
        // Body does not match AmsErrorResponse schema
      }
    }

    final contextStr = context != null ? ' context=$context' : '';
    AppLogger.warning(
      'Auth API error [$operation]: status=$statusCode, code=$errorCode$contextStr',
    );

    switch (statusCode) {
      case 400:
        return BusinessException(
          message: message ?? 'Request rejected by server',
          errorCode: errorCode,
        );
      case 401:
        return OtpAuthException(
          message: message ?? 'Authentication failed',
          errorCode: errorCode,
          remainingAttempts: remainingAttempts,
          lockoutUntil: lockoutUntil,
        );
      case 429:
        return BusinessException(
          message: message ?? 'Too many requests. Please wait.',
          errorCode: errorCode ?? 'RATE_LIMIT_EXCEEDED',
        );
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          return const NetworkException(message: '请求超时，请检查网络连接');
        }
        if (e.type == DioExceptionType.connectionError) {
          return const NetworkException(message: '无法连接服务器，请检查网络');
        }
        return ServerException(
          message: message ?? '服务器错误，请稍后重试',
          statusCode: statusCode ?? 0,
          errorCode: errorCode,
        );
    }
  }
}
