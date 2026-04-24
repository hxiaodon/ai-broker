import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../trading/domain/entities/position.dart';

class PositionListCard extends StatelessWidget {
  const PositionListCard({
    super.key,
    required this.position,
    required this.portfolioWeight,
    required this.colors,
    required this.onTap,
    required this.onBuy,
    required this.onSell,
  });

  final Position position;

  /// Weight of this position in total portfolio (0–1).
  final Decimal portfolioWeight;

  final ColorTokens colors;
  final VoidCallback onTap;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  static const _concentrationThreshold = 0.30;

  bool get _isConcentrated =>
      portfolioWeight > Decimal.parse('$_concentrationThreshold');

  @override
  Widget build(BuildContext context) {
    final pnlColor = position.unrealizedPnl.isPositive
        ? colors.priceUp
        : position.unrealizedPnl.isNegative
            ? colors.priceDown
            : colors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isConcentrated) _ConcentrationBanner(
              symbol: position.symbol,
              weightPct: (portfolioWeight * Decimal.fromInt(100))
                  .toFormatted(1),
              colors: colors,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Left: symbol badge
                      _SymbolBadge(
                        symbol: position.symbol,
                        colors: colors,
                      ),
                      const SizedBox(width: 12),
                      // Center: symbol + shares + avg cost
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              position.symbol,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${position.qty} 股 @ ${position.avgCost.toUsPrice()}',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: market value + P&L
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            position.marketValue.toAmount(),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${position.unrealizedPnl.isPositive ? '+' : ''}'
                            '${position.unrealizedPnl.toAmount()} '
                            '(${position.unrealizedPnlPct.toPercentChange()})',
                            style: TextStyle(
                              color: pnlColor,
                              fontSize: 12,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MetaChip(
                        label:
                            '今日 ${position.todayPnl.isPositive ? '+' : ''}${position.todayPnlPct.toPercentChange()}',
                        color: position.todayPnl.isPositive
                            ? colors.priceUp
                            : position.todayPnl.isNegative
                                ? colors.priceDown
                                : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      _MetaChip(
                        label: '占比 ${(portfolioWeight * Decimal.fromInt(100)).toFormatted(1)}%',
                        color: colors.onSurfaceVariant,
                      ),
                      const Spacer(),
                      // Quick action buttons
                      _ActionButton(
                        label: '买入',
                        color: colors.priceUp,
                        onTap: onBuy,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: '卖出',
                        color: colors.priceDown,
                        onTap: onSell,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcentrationBanner extends StatelessWidget {
  const _ConcentrationBanner({
    required this.symbol,
    required this.weightPct,
    required this.colors,
  });

  final String symbol;
  final String weightPct;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$symbol 占您持仓的 $weightPct%，集中度较高',
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymbolBadge extends StatelessWidget {
  const _SymbolBadge({required this.symbol, required this.colors});

  final String symbol;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol.length > 4 ? symbol.substring(0, 4) : symbol,
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: symbol.length > 3 ? 10 : 12,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontSize: 11, color: color));
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
