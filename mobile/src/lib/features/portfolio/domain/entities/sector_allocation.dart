import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sector_allocation.freezed.dart';

@freezed
abstract class SectorAllocation with _$SectorAllocation {
  const factory SectorAllocation({
    required String sector,
    required Decimal marketValue,
    required Decimal weight,
  }) = _SectorAllocation;
}
