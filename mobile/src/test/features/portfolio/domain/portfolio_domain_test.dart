import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/portfolio/domain/entities/position_detail.dart';
import 'package:trading_app/features/portfolio/presentation/widgets/position_list_card.dart';
import 'package:trading_app/features/trading/domain/entities/position.dart';
import 'package:trading_app/shared/theme/color_tokens.dart';

PositionDetail _makeDetail({bool washSaleFlagged = false}) => PositionDetail(
      symbol: 'AAPL',
      market: 'US',
      companyName: 'Apple Inc.',
      sector: 'Technology',
      qty: 100,
      availableQty: 100,
      avgCost: Decimal.parse('150.00'),
      currentPrice: Decimal.parse('160.00'),
      marketValue: Decimal.parse('16000.00'),
      unrealizedPnl: Decimal.parse('1000.00'),
      unrealizedPnlPct: Decimal.parse('6.67'),
      realizedPnl: Decimal.zero,
      costBasis: Decimal.parse('15000.00'),
      todayPnl: Decimal.parse('200.00'),
      todayPnlPct: Decimal.parse('1.28'),
      washSaleFlagged: washSaleFlagged,
    );

Position _makePosition() => Position(
      symbol: 'AAPL',
      market: 'US',
      qty: 100,
      availableQty: 100,
      avgCost: Decimal.parse('150.00'),
      currentPrice: Decimal.parse('160.00'),
      marketValue: Decimal.parse('16000.00'),
      unrealizedPnl: Decimal.parse('1000.00'),
      unrealizedPnlPct: Decimal.parse('6.67'),
      todayPnl: Decimal.parse('200.00'),
      todayPnlPct: Decimal.parse('1.28'),
    );

void main() {
  group('PositionDetail.washSaleFlagged (PRD-06)', () {
    test('defaults to false', () {
      expect(_makeDetail().washSaleFlagged, isFalse);
    });

    test('true when explicitly flagged', () {
      expect(_makeDetail(washSaleFlagged: true).washSaleFlagged, isTrue);
    });
  });

  group('PositionListCard concentration warning (PRD-06 §5.2 — >30% triggers warning)', () {
    testWidgets('portfolioWeight > 30% renders _ConcentrationBanner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PositionListCard(
              position: _makePosition(),
              portfolioWeight: Decimal.parse('0.31'), // > 30%
              colors: ColorTokens.greenUp,
              onTap: () {},
              onBuy: () {},
              onSell: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // _ConcentrationBanner should be visible when weight > 30%
      expect(
        find.textContaining('集中'),
        findsOneWidget,
        reason: 'Concentration warning banner must appear when weight > 30%',
      );
    });

    testWidgets('portfolioWeight == 30% does NOT render _ConcentrationBanner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PositionListCard(
              position: _makePosition(),
              portfolioWeight: Decimal.parse('0.30'), // exactly 30% — threshold is >30%
              colors: ColorTokens.greenUp,
              onTap: () {},
              onBuy: () {},
              onSell: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining('集中'),
        findsNothing,
        reason: 'Concentration warning must NOT appear at exactly 30% (threshold is >30%)',
      );
    });

    testWidgets('portfolioWeight < 30% does NOT render _ConcentrationBanner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PositionListCard(
              position: _makePosition(),
              portfolioWeight: Decimal.parse('0.20'),
              colors: ColorTokens.greenUp,
              onTap: () {},
              onBuy: () {},
              onSell: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('集中'), findsNothing);
    });
  });
}
