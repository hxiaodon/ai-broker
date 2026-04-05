import 'package:freezed_annotation/freezed_annotation.dart';

part 'market_response_models.freezed.dart';
part 'market_response_models.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quote (GET /v1/market/quotes — market-api-spec §3)
// ─────────────────────────────────────────────────────────────────────────────

/// Raw quote snapshot for a single symbol as returned in quotes[symbol].
///
/// Price fields are [String] per API contract (§1.2 "价格字段 string 类型").
/// Convert to [Decimal] via [MarketMappers] — never pass raw strings to UI.
@freezed
abstract class QuoteDto with _$QuoteDto {
  const factory QuoteDto({
    required String symbol,
    required String name,
    @JsonKey(name: 'name_zh') required String nameZh,
    required String market,
    required String price,
    required String change,
    @JsonKey(name: 'change_pct') required String changePct,
    required int volume,
    String? bid,
    String? ask,
    required String turnover,
    @JsonKey(name: 'prev_close') required String prevClose,
    required String open,
    required String high,
    required String low,
    @JsonKey(name: 'market_cap') required String marketCap,
    @JsonKey(name: 'pe_ratio') String? peRatio,
    required bool delayed,
    @JsonKey(name: 'market_status') required String marketStatus,
    // §1.7 — present in all quote responses; defaulted for spec-example omissions
    @JsonKey(name: 'is_stale') @Default(false) bool isStale,
    @JsonKey(name: 'stale_since_ms') @Default(0) int staleSinceMs,
  }) = _QuoteDto;

  factory QuoteDto.fromJson(Map<String, dynamic> json) =>
      _$QuoteDtoFromJson(json);
}

/// Response envelope for GET /v1/market/quotes.
@freezed
abstract class QuotesResponseDto with _$QuotesResponseDto {
  const factory QuotesResponseDto({
    required Map<String, QuoteDto> quotes,
    @JsonKey(name: 'as_of') required String asOf,
  }) = _QuotesResponseDto;

  factory QuotesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$QuotesResponseDtoFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// K-line (GET /v1/market/kline — market-api-spec §4)
// ─────────────────────────────────────────────────────────────────────────────

/// A single OHLCV candlestick as returned in candles[i].
@freezed
abstract class CandleDto with _$CandleDto {
  const factory CandleDto({
    /// Candle open time — ISO 8601 UTC string (e.g. "2026-03-13T14:30:00.000Z").
    required String t,
    required String o,
    required String h,
    required String l,
    required String c,
    required int v,
    required int n,
  }) = _CandleDto;

  factory CandleDto.fromJson(Map<String, dynamic> json) =>
      _$CandleDtoFromJson(json);
}

/// Response envelope for GET /v1/market/kline.
@freezed
abstract class KlineResponseDto with _$KlineResponseDto {
  const factory KlineResponseDto({
    required String symbol,
    required String period,
    required List<CandleDto> candles,
    @JsonKey(name: 'next_cursor') String? nextCursor,
    required int total,
  }) = _KlineResponseDto;

  factory KlineResponseDto.fromJson(Map<String, dynamic> json) =>
      _$KlineResponseDtoFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Search (GET /v1/market/search — market-api-spec §5)
// ─────────────────────────────────────────────────────────────────────────────

/// A single search result as returned in results[i].
@freezed
abstract class SearchResultDto with _$SearchResultDto {
  const factory SearchResultDto({
    required String symbol,
    required String name,
    @JsonKey(name: 'name_zh') required String nameZh,
    required String market,
    required String price,
    @JsonKey(name: 'change_pct') required String changePct,
    required bool delayed,
  }) = _SearchResultDto;

  factory SearchResultDto.fromJson(Map<String, dynamic> json) =>
      _$SearchResultDtoFromJson(json);
}

/// Response envelope for GET /v1/market/search.
@freezed
abstract class SearchResponseDto with _$SearchResponseDto {
  const factory SearchResponseDto({
    required List<SearchResultDto> results,
    required int total,
  }) = _SearchResponseDto;

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SearchResponseDtoFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Movers (GET /v1/market/movers — market-api-spec §6)
// ─────────────────────────────────────────────────────────────────────────────

/// A single mover entry as returned in items[i].
@freezed
abstract class MoverItemDto with _$MoverItemDto {
  const factory MoverItemDto({
    required int rank,
    required String symbol,
    required String name,
    @JsonKey(name: 'name_zh') required String nameZh,
    required String price,
    required String change,
    @JsonKey(name: 'change_pct') required String changePct,
    required int volume,
    required String turnover,
    @JsonKey(name: 'market_status') required String marketStatus,
  }) = _MoverItemDto;

  factory MoverItemDto.fromJson(Map<String, dynamic> json) =>
      _$MoverItemDtoFromJson(json);
}

/// Response envelope for GET /v1/market/movers.
@freezed
abstract class MoversResponseDto with _$MoversResponseDto {
  const factory MoversResponseDto({
    required String type,
    required String market,
    required List<MoverItemDto> items,
    @JsonKey(name: 'as_of') required String asOf,
  }) = _MoversResponseDto;

  factory MoversResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MoversResponseDtoFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock Detail (GET /v1/market/stocks/{symbol} — market-api-spec §7)
// ─────────────────────────────────────────────────────────────────────────────

/// Full stock detail flat DTO (quote fields + fundamental fields).
@freezed
abstract class StockDetailDto with _$StockDetailDto {
  const factory StockDetailDto({
    required String symbol,
    required String name,
    @JsonKey(name: 'name_zh') required String nameZh,
    required String market,
    required String price,
    required String change,
    @JsonKey(name: 'change_pct') required String changePct,
    required String open,
    required String high,
    required String low,
    @JsonKey(name: 'prev_close') required String prevClose,
    required int volume,
    required String turnover,
    String? bid,
    String? ask,
    required bool delayed,
    @JsonKey(name: 'market_status') required String marketStatus,
    required String session,
    @JsonKey(name: 'is_stale') @Default(false) bool isStale,
    @JsonKey(name: 'stale_since_ms') @Default(0) int staleSinceMs,
    // Fundamental fields
    @JsonKey(name: 'market_cap') required String marketCap,
    @JsonKey(name: 'pe_ratio') required String peRatio,
    @JsonKey(name: 'pb_ratio') required String pbRatio,
    @JsonKey(name: 'dividend_yield') required String dividendYield,
    @JsonKey(name: 'shares_outstanding') required int sharesOutstanding,
    @JsonKey(name: 'avg_volume') required int avgVolume,
    @JsonKey(name: 'week52_high') required String week52High,
    @JsonKey(name: 'week52_low') required String week52Low,
    @JsonKey(name: 'turnover_rate') required String turnoverRate,
    required String exchange,
    required String sector,
    @JsonKey(name: 'as_of') required String asOf,
  }) = _StockDetailDto;

  factory StockDetailDto.fromJson(Map<String, dynamic> json) =>
      _$StockDetailDtoFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// News (GET /v1/market/news/{symbol} — market-api-spec §8)
// ─────────────────────────────────────────────────────────────────────────────

/// A single news article as returned in news[i].
@freezed
abstract class NewsArticleDto with _$NewsArticleDto {
  const factory NewsArticleDto({
    required String id,
    required String title,
    required String summary,
    required String source,
    @JsonKey(name: 'published_at') required String publishedAt,
    required String url,
  }) = _NewsArticleDto;

  factory NewsArticleDto.fromJson(Map<String, dynamic> json) =>
      _$NewsArticleDtoFromJson(json);
}

/// Response envelope for GET /v1/market/news/{symbol}.
@freezed
abstract class NewsResponseDto with _$NewsResponseDto {
  const factory NewsResponseDto({
    required String symbol,
    required List<NewsArticleDto> news,
    required int page,
    @JsonKey(name: 'page_size') required int pageSize,
    required int total,
  }) = _NewsResponseDto;

  factory NewsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$NewsResponseDtoFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Financials (GET /v1/market/financials/{symbol} — market-api-spec §9)
// ─────────────────────────────────────────────────────────────────────────────

/// A single quarterly earnings record as returned in quarters[i].
@freezed
abstract class FinancialsQuarterDto with _$FinancialsQuarterDto {
  const factory FinancialsQuarterDto({
    required String period,
    @JsonKey(name: 'report_date') required String reportDate,
    required String revenue,
    @JsonKey(name: 'net_income') required String netIncome,
    required String eps,
    @JsonKey(name: 'eps_estimate') required String epsEstimate,
    @JsonKey(name: 'revenue_growth') required String revenueGrowth,
    @JsonKey(name: 'net_income_growth') required String netIncomeGrowth,
  }) = _FinancialsQuarterDto;

  factory FinancialsQuarterDto.fromJson(Map<String, dynamic> json) =>
      _$FinancialsQuarterDtoFromJson(json);
}

/// Response envelope for GET /v1/market/financials/{symbol}.
@freezed
abstract class FinancialsResponseDto with _$FinancialsResponseDto {
  const factory FinancialsResponseDto({
    required String symbol,
    @JsonKey(name: 'next_earnings_date') required String nextEarningsDate,
    @JsonKey(name: 'next_earnings_quarter') required String nextEarningsQuarter,
    required List<FinancialsQuarterDto> quarters,
  }) = _FinancialsResponseDto;

  factory FinancialsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FinancialsResponseDtoFromJson(json);
}

// ─────────────────────────────────────────────────────────────────────────────
// Watchlist (GET /v1/watchlist — market-api-spec §10)
// ─────────────────────────────────────────────────────────────────────────────

/// Response envelope for GET /v1/watchlist.
/// [quotes] format is identical to [QuotesResponseDto.quotes].
@freezed
abstract class WatchlistResponseDto with _$WatchlistResponseDto {
  const factory WatchlistResponseDto({
    required List<String> symbols,
    required Map<String, QuoteDto> quotes,
    @JsonKey(name: 'as_of') required String asOf,
  }) = _WatchlistResponseDto;

  factory WatchlistResponseDto.fromJson(Map<String, dynamic> json) =>
      _$WatchlistResponseDtoFromJson(json);
}
