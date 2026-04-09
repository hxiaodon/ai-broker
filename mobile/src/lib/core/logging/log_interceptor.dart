import 'package:dio/dio.dart';
import '../logging/app_logger.dart';

/// Dio interceptor that logs requests and responses with PII masking.
///
/// Sensitive headers (Authorization, Cookie) and known PII body fields
/// are redacted before emission.
class DioLogInterceptor extends Interceptor {
  const DioLogInterceptor();

  static const _sensitiveHeaders = {'authorization', 'cookie', 'x-api-key'};
  static const _sensitiveFields = {
    'password',
    'ssn',
    'hkid',
    'bank_account_number',
    'access_token',
    'refresh_token',
    'id_number',
    'tax_id',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = options.headers['X-Request-ID'] ?? '-';
    final headers = _maskHeaders(options.headers);
    AppLogger.debug(
      '[DIO →] [$requestId] ${options.method} ${options.path} '
      'headers=$headers data=${_maskBody(options.data)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final requestId = response.requestOptions.headers['X-Request-ID'] ?? '-';
    AppLogger.debug(
      '[DIO ←] [$requestId] ${response.statusCode} ${response.requestOptions.path} '
      'data=${_maskBody(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = err.requestOptions.headers['X-Request-ID'] ?? '-';
    AppLogger.warning(
      '[DIO ✗] [$requestId] ${err.response?.statusCode} ${err.requestOptions.path} '
      '${err.message}',
      error: err,
      stackTrace: err.stackTrace,
    );
    handler.next(err);
  }

  Map<String, dynamic> _maskHeaders(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _sensitiveHeaders.contains(entry.key.toLowerCase())
            ? '***REDACTED***'
            : entry.value,
    };
  }

  dynamic _maskBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      return {
        for (final entry in data.entries)
          entry.key: _sensitiveFields.contains(entry.key.toLowerCase())
              ? '***REDACTED***'
              : entry.value,
      };
    }
    return data;
  }
}
