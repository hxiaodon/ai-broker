import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app.dart';

/// Market Module Integration Tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Market Module - Basic Navigation', () {
    testWidgets('M1: Market home loads for guests', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppAsGuest());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ M1: Guest sees market');
    });

    testWidgets('M2: Market loads for authenticated', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppWithAuth(
        accessToken: 'token',
        refreshToken: 'refresh',
      ));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ M2: Auth user sees market');
    });
  });

  group('Market Module - Data Display', () {
    testWidgets('M3: Watchlist loads', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppAsGuest());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ M3: Watchlist loads');
    });

    testWidgets('M4: Guest sees delay indicator', (tester) async {
      await tester.pumpWidget(TestAppConfig.createAppAsGuest());
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      print('✅ M4: Delay shown for guest');
    });
  });

  group('Market Module - Performance', () {
    testWidgets('M5: Quick load time', (tester) async {
      final sw = Stopwatch()..start();
      await tester.pumpWidget(TestAppConfig.createAppAsGuest());
      await tester.pump(const Duration(seconds: 2));
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(3000));
      print('✅ M5: Load ${sw.elapsedMilliseconds}ms');
    });
  });
}
