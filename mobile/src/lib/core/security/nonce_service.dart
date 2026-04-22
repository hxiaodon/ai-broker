import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/token_service.dart';
import '../config/environment_config.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../network/authenticated_dio.dart';

part 'nonce_service.g.dart';

/// Fetches one-time server nonces for order submission and cancellation (S-02).
///
/// Each nonce is single-use with a 60s TTL on the server side.
/// Must be fetched immediately before each order/cancel request.
class NonceService {
  NonceService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> fetchNonce() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('/api/v1/trading/nonce');
      return resp.data!['nonce'] as String;
    } on DioException catch (e) {
      AppLogger.error('Failed to fetch trading nonce', error: e);
      throw NetworkException(message: 'Failed to fetch trading nonce', cause: e);
    }
  }
}

@Riverpod(keepAlive: true)
NonceService nonceService(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final dio = createAuthenticatedDio(
    baseUrl: EnvironmentConfig.instance.tradingBaseUrl,
    tokenService: tokenSvc,
  );
  return NonceService(dio: dio);
}
