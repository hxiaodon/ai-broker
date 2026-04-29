import 'package:decimal/decimal.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_fill.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/position.dart';
import 'models/order_model.dart';
import 'models/portfolio_summary_model.dart';
import 'models/position_model.dart';

// Safe decimal parser — surfaces field name in the error for easier debugging.
Decimal _d(String? raw, String field) {
  if (raw == null || raw.isEmpty) {
    throw FormatException('Missing required field: $field');
  }
  return Decimal.tryParse(raw) ??
      (throw FormatException('Invalid decimal for field: $field'));
}

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
        limitPrice: limitPrice != null ? _d(limitPrice!, 'limit_price') : null,
        avgFillPrice:
            avgFillPrice != null ? _d(avgFillPrice!, 'avg_fill_price') : null,
        validity: _parseValidity(validity),
        extendedHours: extendedHours,
        fees: fees.toDomain(),
        createdAt: DateTime.parse(createdAt).toUtc(),
        updatedAt: DateTime.parse(updatedAt).toUtc(),
      );
}

extension OrderFeesModelMapper on OrderFeesModel {
  OrderFees toDomain() => OrderFees(
        commission: _d(commission, 'commission'),
        exchangeFee: _d(exchangeFee, 'exchange_fee'),
        secFee: _d(secFee, 'sec_fee'),
        finraFee: _d(finraFee, 'finra_fee'),
        total: _d(total, 'total'),
      );
}

extension OrderFillModelMapper on OrderFillModel {
  OrderFill toDomain() => OrderFill(
        fillId: fillId,
        orderId: orderId,
        qty: qty,
        price: _d(price, 'price'),
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
        avgCost: _d(avgCost, 'avg_cost'),
        currentPrice: _d(currentPrice, 'current_price'),
        marketValue: _d(marketValue, 'market_value'),
        unrealizedPnl: _d(unrealizedPnl, 'unrealized_pnl'),
        unrealizedPnlPct: _d(unrealizedPnlPct, 'unrealized_pnl_pct'),
        todayPnl: _d(todayPnl, 'today_pnl'),
        todayPnlPct: _d(todayPnlPct, 'today_pnl_pct'),
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
        totalEquity: _d(totalEquity, 'total_equity'),
        cashBalance: _d(cashBalance, 'cash_balance'),
        marketValue: _d(marketValue, 'market_value'),
        dayPnl: _d(dayPnl, 'day_pnl'),
        dayPnlPct: _d(dayPnlPct, 'day_pnl_pct'),
        totalPnl: _d(totalPnl, 'total_pnl'),
        totalPnlPct: _d(totalPnlPct, 'total_pnl_pct'),
        buyingPower: _d(buyingPower, 'buying_power'),
        unsettledCash: _d(unsettledCash, 'unsettled_cash'),
      );
}

OrderSide _parseSide(String s) => switch (s) {
      'buy' => OrderSide.buy,
      'sell' => OrderSide.sell,
      _ => throw FormatException('Unknown order side'),
    };

OrderType _parseOrderType(String s) => switch (s) {
      'market' => OrderType.market,
      'limit' => OrderType.limit,
      _ => throw FormatException('Unknown order type'),
    };

OrderValidity _parseValidity(String s) => switch (s) {
      'gtc' => OrderValidity.gtc,
      'day' => OrderValidity.day,
      _ => throw FormatException('Unknown order validity'),
    };

OrderStatus _parseStatus(String s) => switch (s) {
      'RISK_CHECKING' => OrderStatus.riskChecking,
      'PENDING' => OrderStatus.pending,
      'PARTIALLY_FILLED' => OrderStatus.partiallyFilled,
      'FILLED' => OrderStatus.filled,
      'CANCELLED' => OrderStatus.cancelled,
      'PARTIALLY_FILLED_CANCELLED' => OrderStatus.partiallyFilledCancelled,
      'EXPIRED' => OrderStatus.expired,
      'REJECTED' => OrderStatus.rejected,
      'EXCHANGE_REJECTED' => OrderStatus.exchangeRejected,
      _ => throw FormatException('Unknown order status'),
    };
