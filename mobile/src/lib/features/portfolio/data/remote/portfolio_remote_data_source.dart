import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/position_detail.dart';
import 'models/position_detail_model.dart';
import 'portfolio_mappers.dart';

class PortfolioRemoteDataSource {
  PortfolioRemoteDataSource({
    required Dio dio,
    required ConnectivityService connectivity,
  })  : _dio = dio,
        _connectivity = connectivity;

  final Dio _dio;
  final ConnectivityService _connectivity;

  Future<PositionDetail> getPositionDetail(String symbol) async {
    await _checkConnectivity();
    try {
      final resp = await _dio.get<Map<String, dynamic>>(
        '/api/v1/positions/$symbol',
      );
      return PositionDetailModel.fromJson(resp.data!).toDomain();
    } on DioException catch (e) {
      throw _mapDioError(e, 'getPositionDetail');
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
      final msg = body is Map ? body['message'] as String? : null;
      return ServerException(
          statusCode: statusCode, message: msg ?? 'Client error');
    }
    return NetworkException(message: '$op failed: ${e.message}', cause: e);
  }
}
