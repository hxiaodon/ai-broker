import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../trading/domain/entities/position.dart';
import 'trade_record.dart';

part 'position_detail.freezed.dart';

@freezed
abstract class PositionDetail with _$PositionDetail {
  const factory PositionDetail({
    required String symbol,
    required String companyName,
    required String market,
    required String sector,
    required int qty,
    required int availableQty,
    required Decimal avgCost,
    required Decimal currentPrice,
    required Decimal marketValue,
    required Decimal unrealizedPnl,
    required Decimal unrealizedPnlPct,
    required Decimal todayPnl,
    required Decimal todayPnlPct,
    required Decimal realizedPnl,
    required Decimal costBasis,
    @Default(false) bool washSaleFlagged,
    @Default([]) List<PendingSettlement> pendingSettlements,
    @Default([]) List<TradeRecord> recentTrades,
  }) = _PositionDetail;
}
