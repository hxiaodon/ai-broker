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
/// JWT is injected by [AuthInterceptor] via [createAuthenticatedDio].

@ProviderFor(marketDataRepository)
final marketDataRepositoryProvider = MarketDataRepositoryProvider._();

/// Wires up [MarketDataRepositoryImpl] with its [MarketRemoteDataSource].
///
/// Uses a dedicated Dio instance for the market-data service.
/// JWT is injected by [AuthInterceptor] via [createAuthenticatedDio].

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
  /// JWT is injected by [AuthInterceptor] via [createAuthenticatedDio].
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
    r'f6e0e7ae5d441abfa523a7b37cd9c9fe3532788b';
