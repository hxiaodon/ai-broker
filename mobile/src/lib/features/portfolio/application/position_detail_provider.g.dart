// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Private provider: performs the REST fetch only.
/// Cached independently so WS overlay rebuilds do not re-trigger the network call.

@ProviderFor(_positionDetailRest)
final _positionDetailRestProvider = _PositionDetailRestFamily._();

/// Private provider: performs the REST fetch only.
/// Cached independently so WS overlay rebuilds do not re-trigger the network call.

final class _PositionDetailRestProvider
    extends
        $FunctionalProvider<
          AsyncValue<PositionDetail>,
          PositionDetail,
          FutureOr<PositionDetail>
        >
    with $FutureModifier<PositionDetail>, $FutureProvider<PositionDetail> {
  /// Private provider: performs the REST fetch only.
  /// Cached independently so WS overlay rebuilds do not re-trigger the network call.
  _PositionDetailRestProvider._({
    required _PositionDetailRestFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'_positionDetailRestProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_positionDetailRestHash();

  @override
  String toString() {
    return r'_positionDetailRestProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PositionDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PositionDetail> create(Ref ref) {
    final argument = this.argument as String;
    return _positionDetailRest(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _PositionDetailRestProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_positionDetailRestHash() =>
    r'b3dae7425c613c833a1c5cd8575eae4462c49d16';

/// Private provider: performs the REST fetch only.
/// Cached independently so WS overlay rebuilds do not re-trigger the network call.

final class _PositionDetailRestFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PositionDetail>, String> {
  _PositionDetailRestFamily._()
    : super(
        retry: null,
        name: r'_positionDetailRestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Private provider: performs the REST fetch only.
  /// Cached independently so WS overlay rebuilds do not re-trigger the network call.

  _PositionDetailRestProvider call(String symbol) =>
      _PositionDetailRestProvider._(argument: symbol, from: this);

  @override
  String toString() => r'_positionDetailRestProvider';
}

/// Public provider: overlays real-time WS data on top of the cached REST result.
///
/// Watches [_positionDetailRestProvider] for the REST fetch, then synchronously
/// reads [positionsProvider] as an AsyncValue (no await) to apply the WS overlay.
/// This separates the two concerns: the REST provider rebuilds only on explicit
/// invalidation, while WS updates rebuild this provider without re-fetching REST.

@ProviderFor(positionDetail)
final positionDetailProvider = PositionDetailFamily._();

/// Public provider: overlays real-time WS data on top of the cached REST result.
///
/// Watches [_positionDetailRestProvider] for the REST fetch, then synchronously
/// reads [positionsProvider] as an AsyncValue (no await) to apply the WS overlay.
/// This separates the two concerns: the REST provider rebuilds only on explicit
/// invalidation, while WS updates rebuild this provider without re-fetching REST.

final class PositionDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<PositionDetail>,
          PositionDetail,
          FutureOr<PositionDetail>
        >
    with $FutureModifier<PositionDetail>, $FutureProvider<PositionDetail> {
  /// Public provider: overlays real-time WS data on top of the cached REST result.
  ///
  /// Watches [_positionDetailRestProvider] for the REST fetch, then synchronously
  /// reads [positionsProvider] as an AsyncValue (no await) to apply the WS overlay.
  /// This separates the two concerns: the REST provider rebuilds only on explicit
  /// invalidation, while WS updates rebuild this provider without re-fetching REST.
  PositionDetailProvider._({
    required PositionDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'positionDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$positionDetailHash();

  @override
  String toString() {
    return r'positionDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PositionDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PositionDetail> create(Ref ref) {
    final argument = this.argument as String;
    return positionDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PositionDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$positionDetailHash() => r'04193585f0924b94fef49d449a5cf05eca8969fa';

/// Public provider: overlays real-time WS data on top of the cached REST result.
///
/// Watches [_positionDetailRestProvider] for the REST fetch, then synchronously
/// reads [positionsProvider] as an AsyncValue (no await) to apply the WS overlay.
/// This separates the two concerns: the REST provider rebuilds only on explicit
/// invalidation, while WS updates rebuild this provider without re-fetching REST.

final class PositionDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PositionDetail>, String> {
  PositionDetailFamily._()
    : super(
        retry: null,
        name: r'positionDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Public provider: overlays real-time WS data on top of the cached REST result.
  ///
  /// Watches [_positionDetailRestProvider] for the REST fetch, then synchronously
  /// reads [positionsProvider] as an AsyncValue (no await) to apply the WS overlay.
  /// This separates the two concerns: the REST provider rebuilds only on explicit
  /// invalidation, while WS updates rebuild this provider without re-fetching REST.

  PositionDetailProvider call(String symbol) =>
      PositionDetailProvider._(argument: symbol, from: this);

  @override
  String toString() => r'positionDetailProvider';
}
