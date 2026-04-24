import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/token_service.dart';
import '../../../core/config/environment_config.dart';
import '../../../core/network/authenticated_dio.dart';
import '../../../core/network/connectivity_service.dart';
import '../domain/entities/position_detail.dart';
import '../domain/repositories/portfolio_repository.dart';
import 'remote/portfolio_remote_data_source.dart';

part 'portfolio_repository_impl.g.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl({required PortfolioRemoteDataSource remote})
      : _remote = remote;

  final PortfolioRemoteDataSource _remote;

  @override
  Future<PositionDetail> getPositionDetail(String symbol) =>
      _remote.getPositionDetail(symbol);
}

@Riverpod(keepAlive: true)
PortfolioRepository portfolioRepository(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final baseUrl = EnvironmentConfig.instance.tradingBaseUrl;
  final dio = createAuthenticatedDio(baseUrl: baseUrl, tokenService: tokenSvc);
  return PortfolioRepositoryImpl(
    remote: PortfolioRemoteDataSource(
      dio: dio,
      connectivity: ref.watch(connectivityServiceProvider),
    ),
  );
}
