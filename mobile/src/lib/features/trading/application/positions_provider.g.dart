// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'positions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PositionsNotifier)
final positionsProvider = PositionsNotifierProvider._();

final class PositionsNotifierProvider
    extends $AsyncNotifierProvider<PositionsNotifier, List<Position>> {
  PositionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'positionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$positionsNotifierHash();

  @$internal
  @override
  PositionsNotifier create() => PositionsNotifier();
}

String _$positionsNotifierHash() => r'c086707fe7551c6ea8f0f21c1dacc4736f2233e3';

abstract class _$PositionsNotifier extends $AsyncNotifier<List<Position>> {
  FutureOr<List<Position>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Position>>, List<Position>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Position>>, List<Position>>,
              AsyncValue<List<Position>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
