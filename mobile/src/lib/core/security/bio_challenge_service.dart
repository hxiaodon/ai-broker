import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/token_service.dart';
import '../config/environment_config.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../network/authenticated_dio.dart';

part 'bio_challenge_service.g.dart';

/// Handles biometric challenge-response protocol for order submission (S-03).
///
/// Flow:
///   1. fetchChallenge() — GET /api/v1/trading/bio-challenge (30s TTL, one-time)
///   2. Caller triggers local_auth.authenticate()
///   3. computeBioToken() — HMAC binds challenge to specific order + device
class BioChallengeService {
  BioChallengeService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> fetchChallenge() async {
    try {
      final resp =
          await _dio.get<Map<String, dynamic>>('/api/v1/trading/bio-challenge');
      return resp.data!['challenge'] as String;
    } on DioException catch (e) {
      AppLogger.error('Failed to fetch bio challenge', error: e);
      throw NetworkException(message: 'Failed to fetch biometric challenge', cause: e);
    }
  }

  /// HMAC-SHA256(sessionSecret, challenge|timestamp|deviceId|actionHash)
  ///
  /// Uses `|` separators matching the production spec (security-protocol.md §4.2).
  String computeBioToken({
    required String sessionSecret,
    required String challenge,
    required String timestamp,
    required String deviceId,
    required String actionHash,
  }) {
    final payload = '$challenge|$timestamp|$deviceId|$actionHash';
    final hmac = Hmac(sha256, utf8.encode(sessionSecret));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  /// SHA256(SIDE|SYMBOL|QTY|PRICE|ACCOUNT_ID)
  ///
  /// Binds the challenge to a specific account + order, preventing cross-account
  /// replay (security-protocol.md §4.2). All fields use `|` separator.
  static String computeActionHash({
    required String side,
    required String symbol,
    required int qty,
    required String accountId,
    String price = '',
  }) {
    final normalized =
        '${side.toUpperCase()}|$symbol|$qty|$price|$accountId';
    return sha256.convert(utf8.encode(normalized)).toString();
  }
}

@Riverpod(keepAlive: true)
BioChallengeService bioChallengeService(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final dio = createAuthenticatedDio(
    baseUrl: EnvironmentConfig.instance.tradingBaseUrl,
    tokenService: tokenSvc,
  );
  return BioChallengeService(dio: dio);
}
