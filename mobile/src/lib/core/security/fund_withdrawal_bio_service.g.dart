// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_withdrawal_bio_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fundWithdrawalBioService)
final fundWithdrawalBioServiceProvider = FundWithdrawalBioServiceProvider._();

final class FundWithdrawalBioServiceProvider
    extends
        $FunctionalProvider<
          FundWithdrawalBioService,
          FundWithdrawalBioService,
          FundWithdrawalBioService
        >
    with $Provider<FundWithdrawalBioService> {
  FundWithdrawalBioServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fundWithdrawalBioServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fundWithdrawalBioServiceHash();

  @$internal
  @override
  $ProviderElement<FundWithdrawalBioService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FundWithdrawalBioService create(Ref ref) {
    return fundWithdrawalBioService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FundWithdrawalBioService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FundWithdrawalBioService>(value),
    );
  }
}

String _$fundWithdrawalBioServiceHash() =>
    r'37907b11455b7645a22c63f25a2eea25e200b370';
