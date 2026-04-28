// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_assessment_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InvestmentAssessmentNotifier)
final investmentAssessmentProvider = InvestmentAssessmentNotifierProvider._();

final class InvestmentAssessmentNotifierProvider
    extends
        $NotifierProvider<
          InvestmentAssessmentNotifier,
          InvestmentAssessmentState
        > {
  InvestmentAssessmentNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'investmentAssessmentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$investmentAssessmentNotifierHash();

  @$internal
  @override
  InvestmentAssessmentNotifier create() => InvestmentAssessmentNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvestmentAssessmentState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvestmentAssessmentState>(value),
    );
  }
}

String _$investmentAssessmentNotifierHash() =>
    r'0cd74e69431aa014ef59861e8fd86ab896945b6a';

abstract class _$InvestmentAssessmentNotifier
    extends $Notifier<InvestmentAssessmentState> {
  InvestmentAssessmentState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<InvestmentAssessmentState, InvestmentAssessmentState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InvestmentAssessmentState, InvestmentAssessmentState>,
              InvestmentAssessmentState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
