import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/token_service.dart';
import '../config/environment_config.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../network/authenticated_dio.dart';

part 'fund_withdrawal_bio_service.g.dart';

/// Handles biometric challenge-response for fund withdrawal operations.
///
/// Flow:
///   1. fetchChallenge() — POST /api/v1/funding/bio-challenge (30s TTL, one-time)
///   2. Caller triggers local_auth.authenticate()
///   3. computeBioToken() — HMAC binds challenge to withdrawal + device
class FundWithdrawalBioService {
  FundWithdrawalBioService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> fetchChallenge() async {
    try {
      final resp = await _dio
          .post<Map<String, dynamic>>('/api/v1/funding/bio-challenge');
      return resp.data!['challenge'] as String;
    } on DioException catch (e) {
      AppLogger.error('Failed to fetch fund bio challenge', error: e);
      throw NetworkException(
          message: 'Failed to fetch biometric challenge', cause: e);
    }
  }

  /// HMAC-SHA256(sessionSecret, challenge|timestamp|deviceId|actionHash)
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

  /// SHA256(WITHDRAWAL|AMOUNT|BANK_ACCOUNT_ID|ACCOUNT_ID)
  ///
  /// Binds the challenge to a specific withdrawal, preventing cross-account
  /// replay attacks.
  static String computeActionHash({
    required String amount,
    required String bankAccountId,
    required String accountId,
  }) {
    final normalized = 'WITHDRAWAL|$amount|$bankAccountId|$accountId';
    return sha256.convert(utf8.encode(normalized)).toString();
  }
}

@Riverpod(keepAlive: true)
FundWithdrawalBioService fundWithdrawalBioService(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final dio = createAuthenticatedDio(
    baseUrl: EnvironmentConfig.instance.fundingBaseUrl,
    tokenService: tokenSvc,
  );
  return FundWithdrawalBioService(dio: dio);
}
