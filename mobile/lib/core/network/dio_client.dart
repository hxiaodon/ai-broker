import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../logging/app_logger.dart';
import '../security/ssl_pinning_config.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';
import '../logging/log_interceptor.dart' as app_log;

/// Factory that creates a configured [Dio] instance.
///
/// Interceptor chain (in order):
///   1. [DioLogInterceptor]   — log requests/responses with PII masking
///   2. [AuthInterceptor]     — inject JWT, handle 401 refresh
///   3. [ErrorInterceptor]    — map DioException → AppException
///
/// Security:
///   Certificate pinning is applied via [createPinnedHttpClient] from
///   [ssl_pinning_config.dart] using SPKI SHA-256 fingerprints.
///   Phase 1: placeholder pins (see ssl_pinning_config.dart).
///   Phase 2: replace placeholder pins with real fingerprints.
class DioClient {
  DioClient._();

  static Dio create({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    List<Interceptor> additionalInterceptors = const [],
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    final dio = Dio(options);

    // Wire SPKI certificate pinning. createPinnedHttpClient() sets a
    // badCertificateCallback that validates the server's SPKI fingerprint
    // against the allow-list in ssl_pinning_config.dart.
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        createPinnedHttpClient;

    dio.interceptors.addAll([
      const app_log.DioLogInterceptor(),
      AuthInterceptor(dio),
      const ErrorInterceptor(),
      ...additionalInterceptors,
    ]);

    AppLogger.debug('DioClient created for $baseUrl (SSL pinning enabled)');
    return dio;
  }
}
