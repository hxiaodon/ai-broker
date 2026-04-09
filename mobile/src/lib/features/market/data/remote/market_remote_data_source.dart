import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/connectivity_service.dart';
import '../mappers/market_mappers.dart';
import '../remote/market_response_models.dart';
import '../../domain/entities/financials.dart';
import '../../domain/entities/mover_item.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/stock_detail.dart';
import '../../domain/entities/watchlist.dart';
import '../../domain/repositories/market_data_repository.dart';

/// Dio-based implementation of all market-data REST endpoints.
///
/// Endpoints called:
///   GET /v1/market/quotes
///   GET /v1/market/kline
///   GET /v1/market/search
///   GET /v1/market/movers
///   GET /v1/market/stocks/{symbol}
///   GET /v1/market/news/{symbol}
///   GET /v1/market/financials/{symbol}
///   GET /v1/watchlist
///   POST /v1/watchlist
///   DELETE /v1/watchlist/{symbol}
///
/// Authentication is optional for /v1/market/* (JWT injected via Dio interceptor
/// when present — controls whether `delayed` is true/false in responses).
/// /v1/watchlist endpoints require a valid JWT.
///
/// Rate-limit handling: on 429 the response carries a `Retry-After: <seconds>`
/// header. This source waits for that duration (capped at [_maxRetryAfterSeconds])
/// and retries once before surfacing a [BusinessException].
class MarketRemoteDataSource {
  MarketRemoteDataSource(this._dio, this._connectivity);

  final Dio _dio;
  final ConnectivityService _connectivity;

  /// Maximum seconds to honour a Retry-After header before failing fast.
  static const int _maxRetryAfterSeconds = 30;

  // ─── Quotes ───────────────────────────────────────────────────────────────

  /// GET /v1/market/quotes?symbols=AAPL,TSLA,...
  Future<QuotesResponseDto> getQuotes(List<String> symbols) async {
    assert(symbols.isNotEmpty && symbols.length <= 50);
    return _withConnectivityCheck(
      operation: 'getQuotes',
      call: () => _withRateLimitRetry(
        operation: 'getQuotes',
        call: () async {
          final response = await _dio.get<Map<String, dynamic>>(
            '/v1/market/quotes',
            queryParameters: {'symbols': symbols.join(',')},
          );
          return QuotesResponseDto.fromJson(response.data!);
        },
      ),
    );
  }

  // ─── K-line ───────────────────────────────────────────────────────────────

  /// GET /v1/market/kline
  Future<KlineResponseDto> getKline({
    required String symbol,
    required String period,
    required String from,
    String? to,
    int? limit,
    String? cursor,
  }) async {
    return _withConnectivityCheck(
      operation: 'getKline',
      call: () => _withRateLimitRetry(
        operation: 'getKline',
        call: () async {
          final params = <String, dynamic>{
            'symbol': symbol,
            'period': period,
            'from': from,
          };
          if (to != null) params['to'] = to;
          if (limit != null) params['limit'] = limit;
          if (cursor != null) params['cursor'] = cursor;

          final startTime = DateTime.now();
          final response = await _dio.get<Map<String, dynamic>>(
            '/v1/market/kline',
            queryParameters: params,
          );
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          AppLogger.debug(
            'Market API: getKline $symbol/$period (from=$from, limit=$limit) — ${duration}ms',
          );
          return KlineResponseDto.fromJson(response.data!);
        },
      ),
    );
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  /// GET /v1/market/search?q=...
  Future<SearchResponseDto> searchStocks({
    required String q,
    String? market,
    int? limit,
  }) async {
    return _withConnectivityCheck(
      operation: 'searchStocks',
      call: () => _withRateLimitRetry(
        operation: 'searchStocks',
        call: () async {
          final params = <String, dynamic>{'q': q};
          if (market != null) params['market'] = market;
          if (limit != null) params['limit'] = limit;

          final startTime = DateTime.now();
          final response = await _dio.get<Map<String, dynamic>>(
            '/v1/market/search',
            queryParameters: params,
          );
          final duration = DateTime.now().difference(startTime).inMilliseconds;
          AppLogger.debug('Market API: searchStocks q="$q" (market=$market) — ${duration}ms');
          return SearchResponseDto.fromJson(response.data!);
        },
      ),
    );
  }

  // ─── Movers ───────────────────────────────────────────────────────────────

  /// GET /v1/market/movers
  Future<MoversResponseDto> getMovers({String? type, String? market}) async {
    return _withConnectivityCheck(
      operation: 'getMovers',
      call: () => _withRateLimitRetry(
        operation: 'getMovers',
        call: () async {
        final params = <String, dynamic>{};
        if (type != null) params['type'] = type;
        if (market != null) params['market'] = market;

        final response = await _dio.get<Map<String, dynamic>>(
          '/v1/market/movers',
          queryParameters: params.isEmpty ? null : params,
        );
        return MoversResponseDto.fromJson(response.data!);
        },
      ),
    );
  }

  // ─── Stock Detail ─────────────────────────────────────────────────────────

  /// GET /v1/market/stocks/{symbol}
  Future<StockDetailDto> getStockDetail(String symbol) async {
    return _withConnectivityCheck(
      operation: 'getStockDetail',
      call: () => _withRateLimitRetry(
        operation: 'getStockDetail',
        call: () async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/$symbol',
        );
        return StockDetailDto.fromJson(response.data!);
        },
      ),
    );
  }

  // ─── News ─────────────────────────────────────────────────────────────────

  /// GET /v1/market/news/{symbol}?page=...&page_size=...
  Future<NewsResponseDto> getNews(
    String symbol, {
    int page = 1,
    int pageSize = 10,
  }) async {
    return _withConnectivityCheck(
      operation: 'getNews',
      call: () => _withRateLimitRetry(
        operation: 'getNews',
        call: () async {
          final response = await _dio.get<Map<String, dynamic>>(
            '/v1/market/news/$symbol',
            queryParameters: {'page': page, 'page_size': pageSize},
          );
          AppLogger.debug('Market API: getNews $symbol (page=$page) — success');
          return NewsResponseDto.fromJson(response.data!);
        },
      ),
    );
  }

  // ─── Financials ───────────────────────────────────────────────────────────

  /// GET /v1/market/financials/{symbol}
  Future<FinancialsResponseDto> getFinancials(String symbol) async {
    return _withConnectivityCheck(
      operation: 'getFinancials',
      call: () => _withRateLimitRetry(
        operation: 'getFinancials',
        call: () async {
          final response = await _dio.get<Map<String, dynamic>>(
            '/v1/market/financials/$symbol',
          );
          AppLogger.debug('Market API: getFinancials $symbol — success');
          return FinancialsResponseDto.fromJson(response.data!);
        },
      ),
    );
  }

  // ─── Watchlist (requires JWT) ─────────────────────────────────────────────

  /// GET /v1/watchlist
  Future<WatchlistResponseDto> getWatchlist() async {
    return _withConnectivityCheck(
      operation: 'getWatchlist',
      call: () async {
        try {
          final response = await _dio.get<Map<String, dynamic>>('/v1/watchlist');
          AppLogger.debug('Market API: getWatchlist — success');
          return WatchlistResponseDto.fromJson(response.data!);
        } on DioException catch (e) {
          throw _mapDioException(e, 'getWatchlist');
        }
      },
    );
  }

  /// POST /v1/watchlist  { symbol, market }
  Future<void> addToWatchlist({
    required String symbol,
    required String market,
  }) async {
    return _withConnectivityCheck(
      operation: 'addToWatchlist',
      call: () async {
        try {
          await _dio.post<dynamic>(
            '/v1/watchlist',
            data: {'symbol': symbol, 'market': market},
          );
          AppLogger.info('Market API: added $symbol to watchlist');
        } on DioException catch (e) {
          throw _mapDioException(
            e,
            'addToWatchlist',
            context: {'symbol': symbol, 'market': market},
          );
        }
      },
    );
  }

  /// DELETE /v1/watchlist/{symbol}
  Future<void> removeFromWatchlist(String symbol) async {
    return _withConnectivityCheck(
      operation: 'removeFromWatchlist',
      call: () async {
        try {
          await _dio.delete<dynamic>('/v1/watchlist/$symbol');
          AppLogger.info('Market API: removed $symbol from watchlist');
        } on DioException catch (e) {
          throw _mapDioException(e, 'removeFromWatchlist', context: {'symbol': symbol});
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Connectivity check wrapper
  // ─────────────────────────────────────────────────────────────────────────

  /// Checks network connectivity before executing [call].
  /// Throws [NetworkException] immediately if offline, avoiding 30s timeout.
  Future<T> _withConnectivityCheck<T>({
    required String operation,
    required Future<T> Function() call,
  }) async {
    final isConnected = await _connectivity.isConnected;
    if (!isConnected) {
      AppLogger.warning('$operation: no network connectivity');
      throw NetworkException(message: '网络未连接，请检查网络设置');
    }
    return call();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 429 Retry-After wrapper
  // ─────────────────────────────────────────────────────────────────────────

  /// Executes [call], and if a 429 is received with a valid `Retry-After`
  /// header, waits for the specified duration (capped at
  /// [_maxRetryAfterSeconds]) and retries once.
  Future<T> _withRateLimitRetry<T>({
    required String operation,
    required Future<T> Function() call,
  }) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final retryAfter = _parseRetryAfter(e.response);
        if (retryAfter != null && retryAfter <= _maxRetryAfterSeconds) {
          AppLogger.warning(
            'Market API 429 [$operation] — retrying after ${retryAfter}s',
          );
          await Future<void>.delayed(Duration(seconds: retryAfter));
          try {
            final result = await call();
            AppLogger.info('Market API 429 [$operation] — retry succeeded');
            return result;
          } on DioException catch (e2) {
            AppLogger.error(
              'Market API 429 [$operation] — retry failed: ${e2.type}',
              error: e2,
            );
            throw _mapDioException(e2, '$operation (retry)');
          }
        }
      }
      throw _mapDioException(e, operation);
    }
  }

  /// Parse the `Retry-After` header value in seconds.
  int? _parseRetryAfter(Response<dynamic>? response) {
    final header = response?.headers.value('retry-after');
    if (header == null) return null;
    return int.tryParse(header);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dio → AppException mapping
  // ─────────────────────────────────────────────────────────────────────────

  AppException _mapDioException(
    DioException e,
    String operation, {
    Map<String, dynamic>? context,
  }) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String? errorCode;
    String? message;

    if (data is Map<String, dynamic>) {
      errorCode = data['error'] as String?;
      message = data['message'] as String?;
    }

    final contextStr = context != null ? ' context=$context' : '';
    AppLogger.warning(
      'Market API error [$operation]: status=$statusCode, code=$errorCode$contextStr',
    );

    switch (statusCode) {
      case 400:
        return BusinessException(
          message: message ?? '请求参数错误',
          errorCode: errorCode,
        );
      case 401:
        return const AuthException(message: '未登录或登录已过期，请重新登录');
      case 403:
        return const AuthException(message: '没有权限访问该资源');
      case 404:
        return BusinessException(
          message: message ?? '股票代码不存在或暂无数据',
          errorCode: errorCode ?? 'NOT_FOUND',
        );
      case 429:
        return BusinessException(
          message: message ?? '请求过于频繁，请稍后重试',
          errorCode: errorCode ?? 'RATE_LIMIT_EXCEEDED',
        );
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          return const NetworkException(message: '请求超时，请检查网络连接');
        }
        if (e.type == DioExceptionType.connectionError) {
          return const NetworkException(message: '无法连接服务器，请检查网络');
        }
        return ServerException(
          message: message ?? '服务器错误，请稍后重试',
          statusCode: statusCode ?? 0,
          errorCode: errorCode,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience mappers used by MarketDataRepositoryImpl (thin pass-through)
// ─────────────────────────────────────────────────────────────────────────────

extension QuotesResponseDtoMapperExt on QuotesResponseDto {
  Map<String, dynamic> toQuoteMap() =>
      quotes.map((k, v) => MapEntry(k, v.toDomain()));
}

extension MoversResponseDtoExt on MoversResponseDto {
  List<MoverItem> toMoverList() => items.toDomainList();
}

extension SearchResponseDtoExt on SearchResponseDto {
  List<SearchResult> toSearchResultList() => results.toDomainList();
}

extension KlineResponseDtoExt on KlineResponseDto {
  KlineResult toKlineResult() => KlineResult(
        symbol: symbol,
        period: period,
        candles: candles.toDomainList(),
        total: total,
        nextCursor: nextCursor,
      );
}

extension NewsResponseDtoExt on NewsResponseDto {
  NewsResult toNewsResult() => NewsResult(
        symbol: symbol,
        articles: news.toDomainList(),
        page: page,
        pageSize: pageSize,
        total: total,
      );
}

extension StockDetailDtoExt on StockDetailDto {
  StockDetail toStockDetail() => toDomain();
}

extension FinancialsResponseDtoExt on FinancialsResponseDto {
  Financials toFinancials() => toDomain();
}

extension WatchlistResponseDtoExt on WatchlistResponseDto {
  Watchlist toWatchlist() => toDomain();
}
