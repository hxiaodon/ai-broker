import 'package:freezed_annotation/freezed_annotation.dart';

part 'investment_assessment.freezed.dart';

enum InvestmentObjective {
  capitalPreservation,
  income,
  growth,
  speculation;

  String toApi() => switch (this) {
        capitalPreservation => 'CAPITAL_PRESERVATION',
        income => 'INCOME',
        growth => 'GROWTH',
        speculation => 'SPECULATION',
      };
}

enum RiskTolerance {
  conservative,
  moderate,
  aggressive;

  String toApi() => switch (this) {
        conservative => 'CONSERVATIVE',
        moderate => 'MODERATE',
        aggressive => 'AGGRESSIVE',
      };
}

enum TimeHorizon {
  short,
  medium,
  long;

  String toApi() => switch (this) {
        short => 'SHORT',
        medium => 'MEDIUM',
        long => 'LONG',
      };
}

enum LiquidityNeed {
  low,
  medium,
  high;

  String toApi() => switch (this) {
        low => 'LOW',
        medium => 'MEDIUM',
        high => 'HIGH',
      };
}

@freezed
abstract class InvestmentAssessment with _$InvestmentAssessment {
  const factory InvestmentAssessment({
    required InvestmentObjective investmentObjective,
    required RiskTolerance riskTolerance,
    required TimeHorizon timeHorizon,
    required int stockExperienceYears,
    @Default(0) int optionsExperienceYears,
    @Default(0) int marginExperienceYears,
    required LiquidityNeed liquidityNeed,
  }) = _InvestmentAssessment;
}
