import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'market_status.dart';

part 'mover_item.freezed.dart';

/// A single entry in the gainers / losers / hot movers list.
///
/// Price fields use [Decimal] — never float (financial-coding-standards §Rule 1).
/// Field definitions match market-api-spec §6.3 items[i].
@freezed
abstract class MoverItem with _$MoverItem {
  const factory MoverItem({
    /// 1-based ranking position.
    required int rank,

    required String symbol,
    required String name,

    /// Company Chinese name. Empty string if not available.
    required String nameZh,

    required Decimal price,
    required Decimal change,

    /// Percentage change (2 decimal places, signed).
    required Decimal changePct,

    /// Daily volume (shares).
    required int volume,

    /// Daily turnover with unit suffix, e.g. "33.31B". Kept as String.
    required String turnover,

    required MarketStatus marketStatus,
  }) = _MoverItem;
}
