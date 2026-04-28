import 'package:freezed_annotation/freezed_annotation.dart';
import 'kyc_enums.dart';

part 'financial_profile.freezed.dart';

enum IncomeRange {
  under25k,
  k25To50k,
  k50To100k,
  k100To250k,
  k250To500k,
  k500To1m,
  over1m;

  String toApi() => switch (this) {
        under25k => 'UNDER_25K',
        k25To50k => '25K_50K',
        k50To100k => '50K_100K',
        k100To250k => '100K_250K',
        k250To500k => '250K_500K',
        k500To1m => '500K_1M',
        over1m => 'OVER_1M',
      };

  static IncomeRange fromApi(String v) => switch (v) {
        'UNDER_25K' => under25k,
        '25K_50K' => k25To50k,
        '50K_100K' => k50To100k,
        '100K_250K' => k100To250k,
        '250K_500K' => k250To500k,
        '500K_1M' => k500To1m,
        _ => over1m,
      };
}

enum NetWorthRange {
  under25k,
  k25To100k,
  k100To500k,
  k500To1m,
  m1To5m,
  over5m;

  String toApi() => switch (this) {
        under25k => 'UNDER_25K',
        k25To100k => '25K_100K',
        k100To500k => '100K_500K',
        k500To1m => '500K_1M',
        m1To5m => '1M_5M',
        over5m => 'OVER_5M',
      };

  int get ordinalValue => switch (this) {
        under25k => 0,
        k25To100k => 1,
        k100To500k => 2,
        k500To1m => 3,
        m1To5m => 4,
        over5m => 5,
      };
}

enum FundsSource {
  salary,
  investmentReturns,
  businessOperations,
  realEstate,
  inheritance,
  other;

  String toApi() => switch (this) {
        salary => 'SALARY',
        investmentReturns => 'INVESTMENT_RETURNS',
        businessOperations => 'BUSINESS_OPERATIONS',
        realEstate => 'REAL_ESTATE',
        inheritance => 'INHERITANCE',
        other => 'OTHER',
      };
}

@freezed
abstract class FinancialProfile with _$FinancialProfile {
  const factory FinancialProfile({
    required IncomeRange annualIncomeRange,
    required NetWorthRange totalNetWorthRange,
    required NetWorthRange liquidNetWorthRange,
    required List<FundsSource> fundsSources,
    required EmploymentStatus employmentStatus,
    String? employerName,
  }) = _FinancialProfile;

  const FinancialProfile._();

  bool get isLiquidNetWorthValid =>
      liquidNetWorthRange.ordinalValue <= totalNetWorthRange.ordinalValue;
}

