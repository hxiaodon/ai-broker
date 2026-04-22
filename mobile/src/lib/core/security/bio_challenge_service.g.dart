// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bio_challenge_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bioChallengeService)
final bioChallengeServiceProvider = BioChallengeServiceProvider._();

final class BioChallengeServiceProvider
    extends
        $FunctionalProvider<
          BioChallengeService,
          BioChallengeService,
          BioChallengeService
        >
    with $Provider<BioChallengeService> {
  BioChallengeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bioChallengeServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bioChallengeServiceHash();

  @$internal
  @override
  $ProviderElement<BioChallengeService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BioChallengeService create(Ref ref) {
    return bioChallengeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BioChallengeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BioChallengeService>(value),
    );
  }
}

String _$bioChallengeServiceHash() =>
    r'4b812582b0b506dc09927ccc68f9325e9bc9edd1';
