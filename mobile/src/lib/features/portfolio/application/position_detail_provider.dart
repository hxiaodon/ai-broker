import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../trading/application/positions_provider.dart';
import '../../trading/domain/entities/position.dart';
import '../data/portfolio_repository_impl.dart';
import '../domain/entities/position_detail.dart';

part 'position_detail_provider.g.dart';

/// Private provider: performs the REST fetch only.
/// Cached independently so WS overlay rebuilds do not re-trigger the network call.
@riverpod
Future<PositionDetail> _positionDetailRest(Ref ref, String symbol) =>
    ref.watch(portfolioRepositoryProvider).getPositionDetail(symbol);

/// Public provider: overlays real-time WS data on top of the cached REST result.
///
/// Watches [_positionDetailRestProvider] for the REST fetch, then synchronously
/// reads [positionsProvider] as an AsyncValue (no await) to apply the WS overlay.
/// This separates the two concerns: the REST provider rebuilds only on explicit
/// invalidation, while WS updates rebuild this provider without re-fetching REST.
@riverpod
Future<PositionDetail> positionDetail(Ref ref, String symbol) async {
  final detail = await ref.watch(_positionDetailRestProvider(symbol).future);

  final wsPosition = ref
      .watch(positionsProvider)
      .asData
      ?.value
      .where((Position p) => p.symbol == symbol)
      .firstOrNull;

  if (wsPosition != null) {
    return detail.copyWith(
      currentPrice: wsPosition.currentPrice,
      marketValue: wsPosition.marketValue,
      unrealizedPnl: wsPosition.unrealizedPnl,
      unrealizedPnlPct: wsPosition.unrealizedPnlPct,
      todayPnl: wsPosition.todayPnl,
      todayPnlPct: wsPosition.todayPnlPct,
      qty: wsPosition.qty,
      availableQty: wsPosition.availableQty,
      pendingSettlements: wsPosition.pendingSettlements,
    );
  }

  return detail;
}
