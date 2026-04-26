// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(portfolioRepository)
final portfolioRepositoryProvider = PortfolioRepositoryProvider._();

final class PortfolioRepositoryProvider
    extends
        $FunctionalProvider<
          PortfolioRepository,
          PortfolioRepository,
          PortfolioRepository
        >
    with $Provider<PortfolioRepository> {
  PortfolioRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portfolioRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portfolioRepositoryHash();

  @$internal
  @override
  $ProviderElement<PortfolioRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PortfolioRepository create(Ref ref) {
    return portfolioRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortfolioRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortfolioRepository>(value),
    );
  }
}

String _$portfolioRepositoryHash() =>
    r'5740abf7bdeb8dd707aedd02605284aca939b922';
