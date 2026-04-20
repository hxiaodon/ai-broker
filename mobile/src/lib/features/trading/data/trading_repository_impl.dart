import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/token_service.dart';
import '../../../core/config/environment_config.dart';
import '../../../core/network/authenticated_dio.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/security/hmac_signer.dart';
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
      );

  @override
  Future<void> cancelOrder(String orderId) => _remote.cancelOrder(orderId);

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
  final dio = createAuthenticatedDio(
    baseUrl: baseUrl,
    tokenService: tokenSvc,
  );
  final connectivity = ref.watch(connectivityServiceProvider);
  // HMAC secret comes from env; empty string is safe for dev (server validates)
  const hmacSecret = String.fromEnvironment('TRADING_HMAC_SECRET');
  return TradingRepositoryImpl(
    remote: TradingRemoteDataSource(
      dio: dio,
      signer: const HmacSigner(hmacSecret),
      connectivity: connectivity,
    ),
  );
}
