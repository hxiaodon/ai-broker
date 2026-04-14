import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/errors/error_category.dart';
import 'package:trading_app/core/errors/error_severity.dart';
import 'package:trading_app/core/errors/app_exception.dart';

void main() {
  group('ErrorSeverity', () {
    test('has all required severity levels', () {
      expect(ErrorSeverity.values.length, 4);
      expect(ErrorSeverity.values, containsAll([
        ErrorSeverity.info,
        ErrorSeverity.warning,
        ErrorSeverity.error,
        ErrorSeverity.critical,
      ]));
    });

    test('converts to Sentry severity levels correctly', () {
      expect(ErrorSeverity.info.toSentryLevel(), 'info');
      expect(ErrorSeverity.warning.toSentryLevel(), 'warning');
      expect(ErrorSeverity.error.toSentryLevel(), 'error');
      expect(ErrorSeverity.critical.toSentryLevel(), 'fatal');
    });

    test('maintains index ordering for severity comparison', () {
      expect(ErrorSeverity.info.index, 0);
      expect(ErrorSeverity.warning.index, 1);
      expect(ErrorSeverity.error.index, 2);
      expect(ErrorSeverity.critical.index, 3);
    });
  });

  group('ErrorCategory', () {
    test('has all required error categories', () {
      expect(ErrorCategory.values.length, 7);
      expect(ErrorCategory.values, containsAll([
        ErrorCategory.network,
        ErrorCategory.auth,
        ErrorCategory.validation,
        ErrorCategory.business,
        ErrorCategory.database,
        ErrorCategory.platform,
        ErrorCategory.unknown,
      ]));
    });

    test('provides display names for all categories', () {
      expect(ErrorCategory.network.displayName, '网络错误');
      expect(ErrorCategory.auth.displayName, '认证错误');
      expect(ErrorCategory.validation.displayName, '验证错误');
      expect(ErrorCategory.business.displayName, '业务错误');
      expect(ErrorCategory.database.displayName, '数据库错误');
      expect(ErrorCategory.platform.displayName, '平台错误');
      expect(ErrorCategory.unknown.displayName, '未知错误');
    });
  });

  group('AppException hierarchy', () {
    test('NetworkException can be instantiated with status code', () {
      const error = NetworkException(
        message: 'Network error',
        statusCode: 500,
      );
      expect(error.message, 'Network error');
      expect(error.statusCode, 500);
      expect(error.toString(), contains('NetworkException'));
    });

    test('AuthException can be instantiated', () {
      const error = AuthException(message: 'Auth error');
      expect(error.message, 'Auth error');
      expect(error.toString(), contains('AuthException'));
    });

    test('BusinessException stores error code', () {
      const error = BusinessException(
        message: 'Business error',
        errorCode: 'INSUFFICIENT_BALANCE',
      );
      expect(error.errorCode, 'INSUFFICIENT_BALANCE');
      expect(error.toString(), contains('BusinessException'));
    });

    test('ValidationException stores field name', () {
      const error = ValidationException(
        message: 'Validation error',
        field: 'phoneNumber',
      );
      expect(error.field, 'phoneNumber');
      expect(error.toString(), contains('ValidationException'));
    });

    test('OtpAuthException stores OTP metadata', () {
      final lockoutTime = DateTime.now().add(const Duration(minutes: 5));
      final error = OtpAuthException(
        message: 'OTP verification failed',
        errorCode: 'INVALID_OTP',
        remainingAttempts: 2,
        lockoutUntil: lockoutTime,
      );

      expect(error.errorCode, 'INVALID_OTP');
      expect(error.remainingAttempts, 2);
      expect(error.lockoutUntil, lockoutTime);
      expect(error.toString(), contains('OtpAuthException'));
    });

    test('WsTokenExpiringException stores expiry time', () {
      const error = WsTokenExpiringException(expiresInSeconds: 300);
      expect(error.expiresInSeconds, 300);
      expect(error.message, 'WS token expiring in 300s');
      expect(error.toString(), contains('WsTokenExpiringException'));
    });

    test('SecurityException indicates security violation', () {
      const error = SecurityException(message: 'Jailbreak detected');
      expect(error.message, 'Jailbreak detected');
      expect(error.toString(), contains('SecurityException'));
    });

    test('StorageException indicates storage failure', () {
      const error = StorageException(message: 'Database error');
      expect(error.message, 'Database error');
      expect(error.toString(), contains('StorageException'));
    });

    test('UnknownException is for unexpected errors', () {
      const error = UnknownException(message: 'Unknown error');
      expect(error.message, 'Unknown error');
      expect(error.toString(), contains('UnknownException'));
    });

    test('ServerException stores HTTP status code and error code', () {
      const error = ServerException(
        message: 'Server error',
        statusCode: 500,
        errorCode: 'INTERNAL_ERROR',
      );
      expect(error.statusCode, 500);
      expect(error.errorCode, 'INTERNAL_ERROR');
      expect(error.toString(), contains('ServerException'));
    });
  });

  group('Exception Cause Tracking', () {
    test('exceptions can chain cause information', () {
      const original = NetworkException(message: 'Connection failed');
      const wrapped = NetworkException(
        message: 'Failed to fetch data',
        cause: original,
      );
      expect(wrapped.cause, original);
    });

    test('all exception types support cause parameter', () {
      final original = Exception('Original error');

      expect(
        NetworkException(message: 'msg', cause: original).cause,
        original,
      );
      expect(
        AuthException(message: 'msg', cause: original).cause,
        original,
      );
      expect(
        BusinessException(message: 'msg', cause: original).cause,
        original,
      );
      expect(
        ValidationException(message: 'msg', cause: original).cause,
        original,
      );
      expect(
        StorageException(message: 'msg', cause: original).cause,
        original,
      );
      expect(
        SecurityException(message: 'msg', cause: original).cause,
        original,
      );
    });
  });

  group('Error Severity Ordering', () {
    test('info severity has lowest index', () {
      expect(ErrorSeverity.info.index, lessThan(ErrorSeverity.warning.index));
      expect(ErrorSeverity.info.index, lessThan(ErrorSeverity.error.index));
      expect(ErrorSeverity.info.index, lessThan(ErrorSeverity.critical.index));
    });

    test('critical severity has highest index', () {
      expect(ErrorSeverity.critical.index, greaterThan(ErrorSeverity.warning.index));
      expect(ErrorSeverity.critical.index, greaterThan(ErrorSeverity.error.index));
      expect(ErrorSeverity.critical.index, greaterThan(ErrorSeverity.info.index));
    });
  });

  group('Error Category Classification', () {
    test('network errors map to network category', () {
      expect(ErrorCategory.network.name, 'network');
      expect(ErrorCategory.network.displayName, '网络错误');
    });

    test('auth errors map to auth category', () {
      expect(ErrorCategory.auth.name, 'auth');
      expect(ErrorCategory.auth.displayName, '认证错误');
    });

    test('validation errors map to validation category', () {
      expect(ErrorCategory.validation.name, 'validation');
      expect(ErrorCategory.validation.displayName, '验证错误');
    });

    test('business errors map to business category', () {
      expect(ErrorCategory.business.name, 'business');
      expect(ErrorCategory.business.displayName, '业务错误');
    });

    test('storage errors map to database category', () {
      expect(ErrorCategory.database.name, 'database');
      expect(ErrorCategory.database.displayName, '数据库错误');
    });

    test('platform errors map to platform category', () {
      expect(ErrorCategory.platform.name, 'platform');
      expect(ErrorCategory.platform.displayName, '平台错误');
    });

    test('unknown category is for unclassified errors', () {
      expect(ErrorCategory.unknown.name, 'unknown');
      expect(ErrorCategory.unknown.displayName, '未知错误');
    });
  });
}
