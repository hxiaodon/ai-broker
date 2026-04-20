// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_summary_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PortfolioSummaryNotifier)
final portfolioSummaryProvider = PortfolioSummaryNotifierProvider._();

final class PortfolioSummaryNotifierProvider
    extends $AsyncNotifierProvider<PortfolioSummaryNotifier, PortfolioSummary> {
  PortfolioSummaryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portfolioSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portfolioSummaryNotifierHash();

  @$internal
  @override
  PortfolioSummaryNotifier create() => PortfolioSummaryNotifier();
}

String _$portfolioSummaryNotifierHash() =>
    r'f7820cf56861ea1b72e18261cb46db377cc415f8';

abstract class _$PortfolioSummaryNotifier
    extends $AsyncNotifier<PortfolioSummary> {
  FutureOr<PortfolioSummary> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<PortfolioSummary>, PortfolioSummary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PortfolioSummary>, PortfolioSummary>,
              AsyncValue<PortfolioSummary>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
