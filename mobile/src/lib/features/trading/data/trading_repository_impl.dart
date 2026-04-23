import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/device_info_service.dart';
import '../../../core/auth/token_service.dart';
import '../../../core/config/environment_config.dart';
import '../../../core/network/authenticated_dio.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/security/hmac_signer.dart';
import '../../../core/security/nonce_service.dart';
import '../../../core/security/session_key_service.dart';
import '../domain/entities/order.dart';
import '../domain/entities/order_fill.dart';
import '../domain/entities/portfolio_summary.dart';
import '../domain/entities/position.dart';
import '../domain/repositories/trading_repository.dart';
import 'remote/trading_remote_data_source.dart';

part 'trading_repository_impl.g.dart';

class TradingRepositoryImpl implements TradingRepository {
  TradingRepositoryImpl({required TradingRemoteDataSource remote})
      : _remote = remote;

  final TradingRemoteDataSource _remote;

  @override
  Future<(Order, String? requestId)> submitOrder({
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
  }) =>
      _remote.submitOrder(
        symbol: symbol,
        market: market,
        side: side,
        orderType: orderType,
        qty: qty,
        limitPrice: limitPrice,
        validity: validity,
        extendedHours: extendedHours,
        idempotencyKey: idempotencyKey,
        biometricToken: biometricToken,
        bioChallenge: bioChallenge,
        bioTimestamp: bioTimestamp,
      );

  @override
  Future<void> cancelOrder(String orderId, {required String idempotencyKey}) =>
      _remote.cancelOrder(orderId, idempotencyKey: idempotencyKey);

  @override
  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String? market,
  }) =>
      _remote.getOrders(
        status: status,
        fromDate: fromDate,
        toDate: toDate,
        market: market,
      );

  @override
  Future<(Order, List<OrderFill>)> getOrderDetail(String orderId) =>
      _remote.getOrderDetail(orderId);

  @override
  Future<List<Position>> getPositions() => _remote.getPositions();

  @override
  Future<Position> getPositionDetail(String symbol) =>
      _remote.getPositionDetail(symbol);

  @override
  Future<PortfolioSummary> getPortfolioSummary() =>
      _remote.getPortfolioSummary();
}

@Riverpod(keepAlive: true)
TradingRepository tradingRepository(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final baseUrl = EnvironmentConfig.instance.tradingBaseUrl;
  final dio = createAuthenticatedDio(baseUrl: baseUrl, tokenService: tokenSvc);
  return TradingRepositoryImpl(
    remote: TradingRemoteDataSource(
      dio: dio,
      signer: const HmacSigner(),
      connectivity: ref.watch(connectivityServiceProvider),
      sessionKeyService: ref.read(sessionKeyServiceProvider),
      nonceService: ref.read(nonceServiceProvider),
      deviceInfoService: ref.read(deviceInfoServiceProvider),
    ),
  );
}
