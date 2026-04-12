import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/token_service.dart';
import '../../../core/network/authenticated_dio.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/entities/financials.dart';
import '../domain/entities/mover_item.dart';
import '../domain/entities/search_result.dart';
import '../domain/entities/stock_detail.dart';
import '../domain/entities/watchlist.dart';
import '../domain/repositories/market_data_repository.dart';
import 'remote/market_remote_data_source.dart';

part 'market_data_repository_impl.g.dart';

const _kMarketBaseUrl = String.fromEnvironment(
  'MARKET_BASE_URL',
  defaultValue: _defaultMarketBaseUrl,
);

/// Default base URL for market API.
/// In test environments (iOS simulator), use 10.0.2.2 to access host machine.
/// In production, use the actual staging/production endpoint.
const _defaultMarketBaseUrl = 'http://localhost:8080';

/// Production implementation of [MarketDataRepository].
///
/// Delegates all network calls to [MarketRemoteDataSource].
/// Errors from the data source (already [AppException] subtypes) propagate
/// unchanged — no second mapping layer is needed.
class MarketDataRepositoryImpl implements MarketDataRepository {
  MarketDataRepositoryImpl({required MarketRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final MarketRemoteDataSource _remote;

  // ─── Quotes ───────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getQuotes(List<String> symbols) async {
    AppLogger.debug('getQuotes: ${symbols.join(',')}');
    final dto = await _remote.getQuotes(symbols);
    return dto.toQuoteMap();
  }

  // ─── K-line ───────────────────────────────────────────────────────────────

  @override
  Future<KlineResult> getKline({
    required String symbol,
    required String period,
    required String from,
    String? to,
    int? limit,
    String? cursor,
  }) async {
    AppLogger.debug('getKline: $symbol $period from=$from');
    final dto = await _remote.getKline(
      symbol: symbol,
      period: period,
      from: from,
      to: to,
      limit: limit,
      cursor: cursor,
    );
    return dto.toKlineResult();
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  @override
  Future<List<SearchResult>> searchStocks({
    required String q,
    String? market,
    int? limit,
  }) async {
    AppLogger.debug('searchStocks: "$q"');
    final dto = await _remote.searchStocks(q: q, market: market, limit: limit);
    return dto.toSearchResultList();
  }

  // ─── Movers ───────────────────────────────────────────────────────────────

  @override
  Future<List<MoverItem>> getMovers({String? type, String? market}) async {
    AppLogger.debug('getMovers: type=$type market=$market');
    final dto = await _remote.getMovers(type: type, market: market);
    return dto.toMoverList();
  }

  // ─── Stock Detail ─────────────────────────────────────────────────────────

  @override
  Future<StockDetail> getStockDetail(String symbol) async {
    AppLogger.debug('getStockDetail: $symbol');
    final dto = await _remote.getStockDetail(symbol);
    return dto.toStockDetail();
  }

  // ─── News ─────────────────────────────────────────────────────────────────

  @override
  Future<NewsResult> getNews(
    String symbol, {
    int page = 1,
    int pageSize = 10,
  }) async {
    AppLogger.debug('getNews: $symbol page=$page');
    final dto = await _remote.getNews(symbol, page: page, pageSize: pageSize);
    return dto.toNewsResult();
  }

  // ─── Financials ───────────────────────────────────────────────────────────

  @override
  Future<Financials> getFinancials(String symbol) async {
    AppLogger.debug('getFinancials: $symbol');
    final dto = await _remote.getFinancials(symbol);
    return dto.toFinancials();
  }

  // ─── Watchlist ────────────────────────────────────────────────────────────

  @override
  Future<Watchlist> getWatchlist() async {
    AppLogger.debug('getWatchlist');
    final dto = await _remote.getWatchlist();
    return dto.toWatchlist();
  }

  @override
  Future<void> addToWatchlist({
    required String symbol,
    required String market,
  }) async {
    AppLogger.debug('addToWatchlist: $symbol ($market)');
    await _remote.addToWatchlist(symbol: symbol, market: market);
  }

  @override
  Future<void> removeFromWatchlist(String symbol) async {
    AppLogger.debug('removeFromWatchlist: $symbol');
    await _remote.removeFromWatchlist(symbol);
  }
}

/// Wires up [MarketDataRepositoryImpl] with its [MarketRemoteDataSource].
///
/// Uses a dedicated Dio instance for the market-data service.
/// JWT is injected by [AuthInterceptor] via [createAuthenticatedDio].
@Riverpod(keepAlive: true)
MarketDataRepository marketDataRepository(Ref ref) {
  final tokenSvc = ref.read(tokenServiceProvider);
  final dio = createAuthenticatedDio(
    baseUrl: _kMarketBaseUrl,
    tokenService: tokenSvc,
  );
  final connectivity = ref.watch(connectivityServiceProvider);
  return MarketDataRepositoryImpl(
    remoteDataSource: MarketRemoteDataSource(dio, connectivity),
  );
}
