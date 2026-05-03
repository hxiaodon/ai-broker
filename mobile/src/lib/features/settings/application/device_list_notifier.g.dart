// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the list of bound devices and supports remote device revocation.

@ProviderFor(DeviceListNotifier)
final deviceListProvider = DeviceListNotifierProvider._();

/// Manages the list of bound devices and supports remote device revocation.
final class DeviceListNotifierProvider
    extends $AsyncNotifierProvider<DeviceListNotifier, List<DeviceInfo>> {
  /// Manages the list of bound devices and supports remote device revocation.
  DeviceListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceListNotifierHash();

  @$internal
  @override
  DeviceListNotifier create() => DeviceListNotifier();
}

String _$deviceListNotifierHash() =>
    r'65975e09e6dd284c04568885c19e7b26bddfcd38';

/// Manages the list of bound devices and supports remote device revocation.

abstract class _$DeviceListNotifier extends $AsyncNotifier<List<DeviceInfo>> {
  FutureOr<List<DeviceInfo>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<DeviceInfo>>, List<DeviceInfo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<DeviceInfo>>, List<DeviceInfo>>,
              AsyncValue<List<DeviceInfo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
