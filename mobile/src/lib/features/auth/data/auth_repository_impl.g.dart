// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wires up [AuthRepositoryImpl] with all required dependencies.
///
/// - Creates a dedicated [Dio] instance for the AMS service (SPKI pinned).
/// - Injects [TokenService], [DeviceInfoService], [SecureStorageService].

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Wires up [AuthRepositoryImpl] with all required dependencies.
///
/// - Creates a dedicated [Dio] instance for the AMS service (SPKI pinned).
/// - Injects [TokenService], [DeviceInfoService], [SecureStorageService].

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Wires up [AuthRepositoryImpl] with all required dependencies.
  ///
  /// - Creates a dedicated [Dio] instance for the AMS service (SPKI pinned).
  /// - Injects [TokenService], [DeviceInfoService], [SecureStorageService].
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'c52b409c6bede34a0543644e0a3b141973216a87';
