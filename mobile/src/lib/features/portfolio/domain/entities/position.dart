import 'package:freezed_annotation/freezed_annotation.dart';

part 'position.freezed.dart';
part 'position.g.dart';

/// Portfolio holding position for a single symbol.
///
/// All monetary values are [String] to avoid floating-point precision issues.
@freezed
class Position with _$Position {
  const factory Position({
    required String symbol,
    required String quantity,       // Shares held
    required String avgCostPrice,   // Average cost basis
    required String marketValue,    // Current market value
    required String unrealizedPnl,  // Unrealized P&L
    required String unrealizedPnlPercent,
    required String totalCost,
    required DateTime updatedAt,    // UTC
    @Default('US') String market,
  }) = _Position;

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);
}
