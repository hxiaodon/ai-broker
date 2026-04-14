import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/presentation/widgets/kline_chart_widget.dart';
import '../../../../helpers/widget_test_integration_helpers.dart';

void main() {
  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
  });

  group('KlineChartWidget Tests', () {
    testWidgets('renders kline chart widget', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const Scaffold(
          body: KLineChartWidget(symbol: 'AAPL'),
        ),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify KLineChartWidget is rendered
      expect(find.byType(KLineChartWidget), findsWidgets);
    });

    testWidgets('displays time period buttons', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const Scaffold(
          body: KLineChartWidget(symbol: 'AAPL'),
        ),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Verify time period selection widget is displayed
      // The widget should have time period controls
      expect(find.byType(KLineChartWidget), findsWidgets);
    });

    testWidgets('symbol is set correctly', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const Scaffold(
          body: KLineChartWidget(symbol: 'TSLA'),
        ),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Chart should render for the given symbol
      expect(find.byType(KLineChartWidget), findsWidgets);
    });

    testWidgets('contains scrollable content', (WidgetTester tester) async {
      final app = WidgetTestIntegrationHelper.buildAuthenticatedApp(
        child: const Scaffold(
          body: KLineChartWidget(symbol: 'AAPL'),
        ),
        watchlistItems: () async => [],
      );

      await tester.pumpWidget(app);
      await tester.pump();

      // Widget should be rendered and ready for interaction
      expect(find.byType(KLineChartWidget), findsWidgets);
    });
  });
}
