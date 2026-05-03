// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'display_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages display preferences (colour scheme) stored in SharedPreferences.
///
/// keepAlive: display settings affect the whole app and must survive navigation.

@ProviderFor(DisplaySettingsNotifier)
final displaySettingsProvider = DisplaySettingsNotifierProvider._();

/// Manages display preferences (colour scheme) stored in SharedPreferences.
///
/// keepAlive: display settings affect the whole app and must survive navigation.
final class DisplaySettingsNotifierProvider
    extends $AsyncNotifierProvider<DisplaySettingsNotifier, DisplaySettings> {
  /// Manages display preferences (colour scheme) stored in SharedPreferences.
  ///
  /// keepAlive: display settings affect the whole app and must survive navigation.
  DisplaySettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'displaySettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$displaySettingsNotifierHash();

  @$internal
  @override
  DisplaySettingsNotifier create() => DisplaySettingsNotifier();
}

String _$displaySettingsNotifierHash() =>
    r'0e894968dcb3088565e95dac56cef9ae6ddad6c8';

/// Manages display preferences (colour scheme) stored in SharedPreferences.
///
/// keepAlive: display settings affect the whole app and must survive navigation.

abstract class _$DisplaySettingsNotifier
    extends $AsyncNotifier<DisplaySettings> {
  FutureOr<DisplaySettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DisplaySettings>, DisplaySettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DisplaySettings>, DisplaySettings>,
              AsyncValue<DisplaySettings>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
