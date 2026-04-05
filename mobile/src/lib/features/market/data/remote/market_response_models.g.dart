// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_response_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuoteDto _$QuoteDtoFromJson(Map<String, dynamic> json) => _QuoteDto(
  symbol: json['symbol'] as String,
  name: json['name'] as String,
  nameZh: json['name_zh'] as String,
  market: json['market'] as String,
  price: json['price'] as String,
  change: json['change'] as String,
  changePct: json['change_pct'] as String,
  volume: (json['volume'] as num).toInt(),
  bid: json['bid'] as String?,
  ask: json['ask'] as String?,
  turnover: json['turnover'] as String,
  prevClose: json['prev_close'] as String,
  open: json['open'] as String,
  high: json['high'] as String,
  low: json['low'] as String,
  marketCap: json['market_cap'] as String,
  peRatio: json['pe_ratio'] as String?,
  delayed: json['delayed'] as bool,
  marketStatus: json['market_status'] as String,
  isStale: json['is_stale'] as bool? ?? false,
  staleSinceMs: (json['stale_since_ms'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$QuoteDtoToJson(_QuoteDto instance) => <String, dynamic>{
  'symbol': instance.symbol,
  'name': instance.name,
  'name_zh': instance.nameZh,
  'market': instance.market,
  'price': instance.price,
  'change': instance.change,
  'change_pct': instance.changePct,
  'volume': instance.volume,
  'bid': instance.bid,
  'ask': instance.ask,
  'turnover': instance.turnover,
  'prev_close': instance.prevClose,
  'open': instance.open,
  'high': instance.high,
  'low': instance.low,
  'market_cap': instance.marketCap,
  'pe_ratio': instance.peRatio,
  'delayed': instance.delayed,
  'market_status': instance.marketStatus,
  'is_stale': instance.isStale,
  'stale_since_ms': instance.staleSinceMs,
};

_QuotesResponseDto _$QuotesResponseDtoFromJson(Map<String, dynamic> json) =>
    _QuotesResponseDto(
      quotes: (json['quotes'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, QuoteDto.fromJson(e as Map<String, dynamic>)),
      ),
      asOf: json['as_of'] as String,
    );

Map<String, dynamic> _$QuotesResponseDtoToJson(_QuotesResponseDto instance) =>
    <String, dynamic>{'quotes': instance.quotes, 'as_of': instance.asOf};

_CandleDto _$CandleDtoFromJson(Map<String, dynamic> json) => _CandleDto(
  t: json['t'] as String,
  o: json['o'] as String,
  h: json['h'] as String,
  l: json['l'] as String,
  c: json['c'] as String,
  v: (json['v'] as num).toInt(),
  n: (json['n'] as num).toInt(),
);

Map<String, dynamic> _$CandleDtoToJson(_CandleDto instance) =>
    <String, dynamic>{
      't': instance.t,
      'o': instance.o,
      'h': instance.h,
      'l': instance.l,
      'c': instance.c,
      'v': instance.v,
      'n': instance.n,
    };

_KlineResponseDto _$KlineResponseDtoFromJson(Map<String, dynamic> json) =>
    _KlineResponseDto(
      symbol: json['symbol'] as String,
      period: json['period'] as String,
      candles: (json['candles'] as List<dynamic>)
          .map((e) => CandleDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['next_cursor'] as String?,
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$KlineResponseDtoToJson(_KlineResponseDto instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'period': instance.period,
      'candles': instance.candles,
      'next_cursor': instance.nextCursor,
      'total': instance.total,
    };

_SearchResultDto _$SearchResultDtoFromJson(Map<String, dynamic> json) =>
    _SearchResultDto(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      nameZh: json['name_zh'] as String,
      market: json['market'] as String,
      price: json['price'] as String,
      changePct: json['change_pct'] as String,
      delayed: json['delayed'] as bool,
    );

Map<String, dynamic> _$SearchResultDtoToJson(_SearchResultDto instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'name_zh': instance.nameZh,
      'market': instance.market,
      'price': instance.price,
      'change_pct': instance.changePct,
      'delayed': instance.delayed,
    };

_SearchResponseDto _$SearchResponseDtoFromJson(Map<String, dynamic> json) =>
    _SearchResponseDto(
      results: (json['results'] as List<dynamic>)
          .map((e) => SearchResultDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$SearchResponseDtoToJson(_SearchResponseDto instance) =>
    <String, dynamic>{'results': instance.results, 'total': instance.total};

_MoverItemDto _$MoverItemDtoFromJson(Map<String, dynamic> json) =>
    _MoverItemDto(
      rank: (json['rank'] as num).toInt(),
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      nameZh: json['name_zh'] as String,
      price: json['price'] as String,
      change: json['change'] as String,
      changePct: json['change_pct'] as String,
      volume: (json['volume'] as num).toInt(),
      turnover: json['turnover'] as String,
      marketStatus: json['market_status'] as String,
    );

Map<String, dynamic> _$MoverItemDtoToJson(_MoverItemDto instance) =>
    <String, dynamic>{
      'rank': instance.rank,
      'symbol': instance.symbol,
      'name': instance.name,
      'name_zh': instance.nameZh,
      'price': instance.price,
      'change': instance.change,
      'change_pct': instance.changePct,
      'volume': instance.volume,
      'turnover': instance.turnover,
      'market_status': instance.marketStatus,
    };

_MoversResponseDto _$MoversResponseDtoFromJson(Map<String, dynamic> json) =>
    _MoversResponseDto(
      type: json['type'] as String,
      market: json['market'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => MoverItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      asOf: json['as_of'] as String,
    );

Map<String, dynamic> _$MoversResponseDtoToJson(_MoversResponseDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'market': instance.market,
      'items': instance.items,
      'as_of': instance.asOf,
    };

_StockDetailDto _$StockDetailDtoFromJson(Map<String, dynamic> json) =>
    _StockDetailDto(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      nameZh: json['name_zh'] as String,
      market: json['market'] as String,
      price: json['price'] as String,
      change: json['change'] as String,
      changePct: json['change_pct'] as String,
      open: json['open'] as String,
      high: json['high'] as String,
      low: json['low'] as String,
      prevClose: json['prev_close'] as String,
      volume: (json['volume'] as num).toInt(),
      turnover: json['turnover'] as String,
      bid: json['bid'] as String?,
      ask: json['ask'] as String?,
      delayed: json['delayed'] as bool,
      marketStatus: json['market_status'] as String,
      session: json['session'] as String,
      isStale: json['is_stale'] as bool? ?? false,
      staleSinceMs: (json['stale_since_ms'] as num?)?.toInt() ?? 0,
      marketCap: json['market_cap'] as String,
      peRatio: json['pe_ratio'] as String,
      pbRatio: json['pb_ratio'] as String,
      dividendYield: json['dividend_yield'] as String,
      sharesOutstanding: (json['shares_outstanding'] as num).toInt(),
      avgVolume: (json['avg_volume'] as num).toInt(),
      week52High: json['week52_high'] as String,
      week52Low: json['week52_low'] as String,
      turnoverRate: json['turnover_rate'] as String,
      exchange: json['exchange'] as String,
      sector: json['sector'] as String,
      asOf: json['as_of'] as String,
    );

Map<String, dynamic> _$StockDetailDtoToJson(_StockDetailDto instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'name': instance.name,
      'name_zh': instance.nameZh,
      'market': instance.market,
      'price': instance.price,
      'change': instance.change,
      'change_pct': instance.changePct,
      'open': instance.open,
      'high': instance.high,
      'low': instance.low,
      'prev_close': instance.prevClose,
      'volume': instance.volume,
      'turnover': instance.turnover,
      'bid': instance.bid,
      'ask': instance.ask,
      'delayed': instance.delayed,
      'market_status': instance.marketStatus,
      'session': instance.session,
      'is_stale': instance.isStale,
      'stale_since_ms': instance.staleSinceMs,
      'market_cap': instance.marketCap,
      'pe_ratio': instance.peRatio,
      'pb_ratio': instance.pbRatio,
      'dividend_yield': instance.dividendYield,
      'shares_outstanding': instance.sharesOutstanding,
      'avg_volume': instance.avgVolume,
      'week52_high': instance.week52High,
      'week52_low': instance.week52Low,
      'turnover_rate': instance.turnoverRate,
      'exchange': instance.exchange,
      'sector': instance.sector,
      'as_of': instance.asOf,
    };

_NewsArticleDto _$NewsArticleDtoFromJson(Map<String, dynamic> json) =>
    _NewsArticleDto(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      source: json['source'] as String,
      publishedAt: json['published_at'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$NewsArticleDtoToJson(_NewsArticleDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'summary': instance.summary,
      'source': instance.source,
      'published_at': instance.publishedAt,
      'url': instance.url,
    };

_NewsResponseDto _$NewsResponseDtoFromJson(Map<String, dynamic> json) =>
    _NewsResponseDto(
      symbol: json['symbol'] as String,
      news: (json['news'] as List<dynamic>)
          .map((e) => NewsArticleDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num).toInt(),
      pageSize: (json['page_size'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$NewsResponseDtoToJson(_NewsResponseDto instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'news': instance.news,
      'page': instance.page,
      'page_size': instance.pageSize,
      'total': instance.total,
    };

_FinancialsQuarterDto _$FinancialsQuarterDtoFromJson(
  Map<String, dynamic> json,
) => _FinancialsQuarterDto(
  period: json['period'] as String,
  reportDate: json['report_date'] as String,
  revenue: json['revenue'] as String,
  netIncome: json['net_income'] as String,
  eps: json['eps'] as String,
  epsEstimate: json['eps_estimate'] as String,
  revenueGrowth: json['revenue_growth'] as String,
  netIncomeGrowth: json['net_income_growth'] as String,
);

Map<String, dynamic> _$FinancialsQuarterDtoToJson(
  _FinancialsQuarterDto instance,
) => <String, dynamic>{
  'period': instance.period,
  'report_date': instance.reportDate,
  'revenue': instance.revenue,
  'net_income': instance.netIncome,
  'eps': instance.eps,
  'eps_estimate': instance.epsEstimate,
  'revenue_growth': instance.revenueGrowth,
  'net_income_growth': instance.netIncomeGrowth,
};

_FinancialsResponseDto _$FinancialsResponseDtoFromJson(
  Map<String, dynamic> json,
) => _FinancialsResponseDto(
  symbol: json['symbol'] as String,
  nextEarningsDate: json['next_earnings_date'] as String,
  nextEarningsQuarter: json['next_earnings_quarter'] as String,
  quarters: (json['quarters'] as List<dynamic>)
      .map((e) => FinancialsQuarterDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FinancialsResponseDtoToJson(
  _FinancialsResponseDto instance,
) => <String, dynamic>{
  'symbol': instance.symbol,
  'next_earnings_date': instance.nextEarningsDate,
  'next_earnings_quarter': instance.nextEarningsQuarter,
  'quarters': instance.quarters,
};

_WatchlistResponseDto _$WatchlistResponseDtoFromJson(
  Map<String, dynamic> json,
) => _WatchlistResponseDto(
  symbols: (json['symbols'] as List<dynamic>).map((e) => e as String).toList(),
  quotes: (json['quotes'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, QuoteDto.fromJson(e as Map<String, dynamic>)),
  ),
  asOf: json['as_of'] as String,
);

Map<String, dynamic> _$WatchlistResponseDtoToJson(
  _WatchlistResponseDto instance,
) => <String, dynamic>{
  'symbols': instance.symbols,
  'quotes': instance.quotes,
  'as_of': instance.asOf,
};
