import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Guest mode - watchlist loads successfully', (tester) async {
    // Start the app
    app.main();

    // Wait for app to initialize
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Find and tap the guest mode button
    final guestButton = find.text('先逛逛 →');
    expect(guestButton, findsOneWidget);
    print('✅ Found guest mode button');

    await tester.tap(guestButton);
    print('✅ Tapped guest mode button');

    // Wait for navigation with timeout
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));

    // Verify we're on the market page
    final marketTitle = find.text('行情');
    expect(marketTitle, findsOneWidget);
    print('✅ Navigated to market page');

    // Wait for watchlist to load (use pump instead of pumpAndSettle to avoid timeout)
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    // Check that we're on the watchlist tab (自选)
    final watchlistTab = find.text('自选');
    expect(watchlistTab, findsOneWidget);
    print('✅ Found watchlist tab');

    // Check for error message (should NOT exist)
    final errorMessage = find.text('加载自选股失败');
    expect(errorMessage, findsNothing);
    print('✅ No error message found');

    // Check for delayed quote indicator
    final delayedIndicator = find.textContaining('延迟');
    expect(delayedIndicator, findsAtLeastNWidgets(1));
    print('✅ Found delayed quote indicator');

    // Check for stock symbols (default watchlist: AAPL, TSLA, 0700, 9988)
    final symbols = ['AAPL', 'TSLA', '0700', '9988'];
    for (final symbol in symbols) {
      final symbolFinder = find.text(symbol);
      expect(symbolFinder, findsAtLeastNWidgets(1));
      print('✅ Found stock symbol: $symbol');
    }

    // Check for stock names
    final appleStock = find.textContaining('Apple');
    expect(appleStock, findsAtLeastNWidgets(1));
    print('✅ Found Apple stock name');

    print('\n✅ Watchlist loading test completed successfully');
  });
}
