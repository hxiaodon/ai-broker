import 'package:freezed_annotation/freezed_annotation.dart';

part 'quote.freezed.dart';
part 'quote.g.dart';

/// Real-time stock quote. All prices use [String] for JSON transmission
/// and must be parsed to [Decimal] for any calculations.
///
/// Per financial-coding-standards: never use double for price fields.
@freezed
class Quote with _$Quote {
  const factory Quote({
    required String symbol,
    required String lastPrice,      // Decimal string e.g. "150.2500"
    required String change,         // Absolute change
    required String changePercent,  // e.g. "0.0352" = +3.52%
    required String open,
    required String high,
    required String low,
    required String prevClose,
    required int volume,
    required DateTime timestamp,    // UTC
    @Default('US') String market,   // 'US' or 'HK'
  }) = _Quote;

  factory Quote.fromJson(Map<String, dynamic> json) =>
      _$QuoteFromJson(json);
}
