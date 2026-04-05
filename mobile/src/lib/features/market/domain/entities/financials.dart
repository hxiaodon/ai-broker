import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'financials.freezed.dart';

/// A single quarterly earnings report.
///
/// [revenue] and [netIncome] are display strings with units (e.g. "124.10B").
/// [eps] / [epsEstimate] are precise 4-decimal Decimal values for calculations.
/// [revenueGrowth] / [netIncomeGrowth] are percentage Decimal values (2 decimals).
@freezed
abstract class FinancialsQuarter with _$FinancialsQuarter {
  const factory FinancialsQuarter({
    required String period,
    required String reportDate,
    required String revenue,
    required String netIncome,
    required Decimal eps,
    required Decimal epsEstimate,
    required Decimal revenueGrowth,
    required Decimal netIncomeGrowth,
  }) = _FinancialsQuarter;
}

/// Quarterly financials for a stock, including the next earnings date.
///
/// [nextEarningsDate] is a date string ("YYYY-MM-DD") — not parsed to DateTime
/// since no time component is present and it is display-only.
@freezed
abstract class Financials with _$Financials {
  const factory Financials({
    required String symbol,
    required String nextEarningsDate,
    required String nextEarningsQuarter,
    required List<FinancialsQuarter> quarters,
  }) = _Financials;
}
