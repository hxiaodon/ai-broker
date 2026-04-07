import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/price/price_change_badge.dart';

/// A single stock row used in watchlist, movers, and search results.
///
/// Layout (from prototype):
/// ```
/// [Badge 44×44] [symbol / name]    [price / change%]
/// ```
///
/// The [rank] parameter adds a `#N` prefix column instead of the badge
/// (used in MoversTab / gainers / losers lists).
///
/// Tapping the row calls [onTap].
class StockRowTile extends StatelessWidget {
  const StockRowTile({
    super.key,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePct,
    this.market,
    this.rank,
    this.subtitle,
    this.delayed = false,
    this.onTap,
  });

  final String symbol;
  final String name;
  final Decimal price;

  /// Change percentage in decimal form (e.g. 0.0214 = 2.14%).
  final Decimal changePct;

  /// e.g. 'NASDAQ', 'NYSE', 'US'. Appended after name when provided.
  final String? market;

  /// When set, shows `#rank` instead of the symbol badge.
  final int? rank;

  /// Optional secondary line of text (e.g. "成交量 89.2M").
  final String? subtitle;

  /// When true, shows a 'D' delay badge next to the price.
  final bool delayed;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    final nameDisplay = market != null ? '$name · $market' : name;
    final secondLine = subtitle ?? nameDisplay;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left — badge or rank
            if (rank != null)
              SizedBox(
                width: 44,
                child: Text(
                  '#$rank',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              _SymbolBadge(symbol: symbol),

            const SizedBox(width: 12),

            // Middle — symbol + name/subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    symbol,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondLine,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Right — price + change badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: colors.onSurface,
                      ),
                    ),
                    if (delayed) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'D',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                PriceChangeBadge(change: changePct),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 44×44 symbol badge with gradient background.
/// Color is deterministically derived from the symbol string.
class _SymbolBadge extends StatelessWidget {
  const _SymbolBadge({required this.symbol});

  final String symbol;

  static const _gradients = [
    [Color(0xFF1A73E8), Color(0xFF1557B0)], // blue (default)
    [Color(0xFF0DC582), Color(0xFF0A9E66)], // green
    [Color(0xFFFF4747), Color(0xFFCC3333)], // red
    [Color(0xFF9C27B0), Color(0xFF6A1B9A)], // purple
    [Color(0xFF4169E1), Color(0xFF1E40AF)], // indigo
    [Color(0xFFF57C00), Color(0xFFE65100)], // orange
  ];

  @override
  Widget build(BuildContext context) {
    final idx = symbol.isEmpty ? 0 : symbol.codeUnitAt(0) % _gradients.length;
    final colors = _gradients[idx];

    final label = symbol.length > 4 ? symbol.substring(0, 4) : symbol;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
