import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/security/fund_withdrawal_bio_service.dart';

class MockDio extends Mock implements Dio {}

/// Subclass that skips real Dio construction — used only to test pure methods.
class _PureFundWithdrawalBioService extends FundWithdrawalBioService {
  _PureFundWithdrawalBioService() : super(dio: MockDio());
}

void main() {
  group('FundWithdrawalBioService.computeActionHash', () {
    test('produces deterministic hash for same inputs', () {
      final h1 = FundWithdrawalBioService.computeActionHash(
        amount: '1000.00',
        bankAccountId: 'ba-001',
        accountId: 'acc-001',
      );
      final h2 = FundWithdrawalBioService.computeActionHash(
        amount: '1000.00',
        bankAccountId: 'ba-001',
        accountId: 'acc-001',
      );
      expect(h1, h2);
    });

    test('matches manual SHA256 of WITHDRAWAL|AMOUNT|BANK_ACCOUNT_ID|ACCOUNT_ID', () {
      const amount = '5000.00';
      const bankAccountId = 'ba-007';
      const accountId = 'acc-999';

      final hash = FundWithdrawalBioService.computeActionHash(
        amount: amount,
        bankAccountId: bankAccountId,
        accountId: accountId,
      );

      final expected = sha256
          .convert(utf8.encode('WITHDRAWAL|$amount|$bankAccountId|$accountId'))
          .toString();
      expect(hash, expected);
    });

    test('prefix is WITHDRAWAL (not BUY/SELL — different from trading actionHash)', () {
      // The hash format must include WITHDRAWAL prefix to prevent cross-module replay.
      // SELL|1000.00|ba-001|acc-001 ≠ WITHDRAWAL|1000.00|ba-001|acc-001
      final withdrawalHash = FundWithdrawalBioService.computeActionHash(
        amount: '1000.00',
        bankAccountId: 'ba-001',
        accountId: 'acc-001',
      );
      final manualSellHash = sha256
          .convert(utf8.encode('SELL|1000.00|ba-001|acc-001'))
          .toString();
      expect(withdrawalHash, isNot(manualSellHash),
          reason: 'Withdrawal hash must use WITHDRAWAL prefix, not SELL');
    });

    test('different amount produces different hash', () {
      final h1 = FundWithdrawalBioService.computeActionHash(
        amount: '1000.00',
        bankAccountId: 'ba-001',
        accountId: 'acc-001',
      );
      final h2 = FundWithdrawalBioService.computeActionHash(
        amount: '2000.00',
        bankAccountId: 'ba-001',
        accountId: 'acc-001',
      );
      expect(h1, isNot(h2));
    });

    test('different bankAccountId produces different hash', () {
      final h1 = FundWithdrawalBioService.computeActionHash(
        amount: '1000.00',
        bankAccountId: 'ba-001',
        accountId: 'acc-001',
      );
      final h2 = FundWithdrawalBioService.computeActionHash(
        amount: '1000.00',
        bankAccountId: 'ba-999',
        accountId: 'acc-001',
      );
      expect(h1, isNot(h2));
    });

    test('different accountId produces different hash (cross-account replay prevention)', () {
      final h1 = FundWithdrawalBioService.computeActionHash(
        amount: '1000.00',
        bankAccountId: 'ba-001',
        accountId: 'acc-111',
      );
      final h2 = FundWithdrawalBioService.computeActionHash(
        amount: '1000.00',
        bankAccountId: 'ba-001',
        accountId: 'acc-222',
      );
      expect(h1, isNot(h2));
    });
  });

  group('FundWithdrawalBioService.computeBioToken', () {
    const sessionSecret = 'withdrawal-session-secret';
    const challenge = 'challenge-abc-123';
    const timestamp = '1714200000000';
    const deviceId = 'dev-fund-001';
    const actionHash = 'withdrawal-action-hash';

    late FundWithdrawalBioService service;

    setUp(() {
      service = _PureFundWithdrawalBioService();
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

    test('matches manual HMAC-SHA256(sessionSecret, challenge|timestamp|deviceId|actionHash)', () {
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

    test('different challenge → different token (one-time challenge prevents replay)', () {
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

    test('different actionHash → different token (amount-specific binding)', () {
      final t1 = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: 'hash-1000',
      );
      final t2 = service.computeBioToken(
        sessionSecret: sessionSecret,
        challenge: challenge,
        timestamp: timestamp,
        deviceId: deviceId,
        actionHash: 'hash-5000',
      );
      expect(t1, isNot(t2));
    });

    test('different sessionSecret → different token', () {
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
