import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/features/auth/domain/entities/auth_token.dart';

void main() {
  AuthToken makeToken({required DateTime expiresAt}) => AuthToken(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        accessTokenExpiresAt: expiresAt,
        accountId: 'acc-123',
        accountStatus: 'ACTIVE',
      );

  group('AuthToken', () {
    test('isExpired returns true when token has expired', () {
      final token = makeToken(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      expect(token.isExpired, isTrue);
    });

    test('isExpired returns false when token is still valid', () {
      final token = makeToken(
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      expect(token.isExpired, isFalse);
    });

    test('isNearExpiry returns true when less than 15 minutes remain', () {
      final token = makeToken(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 10)),
      );
      expect(token.isNearExpiry, isTrue);
    });

    test('isNearExpiry returns false when more than 15 minutes remain', () {
      final token = makeToken(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      );
      expect(token.isNearExpiry, isFalse);
    });

    test('isNearExpiry returns true when token is already expired', () {
      final token = makeToken(
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );
      expect(token.isNearExpiry, isTrue);
    });

    test('isNearExpiry boundary — just over 15 minutes remaining', () {
      final token = makeToken(
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15, seconds: 5)),
      );
      expect(token.isNearExpiry, isFalse);
    });

    test('equality — two tokens with same fields are equal', () {
      final expiresAt = DateTime.utc(2026, 4, 15, 12, 0, 0);
      final a = makeToken(expiresAt: expiresAt);
      final b = makeToken(expiresAt: expiresAt);
      expect(a, equals(b));
    });

    test('equality — different expiresAt produces different tokens', () {
      final a = makeToken(expiresAt: DateTime.utc(2026, 4, 15, 12, 0, 0));
      final b = makeToken(expiresAt: DateTime.utc(2026, 4, 15, 13, 0, 0));
      expect(a, isNot(equals(b)));
    });
  });
}
