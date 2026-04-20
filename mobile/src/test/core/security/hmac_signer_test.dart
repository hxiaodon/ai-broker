import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/security/hmac_signer.dart';

void main() {
  const secret = 'test-secret-key-not-real';
  const signer = HmacSigner(secret);

  group('HmacSigner.sign', () {
    test('produces deterministic signature', () {
      final sig1 = signer.sign(
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        body: '{"symbol":"AAPL"}',
      );
      final sig2 = signer.sign(
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        body: '{"symbol":"AAPL"}',
      );
      expect(sig1, sig2);
    });

    test('different body produces different signature', () {
      final sig1 = signer.sign(
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        body: '{"symbol":"AAPL"}',
      );
      final sig2 = signer.sign(
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        body: '{"symbol":"TSLA"}',
      );
      expect(sig1, isNot(sig2));
    });

    test('different method produces different signature', () {
      final sig1 = signer.sign(
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
      );
      final sig2 = signer.sign(
        method: 'DELETE',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
      );
      expect(sig1, isNot(sig2));
    });

    test('method is uppercased', () {
      final sig1 = signer.sign(
        method: 'post',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
      );
      final sig2 = signer.sign(
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
      );
      expect(sig1, sig2);
    });

    test('empty body uses SHA256 of empty string', () {
      final sig = signer.sign(
        method: 'DELETE',
        path: '/api/v1/orders/ord-001',
        timestamp: '1713200000000',
      );
      // Manually compute expected
      final emptyBodyHash = sha256.convert(utf8.encode('')).toString();
      final payload =
          'DELETE\n/api/v1/orders/ord-001\n1713200000000\n$emptyBodyHash';
      final key = utf8.encode(secret);
      final expected = Hmac(sha256, key).convert(utf8.encode(payload)).toString();
      expect(sig, expected);
    });
  });

  group('HmacSigner.buildHeaders', () {
    test('returns X-Timestamp and X-Signature', () {
      final headers = signer.buildHeaders(
        method: 'POST',
        path: '/api/v1/orders',
        body: '{"symbol":"AAPL"}',
      );
      expect(headers, contains('X-Timestamp'));
      expect(headers, contains('X-Signature'));
      expect(headers['X-Timestamp'], isNotEmpty);
      expect(headers['X-Signature'], isNotEmpty);
    });

    test('X-Timestamp is a valid millisecond epoch', () {
      final headers = signer.buildHeaders(
        method: 'GET',
        path: '/api/v1/orders',
      );
      final ts = int.tryParse(headers['X-Timestamp']!);
      expect(ts, isNotNull);
      // Should be within last 5 seconds
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      expect(ts!, closeTo(now, 5000));
    });

    test('signature matches manual computation with returned timestamp', () {
      final headers = signer.buildHeaders(
        method: 'POST',
        path: '/api/v1/orders',
        body: '{"qty":100}',
      );
      final expected = signer.sign(
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: headers['X-Timestamp']!,
        body: '{"qty":100}',
      );
      expect(headers['X-Signature'], expected);
    });
  });
}
