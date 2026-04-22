// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nonce_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nonceService)
final nonceServiceProvider = NonceServiceProvider._();

final class NonceServiceProvider
    extends $FunctionalProvider<NonceService, NonceService, NonceService>
    with $Provider<NonceService> {
  NonceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nonceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nonceServiceHash();

  @$internal
  @override
  $ProviderElement<NonceService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NonceService create(Ref ref) {
    return nonceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NonceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NonceService>(value),
    );
  }
}

String _$nonceServiceHash() => r'9423788b6623aa8ea9ded52b5b0effbdeef80baf';
