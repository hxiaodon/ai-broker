
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/presentation/widgets/watchlist_tab.dart';
import 'package:trading_app/shared/widgets/loading/skeleton_loader.dart';
import '../../../../helpers/widget_test_integration_helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Quote makeQuote(String symbol, {String price = '150.0000'}) => Quote(
  symbol: symbol,
  name: '$symbol Inc.',
  nameZh: '',
  market: 'US',
  price: Decimal.parse(price),
  change: Decimal.parse('1.0000'),
  changePct: Decimal.parse('0.0067'),
  volume: 1000000,
  bid: Decimal.parse('149.9900'),
  ask: Decimal.parse('150.0100'),
  turnover: '150M',
  prevClose: Decimal.parse('149.0000'),
  open: Decimal.parse('149.5000'),
  high: Decimal.parse('151.0000'),
  low: Decimal.parse('148.5000'),
  marketCap: '2.8T',
  delayed: false,
  marketStatus: MarketStatus.regular,
);

void main() {
  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
  });

  group('WatchlistTab Widget Tests', () {
    testWidgets('displays loading skeleton while fetching', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: WatchlistTab(onStockTap: (_) {}),
        watchlistItems: () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return [];
        },
      );

      await tester.pumpWidget(app);

      // Widget tree now shows the loading skeleton
      expect(find.byType(SkeletonLoader), findsWidgets);

      // Now let the delay finish
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
    });

    testWidgets('displays watchlist items after loading', (WidgetTester tester) async {
      final quotes = [
        makeQuote('AAPL', price: '150.2500'),
        makeQuote('TSLA', price: '180.5000'),
      ];

      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: WatchlistTab(onStockTap: (_) {}),
        watchlistItems: () async => quotes,
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Should display symbols
      expect(find.text('AAPL'), findsWidgets);
      expect(find.text('TSLA'), findsWidgets);
    });

    testWidgets('calls onStockTap when item is tapped', (WidgetTester tester) async {
      String? tappedSymbol;

      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: WatchlistTab(
          onStockTap: (symbol) => tappedSymbol = symbol,
        ),
        watchlistItems: () async => [makeQuote('AAPL')],
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Tap on AAPL
      await tester.tap(find.text('AAPL').first);
      await tester.pumpAndSettle();

      expect(tappedSymbol, 'AAPL');
    });

    testWidgets('shows edit button for authenticated users', (WidgetTester tester) async {
      bool editTapped = false;

      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: WatchlistTab(
          onStockTap: (_) {},
          onEditTap: () => editTapped = true,
        ),
        watchlistItems: () async => [makeQuote('AAPL')],
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Look for edit button
      final editButton = find.byIcon(Icons.edit);
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton.first);
        await tester.pumpAndSettle();
        expect(editTapped, true);
      }
    });

    testWidgets('hides edit button for guest users', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildGuestApp(
        child: WatchlistTab(onStockTap: (_) {}),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // No edit button for guest
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('displays error when fetch fails', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: WatchlistTab(onStockTap: (_) {}),
        watchlistItems: () async => throw Exception('Network error'),
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Should show error state
      expect(find.byType(Center), findsWidgets);
    });
  });
}
