// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_data_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wires up [MarketDataRepositoryImpl] with its [MarketRemoteDataSource].
///
/// Uses a dedicated Dio instance for the market-data service.
/// JWT is injected by the global auth interceptor on [DioClient.create].

@ProviderFor(marketDataRepository)
final marketDataRepositoryProvider = MarketDataRepositoryProvider._();

/// Wires up [MarketDataRepositoryImpl] with its [MarketRemoteDataSource].
///
/// Uses a dedicated Dio instance for the market-data service.
/// JWT is injected by the global auth interceptor on [DioClient.create].

final class MarketDataRepositoryProvider
    extends
        $FunctionalProvider<
          MarketDataRepository,
          MarketDataRepository,
          MarketDataRepository
        >
    with $Provider<MarketDataRepository> {
  /// Wires up [MarketDataRepositoryImpl] with its [MarketRemoteDataSource].
  ///
  /// Uses a dedicated Dio instance for the market-data service.
  /// JWT is injected by the global auth interceptor on [DioClient.create].
  MarketDataRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'marketDataRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$marketDataRepositoryHash();

  @$internal
  @override
  $ProviderElement<MarketDataRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarketDataRepository create(Ref ref) {
    return marketDataRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketDataRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketDataRepository>(value),
    );
  }
}

String _$marketDataRepositoryHash() =>
    r'eb81274a2f097284215fa05bd42d0b10837078f6';
