import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Guest mode - click button and verify market page', (tester) async {
    // Start the app
    app.main();

    // Wait for app to initialize
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Find and tap the guest mode button (actual text is "先逛逛 →")
    final guestButton = find.text('先逛逛 →');
    expect(guestButton, findsOneWidget);
    print('✅ Found guest mode button: "先逛逛 →"');

    await tester.tap(guestButton);
    print('✅ Tapped guest mode button');

    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Verify we're on the market page
    final marketTitle = find.text('行情');
    expect(marketTitle, findsOneWidget);
    print('✅ Navigated to market page');

    // Wait for data to load
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Check for delayed quote indicator
    final delayedIndicator = find.textContaining('延迟');
    if (delayedIndicator.evaluate().isNotEmpty) {
      print('✅ Found delayed quote indicator');
    } else {
      print('⚠️ Delayed quote indicator not found');
    }

    // Print all visible text for debugging
    final allText = find.byType(Text);
    print('\n📋 All visible text widgets:');
    for (final element in allText.evaluate()) {
      final widget = element.widget as Text;
      if (widget.data != null && widget.data!.isNotEmpty) {
        print('  - ${widget.data}');
      }
    }

    print('\n✅ Guest mode test completed');
  });
}

extension ScreenshotExtension on WidgetTester {
  Future<void> takeScreenshot(String name) async {
    await pumpAndSettle();
    print('📸 Screenshot: $name');
  }
}
