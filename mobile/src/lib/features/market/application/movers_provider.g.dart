// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches a ranked mover list for the given [type] and [market].
///
/// Family parameter: `(type, market)` pair.
/// Types: [MoverType.mostActive], [MoverType.gainers], [MoverType.losers].
///
/// The provider is autoDispose so each tab page refreshes on navigation.

@ProviderFor(movers)
final moversProvider = MoversFamily._();

/// Fetches a ranked mover list for the given [type] and [market].
///
/// Family parameter: `(type, market)` pair.
/// Types: [MoverType.mostActive], [MoverType.gainers], [MoverType.losers].
///
/// The provider is autoDispose so each tab page refreshes on navigation.

final class MoversProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MoverItem>>,
          List<MoverItem>,
          FutureOr<List<MoverItem>>
        >
    with $FutureModifier<List<MoverItem>>, $FutureProvider<List<MoverItem>> {
  /// Fetches a ranked mover list for the given [type] and [market].
  ///
  /// Family parameter: `(type, market)` pair.
  /// Types: [MoverType.mostActive], [MoverType.gainers], [MoverType.losers].
  ///
  /// The provider is autoDispose so each tab page refreshes on navigation.
  MoversProvider._({
    required MoversFamily super.from,
    required ({String type, String market}) super.argument,
  }) : super(
         retry: null,
         name: r'moversProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$moversHash();

  @override
  String toString() {
    return r'moversProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<MoverItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MoverItem>> create(Ref ref) {
    final argument = this.argument as ({String type, String market});
    return movers(ref, type: argument.type, market: argument.market);
  }

  @override
  bool operator ==(Object other) {
    return other is MoversProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$moversHash() => r'def6e2166a42ff9d36fcd5ebb8cb41c73acddfbc';

/// Fetches a ranked mover list for the given [type] and [market].
///
/// Family parameter: `(type, market)` pair.
/// Types: [MoverType.mostActive], [MoverType.gainers], [MoverType.losers].
///
/// The provider is autoDispose so each tab page refreshes on navigation.

final class MoversFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<MoverItem>>,
          ({String type, String market})
        > {
  MoversFamily._()
    : super(
        retry: null,
        name: r'moversProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a ranked mover list for the given [type] and [market].
  ///
  /// Family parameter: `(type, market)` pair.
  /// Types: [MoverType.mostActive], [MoverType.gainers], [MoverType.losers].
  ///
  /// The provider is autoDispose so each tab page refreshes on navigation.

  MoversProvider call({required String type, String market = 'US'}) =>
      MoversProvider._(argument: (type: type, market: market), from: this);

  @override
  String toString() => r'moversProvider';
}
