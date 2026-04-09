// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watchlist_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the user's watchlist and provides real-time quote updates.
///
/// ## State
/// `AsyncValue<List<Quote>>` — the ordered list of quotes for all watchlist
/// symbols. Initial data is fetched from [WatchlistRepository]; subsequent
/// updates are streamed from [QuoteWebSocketNotifier].
///
/// ## Dual-mode (guest / registered)
/// The underlying [WatchlistRepository] transparently handles both modes.
/// This notifier only needs to orchestrate WS subscriptions.
///
/// ## Live updates
/// Quote patches arrive from the WS stream ([quoteWebSocketProvider]):
/// - SNAPSHOT / DELAYED → full field replacement (preserves static metadata)
/// - TICK → only non-zero numeric fields are patched
///
/// ## 100-symbol limit
/// [add] throws [ValidationException] when the current count is ≥ 100.
///
/// ## Guest → registered import
/// Call [importGuestItems] after login to sync the guest local list to the
/// server. The UI is responsible for prompting the user.

@ProviderFor(WatchlistNotifier)
final watchlistProvider = WatchlistNotifierProvider._();

/// Manages the user's watchlist and provides real-time quote updates.
///
/// ## State
/// `AsyncValue<List<Quote>>` — the ordered list of quotes for all watchlist
/// symbols. Initial data is fetched from [WatchlistRepository]; subsequent
/// updates are streamed from [QuoteWebSocketNotifier].
///
/// ## Dual-mode (guest / registered)
/// The underlying [WatchlistRepository] transparently handles both modes.
/// This notifier only needs to orchestrate WS subscriptions.
///
/// ## Live updates
/// Quote patches arrive from the WS stream ([quoteWebSocketProvider]):
/// - SNAPSHOT / DELAYED → full field replacement (preserves static metadata)
/// - TICK → only non-zero numeric fields are patched
///
/// ## 100-symbol limit
/// [add] throws [ValidationException] when the current count is ≥ 100.
///
/// ## Guest → registered import
/// Call [importGuestItems] after login to sync the guest local list to the
/// server. The UI is responsible for prompting the user.
final class WatchlistNotifierProvider
    extends $AsyncNotifierProvider<WatchlistNotifier, List<Quote>> {
  /// Manages the user's watchlist and provides real-time quote updates.
  ///
  /// ## State
  /// `AsyncValue<List<Quote>>` — the ordered list of quotes for all watchlist
  /// symbols. Initial data is fetched from [WatchlistRepository]; subsequent
  /// updates are streamed from [QuoteWebSocketNotifier].
  ///
  /// ## Dual-mode (guest / registered)
  /// The underlying [WatchlistRepository] transparently handles both modes.
  /// This notifier only needs to orchestrate WS subscriptions.
  ///
  /// ## Live updates
  /// Quote patches arrive from the WS stream ([quoteWebSocketProvider]):
  /// - SNAPSHOT / DELAYED → full field replacement (preserves static metadata)
  /// - TICK → only non-zero numeric fields are patched
  ///
  /// ## 100-symbol limit
  /// [add] throws [ValidationException] when the current count is ≥ 100.
  ///
  /// ## Guest → registered import
  /// Call [importGuestItems] after login to sync the guest local list to the
  /// server. The UI is responsible for prompting the user.
  WatchlistNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchlistProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchlistNotifierHash();

  @$internal
  @override
  WatchlistNotifier create() => WatchlistNotifier();
}

String _$watchlistNotifierHash() => r'6b44984dda692e83b6addd668688c1460d5ebf40';

/// Manages the user's watchlist and provides real-time quote updates.
///
/// ## State
/// `AsyncValue<List<Quote>>` — the ordered list of quotes for all watchlist
/// symbols. Initial data is fetched from [WatchlistRepository]; subsequent
/// updates are streamed from [QuoteWebSocketNotifier].
///
/// ## Dual-mode (guest / registered)
/// The underlying [WatchlistRepository] transparently handles both modes.
/// This notifier only needs to orchestrate WS subscriptions.
///
/// ## Live updates
/// Quote patches arrive from the WS stream ([quoteWebSocketProvider]):
/// - SNAPSHOT / DELAYED → full field replacement (preserves static metadata)
/// - TICK → only non-zero numeric fields are patched
///
/// ## 100-symbol limit
/// [add] throws [ValidationException] when the current count is ≥ 100.
///
/// ## Guest → registered import
/// Call [importGuestItems] after login to sync the guest local list to the
/// server. The UI is responsible for prompting the user.

abstract class _$WatchlistNotifier extends $AsyncNotifier<List<Quote>> {
  FutureOr<List<Quote>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Quote>>, List<Quote>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Quote>>, List<Quote>>,
              AsyncValue<List<Quote>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
