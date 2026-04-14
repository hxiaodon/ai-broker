/// Error severity levels for reporting and handling decisions.
enum ErrorSeverity {
  /// Informational messages, no action needed.
  /// Examples: "Cache hit", "Using stale data", debug logs
  info,

  /// Warning-level issues, diagnostic info should be collected.
  /// Examples: Slow network, connection timeout (with fallback), invalid input
  warning,

  /// Recoverable error, application continues.
  /// Examples: API error, auth token expiration, business rule violation
  error,

  /// Critical error, application may need restart.
  /// Examples: Unhandled exception, corrupted local data, security breach
  critical;

  /// Convert to Sentry severity level.
  String toSentryLevel() => switch (this) {
        ErrorSeverity.info => 'info',
        ErrorSeverity.warning => 'warning',
        ErrorSeverity.error => 'error',
        ErrorSeverity.critical => 'fatal',
      };
}
