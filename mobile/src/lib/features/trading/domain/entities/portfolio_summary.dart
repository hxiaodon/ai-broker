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
    required Decimal settledCash,
  }) = _PortfolioSummary;
}
