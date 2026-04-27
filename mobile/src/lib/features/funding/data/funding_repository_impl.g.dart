// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'funding_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fundingRepository)
final fundingRepositoryProvider = FundingRepositoryProvider._();

final class FundingRepositoryProvider
    extends
        $FunctionalProvider<
          FundingRepository,
          FundingRepository,
          FundingRepository
        >
    with $Provider<FundingRepository> {
  FundingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fundingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fundingRepositoryHash();

  @$internal
  @override
  $ProviderElement<FundingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FundingRepository create(Ref ref) {
    return fundingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FundingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FundingRepository>(value),
    );
  }
}

String _$fundingRepositoryHash() => r'6797affcd802f5f7cc850901ddbd57b6e1743254';
