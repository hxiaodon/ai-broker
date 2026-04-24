import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../trading/application/positions_provider.dart';
import '../data/portfolio_repository_impl.dart';
import '../domain/entities/position_detail.dart';

part 'position_detail_provider.g.dart';

@riverpod
Future<PositionDetail> positionDetail(Ref ref, String symbol) async {
  final detail =
      await ref.watch(portfolioRepositoryProvider).getPositionDetail(symbol);

  // Overlay real-time price / P&L from WS position updates
  final positions = await ref.watch(positionsProvider.future);
  final wsPosition =
      positions.where((p) => p.symbol == symbol).firstOrNull;

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
