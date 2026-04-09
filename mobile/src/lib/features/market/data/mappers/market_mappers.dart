import 'package:decimal/decimal.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/candle.dart';
import '../../domain/entities/financials.dart';
import '../../domain/entities/market_status.dart';
import '../../domain/entities/mover_item.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/quote.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/stock_detail.dart';
import '../../domain/entities/watchlist.dart';
import '../remote/market_response_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Parse a required price string to [Decimal].
///
/// Per financial-coding-standards §Rule 1 all price fields must be Decimal.
/// Uses [Decimal.tryParse] defensively — logs warning on parse failure
/// and falls back to zero so the app never crashes on malformed API data.
///
/// Empty strings are treated as zero (proto3 zero-value for absent fields in
/// WebSocket TICK frames — callers are responsible for merging with cached data).
Decimal _d(String value) {
  if (value.isEmpty) return Decimal.zero;
  final result = Decimal.tryParse(value);
  if (result == null) {
    AppLogger.warning('MarketMappers: failed to parse Decimal from "$value"');
    return Decimal.zero;
  }
  return result;
}

/// Parse a nullable price string to [Decimal], returning null when absent.
Decimal? _dNullable(String? value) =>
    value == null ? null : Decimal.tryParse(value);

/// Parse an ISO 8601 UTC string to [DateTime].
DateTime _dt(String value) => DateTime.parse(value).toUtc();

// ─────────────────────────────────────────────────────────────────────────────
// QuoteDto → Quote
// ─────────────────────────────────────────────────────────────────────────────

extension QuoteDtoMapper on QuoteDto {
  Quote toDomain() => Quote(
        symbol: symbol,
        name: name,
        nameZh: nameZh,
        market: market,
        price: _d(price),
        change: _d(change),
        changePct: _d(changePct),
        volume: volume,
        bid: _dNullable(bid),
        ask: _dNullable(ask),
        turnover: turnover,
        prevClose: _d(prevClose),
        open: _d(open),
        high: _d(high),
        low: _d(low),
        marketCap: marketCap,
        peRatio: peRatio,
        delayed: delayed,
        marketStatus: MarketStatus.fromApi(marketStatus),
        isStale: isStale,
        staleSinceMs: staleSinceMs,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// QuotesResponseDto → Watchlist (ordered by symbol list)
// ─────────────────────────────────────────────────────────────────────────────

extension WatchlistResponseDtoMapper on WatchlistResponseDto {
  /// Returns quotes ordered by [symbols] list (preserves server-side ordering).
  Watchlist toDomain() => symbols
      .where(quotes.containsKey)
      .map((s) => quotes[s]!.toDomain())
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// CandleDto → Candle
// ─────────────────────────────────────────────────────────────────────────────

extension CandleDtoMapper on CandleDto {
  Candle toDomain() => Candle(
        t: _dt(t),
        o: _d(o),
        h: _d(h),
        l: _d(l),
        c: _d(c),
        v: v,
        n: n,
      );
}

extension CandleListMapper on List<CandleDto> {
  List<Candle> toDomainList() => map((dto) => dto.toDomain()).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// SearchResultDto → SearchResult
// ─────────────────────────────────────────────────────────────────────────────

extension SearchResultDtoMapper on SearchResultDto {
  SearchResult toDomain() => SearchResult(
        symbol: symbol,
        name: name,
        nameZh: nameZh,
        market: market,
        price: _d(price),
        changePct: _d(changePct),
        delayed: delayed,
      );
}

extension SearchResultListMapper on List<SearchResultDto> {
  List<SearchResult> toDomainList() => map((dto) => dto.toDomain()).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// MoverItemDto → MoverItem
// ─────────────────────────────────────────────────────────────────────────────

extension MoverItemDtoMapper on MoverItemDto {
  MoverItem toDomain() => MoverItem(
        rank: rank,
        symbol: symbol,
        name: name,
        nameZh: nameZh,
        price: _d(price),
        change: _d(change),
        changePct: _d(changePct),
        volume: volume,
        turnover: turnover,
        marketStatus: MarketStatus.fromApi(marketStatus),
      );
}

extension MoverItemListMapper on List<MoverItemDto> {
  List<MoverItem> toDomainList() => map((dto) => dto.toDomain()).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// StockDetailDto → StockDetail
// ─────────────────────────────────────────────────────────────────────────────

extension StockDetailDtoMapper on StockDetailDto {
  StockDetail toDomain() => StockDetail(
        symbol: symbol,
        name: name,
        nameZh: nameZh,
        market: market,
        price: _d(price),
        change: _d(change),
        changePct: _d(changePct),
        open: _d(open),
        high: _d(high),
        low: _d(low),
        prevClose: _d(prevClose),
        volume: volume,
        turnover: turnover,
        bid: _dNullable(bid),
        ask: _dNullable(ask),
        delayed: delayed,
        marketStatus: MarketStatus.fromApi(marketStatus),
        session: session,
        isStale: isStale,
        staleSinceMs: staleSinceMs,
        marketCap: marketCap,
        peRatio: peRatio,
        pbRatio: pbRatio,
        dividendYield: dividendYield,
        sharesOutstanding: sharesOutstanding,
        avgVolume: avgVolume,
        week52High: _d(week52High),
        week52Low: _d(week52Low),
        turnoverRate: _d(turnoverRate),
        exchange: exchange,
        sector: sector,
        asOf: _dt(asOf),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NewsArticleDto → NewsArticle
// ─────────────────────────────────────────────────────────────────────────────

extension NewsArticleDtoMapper on NewsArticleDto {
  NewsArticle toDomain() => NewsArticle(
        id: id,
        title: title,
        summary: summary,
        source: source,
        publishedAt: _dt(publishedAt),
        url: url,
      );
}

extension NewsArticleListMapper on List<NewsArticleDto> {
  List<NewsArticle> toDomainList() => map((dto) => dto.toDomain()).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// FinancialsQuarterDto + FinancialsResponseDto → FinancialsQuarter / Financials
// ─────────────────────────────────────────────────────────────────────────────

extension FinancialsQuarterDtoMapper on FinancialsQuarterDto {
  FinancialsQuarter toDomain() => FinancialsQuarter(
        period: period,
        reportDate: reportDate,
        revenue: revenue,
        netIncome: netIncome,
        eps: _d(eps),
        epsEstimate: _d(epsEstimate),
        revenueGrowth: _d(revenueGrowth),
        netIncomeGrowth: _d(netIncomeGrowth),
      );
}

extension FinancialsResponseDtoMapper on FinancialsResponseDto {
  Financials toDomain() => Financials(
        symbol: symbol,
        nextEarningsDate: nextEarningsDate,
        nextEarningsQuarter: nextEarningsQuarter,
        quarters: quarters.map((q) => q.toDomain()).toList(),
      );
}
