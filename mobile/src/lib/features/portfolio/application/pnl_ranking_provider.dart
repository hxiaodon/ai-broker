import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../trading/application/positions_provider.dart';
import '../../trading/domain/entities/position.dart';

part 'pnl_ranking_provider.g.dart';

/// Derived from live positions — sorted by unrealized P&L.
/// Positions with the largest gain come first; largest loss comes last.
@riverpod
Future<List<Position>> pnlRanking(Ref ref) async {
  final positions = await ref.watch(positionsProvider.future);
  if (positions.isEmpty) return [];
  return [...positions]
    ..sort((a, b) => b.unrealizedPnl.compareTo(a.unrealizedPnl));
}
