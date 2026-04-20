import 'package:decimal/decimal.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_fill.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/position.dart';
import 'models/order_model.dart';
import 'models/portfolio_summary_model.dart';
import 'models/position_model.dart';

extension OrderModelMapper on OrderModel {
  Order toDomain() => Order(
        orderId: orderId,
        symbol: symbol,
        market: market,
        side: _parseSide(side),
        orderType: _parseOrderType(orderType),
        status: _parseStatus(status),
        qty: qty,
        filledQty: filledQty,
        limitPrice:
            limitPrice != null ? Decimal.parse(limitPrice!) : null,
        avgFillPrice:
            avgFillPrice != null ? Decimal.parse(avgFillPrice!) : null,
        validity: _parseValidity(validity),
        extendedHours: extendedHours,
        fees: fees.toDomain(),
        createdAt: DateTime.parse(createdAt).toUtc(),
        updatedAt: DateTime.parse(updatedAt).toUtc(),
      );
}

extension OrderFeesModelMapper on OrderFeesModel {
  OrderFees toDomain() => OrderFees(
        commission: Decimal.parse(commission),
        exchangeFee: Decimal.parse(exchangeFee),
        secFee: Decimal.parse(secFee),
        finraFee: Decimal.parse(finraFee),
        total: Decimal.parse(total),
      );
}

extension OrderFillModelMapper on OrderFillModel {
  OrderFill toDomain() => OrderFill(
        fillId: fillId,
        orderId: orderId,
        qty: qty,
        price: Decimal.parse(price),
        exchange: exchange,
        filledAt: DateTime.parse(filledAt).toUtc(),
      );
}

extension PositionModelMapper on PositionModel {
  Position toDomain() => Position(
        symbol: symbol,
        market: market,
        qty: qty,
        availableQty: availableQty,
        avgCost: Decimal.parse(avgCost),
        currentPrice: Decimal.parse(currentPrice),
        marketValue: Decimal.parse(marketValue),
        unrealizedPnl: Decimal.parse(unrealizedPnl),
        unrealizedPnlPct: Decimal.parse(unrealizedPnlPct),
        todayPnl: Decimal.parse(todayPnl),
        todayPnlPct: Decimal.parse(todayPnlPct),
        pendingSettlements: pendingSettlements
            .map((s) => PendingSettlement(
                  qty: s.qty,
                  settleDate: DateTime.parse(s.settleDate).toUtc(),
                ))
            .toList(),
      );
}

extension PortfolioSummaryModelMapper on PortfolioSummaryModel {
  PortfolioSummary toDomain() => PortfolioSummary(
        totalEquity: Decimal.parse(totalEquity),
        cashBalance: Decimal.parse(cashBalance),
        marketValue: Decimal.parse(marketValue),
        dayPnl: Decimal.parse(dayPnl),
        dayPnlPct: Decimal.parse(dayPnlPct),
        totalPnl: Decimal.parse(totalPnl),
        totalPnlPct: Decimal.parse(totalPnlPct),
        buyingPower: Decimal.parse(buyingPower),
        settledCash: Decimal.parse(settledCash),
      );
}

OrderSide _parseSide(String s) =>
    s == 'buy' ? OrderSide.buy : OrderSide.sell;

OrderType _parseOrderType(String s) =>
    s == 'market' ? OrderType.market : OrderType.limit;

OrderValidity _parseValidity(String s) =>
    s == 'gtc' ? OrderValidity.gtc : OrderValidity.day;

OrderStatus _parseStatus(String s) {
  switch (s) {
    case 'RISK_CHECKING':
      return OrderStatus.riskChecking;
    case 'PENDING':
      return OrderStatus.pending;
    case 'PARTIALLY_FILLED':
      return OrderStatus.partiallyFilled;
    case 'FILLED':
      return OrderStatus.filled;
    case 'CANCELLED':
      return OrderStatus.cancelled;
    case 'PARTIALLY_FILLED_CANCELLED':
      return OrderStatus.partiallyFilledCancelled;
    case 'EXPIRED':
      return OrderStatus.expired;
    case 'REJECTED':
      return OrderStatus.rejected;
    case 'EXCHANGE_REJECTED':
      return OrderStatus.exchangeRejected;
    default:
      return OrderStatus.rejected;
  }
}
