import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Extension methods on [Decimal] for financial price formatting.
///
/// All formatted strings include the correct decimal precision per
/// [AppConstants] and financial-coding-standards.
extension DecimalFinancialExtensions on Decimal {
  /// Format as US stock price (4 decimal places).
  /// Example: Decimal('150.25') → '$150.2500'
  String toUsPrice({String currencySymbol = r'$'}) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: AppConstants.usPriceDecimalPlaces,
    );
    return formatter.format(toDouble());
  }

  /// Format as HK stock price (3 decimal places).
  /// Example: Decimal('25.6') → 'HK$25.600'
  String toHkPrice({String currencySymbol = 'HK\$'}) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: AppConstants.hkPriceDecimalPlaces,
    );
    return formatter.format(toDouble());
  }

  /// Format as currency amount (2 decimal places).
  /// Example: Decimal('1234.5') → '$1,234.50'
  String toAmount({String currencySymbol = r'$'}) {
    final formatter = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: AppConstants.amountDecimalPlaces,
    );
    return formatter.format(toDouble());
  }

  /// Format as percentage change.
  /// [this] is expected in percentage form (e.g. 1.33 means +1.33%).
  /// Example: Decimal('1.33') → '+1.33%'
  String toPercentChange({int decimalPlaces = 2}) {
    final sign = this >= Decimal.zero ? '+' : '';
    return '$sign${toStringAsFixed(decimalPlaces)}%';
  }

  /// Format plain decimal with explicit decimal places.
  String toFormatted([int decimalPlaces = 2]) =>
      toStringAsFixed(decimalPlaces);

  /// Returns true if this value represents a price increase (positive).
  bool get isPositive => this > Decimal.zero;

  /// Returns true if this value represents a price decrease (negative).
  bool get isNegative => this < Decimal.zero;

  /// Returns true if zero.
  bool get isZero => this == Decimal.zero;

  /// Safe absolute value.
  Decimal abs() => isNegative ? -this : this;
}

/// Extension on nullable [Decimal] for safe display.
extension NullableDecimalExtensions on Decimal? {
  /// Returns formatted price or a fallback string when null.
  String toUsPriceOrDash({String dash = '--'}) =>
      this?.toUsPrice() ?? dash;

  String toHkPriceOrDash({String dash = '--'}) =>
      this?.toHkPrice() ?? dash;

  String toAmountOrDash({String dash = '--'}) =>
      this?.toAmount() ?? dash;

  String toPercentChangeOrDash({String dash = '--'}) =>
      this?.toPercentChange() ?? dash;
}
