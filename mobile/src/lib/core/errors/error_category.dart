/// Error categories for classification and monitoring.
enum ErrorCategory {
  /// Network errors: DNS, connection timeout, no connectivity, packet loss
  network,

  /// Authentication errors: login failed, token expired, permission denied
  auth,

  /// Input validation errors: invalid format, wrong type, constraints violated
  validation,

  /// Business logic errors: insufficient funds, max concurrent orders, rate limit
  business,

  /// Local storage errors: database corruption, I/O failure, permission denied
  database,

  /// Platform/OS errors: permission denied, unavailable sensor, unsupported API
  platform,

  /// Unknown errors that don't fit other categories
  unknown;

  /// Human-readable category name for logging and monitoring.
  String get displayName => switch (this) {
        ErrorCategory.network => '网络错误',
        ErrorCategory.auth => '认证错误',
        ErrorCategory.validation => '验证错误',
        ErrorCategory.business => '业务错误',
        ErrorCategory.database => '数据库错误',
        ErrorCategory.platform => '平台错误',
        ErrorCategory.unknown => '未知错误',
      };
}
