// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_quotes_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
///
/// ## Lifecycle
/// - Initial load: REST API batch fetch
/// - Live updates: WebSocket TICK/SNAPSHOT frames
///
/// ## WebSocket integration
/// Automatically subscribes to index symbols when WebSocket is connected.
/// Updates are patched into state in real-time.

@ProviderFor(IndexQuotesNotifier)
final indexQuotesProvider = IndexQuotesNotifierProvider._();

/// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
///
/// ## Lifecycle
/// - Initial load: REST API batch fetch
/// - Live updates: WebSocket TICK/SNAPSHOT frames
///
/// ## WebSocket integration
/// Automatically subscribes to index symbols when WebSocket is connected.
/// Updates are patched into state in real-time.
final class IndexQuotesNotifierProvider
    extends $AsyncNotifierProvider<IndexQuotesNotifier, Map<String, Quote>> {
  /// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
  ///
  /// ## Lifecycle
  /// - Initial load: REST API batch fetch
  /// - Live updates: WebSocket TICK/SNAPSHOT frames
  ///
  /// ## WebSocket integration
  /// Automatically subscribes to index symbols when WebSocket is connected.
  /// Updates are patched into state in real-time.
  IndexQuotesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indexQuotesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indexQuotesNotifierHash();

  @$internal
  @override
  IndexQuotesNotifier create() => IndexQuotesNotifier();
}

String _$indexQuotesNotifierHash() =>
    r'0811770f67f7ecb9806f71f4c660ee1d7e1e4ca9';

/// Provides real-time quotes for market index ETFs (SPY, QQQ, DIA).
///
/// ## Lifecycle
/// - Initial load: REST API batch fetch
/// - Live updates: WebSocket TICK/SNAPSHOT frames
///
/// ## WebSocket integration
/// Automatically subscribes to index symbols when WebSocket is connected.
/// Updates are patched into state in real-time.

abstract class _$IndexQuotesNotifier
    extends $AsyncNotifier<Map<String, Quote>> {
  FutureOr<Map<String, Quote>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Map<String, Quote>>, Map<String, Quote>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Map<String, Quote>>, Map<String, Quote>>,
              AsyncValue<Map<String, Quote>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
