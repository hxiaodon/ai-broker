import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'position.freezed.dart';

@freezed
abstract class PendingSettlement with _$PendingSettlement {
  const factory PendingSettlement({
    required int qty,
    required DateTime settleDate,
  }) = _PendingSettlement;
}

@freezed
abstract class Position with _$Position {
  const factory Position({
    required String symbol,
    required String market,
    required int qty,
    required int availableQty,
    required Decimal avgCost,
    required Decimal currentPrice,
    required Decimal marketValue,
    required Decimal unrealizedPnl,
    required Decimal unrealizedPnlPct,
    required Decimal todayPnl,
    required Decimal todayPnlPct,
    @Default([]) List<PendingSettlement> pendingSettlements,
  }) = _Position;
}
