import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'market_status.dart';

part 'stock_detail.freezed.dart';

/// Full stock detail: real-time quote fields + fundamental data.
///
/// Corresponds to GET /v1/market/stocks/{symbol} flat response (market-api-spec §7.3).
/// Price fields use [Decimal] — never float (financial-coding-standards §Rule 1).
@freezed
abstract class StockDetail with _$StockDetail {
  const factory StockDetail({
    // ── Quote fields ──────────────────────────────────────────────────────────
    required String symbol,
    required String name,
    required String nameZh,

    /// Market identifier: "US" or "HK".
    required String market,

    required Decimal price,
    required Decimal change,
    required Decimal changePct,
    required Decimal open,
    required Decimal high,
    required Decimal low,
    required Decimal prevClose,
    required int volume,

    /// Daily turnover with unit suffix, e.g. "8.24B". Kept as String.
    required String turnover,

    Decimal? bid,
    Decimal? ask,

    required bool delayed,
    required MarketStatus marketStatus,

    /// Human-readable session description, e.g. "Regular Trading Hours".
    required String session,

    @Default(false) bool isStale,
    @Default(0) int staleSinceMs,

    // ── Fundamental fields ────────────────────────────────────────────────────

    /// Market capitalisation with unit suffix, e.g. "2.80T". Kept as String.
    required String marketCap,

    /// P/E ratio (TTM), e.g. "28.50". String to accommodate "N/A" values.
    required String peRatio,

    /// Price-to-book ratio, e.g. "42.30".
    required String pbRatio,

    /// Dividend yield percentage, e.g. "0.52". "0.00" when no dividend.
    required String dividendYield,

    /// Total shares outstanding.
    required int sharesOutstanding,

    /// 30-day average daily volume.
    required int avgVolume,

    /// 52-week high price.
    required Decimal week52High,

    /// 52-week low price.
    required Decimal week52Low,

    /// Daily turnover rate: volume / shares_outstanding × 100 (2 decimal places).
    /// Pre-computed by the server (market-api-spec §7.6, blocker Q2 resolved 2026-04-04).
    required Decimal turnoverRate,

    /// Primary listing exchange, e.g. "NASDAQ", "HKEX".
    required String exchange,

    /// Industry sector in English, e.g. "Technology".
    required String sector,

    /// Timestamp of the data snapshot (UTC).
    required DateTime asOf,
  }) = _StockDetail;

  const StockDetail._();

  /// Whether to show the [StaleQuoteWarningBanner] widget.
  bool get showStaleWarning => isStale && staleSinceMs >= 5000;
}
