import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/usecases/index.dart';
import 'auth_repository_impl.dart';

part 'auth_usecase_providers.g.dart';

/// Provider for [SendOtpUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call
@riverpod
SendOtpUseCase sendOtpUseCase(SendOtpUseCaseRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendOtpUseCase(repository);
}

/// Provider for [VerifyOtpUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call
@riverpod
VerifyOtpUseCase verifyOtpUseCase(VerifyOtpUseCaseRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return VerifyOtpUseCase(repository);
}

/// Provider for [RefreshTokenUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call
@riverpod
RefreshTokenUseCase refreshTokenUseCase(RefreshTokenUseCaseRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RefreshTokenUseCase(repository);
}
