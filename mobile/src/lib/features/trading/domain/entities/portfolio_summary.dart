import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_summary.freezed.dart';

@freezed
abstract class PortfolioSummary with _$PortfolioSummary {
  const factory PortfolioSummary({
    required Decimal totalEquity,
    required Decimal cashBalance,
    required Decimal marketValue,
    required Decimal dayPnl,
    required Decimal dayPnlPct,
    required Decimal totalPnl,
    required Decimal totalPnlPct,
    required Decimal buyingPower,
    required Decimal unsettledCash,
  }) = _PortfolioSummary;

  const PortfolioSummary._();

  /// Verifies totalEquity == cashBalance + marketValue.
  /// A mismatch indicates a mapper or backend serialization bug.
  bool get isEquityConsistent => totalEquity == cashBalance + marketValue;
}
