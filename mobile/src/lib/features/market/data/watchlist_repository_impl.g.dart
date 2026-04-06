// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(watchlistRepository)
final watchlistRepositoryProvider = WatchlistRepositoryProvider._();

final class WatchlistRepositoryProvider
    extends
        $FunctionalProvider<
          WatchlistRepositoryImpl,
          WatchlistRepositoryImpl,
          WatchlistRepositoryImpl
        >
    with $Provider<WatchlistRepositoryImpl> {
  WatchlistRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchlistRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchlistRepositoryHash();

  @$internal
  @override
  $ProviderElement<WatchlistRepositoryImpl> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchlistRepositoryImpl create(Ref ref) {
    return watchlistRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchlistRepositoryImpl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchlistRepositoryImpl>(value),
    );
  }
}

String _$watchlistRepositoryHash() =>
    r'7d274ce51186136863ce26b15a65e74fbc84363c';
