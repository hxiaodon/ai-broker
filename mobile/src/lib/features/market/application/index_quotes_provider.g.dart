// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_quotes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
///
/// Independent of [watchlistProvider] to avoid loading delays.
/// These are always fetched on app startup for the index banner.

@ProviderFor(indexQuotes)
final indexQuotesProvider = IndexQuotesProvider._();

/// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
///
/// Independent of [watchlistProvider] to avoid loading delays.
/// These are always fetched on app startup for the index banner.

final class IndexQuotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Quote>>,
          List<Quote>,
          FutureOr<List<Quote>>
        >
    with $FutureModifier<List<Quote>>, $FutureProvider<List<Quote>> {
  /// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
  ///
  /// Independent of [watchlistProvider] to avoid loading delays.
  /// These are always fetched on app startup for the index banner.
  IndexQuotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indexQuotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indexQuotesHash();

  @$internal
  @override
  $FutureProviderElement<List<Quote>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Quote>> create(Ref ref) {
    return indexQuotes(ref);
  }
}

String _$indexQuotesHash() => r'03a601e3ec63945e6d25533b5c440c62693e21e7';
