import 'package:dio/dio.dart';

/// Converts an exception to a user-facing message, hiding internal details.
///
/// Raw [DioException] messages may include URLs, status codes, or server stack
/// traces — never surface them directly to the UI.
String kycUserMessage(Object e) {
  if (e is DioException) {
    final status = e.response?.statusCode;
    return switch (status) {
      400 => '提交信息有误，请检查后重试',
      401 || 403 => '登录已过期，请重新登录',
      413 => '文件过大，请上传小于 10MB 的文件',
      415 => '不支持的文件格式，请使用 JPG 或 PNG',
      422 => '信息不完整，请检查所有必填项',
      429 => '操作过于频繁，请稍后重试',
      _ when e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout =>
        '网络超时，请检查连接后重试',
      _ when e.type == DioExceptionType.connectionError =>
        '无法连接到服务器，请检查网络',
      _ => '操作失败，请稍后重试',
    };
  }
  final msg = e.toString();
  if (msg.contains('biometric_failed')) return '生物识别验证失败，请重试';
  if (msg.contains('INVALID_AGE')) return '必须年满 18 岁方可开户';
  return '操作失败，请稍后重试';
}
