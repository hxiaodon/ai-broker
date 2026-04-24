import 'package:decimal/decimal.dart';

import '../../../trading/domain/entities/position.dart';
import '../../domain/entities/position_detail.dart';
import '../../domain/entities/trade_record.dart';
import 'models/position_detail_model.dart';
import 'models/trade_record_model.dart';

// ─── Safe parse helpers ───────────────────────────────────────────────────────

Decimal _parseDecimal(String? raw, String field) {
  if (raw == null || raw.isEmpty) {
    throw FormatException('Missing required field: $field');
  }
  return Decimal.tryParse(raw) ??
      (throw FormatException('Invalid decimal for $field: "$raw"'));
}

DateTime _parseUtcDateTime(String? raw, String field) {
  if (raw == null || raw.isEmpty) {
    throw FormatException('Missing required field: $field');
  }
  try {
    return DateTime.parse(raw).toUtc();
  } catch (_) {
    throw FormatException('Invalid datetime for $field: "$raw"');
  }
}

TradeSide _parseTradeSide(String raw) {
  return switch (raw.toUpperCase()) {
    'BUY' => TradeSide.buy,
    'SELL' => TradeSide.sell,
    _ => throw FormatException('Unknown trade side: "$raw"'),
  };
}

// ─── Mappers ──────────────────────────────────────────────────────────────────

extension TradeRecordModelMapper on TradeRecordModel {
  TradeRecord toDomain() => TradeRecord(
        tradeId: tradeId,
        side: _parseTradeSide(side),
        qty: qty,
        price: _parseDecimal(price, 'price'),
        amount: _parseDecimal(amount, 'amount'),
        fee: _parseDecimal(fee, 'fee'),
        executedAt: _parseUtcDateTime(executedAt, 'executed_at'),
        washSale: washSale,
      );
}

extension PositionDetailModelMapper on PositionDetailModel {
  PositionDetail toDomain() => PositionDetail(
        symbol: symbol,
        companyName: companyName,
        market: market,
        sector: sector,
        qty: qty,
        availableQty: availableQty,
        avgCost: _parseDecimal(avgCost, 'avg_cost'),
        currentPrice: _parseDecimal(currentPrice, 'current_price'),
        marketValue: _parseDecimal(marketValue, 'market_value'),
        unrealizedPnl: _parseDecimal(unrealizedPnl, 'unrealized_pnl'),
        unrealizedPnlPct: _parseDecimal(unrealizedPnlPct, 'unrealized_pnl_pct'),
        todayPnl: _parseDecimal(todayPnl, 'today_pnl'),
        todayPnlPct: _parseDecimal(todayPnlPct, 'today_pnl_pct'),
        realizedPnl: _parseDecimal(realizedPnl, 'realized_pnl'),
        costBasis: _parseDecimal(costBasis, 'cost_basis'),
        washSaleFlagged: washSaleStatus == 'flagged',
        pendingSettlements: pendingSettlements
            .map((s) => PendingSettlement(
                  qty: s.qty,
                  settleDate: _parseUtcDateTime(s.settleDate, 'settle_date'),
                ))
            .toList(),
        recentTrades: recentTrades.map((t) => t.toDomain()).toList(),
      );
}
