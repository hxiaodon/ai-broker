import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../trading/application/positions_provider.dart';
import '../domain/entities/position_detail.dart';
import '../domain/entities/sector_allocation.dart';
import 'position_detail_provider.dart';

part 'sector_allocation_provider.g.dart';

/// Loads all position details in parallel and aggregates by sector.
/// Only active when the analysis tab is visible (autoDispose).
///
/// Individual position detail failures are tolerated — the allocation is
/// computed from whichever positions succeeded (graceful degradation).
@riverpod
Future<List<SectorAllocation>> sectorAllocation(Ref ref) async {
  final positions = await ref.watch(positionsProvider.future);
  if (positions.isEmpty) return [];

  final futures = positions
      .map((p) => ref.watch(positionDetailProvider(p.symbol).future)
          .then<PositionDetail?>((d) => d)
          .catchError((Object _) => null))
      .toList();

  final results = await Future.wait(futures);

  final totals = <String, Decimal>{};
  for (final detail in results) {
    if (detail != null) {
      totals[detail.sector] =
          (totals[detail.sector] ?? Decimal.zero) + detail.marketValue;
    }
  }

  if (totals.isEmpty) return [];

  final total = totals.values.fold(Decimal.zero, (a, b) => a + b);
  if (total == Decimal.zero) return [];

  return totals.entries
      .map((e) => SectorAllocation(
            sector: e.key,
            marketValue: e.value,
            weight: Decimal.parse(
                (e.value / total).toDecimal(scaleOnInfinitePrecision: 6).toString()),
          ))
      .toList()
    ..sort((a, b) => b.marketValue.compareTo(a.marketValue));
}
