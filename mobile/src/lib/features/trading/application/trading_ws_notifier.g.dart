// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_ws_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TradingWsNotifier)
final tradingWsProvider = TradingWsNotifierProvider._();

final class TradingWsNotifierProvider
    extends $AsyncNotifierProvider<TradingWsNotifier, void> {
  TradingWsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tradingWsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tradingWsNotifierHash();

  @$internal
  @override
  TradingWsNotifier create() => TradingWsNotifier();
}

String _$tradingWsNotifierHash() => r'56aaba9e43b191d9caeef79d25353a717ba0937f';

abstract class _$TradingWsNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
