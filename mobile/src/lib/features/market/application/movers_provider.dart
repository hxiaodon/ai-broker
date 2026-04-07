import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/market_data_repository_impl.dart';
import '../domain/entities/mover_item.dart';

part 'movers_provider.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mover type constants
// ─────────────────────────────────────────────────────────────────────────────

/// Available mover list types from market-api-spec §6.1.
class MoverType {
  MoverType._();

  static const mostActive = 'most_active';
  static const gainers = 'gainers';
  static const losers = 'losers';
}

// ─────────────────────────────────────────────────────────────────────────────
// moversProvider
// ─────────────────────────────────────────────────────────────────────────────

/// Fetches a ranked mover list for the given [type] and [market].
///
/// Family parameter: `(type, market)` pair.
/// Types: [MoverType.mostActive], [MoverType.gainers], [MoverType.losers].
///
/// The provider is autoDispose so each tab page refreshes on navigation.
@riverpod
Future<List<MoverItem>> movers(
  Ref ref, {
  required String type,
  String market = 'US',
}) async {
  final repo = ref.read(marketDataRepositoryProvider);
  return repo.getMovers(type: type, market: market);
}
