import 'dart:convert';
import 'package:crypto/crypto.dart';

class HmacSigner {
  final String _secret;

  const HmacSigner(this._secret);

  /// Signs a trading API request per the contract spec:
  /// HMAC-SHA256( method + "\n" + path + "\n" + timestamp + "\n" + bodyHash )
  String sign({
    required String method,
    required String path,
    required String timestamp,
    String body = '',
  }) {
    final bodyHash = sha256.convert(utf8.encode(body)).toString();
    final payload = '${method.toUpperCase()}\n$path\n$timestamp\n$bodyHash';
    final key = utf8.encode(_secret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  Map<String, String> buildHeaders({
    required String method,
    required String path,
    String body = '',
  }) {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    final signature = sign(
      method: method,
      path: path,
      timestamp: timestamp,
      body: body,
    );
    return {
      'X-Timestamp': timestamp,
      'X-Signature': signature,
    };
  }
}
