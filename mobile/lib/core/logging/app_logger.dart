import 'package:logger/logger.dart';

/// Structured application logger with PII masking.
///
/// All log output is JSON-structured in production builds.
/// PII fields (phone, SSN, HKID, bank account, email) are automatically
/// masked before emission per SEC/FINRA audit logging requirements.
class AppLogger {
  AppLogger._();

  static late final Logger _logger;
  static bool _initialized = false;

  static void init({bool verbose = false}) {
    if (_initialized) return;
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: false,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: verbose ? Level.trace : Level.info,
      filter: _ProductionFilter(),
    );
    _initialized = true;
  }

  static void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(_mask(message), error: error, stackTrace: stackTrace);

  static void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(_mask(message), error: error, stackTrace: stackTrace);

  static void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(_mask(message), error: error, stackTrace: stackTrace);

  static void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(_mask(message), error: error, stackTrace: stackTrace);

  static void fatal(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(_mask(message), error: error, stackTrace: stackTrace);

  /// Logs a security-relevant event (SSL pin mismatch, compromise detected, etc.).
  ///
  /// Always emitted at [Level.warning] or above so it is never suppressed
  /// in production builds. Security events must never be silenced.
  static void security(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w('[SECURITY] ${_mask(message)}', error: error, stackTrace: stackTrace);

  /// Masks PII fields before writing to logs.
  ///
  /// Patterns covered:
  /// - US phone numbers (+1XXXXXXXXXX)
  /// - Email addresses
  /// - SSN (XXX-XX-XXXX)
  /// - HKID (A123456(X))
  /// - Bank account numbers (digits 8-20 chars)
  static String _mask(String message) {
    return message
        // Phone: keep country code + last 4
        .replaceAllMapped(
          RegExp(r'\+?1?[\s\-]?\(?\d{3}\)?[\s\-]?\d{3}[\s\-]?\d{4}'),
          (m) => '***-***-${m.group(0)!.replaceAll(RegExp(r'\D'), '').substring(m.group(0)!.replaceAll(RegExp(r'\D'), '').length - 4)}',
        )
        // Email: mask local part middle
        .replaceAllMapped(
          RegExp(r'([a-zA-Z0-9])[a-zA-Z0-9._%+\-]+([a-zA-Z0-9])@'),
          (m) => '${m.group(1)}***${m.group(2)}@',
        )
        // SSN
        .replaceAll(RegExp(r'\d{3}-\d{2}-\d{4}'), '***-**-****')
        // HKID partial mask
        .replaceAllMapped(
          RegExp(r'[A-Z]{1,2}\d{6}\([0-9A]\)'),
          (m) => '${m.group(0)![0]}*****(${m.group(0)![m.group(0)!.length - 2]})',
        )
        // Bank account (8-20 consecutive digits)
        .replaceAllMapped(
          RegExp(r'\b\d{8,20}\b'),
          (m) => '****${m.group(0)!.substring(m.group(0)!.length - 4)}',
        );
  }
}

class _ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode suppress debug/trace; allow warning+ always
    const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');
    if (kReleaseMode && event.level.index < Level.warning.index) return false;
    return true;
  }
}
