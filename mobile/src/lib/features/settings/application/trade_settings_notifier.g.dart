// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages trading preferences.
/// Non-sensitive fields stored in SharedPreferences; [confirmationMethod]
/// stored in flutter_secure_storage to prevent tampering on rooted devices.

@ProviderFor(TradeSettingsNotifier)
final tradeSettingsProvider = TradeSettingsNotifierProvider._();

/// Manages trading preferences.
/// Non-sensitive fields stored in SharedPreferences; [confirmationMethod]
/// stored in flutter_secure_storage to prevent tampering on rooted devices.
final class TradeSettingsNotifierProvider
    extends $AsyncNotifierProvider<TradeSettingsNotifier, TradeSettings> {
  /// Manages trading preferences.
  /// Non-sensitive fields stored in SharedPreferences; [confirmationMethod]
  /// stored in flutter_secure_storage to prevent tampering on rooted devices.
  TradeSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tradeSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tradeSettingsNotifierHash();

  @$internal
  @override
  TradeSettingsNotifier create() => TradeSettingsNotifier();
}

String _$tradeSettingsNotifierHash() =>
    r'e418d0af1037b8f9718d0a6119cba4d075151ab0';

/// Manages trading preferences.
/// Non-sensitive fields stored in SharedPreferences; [confirmationMethod]
/// stored in flutter_secure_storage to prevent tampering on rooted devices.

abstract class _$TradeSettingsNotifier extends $AsyncNotifier<TradeSettings> {
  FutureOr<TradeSettings> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TradeSettings>, TradeSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TradeSettings>, TradeSettings>,
              AsyncValue<TradeSettings>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
