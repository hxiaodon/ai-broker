
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/presentation/screens/market_home_screen.dart';
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

  group('MarketHomeScreen Widget Tests', () {
    testWidgets('displays all 5 tabs', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const MarketHomeScreen(),
        watchlistItems: () async => [makeQuote('AAPL')],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify all 5 tabs are present
      expect(find.text('自选'), findsWidgets);
      expect(find.text('热门'), findsWidgets);
      expect(find.text('涨幅榜'), findsWidgets);
      expect(find.text('跌幅榜'), findsWidgets);
      expect(find.text('港股'), findsWidgets);
    });

    testWidgets('displays watchlist tab content by default', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const MarketHomeScreen(),
        watchlistItems: () async => [
          makeQuote('AAPL', price: '150.2500'),
          makeQuote('TSLA', price: '180.5000'),
        ],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify watchlist tab is displayed with stocks
      expect(find.text('AAPL'), findsWidgets);
      expect(find.text('TSLA'), findsWidgets);
    });

    testWidgets('shows market header with title', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const MarketHomeScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify market screen title
      expect(find.text('行情'), findsWidgets);
    });

    testWidgets('displays edit button for authenticated users', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const MarketHomeScreen(),
        watchlistItems: () async => [makeQuote('AAPL')],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Edit button should be visible for authenticated users
      expect(find.text('编辑'), findsWidgets);
    });

    testWidgets('hides edit button for guest users', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildGuestApp(
        child: const MarketHomeScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Edit button should NOT be visible for guest users
      expect(find.text('编辑'), findsNothing);
    });

    testWidgets('switches to hot tab', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const MarketHomeScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Tap the 热门 (hot) tab
      await tester.tap(find.text('热门'));
      await tester.pump();

      // Verify we can tap the tab successfully
      expect(find.text('热门'), findsWidgets);
    });

    testWidgets('tab bar exists with proper tabs', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const MarketHomeScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify TabBar exists
      expect(find.byType(TabBar), findsWidgets);
    });
  });
}
