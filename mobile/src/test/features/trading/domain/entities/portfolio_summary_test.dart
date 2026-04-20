import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/trading/domain/entities/portfolio_summary.dart';

void main() {
  group('PortfolioSummary', () {
    test('all fields are Decimal', () {
      final summary = PortfolioSummary(
        totalEquity: Decimal.parse('100000.00'),
        cashBalance: Decimal.parse('50000.00'),
        marketValue: Decimal.parse('50000.00'),
        dayPnl: Decimal.parse('1200.50'),
        dayPnlPct: Decimal.parse('1.22'),
        totalPnl: Decimal.parse('5000.00'),
        totalPnlPct: Decimal.parse('5.26'),
        buyingPower: Decimal.parse('75000.00'),
        settledCash: Decimal.parse('45000.00'),
      );
      expect(summary.totalEquity, isA<Decimal>());
      expect(summary.cashBalance, isA<Decimal>());
      expect(summary.buyingPower, isA<Decimal>());
      expect(summary.settledCash, isA<Decimal>());
    });

    test('negative P&L values', () {
      final summary = PortfolioSummary(
        totalEquity: Decimal.parse('95000.00'),
        cashBalance: Decimal.parse('50000.00'),
        marketValue: Decimal.parse('45000.00'),
        dayPnl: Decimal.parse('-800.00'),
        dayPnlPct: Decimal.parse('-0.83'),
        totalPnl: Decimal.parse('-5000.00'),
        totalPnlPct: Decimal.parse('-5.00'),
        buyingPower: Decimal.parse('70000.00'),
        settledCash: Decimal.parse('45000.00'),
      );
      expect(summary.dayPnl, Decimal.parse('-800.00'));
      expect(summary.totalPnlPct, Decimal.parse('-5.00'));
    });
  });
}
