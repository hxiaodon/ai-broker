import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';

/// Text widget that displays a [Decimal] price value with proper formatting.
///
/// Colour adapts based on [change] direction using the theme's trading colours.
/// Uses tabular figures for proper numeric alignment in lists.
class DecimalPriceText extends StatelessWidget {
  const DecimalPriceText({
    super.key,
    required this.price,
    this.change,
    this.decimalPlaces = 2,
    this.style,
    this.currencySymbol,
  });

  final Decimal price;
  final Decimal? change;
  final int decimalPlaces;
  final TextStyle? style;
  final String? currencySymbol;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;

    Color textColor = scheme.onSurface;
    if (change != null) {
      if (change! > Decimal.zero) {
        textColor = scheme.tertiary; // priceUp
      } else if (change! < Decimal.zero) {
        textColor = scheme.error; // priceDown
      }
    }

    final prefix = currencySymbol ?? '';
    final formatted = '$prefix${price.toStringAsFixed(decimalPlaces)}';

    return Text(
      formatted,
      style: (style ?? defaultStyle)?.copyWith(
        color: textColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
