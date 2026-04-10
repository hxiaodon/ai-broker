import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

/// Interceptor that injects the JWT access token into each request header
/// and handles 401 by attempting a token refresh before retrying.
///
/// Token read/write delegates to [TokenService] (injected lazily to avoid
/// circular dependency with the Dio instance itself).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._dio, {
    String? Function()? getAccessToken,
    Future<String?> Function()? refreshAccessToken,
  })  : getAccessToken = getAccessToken ?? (() => null),
        refreshAccessToken = refreshAccessToken ?? (() async => null);

  final Dio _dio;
  bool _isRefreshing = false;

  /// Returns the current access token synchronously (from in-memory cache).
  /// Wired at provider assembly time via [DioClient.create].
  final String? Function() getAccessToken;

  /// Attempts to refresh the access token. Returns the new token or null.
  /// Wired at provider assembly time via [DioClient.create].
  final Future<String?> Function() refreshAccessToken;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        AppLogger.debug('AuthInterceptor: attempting token refresh for ${err.requestOptions.path}');
        final newToken = await refreshAccessToken();
        if (newToken != null) {
          AppLogger.info('AuthInterceptor: token refresh successful, retrying ${err.requestOptions.path}');
          final options = err.requestOptions
            ..headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch<dynamic>(options);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        } else {
          AppLogger.warning('AuthInterceptor: token refresh returned null');
        }
      } on Object catch (e, stack) {
        AppLogger.error(
          'AuthInterceptor: token refresh failed',
          error: e,
          stackTrace: stack,
        );
        // Refresh failed — propagate original error
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}
