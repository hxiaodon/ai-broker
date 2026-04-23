import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../../../../core/auth/device_info_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/security/hmac_signer.dart';
import '../../../../core/security/nonce_service.dart';
import '../../../../core/security/session_key_service.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_fill.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/position.dart';
import 'models/order_model.dart';
import 'models/portfolio_summary_model.dart';
import 'models/position_model.dart';
import 'trading_mappers.dart';

class TradingRemoteDataSource {
  TradingRemoteDataSource({
    required Dio dio,
    required HmacSigner signer,
    required ConnectivityService connectivity,
    required SessionKeyService sessionKeyService,
    required NonceService nonceService,
    required DeviceInfoService deviceInfoService,
  })  : _dio = dio,
        _signer = signer,
        _connectivity = connectivity,
        _sessionKeyService = sessionKeyService,
        _nonceService = nonceService,
        _deviceInfoService = deviceInfoService;

  final Dio _dio;
  final HmacSigner _signer;
  final ConnectivityService _connectivity;
  final SessionKeyService _sessionKeyService;
  final NonceService _nonceService;
  final DeviceInfoService _deviceInfoService;

  Future<Order> submitOrder({
    required String symbol,
    required String market,
    required OrderSide side,
    required OrderType orderType,
    required int qty,
    Decimal? limitPrice,
    required OrderValidity validity,
    required bool extendedHours,
    required String idempotencyKey,
    required String biometricToken,
    required String bioChallenge,
    required String bioTimestamp,
  }) async {
    await _checkConnectivity();
    const path = '/api/v1/orders';
    final body = {
      'symbol': symbol,
      'market': market,
      'side': side.name,
      'order_type': orderType == OrderType.market ? 'market' : 'limit',
      'qty': qty,
      if (limitPrice != null) 'limit_price': limitPrice.toString(),
      'validity': validity.name,
      'extended_hours': extendedHours,
    };
    final bodyJson = jsonEncode(body);

    final sessionKey = await _sessionKeyService.getSessionKey();
    final nonce = await _nonceService.fetchNonce();
    final deviceId = await _deviceInfoService.getDeviceId();

    final sigHeaders = _signer.buildHeaders(
      secret: sessionKey.secret,
      keyId: sessionKey.keyId,
      method: 'POST',
      path: path,
      nonce: nonce,
      deviceId: deviceId,
      body: bodyJson,
    );

    try {
      final resp = await _dio.post<Map<String, dynamic>>(
        path,
        data: bodyJson,
        options: Options(headers: {
          'Content-Type': 'application/json',
          ...sigHeaders,
          'Idempotency-Key': idempotencyKey,
          'X-Biometric-Token': biometricToken,
          'X-Bio-Challenge': bioChallenge,
          'X-Bio-Timestamp': bioTimestamp,
        }),
      );
      AppLogger.debug('submitOrder success: orderId=${resp.data?['order_id']}');
      return OrderModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'submitOrder');
    }
  }

  Future<void> cancelOrder(String orderId, {required String idempotencyKey}) async {
    await _checkConnectivity();
    final path = '/api/v1/orders/$orderId';

    final sessionKey = await _sessionKeyService.getSessionKey();
    final nonce = await _nonceService.fetchNonce();
    final deviceId = await _deviceInfoService.getDeviceId();

    final sigHeaders = _signer.buildHeaders(
      secret: sessionKey.secret,
      keyId: sessionKey.keyId,
      method: 'DELETE',
      path: path,
      nonce: nonce,
      deviceId: deviceId,
    );

    try {
      await _dio.delete<void>(
        path,
        options: Options(headers: {
          ...sigHeaders,
          'Idempotency-Key': idempotencyKey,
        }),
      );
    } on DioException catch (e) {
      throw _mapDioError(e, 'cancelOrder');
    }
  }

  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? market,
  }) async {
    await _checkConnectivity();
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/v1/orders',
        queryParameters: {
          'status': status != null ? _statusToString(status) : null,
          'from_date': fromDate?.toUtc().toIso8601String(),
          'to_date': toDate?.toUtc().toIso8601String(),
          'market': market,
        }..removeWhere((_, v) => v == null),
      );
      return (resp.data!['orders'] as List)
          .cast<Map<String, dynamic>>()
          .map((j) => OrderModel.fromJson(j).toDomain())
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getOrders');
    }
  }

  Future<(Order, List<OrderFill>)> getOrderDetail(String orderId) async {
    await _checkConnectivity();
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/v1/orders/$orderId',
      );
      final detail = OrderDetailModel.fromJson(resp.data!);
      return (
        detail.order.toDomain(),
        detail.fills.map((f) => f.toDomain()).toList(),
      );
    } on DioException catch (e) {
      throw _mapDioError(e, 'getOrderDetail');
    }
  }

  Future<List<Position>> getPositions() async {
    await _checkConnectivity();
    try {
      final resp = await _dio.get<Map<String, dynamic>>('/api/v1/positions');
      return (resp.data!['positions'] as List)
          .cast<Map<String, dynamic>>()
          .map((j) => PositionModel.fromJson(j).toDomain())
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getPositions');
    }
  }

  Future<Position> getPositionDetail(String symbol) async {
    await _checkConnectivity();
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/v1/positions/$symbol',
      );
      return PositionModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getPositionDetail');
    }
  }

  Future<PortfolioSummary> getPortfolioSummary() async {
    await _checkConnectivity();
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/v1/portfolio/summary',
      );
      return PortfolioSummaryModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getPortfolioSummary');
    }
  }

  Future<void> _checkConnectivity() async {
    if (!await _connectivity.isConnected) {
      throw const NetworkException(message: 'No internet connection');
    }
  }

  AppException _mapDioError(DioException e, String op) {
    AppLogger.warning('$op failed: ${e.message}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException(message: '$op timed out', cause: e);
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return AuthException(message: 'Unauthorized', cause: e);
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      final body = e.response?.data;
      final errorCode = body is Map ? body['error_code'] as String? : null;
      final message = body is Map ? body['message'] as String? : null;
      return BusinessException(
        message: message ?? '$op failed',
        errorCode: errorCode ?? 'UNKNOWN',
        cause: e,
      );
    }
    return NetworkException(message: '$op failed: ${e.message}', cause: e);
  }

  String _statusToString(OrderStatus s) {
    switch (s) {
      case OrderStatus.riskChecking:
        return 'RISK_CHECKING';
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.partiallyFilled:
        return 'PARTIALLY_FILLED';
      case OrderStatus.filled:
        return 'FILLED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      case OrderStatus.partiallyFilledCancelled:
        return 'PARTIALLY_FILLED_CANCELLED';
      case OrderStatus.expired:
        return 'EXPIRED';
      case OrderStatus.rejected:
        return 'REJECTED';
      case OrderStatus.exchangeRejected:
        return 'EXCHANGE_REJECTED';
    }
  }
}
