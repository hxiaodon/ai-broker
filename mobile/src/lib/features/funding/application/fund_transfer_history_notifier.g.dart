// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fund_transfer_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Recent 10 transfers — shown on the FundingScreen main page.

@ProviderFor(fundTransferHistory)
final fundTransferHistoryProvider = FundTransferHistoryProvider._();

/// Recent 10 transfers — shown on the FundingScreen main page.

final class FundTransferHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FundTransfer>>,
          List<FundTransfer>,
          FutureOr<List<FundTransfer>>
        >
    with
        $FutureModifier<List<FundTransfer>>,
        $FutureProvider<List<FundTransfer>> {
  /// Recent 10 transfers — shown on the FundingScreen main page.
  FundTransferHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fundTransferHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fundTransferHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<FundTransfer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FundTransfer>> create(Ref ref) {
    return fundTransferHistory(ref);
  }
}

String _$fundTransferHistoryHash() =>
    r'f392115617a24f9c8ba7414f21e3bb9aa3cfb451';

/// Paginated transfers — used in the full history page.

@ProviderFor(fundTransferHistoryPage)
final fundTransferHistoryPageProvider = FundTransferHistoryPageFamily._();

/// Paginated transfers — used in the full history page.

final class FundTransferHistoryPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FundTransfer>>,
          List<FundTransfer>,
          FutureOr<List<FundTransfer>>
        >
    with
        $FutureModifier<List<FundTransfer>>,
        $FutureProvider<List<FundTransfer>> {
  /// Paginated transfers — used in the full history page.
  FundTransferHistoryPageProvider._({
    required FundTransferHistoryPageFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'fundTransferHistoryPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fundTransferHistoryPageHash();

  @override
  String toString() {
    return r'fundTransferHistoryPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FundTransfer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FundTransfer>> create(Ref ref) {
    final argument = this.argument as int;
    return fundTransferHistoryPage(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FundTransferHistoryPageProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fundTransferHistoryPageHash() =>
    r'0fe591d4ebf83f1d2b83ff424501fa82e5fa541f';

/// Paginated transfers — used in the full history page.

final class FundTransferHistoryPageFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FundTransfer>>, int> {
  FundTransferHistoryPageFamily._()
    : super(
        retry: null,
        name: r'fundTransferHistoryPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Paginated transfers — used in the full history page.

  FundTransferHistoryPageProvider call(int page) =>
      FundTransferHistoryPageProvider._(argument: page, from: this);

  @override
  String toString() => r'fundTransferHistoryPageProvider';
}
