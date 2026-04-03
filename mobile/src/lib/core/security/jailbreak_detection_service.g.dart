// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jailbreak_detection_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(jailbreakDetectionService)
final jailbreakDetectionServiceProvider = JailbreakDetectionServiceProvider._();

final class JailbreakDetectionServiceProvider
    extends
        $FunctionalProvider<
          JailbreakDetectionService,
          JailbreakDetectionService,
          JailbreakDetectionService
        >
    with $Provider<JailbreakDetectionService> {
  JailbreakDetectionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jailbreakDetectionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jailbreakDetectionServiceHash();

  @$internal
  @override
  $ProviderElement<JailbreakDetectionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  JailbreakDetectionService create(Ref ref) {
    return jailbreakDetectionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(JailbreakDetectionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<JailbreakDetectionService>(value),
    );
  }
}

String _$jailbreakDetectionServiceHash() =>
    r'a85b445dd9082a17c4d10457befc841dad473990';
