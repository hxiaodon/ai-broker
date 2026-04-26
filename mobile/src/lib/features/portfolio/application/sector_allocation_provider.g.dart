// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sector_allocation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads all position details in parallel and aggregates by sector.
/// Only active when the analysis tab is visible (autoDispose).
///
/// Individual position detail failures are tolerated — the allocation is
/// computed from whichever positions succeeded (graceful degradation).

@ProviderFor(sectorAllocation)
final sectorAllocationProvider = SectorAllocationProvider._();

/// Loads all position details in parallel and aggregates by sector.
/// Only active when the analysis tab is visible (autoDispose).
///
/// Individual position detail failures are tolerated — the allocation is
/// computed from whichever positions succeeded (graceful degradation).

final class SectorAllocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SectorAllocation>>,
          List<SectorAllocation>,
          FutureOr<List<SectorAllocation>>
        >
    with
        $FutureModifier<List<SectorAllocation>>,
        $FutureProvider<List<SectorAllocation>> {
  /// Loads all position details in parallel and aggregates by sector.
  /// Only active when the analysis tab is visible (autoDispose).
  ///
  /// Individual position detail failures are tolerated — the allocation is
  /// computed from whichever positions succeeded (graceful degradation).
  SectorAllocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sectorAllocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sectorAllocationHash();

  @$internal
  @override
  $FutureProviderElement<List<SectorAllocation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SectorAllocation>> create(Ref ref) {
    return sectorAllocation(ref);
  }
}

String _$sectorAllocationHash() => r'3df9e9aabb6b46b70a7baaa3f7392d1fb337ab93';
