// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_order_banner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the most recently submitted order for cross-screen feedback.
/// Consumers dismiss it via [RecentOrderBanner.clear].

@ProviderFor(RecentOrderBanner)
final recentOrderBannerProvider = RecentOrderBannerProvider._();

/// Holds the most recently submitted order for cross-screen feedback.
/// Consumers dismiss it via [RecentOrderBanner.clear].
final class RecentOrderBannerProvider
    extends $NotifierProvider<RecentOrderBanner, RecentOrderInfo?> {
  /// Holds the most recently submitted order for cross-screen feedback.
  /// Consumers dismiss it via [RecentOrderBanner.clear].
  RecentOrderBannerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentOrderBannerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentOrderBannerHash();

  @$internal
  @override
  RecentOrderBanner create() => RecentOrderBanner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentOrderInfo? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentOrderInfo?>(value),
    );
  }
}

String _$recentOrderBannerHash() => r'7f58c627a3a32a45282ce3c32a537ebc4d4f4973';

/// Holds the most recently submitted order for cross-screen feedback.
/// Consumers dismiss it via [RecentOrderBanner.clear].

abstract class _$RecentOrderBanner extends $Notifier<RecentOrderInfo?> {
  RecentOrderInfo? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RecentOrderInfo?, RecentOrderInfo?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecentOrderInfo?, RecentOrderInfo?>,
              RecentOrderInfo?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
