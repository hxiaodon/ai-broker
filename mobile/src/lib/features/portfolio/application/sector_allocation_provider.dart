import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../trading/application/positions_provider.dart';
import '../domain/entities/sector_allocation.dart';
import 'position_detail_provider.dart';

part 'sector_allocation_provider.g.dart';

/// Loads all position details in parallel and aggregates by sector.
/// Only active when the analysis tab is visible (autoDispose).
@riverpod
Future<List<SectorAllocation>> sectorAllocation(Ref ref) async {
  final positions = await ref.watch(positionsProvider.future);
  if (positions.isEmpty) return [];

  final details = await Future.wait(
    positions.map((p) => ref.watch(positionDetailProvider(p.symbol).future)),
  );

  final totals = <String, Decimal>{};
  for (final d in details) {
    totals[d.sector] =
        (totals[d.sector] ?? Decimal.zero) + d.marketValue;
  }

  final total = totals.values.fold(Decimal.zero, (a, b) => a + b);
  if (total == Decimal.zero) return [];

  return totals.entries
      .map((e) => SectorAllocation(
            sector: e.key,
            marketValue: e.value,
            weight: Decimal.parse((e.value / total).toDecimal(scaleOnInfinitePrecision: 6).toString()),
          ))
      .toList()
    ..sort((a, b) => b.marketValue.compareTo(a.marketValue));
}
