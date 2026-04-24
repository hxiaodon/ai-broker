import 'package:decimal/decimal.dart';

import '../../../trading/domain/entities/position.dart';
import '../../domain/entities/position_detail.dart';
import '../../domain/entities/trade_record.dart';
import 'models/position_detail_model.dart';
import 'models/trade_record_model.dart';

extension TradeRecordModelMapper on TradeRecordModel {
  TradeRecord toDomain() => TradeRecord(
        tradeId: tradeId,
        side: side.toUpperCase() == 'BUY' ? TradeSide.buy : TradeSide.sell,
        qty: qty,
        price: Decimal.parse(price),
        amount: Decimal.parse(amount),
        fee: Decimal.parse(fee),
        executedAt: DateTime.parse(executedAt).toUtc(),
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
        avgCost: Decimal.parse(avgCost),
        currentPrice: Decimal.parse(currentPrice),
        marketValue: Decimal.parse(marketValue),
        unrealizedPnl: Decimal.parse(unrealizedPnl),
        unrealizedPnlPct: Decimal.parse(unrealizedPnlPct),
        todayPnl: Decimal.parse(todayPnl),
        todayPnlPct: Decimal.parse(todayPnlPct),
        realizedPnl: Decimal.parse(realizedPnl),
        costBasis: Decimal.parse(costBasis),
        washSaleFlagged: washSaleStatus == 'flagged',
        pendingSettlements: pendingSettlements
            .map((s) => PendingSettlement(
                  qty: s.qty,
                  settleDate: DateTime.parse(s.settleDate).toUtc(),
                ))
            .toList(),
        recentTrades: recentTrades.map((t) => t.toDomain()).toList(),
      );
}
