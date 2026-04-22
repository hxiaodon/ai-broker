import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Stateless HMAC-SHA256 signer for trading API requests.
///
/// Payload format (contract v3, 6 segments):
///   METHOD\nPATH\nTIMESTAMP\nNONCE\nDEVICE_ID\nBODY_HASH
///
/// Secret is passed per-call (dynamic session key from SessionKeyService).
class HmacSigner {
  const HmacSigner();

  String sign({
    required String secret,
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
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  Map<String, String> buildHeaders({
    required String secret,
    required String keyId,
    required String method,
    required String path,
    required String nonce,
    required String deviceId,
    String body = '',
  }) {
    final timestamp =
        DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    final signature = sign(
      secret: secret,
      method: method,
      path: path,
      timestamp: timestamp,
      nonce: nonce,
      deviceId: deviceId,
      body: body,
    );
    return {
      'X-Timestamp': timestamp,
      'X-Nonce': nonce,
      'X-Device-Id': deviceId,
      'X-Key-Id': keyId,
      'X-Signature': signature,
    };
  }
}
