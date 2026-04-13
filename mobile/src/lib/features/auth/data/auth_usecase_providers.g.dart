// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_usecase_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [SendOtpUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call

@ProviderFor(sendOtpUseCase)
final sendOtpUseCaseProvider = SendOtpUseCaseProvider._();

/// Provider for [SendOtpUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call

final class SendOtpUseCaseProvider
    extends $FunctionalProvider<SendOtpUseCase, SendOtpUseCase, SendOtpUseCase>
    with $Provider<SendOtpUseCase> {
  /// Provider for [SendOtpUseCase].
  ///
  /// Depends on: [authRepositoryProvider]
  /// Lifetime: stateless, new instance on every call
  SendOtpUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendOtpUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendOtpUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendOtpUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SendOtpUseCase create(Ref ref) {
    return sendOtpUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendOtpUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendOtpUseCase>(value),
    );
  }
}

String _$sendOtpUseCaseHash() => r'8a33c8957052c4536620b85c3d5249e9a14828c5';

/// Provider for [VerifyOtpUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call

@ProviderFor(verifyOtpUseCase)
final verifyOtpUseCaseProvider = VerifyOtpUseCaseProvider._();

/// Provider for [VerifyOtpUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call

final class VerifyOtpUseCaseProvider
    extends
        $FunctionalProvider<
          VerifyOtpUseCase,
          VerifyOtpUseCase,
          VerifyOtpUseCase
        >
    with $Provider<VerifyOtpUseCase> {
  /// Provider for [VerifyOtpUseCase].
  ///
  /// Depends on: [authRepositoryProvider]
  /// Lifetime: stateless, new instance on every call
  VerifyOtpUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyOtpUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyOtpUseCaseHash();

  @$internal
  @override
  $ProviderElement<VerifyOtpUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VerifyOtpUseCase create(Ref ref) {
    return verifyOtpUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifyOtpUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifyOtpUseCase>(value),
    );
  }
}

String _$verifyOtpUseCaseHash() => r'9ce93a0681dba1ac837f08d442354fcc4b4b067d';

/// Provider for [RefreshTokenUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call

@ProviderFor(refreshTokenUseCase)
final refreshTokenUseCaseProvider = RefreshTokenUseCaseProvider._();

/// Provider for [RefreshTokenUseCase].
///
/// Depends on: [authRepositoryProvider]
/// Lifetime: stateless, new instance on every call

final class RefreshTokenUseCaseProvider
    extends
        $FunctionalProvider<
          RefreshTokenUseCase,
          RefreshTokenUseCase,
          RefreshTokenUseCase
        >
    with $Provider<RefreshTokenUseCase> {
  /// Provider for [RefreshTokenUseCase].
  ///
  /// Depends on: [authRepositoryProvider]
  /// Lifetime: stateless, new instance on every call
  RefreshTokenUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'refreshTokenUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$refreshTokenUseCaseHash();

  @$internal
  @override
  $ProviderElement<RefreshTokenUseCase> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RefreshTokenUseCase create(Ref ref) {
    return refreshTokenUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefreshTokenUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefreshTokenUseCase>(value),
    );
  }
}

String _$refreshTokenUseCaseHash() =>
    r'48ef56919375fb9bbfb85ea4a69d86248b4e0ee9';
