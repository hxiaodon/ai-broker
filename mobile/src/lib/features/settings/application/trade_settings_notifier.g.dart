// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages trading preferences stored locally in SharedPreferences.

@ProviderFor(TradeSettingsNotifier)
final tradeSettingsProvider = TradeSettingsNotifierProvider._();

/// Manages trading preferences stored locally in SharedPreferences.
final class TradeSettingsNotifierProvider
    extends $AsyncNotifierProvider<TradeSettingsNotifier, TradeSettings> {
  /// Manages trading preferences stored locally in SharedPreferences.
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
    r'd72aa408e0e96d002805d523ae07fa4fbb481fff';

/// Manages trading preferences stored locally in SharedPreferences.

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
