// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kycRemoteDataSource)
final kycRemoteDataSourceProvider = KycRemoteDataSourceProvider._();

final class KycRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          KycRemoteDataSource,
          KycRemoteDataSource,
          KycRemoteDataSource
        >
    with $Provider<KycRemoteDataSource> {
  KycRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kycRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kycRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<KycRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KycRemoteDataSource create(Ref ref) {
    return kycRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KycRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KycRemoteDataSource>(value),
    );
  }
}

String _$kycRemoteDataSourceHash() =>
    r'86039a7c2ac11a7cd08f268b62de271e838f4f3d';

@ProviderFor(kycRepository)
final kycRepositoryProvider = KycRepositoryProvider._();

final class KycRepositoryProvider
    extends $FunctionalProvider<KycRepository, KycRepository, KycRepository>
    with $Provider<KycRepository> {
  KycRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kycRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kycRepositoryHash();

  @$internal
  @override
  $ProviderElement<KycRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KycRepository create(Ref ref) {
    return kycRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KycRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KycRepository>(value),
    );
  }
}

String _$kycRepositoryHash() => r'e0ab3ce60dad36e70078092cabc5a889e7727d6f';
