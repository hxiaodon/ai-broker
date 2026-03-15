/// Domain-level failure types mapped from [AppException].
///
/// Use [Failure] in repository interfaces and use-case return types
/// so the domain layer remains decoupled from infrastructure exceptions.
library;

sealed class Failure {
  const Failure({required this.message});

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, this.statusCode});
  final int? statusCode;
}

final class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    required this.statusCode,
    this.errorCode,
  });
  final int statusCode;
  final String? errorCode;
}

final class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

final class BusinessFailure extends Failure {
  const BusinessFailure({required super.message, this.errorCode});
  final String? errorCode;
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, this.field});
  final String? field;
}

final class StorageFailure extends Failure {
  const StorageFailure({required super.message});
}

final class SecurityFailure extends Failure {
  const SecurityFailure({required super.message});
}

final class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}
