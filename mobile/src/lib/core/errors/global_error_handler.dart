import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../logging/app_logger.dart';
import 'error_category.dart';
import 'error_severity.dart';
import 'app_exception.dart';

/// Global error handling and reporting system with Sentry integration.
///
/// Responsibilities:
/// 1. Classify errors by severity and category
/// 2. Report to Sentry with deduplication
/// 3. Store offline logs in local file system
/// 4. Provide user-friendly error messages
/// 5. Track device and user context
///
/// Usage:
/// ```dart
/// // Initialize in main() before running the app
/// await GlobalErrorHandler.init(
///   sentryDsn: 'your-sentry-dsn',
///   environment: 'production',
/// );
///
/// // Report errors anywhere in the app
/// GlobalErrorHandler.reportError(
///   error,
///   stackTrace: stackTrace,
///   userMessage: 'An error occurred. Please try again.',
/// );
/// ```
class GlobalErrorHandler {
  static final _instance = GlobalErrorHandler._internal();

  factory GlobalErrorHandler() => _instance;

  GlobalErrorHandler._internal();

  static bool _initialized = false;
  static File? _logFile;
  static final Set<String> _reportedErrors = {};

  /// Initialize the error handler. Call once at app startup.
  static Future<void> init({
    required String sentryDsn,
    required String environment,
  }) async {
    if (_initialized) return;

    try {
      // 1. Initialize Sentry
      await Sentry.init(
        (options) {
          options.dsn = sentryDsn;
          options.environment = environment;
          options.tracesSampleRate = environment == 'production' ? 0.1 : 1.0;
          options.attachStacktrace = true;
          options.maxBreadcrumbs = environment == 'production' ? 50 : 100;

          // Custom beforeSend for filtering
          options.beforeSend = _beforeSendToSentry;
        },
      );

      // 2. Set up Flutter error handling
      FlutterError.onError = _handleFlutterError;

      // 3. Initialize local logging
      await _initLocalLogging();

      _initialized = true;
      AppLogger.info('GlobalErrorHandler initialized');
    } catch (e) {
      debugPrint('Failed to initialize GlobalErrorHandler: $e');
      rethrow;
    }
  }

  /// Report an error to Sentry and log locally.
  ///
  /// [error] — the exception object
  /// [stackTrace] — optional stack trace
  /// [userMessage] — human-readable message to show the user
  static void reportError(
    Object error, {
    StackTrace? stackTrace,
    String? userMessage,
  }) {
    if (!_initialized) {
      AppLogger.warning('GlobalErrorHandler not initialized, logging locally only');
    }

    final severity = _getSeverity(error);
    final category = _getCategory(error);

    // Always log locally
    _logLocally(error, stackTrace, severity, category);

    // Only report to Sentry for warning and above
    if (severity.index >= ErrorSeverity.warning.index) {
      _reportToSentry(error, stackTrace, severity, category, userMessage);
    }
  }

  /// Get the current device ID for tracking.
  static Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown-ios';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      }
      return 'unknown-device';
    } catch (e) {
      return 'device-id-error';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> _initLocalLogging() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${docDir.path}/logs');

      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final dateStr = DateTime.now().toIso8601String().split('T').first;
      _logFile = File('${logDir.path}/error_$dateStr.log');

      AppLogger.debug('Local logging initialized at ${_logFile!.path}');
    } catch (e) {
      debugPrint('Failed to initialize local logging: $e');
    }
  }

  static void _logLocally(
    Object error,
    StackTrace? stackTrace,
    ErrorSeverity severity,
    ErrorCategory category,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = [
      '[$timestamp] [$severity] [$category] $error',
      if (stackTrace != null) stackTrace.toString(),
      '---',
    ].join('\n');

    // Write to file
    try {
      _logFile?.writeAsStringSync('$logEntry\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }

    // Also log to console in debug mode
    debugPrint(logEntry);
  }

  static void _reportToSentry(
    Object error,
    StackTrace? stackTrace,
    ErrorSeverity severity,
    ErrorCategory category,
    String? userMessage,
  ) {
    // Check for duplicates (simple deduplication within this session)
    final errorKey = '${error.runtimeType}::${error.toString()}';
    if (_reportedErrors.contains(errorKey)) {
      return; // Already reported recently
    }
    _reportedErrors.add(errorKey);

    // Limit set size to avoid memory bloat
    if (_reportedErrors.length > 100) {
      _reportedErrors.clear();
    }

    try {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'severity': severity.name,
          'category': category.name,
          'user_message': userMessage,
        }),
      );
    } catch (e) {
      debugPrint('Failed to report error to Sentry: $e');
    }
  }

  static SentryEvent? _beforeSendToSentry(SentryEvent event, Hint hint) {
    // 1. Filter sensitive headers
    final headers = Map<String, String>.from(event.request?.headers ?? {})
      ..remove('Authorization')
      ..remove('X-API-Key');
    final request = event.request?.copyWith(headers: headers);

    // 2. Build updated tags
    final tags = Map<String, String>.from(event.tags ?? {});
    if (hint.get('category') is String) {
      tags['error_category'] = hint.get('category') as String;
    }

    // 3. Resolve level from hint
    final level = SentryLevel.fromName(
      hint.get('severity')?.toString() ?? 'error',
    );

    return event.copyWith(
      request: request,
      level: level,
      tags: tags,
    );
  }

  static void _handleFlutterError(FlutterErrorDetails details) {
    reportError(
      details.exception,
      stackTrace: details.stack,
      userMessage: '应用发生错误，我们已记录此问题',
    );

    // Optional: re-throw to show red error box in debug
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  static ErrorSeverity _getSeverity(Object error) {
    return switch (error) {
      NetworkException() => ErrorSeverity.warning,
      AuthException() => ErrorSeverity.error,
      BusinessException() => ErrorSeverity.warning,
      ValidationException() => ErrorSeverity.warning,
      SecurityException() => ErrorSeverity.critical,
      StorageException() => ErrorSeverity.error,
      _ => ErrorSeverity.critical,
    };
  }

  static ErrorCategory _getCategory(Object error) {
    return switch (error) {
      NetworkException() => ErrorCategory.network,
      AuthException() => ErrorCategory.auth,
      ValidationException() => ErrorCategory.validation,
      BusinessException() => ErrorCategory.business,
      StorageException() => ErrorCategory.database,
      SecurityException() => ErrorCategory.platform,
      _ => ErrorCategory.unknown,
    };
  }
}
