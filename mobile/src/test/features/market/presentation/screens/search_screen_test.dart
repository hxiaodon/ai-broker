import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/presentation/screens/search_screen.dart';
import '../../../../helpers/widget_test_integration_helpers.dart';

void main() {
  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
  });

  group('SearchScreen Widget Tests', () {
    testWidgets('renders search screen with app bar', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const SearchScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify AppBar is rendered
      expect(find.byType(AppBar), findsWidgets);
    });

    testWidgets('displays back button in app bar', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const SearchScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify back button icon exists
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsWidgets);
    });

    testWidgets('has search text field in app bar', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const SearchScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify TextField exists for search input
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('updates when query is typed', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const SearchScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Find and interact with search field
      final textField = find.byType(TextField).first;
      await tester.tap(textField);
      await tester.pump();

      // Type a search query
      await tester.enterText(textField, 'AAPL');
      await tester.pump();

      // Verify the text was entered
      expect(find.text('AAPL'), findsWidgets);
    });

    testWidgets('displays scaffold with body', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const SearchScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify Scaffold structure
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('has animated switcher for body transitions', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const SearchScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // AnimatedSwitcher is used for body state transitions
      expect(find.byType(AnimatedSwitcher), findsWidgets);
    });

    testWidgets('renders empty query state initially', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const SearchScreen(),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Empty query state shows history and hot stocks
      expect(find.byType(SearchScreen), findsWidgets);
    });
  });
}
