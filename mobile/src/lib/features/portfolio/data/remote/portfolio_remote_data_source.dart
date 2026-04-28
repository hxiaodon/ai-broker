import 'package:dio/dio.dart';

import '../../../../core/auth/device_info_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/security/hmac_signer.dart';
import '../../../../core/security/nonce_service.dart';
import '../../../../core/security/session_key_service.dart';
import '../../domain/entities/position_detail.dart';
import 'models/position_detail_model.dart';
import 'portfolio_mappers.dart';

/// US stock symbols: 1–5 uppercase letters.
/// HK stock symbols: 4–5 digit codes.
final _symbolPattern = RegExp(r'^([A-Z]{1,5}|\d{4,5})$');

class PortfolioRemoteDataSource {
  PortfolioRemoteDataSource({
    required Dio dio,
    required ConnectivityService connectivity,
    required HmacSigner signer,
    required SessionKeyService sessionKeyService,
    required NonceService nonceService,
    required DeviceInfoService deviceInfoService,
  })  : _dio = dio,
        _connectivity = connectivity,
        _signer = signer,
        _sessionKeyService = sessionKeyService,
        _nonceService = nonceService,
        _deviceInfoService = deviceInfoService;

  final Dio _dio;
  final ConnectivityService _connectivity;
  final HmacSigner _signer;
  final SessionKeyService _sessionKeyService;
  final NonceService _nonceService;
  final DeviceInfoService _deviceInfoService;

  Future<PositionDetail> getPositionDetail(String symbol) async {
    if (!_symbolPattern.hasMatch(symbol)) {
      throw const ValidationException(message: 'Invalid symbol format');
    }
    await _checkConnectivity();
    final path = '/api/v1/positions/$symbol';
    final sessionKey = await _sessionKeyService.getSessionKey();
    final nonce = await _nonceService.fetchNonce();
    final deviceId = await _deviceInfoService.getDeviceId();
    final sigHeaders = _signer.buildHeaders(
      secret: sessionKey.secret,
      keyId: sessionKey.keyId,
      method: 'GET',
      path: path,
      nonce: nonce,
      deviceId: deviceId,
    );
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(headers: sigHeaders),
      );
      return PositionDetailModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getPositionDetail');
    } on FormatException catch (_) {
      AppLogger.warning('getPositionDetail: invalid response format');
      throw const ServerException(statusCode: 0, message: 'Invalid response format');
    }
  }

  Future<void> _checkConnectivity() async {
    if (!await _connectivity.isConnected) {
      throw const NetworkException(message: 'No internet connection');
    }
  }

  AppException _mapDioError(DioException e, String op) {
    AppLogger.warning('$op failed: type=${e.type.name}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: '$op timed out', cause: e);
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return AuthException(message: 'Unauthorized', cause: e);
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerException(
          statusCode: statusCode, message: 'Server error ($statusCode)');
    }
    if (statusCode != null && statusCode >= 400) {
      final body = e.response?.data;
      final raw = body is Map ? body['message'] as String? : null;
      // Truncate server message to prevent internal detail leakage.
      final msg = raw != null && raw.length <= 200 ? raw : null;
      return ServerException(
          statusCode: statusCode, message: msg ?? 'Client error');
    }
    return NetworkException(message: '$op failed', cause: e);
  }
}
