import 'package:flutter/material.dart';

import '../../../../shared/extensions/decimal_extensions.dart';
import '../../../../shared/theme/color_tokens.dart';
import '../../../trading/domain/entities/position.dart';

class PnlRankingItem extends StatelessWidget {
  const PnlRankingItem({
    super.key,
    required this.rank,
    required this.position,
    required this.colors,
    required this.onTap,
  });

  final int rank;
  final Position position;
  final ColorTokens colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pnlColor = position.unrealizedPnl.isPositive
        ? colors.priceUp
        : position.unrealizedPnl.isNegative
            ? colors.priceDown
            : colors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                position.symbol,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${position.unrealizedPnl.isPositive ? '+' : ''}'
                  '${position.unrealizedPnl.toAmount()}',
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  position.unrealizedPnlPct.toPercentChange(),
                  style: TextStyle(color: pnlColor, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
