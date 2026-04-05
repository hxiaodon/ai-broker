import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'market_status.dart';

part 'quote.freezed.dart';

/// Real-time or delayed quote for a single stock symbol.
///
/// Price fields use [Decimal] — never float (financial-coding-standards §Rule 1).
/// Field definitions match market-api-spec §3.3 (quotes[symbol]) + §1.7 (is_stale).
@freezed
abstract class Quote with _$Quote {
  const factory Quote({
    required String symbol,

    /// Company English name.
    required String name,

    /// Company Chinese name. Empty string if not available.
    required String nameZh,

    /// Market identifier: "US" or "HK".
    required String market,

    /// Latest trade price (4 decimal places for US, 3 for HK).
    required Decimal price,

    /// Price change vs previous regular-session close (market-api-spec §1.8).
    required Decimal change,

    /// Percentage change vs previous regular-session close (2 decimal places).
    required Decimal changePct,

    /// Cumulative daily trade volume (shares).
    required int volume,

    /// Best bid price (Level 1). Null when market is closed.
    Decimal? bid,

    /// Best ask price (Level 1). Null when market is closed.
    Decimal? ask,

    /// Daily turnover with unit suffix, e.g. "8.24B". Kept as String (带单位).
    required String turnover,

    /// Previous regular-session closing price.
    required Decimal prevClose,

    /// Daily opening price.
    required Decimal open,

    /// Daily high price.
    required Decimal high,

    /// Daily low price.
    required Decimal low,

    /// Market capitalisation with unit suffix, e.g. "2.80T". Kept as String.
    required String marketCap,

    /// P/E ratio (TTM). Null for stocks with no earnings (SPACs, loss-making).
    String? peRatio,

    /// True when the quote is delayed 15 minutes (guest / unauthenticated).
    required bool delayed,

    /// Current market trading status.
    required MarketStatus marketStatus,

    /// True when this data point has not been refreshed within 1 second
    /// (market-api-spec §1.7). Used by the trading engine to reject market orders.
    @Default(false) bool isStale,

    /// Duration in milliseconds that the quote has been stale.
    /// 0 when [isStale] is false.
    @Default(0) int staleSinceMs,
  }) = _Quote;

  const Quote._();

  /// Whether to show the [StaleQuoteWarningBanner] widget.
  ///
  /// Per market-api-spec §1.7 and design decision 2026-04-04:
  /// the front-end only shows the banner when stale_since_ms >= 5000ms,
  /// even though the trading engine uses a stricter 1s threshold.
  bool get showStaleWarning => isStale && staleSinceMs >= 5000;
}
