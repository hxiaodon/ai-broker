import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/security/bio_challenge_service.dart';
import 'package:trading_app/core/security/nonce_service.dart';
import 'package:trading_app/core/security/session_key_service.dart';
import 'package:trading_app/core/storage/secure_storage_service.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/trading/presentation/screens/order_entry_screen.dart';
import 'package:trading_app/features/trading/presentation/widgets/slide_to_confirm_widget.dart';

class _MockDio extends Mock implements Dio {}
class _MockStorage extends Mock implements SecureStorageService {}

class _StubSessionKey extends SessionKeyService {
  _StubSessionKey() : super(dio: _MockDio(), storage: _MockStorage());
  @override
  Future<SessionKey> getSessionKey() async =>
      (keyId: 'sk-test', secret: 'secret-test');
  @override
  Future<SessionKey> rotate() => getSessionKey();
  @override
  Future<void> clear() async {}
}

class _StubNonce extends NonceService {
  _StubNonce() : super(dio: _MockDio());
  @override
  Future<String> fetchNonce() async => 'nonce-test';
}

class _StubBioChallenge extends BioChallengeService {
  _StubBioChallenge() : super(dio: _MockDio());
  @override
  Future<String> fetchChallenge() async => 'challenge-test';
}

final _stubOverrides = [
  sessionKeyServiceProvider.overrideWithValue(_StubSessionKey()),
  nonceServiceProvider.overrideWithValue(_StubNonce()),
  bioChallengeServiceProvider.overrideWithValue(_StubBioChallenge()),
];

/// PRD-04 §6.7: Buy/sell colors are FIXED (green=buy, red=sell) and do NOT
/// change with the user's color scheme preference (greenUp vs redUp).
void main() {
  group('OrderEntryScreen — fixed buy/sell colors (PRD-04 §6.7)', () {
    testWidgets('buy side → SlideToConfirmWidget thumbColor is green (0xFF0DC582)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _stubOverrides,
          child: const MaterialApp(
            home: OrderEntryScreen(
              symbol: 'AAPL',
              market: 'US',
              initialSide: OrderSide.buy,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final slide = tester.widget<SlideToConfirmWidget>(
        find.byType(SlideToConfirmWidget),
      );
      expect(
        slide.thumbColor,
        const Color(0xFF0DC582),
        reason: 'Buy side must use green thumb color per PRD-04 §6.7',
      );
    });

    testWidgets('sell side → SlideToConfirmWidget thumbColor is red (0xFFFF4747)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _stubOverrides,
          child: const MaterialApp(
            home: OrderEntryScreen(
              symbol: 'AAPL',
              market: 'US',
              initialSide: OrderSide.sell,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final slide = tester.widget<SlideToConfirmWidget>(
        find.byType(SlideToConfirmWidget),
      );
      expect(
        slide.thumbColor,
        const Color(0xFFFF4747),
        reason: 'Sell side must use red thumb color per PRD-04 §6.7',
      );
    });

    testWidgets('both buy/sell tab labels are always present regardless of initial side',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _stubOverrides,
          child: const MaterialApp(
            home: OrderEntryScreen(
              symbol: 'TSLA',
              market: 'US',
              initialSide: OrderSide.buy,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('买入'), findsWidgets);
      expect(find.text('卖出'), findsWidgets);
    });
  });
}
