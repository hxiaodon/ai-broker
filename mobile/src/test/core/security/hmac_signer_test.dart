import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/security/hmac_signer.dart';

void main() {
  const secret = 'test-secret-key-not-real';
  const signer = HmacSigner();

  // Helper: manually compute expected HMAC for 6-segment payload
  String _expected({
    required String method,
    required String path,
    required String timestamp,
    required String nonce,
    required String deviceId,
    String body = '',
  }) {
    final bodyHash = sha256.convert(utf8.encode(body)).toString();
    final payload =
        '${method.toUpperCase()}\n$path\n$timestamp\n$nonce\n$deviceId\n$bodyHash';
    return Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(payload))
        .toString();
  }

  group('HmacSigner.sign — 6-segment payload', () {
    test('produces deterministic signature', () {
      final sig1 = signer.sign(
        secret: secret,
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        nonce: 'n-abc',
        deviceId: 'dev-001',
        body: '{"symbol":"AAPL"}',
      );
      final sig2 = signer.sign(
        secret: secret,
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        nonce: 'n-abc',
        deviceId: 'dev-001',
        body: '{"symbol":"AAPL"}',
      );
      expect(sig1, sig2);
    });

    test('matches manual HMAC computation', () {
      const ts = '1713200000000';
      const nonce = 'n-xyz';
      const deviceId = 'dev-001';
      const body = '{"symbol":"AAPL","qty":100}';

      final sig = signer.sign(
        secret: secret,
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: ts,
        nonce: nonce,
        deviceId: deviceId,
        body: body,
      );

      expect(
        sig,
        _expected(
          method: 'POST',
          path: '/api/v1/orders',
          timestamp: ts,
          nonce: nonce,
          deviceId: deviceId,
          body: body,
        ),
      );
    });

    test('method is case-insensitive (uppercased internally)', () {
      const args = (
        path: '/api/v1/orders',
        ts: '1713200000000',
        nonce: 'n-1',
        deviceId: 'dev-1',
      );
      final lower = signer.sign(
        secret: secret,
        method: 'post',
        path: args.path,
        timestamp: args.ts,
        nonce: args.nonce,
        deviceId: args.deviceId,
      );
      final upper = signer.sign(
        secret: secret,
        method: 'POST',
        path: args.path,
        timestamp: args.ts,
        nonce: args.nonce,
        deviceId: args.deviceId,
      );
      expect(lower, upper);
    });

    test('empty body uses SHA256("") — not omitted', () {
      const ts = '1713200000000';
      const nonce = 'n-empty';
      const deviceId = 'dev-001';

      final sig = signer.sign(
        secret: secret,
        method: 'DELETE',
        path: '/api/v1/orders/ord-001',
        timestamp: ts,
        nonce: nonce,
        deviceId: deviceId,
      );

      expect(
        sig,
        _expected(
          method: 'DELETE',
          path: '/api/v1/orders/ord-001',
          timestamp: ts,
          nonce: nonce,
          deviceId: deviceId,
          body: '',
        ),
      );
    });

    test('changing any segment produces a different signature', () {
      final base = signer.sign(
        secret: secret,
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        nonce: 'n-abc',
        deviceId: 'dev-001',
        body: '{}',
      );

      final diffNonce = signer.sign(
        secret: secret,
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        nonce: 'n-DIFFERENT',
        deviceId: 'dev-001',
        body: '{}',
      );
      final diffDevice = signer.sign(
        secret: secret,
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        nonce: 'n-abc',
        deviceId: 'dev-DIFFERENT',
        body: '{}',
      );
      final diffBody = signer.sign(
        secret: secret,
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: '1713200000000',
        nonce: 'n-abc',
        deviceId: 'dev-001',
        body: '{"changed":true}',
      );

      expect(diffNonce, isNot(base));
      expect(diffDevice, isNot(base));
      expect(diffBody, isNot(base));
    });

    test('different secret produces different signature', () {
      const args = (
        method: 'POST',
        path: '/api/v1/orders',
        ts: '1713200000000',
        nonce: 'n-1',
        deviceId: 'dev-1',
      );
      final sig1 = signer.sign(
        secret: 'secret-A',
        method: args.method,
        path: args.path,
        timestamp: args.ts,
        nonce: args.nonce,
        deviceId: args.deviceId,
      );
      final sig2 = signer.sign(
        secret: 'secret-B',
        method: args.method,
        path: args.path,
        timestamp: args.ts,
        nonce: args.nonce,
        deviceId: args.deviceId,
      );
      expect(sig1, isNot(sig2));
    });
  });

  group('HmacSigner.buildHeaders', () {
    test('returns all 5 required headers', () {
      final headers = signer.buildHeaders(
        secret: secret,
        keyId: 'sk-001',
        method: 'POST',
        path: '/api/v1/orders',
        nonce: 'n-abc',
        deviceId: 'dev-001',
        body: '{"symbol":"AAPL"}',
      );
      expect(headers.keys, containsAll(['X-Timestamp', 'X-Nonce', 'X-Device-Id', 'X-Key-Id', 'X-Signature']));
    });

    test('X-Nonce and X-Device-Id match inputs', () {
      final headers = signer.buildHeaders(
        secret: secret,
        keyId: 'sk-001',
        method: 'POST',
        path: '/api/v1/orders',
        nonce: 'n-test-nonce',
        deviceId: 'dev-test-device',
      );
      expect(headers['X-Nonce'], 'n-test-nonce');
      expect(headers['X-Device-Id'], 'dev-test-device');
      expect(headers['X-Key-Id'], 'sk-001');
    });

    test('X-Timestamp is a valid millisecond epoch close to now', () {
      final headers = signer.buildHeaders(
        secret: secret,
        keyId: 'sk-001',
        method: 'GET',
        path: '/api/v1/orders',
        nonce: 'n-1',
        deviceId: 'dev-1',
      );
      final ts = int.tryParse(headers['X-Timestamp']!);
      expect(ts, isNotNull);
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      expect(ts!, closeTo(now, 5000));
    });

    test('X-Signature matches manual computation with returned timestamp', () {
      const nonce = 'n-verify';
      const deviceId = 'dev-verify';
      const body = '{"qty":100}';

      final headers = signer.buildHeaders(
        secret: secret,
        keyId: 'sk-001',
        method: 'POST',
        path: '/api/v1/orders',
        nonce: nonce,
        deviceId: deviceId,
        body: body,
      );

      final expected = signer.sign(
        secret: secret,
        method: 'POST',
        path: '/api/v1/orders',
        timestamp: headers['X-Timestamp']!,
        nonce: nonce,
        deviceId: deviceId,
        body: body,
      );
      expect(headers['X-Signature'], expected);
    });
  });
}
