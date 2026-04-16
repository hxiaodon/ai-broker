import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';

/// Displays a price change percentage as a coloured badge.
///
/// Colour is determined by the sign of [change]:
///   - Positive: [Theme.of(context).colorScheme.tertiary] (priceUp colour)
///   - Negative: [Theme.of(context).colorScheme.error] (priceDown colour)
///   - Zero: grey
class PriceChangeBadge extends StatelessWidget {
  const PriceChangeBadge({
    super.key,
    required this.change,
    this.decimalPlaces = 2,
    this.showSign = true,
  });

  final Decimal change;
  final int decimalPlaces;
  final bool showSign;

  /// Displays a price change percentage as a coloured badge.
  ///
  /// Colour is determined by the sign of [change]:
  ///   - Positive: [Theme.of(context).colorScheme.tertiary] (priceUp colour)
  ///   - Negative: [Theme.of(context).colorScheme.error] (priceDown colour)
  ///   - Zero: grey
  ///
  /// [change] is expected in percentage form (e.g. 1.33 means +1.33%).
  @override
  Widget build(BuildContext context) {
    final isPositive = change > Decimal.zero;
    final isNegative = change < Decimal.zero;
    final scheme = Theme.of(context).colorScheme;

    final Color bgColor;
    final Color textColor;
    if (isPositive) {
      bgColor = scheme.tertiaryContainer;
      textColor = scheme.tertiary;
    } else if (isNegative) {
      bgColor = scheme.errorContainer;
      textColor = scheme.error;
    } else {
      bgColor = scheme.surfaceContainerHighest;
      textColor = scheme.onSurfaceVariant;
    }

    // change is already in percentage form (e.g. 1.33 = 1.33%), no * 100 needed
    final sign = (showSign && isPositive) ? '+' : '';
    final text = '$sign${change.toStringAsFixed(decimalPlaces)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
