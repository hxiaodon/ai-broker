import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/security/bio_challenge_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  group('BioChallengeService.computeActionHash', () {
    test('produces deterministic hash for same inputs', () {
      final h1 = BioChallengeService.computeActionHash(
        side: 'buy',
        symbol: 'AAPL',
        qty: 100,
        price: '150.2500',
        accountId: 'acc-123',
      );
      final h2 = BioChallengeService.computeActionHash(
        side: 'buy',
        symbol: 'AAPL',
        qty: 100,
        price: '150.2500',
        accountId: 'acc-123',
      );
      expect(h1, h2);
    });

    test('side is uppercased — buy == BUY', () {
      final lower = BioChallengeService.computeActionHash(
        side: 'buy',
        symbol: 'AAPL',
        qty: 100,
        accountId: 'acc-123',
      );
      final upper = BioChallengeService.computeActionHash(
        side: 'BUY',
        symbol: 'AAPL',
        qty: 100,
        accountId: 'acc-123',
      );
      expect(lower, upper);
    });

    test('different side produces different hash', () {
      final buy = BioChallengeService.computeActionHash(
        side: 'buy',
        symbol: 'AAPL',
        qty: 100,
        price: '150.00',
        accountId: 'acc-123',
      );
      final sell = BioChallengeService.computeActionHash(
        side: 'sell',
        symbol: 'AAPL',
        qty: 100,
        price: '150.00',
        accountId: 'acc-123',
      );
      expect(buy, isNot(sell));
    });

    test('different qty produces different hash', () {
      final h1 = BioChallengeService.computeActionHash(
        side: 'buy',
        symbol: 'AAPL',
        qty: 100,
        accountId: 'acc-123',
      );
      final h2 = BioChallengeService.computeActionHash(
        side: 'buy',
        symbol: 'AAPL',
        qty: 200,
        accountId: 'acc-123',
      );
      expect(h1, isNot(h2));
    });

    test('different accountId produces different hash (cross-account replay prevention)', () {
      final h1 = BioChallengeService.computeActionHash(
        side: 'buy',
        symbol: 'AAPL',
        qty: 100,
        accountId: 'acc-111',
      );
      final h2 = BioChallengeService.computeActionHash(
        side: 'buy',
        symbol: 'AAPL',
        qty: 100,
        accountId: 'acc-222',
      );
      expect(h1, isNot(h2));
    });

    test('matches manual SHA256 of | separated format', () {
      const side = 'BUY';
      const symbol = 'TSLA';
      const qty = 50;
      const price = '200.0000';
      const accountId = 'acc-test';

      final hash = BioChallengeService.computeActionHash(
        side: side,
        symbol: symbol,
        qty: qty,
        price: price,
        accountId: accountId,
      );

      final expected = sha256
          .convert(utf8.encode('$side|$symbol|$qty|$price|$accountId'))
          .toString();
      expect(hash, expected);
    });

    test('empty price defaults to empty string — not null', () {
      expect(
        () => BioChallengeService.computeActionHash(
          side: 'buy',
          symbol: 'AAPL',
          qty: 100,
          accountId: 'acc-123',
        ),
        returnsNormally,
      );
    });
  });

  group('BioChallengeService.computeBioToken', () {
    const sessionSecret = 'test-session-secret';
    const challenge = 'base64challenge==';
    const timestamp = '1713200000000';
    const deviceId = 'dev-001';
    const actionHash = 'abc123actionhash';

    late BioChallengeService service;

    setUp(() {
      // BioChallengeService needs a Dio but computeBioToken is pure — use a
      // null-safe workaround: create with a real Dio stub isn't needed here
      // since we only test the pure computation method.
      service = _PureBioChallengeService();
    });

    test('produces deterministic token', () {
      final t1 = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: actionHash,
      );
      final t2 = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: actionHash,
      );
      expect(t1, t2);
    });

    test('matches manual HMAC-SHA256 computation', () {
      final token = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: actionHash,
      );

      final payload = '$challenge|$timestamp|$deviceId|$actionHash';
      final expected = Hmac(sha256, utf8.encode(sessionSecret))
          .convert(utf8.encode(payload))
          .toString();
      expect(token, expected);
    });

    test('different challenge produces different token', () {
      final t1 = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: 'challenge-A',
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: actionHash,
      );
      final t2 = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: 'challenge-B',
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: actionHash,
      );
      expect(t1, isNot(t2));
    });

    test('different actionHash produces different token', () {
      final t1 = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: 'hash-buy-100',
      );
      final t2 = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: 'hash-sell-100',
      );
      expect(t1, isNot(t2));
    });

    test('different sessionSecret produces different token', () {
      final t1 = service.computeBioToken(
        sessionSecret: 'secret-A',
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: actionHash,
      );
      final t2 = service.computeBioToken(
        sessionSecret: 'secret-B',
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: actionHash,
      );
      expect(t1, isNot(t2));
    });
  });
}

/// Subclass that skips real Dio construction — only used to test pure methods.
class _PureBioChallengeService extends BioChallengeService {
  _PureBioChallengeService() : super(dio: MockDio());
}
