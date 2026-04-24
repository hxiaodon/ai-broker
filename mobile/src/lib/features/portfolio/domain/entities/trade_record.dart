import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_record.freezed.dart';

enum TradeSide { buy, sell }

@freezed
abstract class TradeRecord with _$TradeRecord {
  const factory TradeRecord({
    required String tradeId,
    required TradeSide side,
    required int qty,
    required Decimal price,
    required Decimal amount,
    required Decimal fee,
    required DateTime executedAt,
    @Default(false) bool washSale,
  }) = _TradeRecord;
}
