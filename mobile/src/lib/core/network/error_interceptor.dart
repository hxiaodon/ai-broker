import 'package:dio/dio.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

/// Maps [DioException] to domain-level [AppException] subtypes.
class ErrorInterceptor extends Interceptor {
  const ErrorInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    throw _mapError(err);
  }

  AppException _mapError(DioException err) {
    AppLogger.warning(
      'DioException: ${err.type} ${err.response?.statusCode ?? "no-status"} ${err.requestOptions.path}',
      error: err,
    );

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException(
          message: 'Request timed out: ${err.requestOptions.path}',
          cause: err,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'No network connection',
          cause: err,
        );
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        final body = err.response?.data;
        final serverMsg = _extractMessage(body) ?? err.message ?? 'Server error';
        final errorCode = _extractErrorCode(body);
        if (status == 401 || status == 403) {
          return AuthException(message: serverMsg, cause: err);
        }
        return ServerException(
          message: serverMsg,
          statusCode: status,
          cause: err,
          errorCode: errorCode,
        );
      case DioExceptionType.badCertificate:
        return SecurityException(
          message: 'Certificate validation failed',
          cause: err,
        );
      default:
        return UnknownException(
          message: err.message ?? 'Unknown network error',
          cause: err,
        );
    }
  }

  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['message'] as String? ??
          body['error'] as String? ??
          body['msg'] as String?;
    }
    return null;
  }

  String? _extractErrorCode(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['error_code'] as String? ?? body['code'] as String?;
    }
    return null;
  }
}
