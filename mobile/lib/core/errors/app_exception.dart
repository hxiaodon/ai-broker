/// Application-level exception hierarchy.
///
/// All exceptions thrown within the app derive from [AppException].
/// Use sealed class pattern to force exhaustive handling at call sites.
library;

sealed class AppException implements Exception {
  const AppException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Network-level errors (HTTP, timeout, no connectivity).
final class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.cause,
    this.statusCode,
  });

  final int? statusCode;
}

/// Server returned an error response (4xx / 5xx with body).
final class ServerException extends AppException {
  const ServerException({
    required super.message,
    required this.statusCode,
    super.cause,
    this.errorCode,
  });

  final int statusCode;
  final String? errorCode;
}

/// Authentication / authorisation errors (401, 403, token expired).
final class AuthException extends AppException {
  const AuthException({required super.message, super.cause});
}

/// Business rule violations (insufficient balance, settlement lock, etc.).
final class BusinessException extends AppException {
  const BusinessException({
    required super.message,
    super.cause,
    this.errorCode,
  });

  final String? errorCode;
}

/// Input validation errors at the client side.
final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.cause,
    this.field,
  });

  final String? field;
}

/// Local storage read/write failures.
final class StorageException extends AppException {
  const StorageException({required super.message, super.cause});
}

/// Security policy violations (jailbreak detected, certificate mismatch, etc.).
final class SecurityException extends AppException {
  const SecurityException({required super.message, super.cause});
}

/// Unexpected / unknown errors that don't fit other categories.
final class UnknownException extends AppException {
  const UnknownException({required super.message, super.cause});
}
