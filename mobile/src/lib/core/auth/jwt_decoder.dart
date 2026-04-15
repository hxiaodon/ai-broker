import 'dart:convert';

import '../logging/app_logger.dart';

/// JWT decoder utility for extracting claims from JWT tokens.
///
/// Provides safe parsing of JWT tokens without external dependencies.
/// Used by AuthNotifier and AuthRepositoryImpl to extract account information.
class JwtDecoder {
  JwtDecoder._();

  /// Extracts a claim from a JWT token.
  ///
  /// Returns null if the token is malformed or the claim doesn't exist.
  static String? extractClaim(String jwt, String claim) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) {
        AppLogger.debug('JwtDecoder: invalid JWT format (expected 3 parts)');
        return null;
      }

      final payload = parts[1];
      final decoded = _base64UrlDecode(payload);
      final jsonStr = utf8.decode(decoded);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      return json[claim]?.toString();
    } catch (e, st) {
      AppLogger.debug('JwtDecoder: failed to extract claim "$claim"', error: e, stackTrace: st);
      return null;
    }
  }

  /// Extracts the account ID from a JWT token.
  ///
  /// Tries multiple claim names in order: 'sub', 'account_id', 'user_id'.
  /// Returns null if none are found.
  static String? extractAccountId(String jwt) {
    return extractClaim(jwt, 'sub') ??
        extractClaim(jwt, 'account_id') ??
        extractClaim(jwt, 'user_id');
  }

  /// Decodes a base64url-encoded string (JWT payload).
  ///
  /// Handles padding normalization required by JWT spec.
  static List<int> _base64UrlDecode(String input) {
    var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    // Add padding if needed
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
      case 3:
        normalized += '=';
    }
    return base64.decode(normalized);
  }
}
