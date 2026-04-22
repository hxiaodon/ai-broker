// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_key_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sessionKeyService)
final sessionKeyServiceProvider = SessionKeyServiceProvider._();

final class SessionKeyServiceProvider
    extends
        $FunctionalProvider<
          SessionKeyService,
          SessionKeyService,
          SessionKeyService
        >
    with $Provider<SessionKeyService> {
  SessionKeyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionKeyServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionKeyServiceHash();

  @$internal
  @override
  $ProviderElement<SessionKeyService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SessionKeyService create(Ref ref) {
    return sessionKeyService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SessionKeyService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SessionKeyService>(value),
    );
  }
}

String _$sessionKeyServiceHash() => r'14080f4cf15af2cf86e1209ac5982d43ed7858f9';
