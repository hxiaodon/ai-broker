// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pnl_ranking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Derived from live positions — sorted by unrealized P&L.
/// Positions with the largest gain come first; largest loss comes last.

@ProviderFor(pnlRanking)
final pnlRankingProvider = PnlRankingProvider._();

/// Derived from live positions — sorted by unrealized P&L.
/// Positions with the largest gain come first; largest loss comes last.

final class PnlRankingProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Position>>,
          List<Position>,
          FutureOr<List<Position>>
        >
    with $FutureModifier<List<Position>>, $FutureProvider<List<Position>> {
  /// Derived from live positions — sorted by unrealized P&L.
  /// Positions with the largest gain come first; largest loss comes last.
  PnlRankingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pnlRankingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pnlRankingHash();

  @$internal
  @override
  $FutureProviderElement<List<Position>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Position>> create(Ref ref) {
    return pnlRanking(ref);
  }
}

String _$pnlRankingHash() => r'a6b074de3455cbbce461feaf22340c711a0664dd';
