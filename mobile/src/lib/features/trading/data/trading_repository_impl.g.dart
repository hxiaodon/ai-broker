// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tradingRepository)
final tradingRepositoryProvider = TradingRepositoryProvider._();

final class TradingRepositoryProvider
    extends
        $FunctionalProvider<
          TradingRepository,
          TradingRepository,
          TradingRepository
        >
    with $Provider<TradingRepository> {
  TradingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tradingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tradingRepositoryHash();

  @$internal
  @override
  $ProviderElement<TradingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TradingRepository create(Ref ref) {
    return tradingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TradingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TradingRepository>(value),
    );
  }
}

String _$tradingRepositoryHash() => r'0acd5590d8ecaa896b962d9025a3ce181116613c';
