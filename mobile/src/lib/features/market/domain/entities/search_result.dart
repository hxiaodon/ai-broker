import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result.freezed.dart';

/// A single stock search result as returned by GET /v1/market/search.
///
/// Price fields use [Decimal] — never float (financial-coding-standards §Rule 1).
/// Field definitions match market-api-spec §5.3 results[i].
@freezed
abstract class SearchResult with _$SearchResult {
  const factory SearchResult({
    required String symbol,

    /// Company English name.
    required String name,

    /// Company Chinese name. Empty string if not available.
    required String nameZh,

    /// Market identifier: "US" or "HK".
    required String market,

    /// Latest price (4 decimal places for US, 3 for HK).
    required Decimal price,

    /// Price change percentage (2 decimal places, signed).
    required Decimal changePct,

    /// True when the quote is delayed by 15 minutes (guest/unauthenticated user).
    required bool delayed,
  }) = _SearchResult;
}
