import 'package:flutter/material.dart';

import '../../../../shared/theme/color_tokens.dart';
import '../../domain/entities/order.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labelAndColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  static (String, Color) _labelAndColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.riskChecking:
        return ('审核中', const Color(0xFF1A73E8));
      case OrderStatus.pending:
        return ('待成交', const Color(0xFF1A73E8));
      case OrderStatus.partiallyFilled:
        return ('部分成交', const Color(0xFFFF9800));
      case OrderStatus.filled:
        return ('已成交', ColorTokens.greenUp.priceUp);
      case OrderStatus.cancelled:
        return ('已撤销', ColorTokens.greenUp.priceNeutral);
      case OrderStatus.partiallyFilledCancelled:
        return ('部分成交后撤销', const Color(0xFFFF9800));
      case OrderStatus.expired:
        return ('已过期', ColorTokens.greenUp.priceNeutral);
      case OrderStatus.rejected:
        return ('已拒绝', ColorTokens.greenUp.priceDown);
      case OrderStatus.exchangeRejected:
        return ('交易所拒绝', ColorTokens.greenUp.priceDown);
    }
  }
}

class OrderCardWidget extends StatelessWidget {
  const OrderCardWidget({
    super.key,
    required this.order,
    required this.colors,
    this.onCancel,
    this.onTap,
    this.isHighlighted = false,
  });

  final Order order;
  final ColorTokens colors;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  /// When true, render a green accent border to signal this card was the
  /// order the user just submitted.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final isBuy = order.side == OrderSide.buy;
    // Buy/sell button colors are fixed per PRD §6.7 — not tied to price color pref
    final sideColor = isBuy
        ? const Color(0xFF0DC582) // fixed green for buy
        : const Color(0xFFFF4747); // fixed red for sell

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted
              ? Border.all(color: const Color(0xFF0DC582), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order.symbol,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: sideColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isBuy ? '买入' : '卖出',
                    style: TextStyle(
                      color: sideColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  order.orderType == OrderType.market ? '市价' : '限价',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  order.orderType == OrderType.market
                      ? '市价 × ${order.qty}'
                      : '${order.limitPrice} × ${order.qty}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (order.filledQty > 0)
                  Text(
                    '已成交 ${order.filledQty}/${order.qty}',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatTime(order.createdAt),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (order.isCancellable && onCancel != null)
                  GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '撤单',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
