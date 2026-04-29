import 'package:dio/dio.dart';

import '../auth/device_info_service.dart';
import '../auth/token_service.dart';
import '../logging/app_logger.dart';
import 'auth_interceptor.dart';
import 'dio_client.dart';

/// Creates a [Dio] instance with [AuthInterceptor] wired to real token
/// read/refresh callbacks via [TokenService].
///
/// All repositories that need JWT injection should call this instead of
/// [DioClient.create] directly.
Dio createAuthenticatedDio({
  required String baseUrl,
  required TokenService tokenService,
  DeviceInfoService? deviceInfoService,
}) {
  // Build a temporary Dio first — AuthInterceptor needs a Dio reference
  // for retry, but we replace it with the real one below.
  late final Dio realDio;

  final authInterceptor = AuthInterceptor(
    // The Dio reference is used for retrying after 401 refresh.
    // We use a getter closure so it captures the final realDio.
    Dio(), // placeholder — overridden below
    getAccessToken: () => tokenService.cachedAccessToken,
    refreshAccessToken: () async {
      final refreshToken = await tokenService.getRefreshToken();
      if (refreshToken == null) return null;
      try {
        // Use a bare Dio (no auth interceptor) to avoid recursion
        final refreshDio = DioClient.create(baseUrl: baseUrl);
        final deviceId = await deviceInfoService?.getDeviceId();
        final response = await refreshDio.post<Map<String, dynamic>>(
          '/v1/auth/token/refresh',
          data: {'refresh_token': refreshToken},
          options: deviceId != null
              ? Options(headers: {'X-Device-ID': deviceId})
              : null,
        );
        final data = response.data!;
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String;
        final expiresIn = data['expires_in'] as int;
        final expiresAt =
            DateTime.now().toUtc().add(Duration(seconds: expiresIn));
        await tokenService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          accessTokenExpiresAt: expiresAt,
        );
        return newAccessToken;
      } on Object catch (e) {
        AppLogger.error('AuthInterceptor: token refresh failed', error: e);
        return null;
      }
    },
  );

  realDio = DioClient.create(
    baseUrl: baseUrl,
    authInterceptor: authInterceptor,
  );

  return realDio;
}
