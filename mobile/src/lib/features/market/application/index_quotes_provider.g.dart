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
          AsyncValue<Map<String, Quote>>,
          Map<String, Quote>,
          FutureOr<Map<String, Quote>>
        >
    with
        $FutureModifier<Map<String, Quote>>,
        $FutureProvider<Map<String, Quote>> {
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
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indexQuotesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Quote>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Quote>> create(Ref ref) {
    return indexQuotes(ref);
  }
}

String _$indexQuotesHash() => r'aafd659799a75b00813fdd2917e3b988f3ad8de4';
