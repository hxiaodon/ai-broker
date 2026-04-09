// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quote_websocket_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wsClientFactory)
final wsClientFactoryProvider = WsClientFactoryProvider._();

final class WsClientFactoryProvider
    extends
        $FunctionalProvider<WsClientFactory, WsClientFactory, WsClientFactory>
    with $Provider<WsClientFactory> {
  WsClientFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wsClientFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wsClientFactoryHash();

  @$internal
  @override
  $ProviderElement<WsClientFactory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WsClientFactory create(Ref ref) {
    return wsClientFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WsClientFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WsClientFactory>(value),
    );
  }
}

String _$wsClientFactoryHash() => r'3aab32cfec13c0390cfe698c9bf98b2141789b29';

/// Manages the lifecycle of a [QuoteWebSocketClient] connection and exposes a
/// persistent broadcast stream of [WsQuoteUpdate] events to the UI layer.
///
/// ## Connection lifecycle
/// - `build()` connects immediately using the current access token (or guest).
/// - On connection loss ([NetworkException]), an exponential-backoff reconnect
///   loop runs up to [_kMaxReconnectAttempts] times, then transitions to
///   [AsyncError].
/// - `pause()` / `resume()` allow the caller (e.g. app lifecycle handler) to
///   gracefully disconnect while backgrounded and reconnect on foreground.
///
/// ## Dual-track quotes
/// - Registered users → real-time TICK/SNAPSHOT frames.
/// - Guest users → T-15 min DELAYED snapshots every 5 s.
///   Both share the same [quoteStream]; callers inspect [WsQuoteUpdate.frameType].
///
/// ## Subscribing to symbols
/// ```dart
/// final notifier = ref.read(quoteWebSocketNotifierProvider.notifier);
/// await notifier.subscribe(['AAPL', 'TSLA']);
/// ```
///
/// ## Listening to per-symbol updates
/// Use [quoteUpdateProvider] which filters by symbol:
/// ```dart
/// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
///   upd.whenData((u) => /* handle WsQuoteUpdate */);
/// });
/// ```

@ProviderFor(QuoteWebSocketNotifier)
final quoteWebSocketProvider = QuoteWebSocketNotifierProvider._();

/// Manages the lifecycle of a [QuoteWebSocketClient] connection and exposes a
/// persistent broadcast stream of [WsQuoteUpdate] events to the UI layer.
///
/// ## Connection lifecycle
/// - `build()` connects immediately using the current access token (or guest).
/// - On connection loss ([NetworkException]), an exponential-backoff reconnect
///   loop runs up to [_kMaxReconnectAttempts] times, then transitions to
///   [AsyncError].
/// - `pause()` / `resume()` allow the caller (e.g. app lifecycle handler) to
///   gracefully disconnect while backgrounded and reconnect on foreground.
///
/// ## Dual-track quotes
/// - Registered users → real-time TICK/SNAPSHOT frames.
/// - Guest users → T-15 min DELAYED snapshots every 5 s.
///   Both share the same [quoteStream]; callers inspect [WsQuoteUpdate.frameType].
///
/// ## Subscribing to symbols
/// ```dart
/// final notifier = ref.read(quoteWebSocketNotifierProvider.notifier);
/// await notifier.subscribe(['AAPL', 'TSLA']);
/// ```
///
/// ## Listening to per-symbol updates
/// Use [quoteUpdateProvider] which filters by symbol:
/// ```dart
/// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
///   upd.whenData((u) => /* handle WsQuoteUpdate */);
/// });
/// ```
final class QuoteWebSocketNotifierProvider
    extends $AsyncNotifierProvider<QuoteWebSocketNotifier, WsUserType> {
  /// Manages the lifecycle of a [QuoteWebSocketClient] connection and exposes a
  /// persistent broadcast stream of [WsQuoteUpdate] events to the UI layer.
  ///
  /// ## Connection lifecycle
  /// - `build()` connects immediately using the current access token (or guest).
  /// - On connection loss ([NetworkException]), an exponential-backoff reconnect
  ///   loop runs up to [_kMaxReconnectAttempts] times, then transitions to
  ///   [AsyncError].
  /// - `pause()` / `resume()` allow the caller (e.g. app lifecycle handler) to
  ///   gracefully disconnect while backgrounded and reconnect on foreground.
  ///
  /// ## Dual-track quotes
  /// - Registered users → real-time TICK/SNAPSHOT frames.
  /// - Guest users → T-15 min DELAYED snapshots every 5 s.
  ///   Both share the same [quoteStream]; callers inspect [WsQuoteUpdate.frameType].
  ///
  /// ## Subscribing to symbols
  /// ```dart
  /// final notifier = ref.read(quoteWebSocketNotifierProvider.notifier);
  /// await notifier.subscribe(['AAPL', 'TSLA']);
  /// ```
  ///
  /// ## Listening to per-symbol updates
  /// Use [quoteUpdateProvider] which filters by symbol:
  /// ```dart
  /// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
  ///   upd.whenData((u) => /* handle WsQuoteUpdate */);
  /// });
  /// ```
  QuoteWebSocketNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quoteWebSocketProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quoteWebSocketNotifierHash();

  @$internal
  @override
  QuoteWebSocketNotifier create() => QuoteWebSocketNotifier();
}

String _$quoteWebSocketNotifierHash() =>
    r'4a3873872efc7ae7893dec8c999e48d0e824af9f';

/// Manages the lifecycle of a [QuoteWebSocketClient] connection and exposes a
/// persistent broadcast stream of [WsQuoteUpdate] events to the UI layer.
///
/// ## Connection lifecycle
/// - `build()` connects immediately using the current access token (or guest).
/// - On connection loss ([NetworkException]), an exponential-backoff reconnect
///   loop runs up to [_kMaxReconnectAttempts] times, then transitions to
///   [AsyncError].
/// - `pause()` / `resume()` allow the caller (e.g. app lifecycle handler) to
///   gracefully disconnect while backgrounded and reconnect on foreground.
///
/// ## Dual-track quotes
/// - Registered users → real-time TICK/SNAPSHOT frames.
/// - Guest users → T-15 min DELAYED snapshots every 5 s.
///   Both share the same [quoteStream]; callers inspect [WsQuoteUpdate.frameType].
///
/// ## Subscribing to symbols
/// ```dart
/// final notifier = ref.read(quoteWebSocketNotifierProvider.notifier);
/// await notifier.subscribe(['AAPL', 'TSLA']);
/// ```
///
/// ## Listening to per-symbol updates
/// Use [quoteUpdateProvider] which filters by symbol:
/// ```dart
/// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
///   upd.whenData((u) => /* handle WsQuoteUpdate */);
/// });
/// ```

abstract class _$QuoteWebSocketNotifier extends $AsyncNotifier<WsUserType> {
  FutureOr<WsUserType> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WsUserType>, WsUserType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WsUserType>, WsUserType>,
              AsyncValue<WsUserType>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// A [StreamProvider.family] that filters the global [QuoteWebSocketNotifier]
/// stream to updates for a single [symbol].
///
/// The stream emits even if the notifier is in [AsyncLoading] state (no events
/// are lost — WS must be subscribed first via [QuoteWebSocketNotifier.subscribe]).
///
/// Example:
/// ```dart
/// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
///   upd.whenData((update) => handleTick(update));
/// });
/// ```

@ProviderFor(quoteUpdate)
final quoteUpdateProvider = QuoteUpdateFamily._();

/// A [StreamProvider.family] that filters the global [QuoteWebSocketNotifier]
/// stream to updates for a single [symbol].
///
/// The stream emits even if the notifier is in [AsyncLoading] state (no events
/// are lost — WS must be subscribed first via [QuoteWebSocketNotifier.subscribe]).
///
/// Example:
/// ```dart
/// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
///   upd.whenData((update) => handleTick(update));
/// });
/// ```

final class QuoteUpdateProvider
    extends
        $FunctionalProvider<
          AsyncValue<WsQuoteUpdate>,
          WsQuoteUpdate,
          Stream<WsQuoteUpdate>
        >
    with $FutureModifier<WsQuoteUpdate>, $StreamProvider<WsQuoteUpdate> {
  /// A [StreamProvider.family] that filters the global [QuoteWebSocketNotifier]
  /// stream to updates for a single [symbol].
  ///
  /// The stream emits even if the notifier is in [AsyncLoading] state (no events
  /// are lost — WS must be subscribed first via [QuoteWebSocketNotifier.subscribe]).
  ///
  /// Example:
  /// ```dart
  /// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
  ///   upd.whenData((update) => handleTick(update));
  /// });
  /// ```
  QuoteUpdateProvider._({
    required QuoteUpdateFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'quoteUpdateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$quoteUpdateHash();

  @override
  String toString() {
    return r'quoteUpdateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<WsQuoteUpdate> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<WsQuoteUpdate> create(Ref ref) {
    final argument = this.argument as String;
    return quoteUpdate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is QuoteUpdateProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$quoteUpdateHash() => r'590af27494d2b2b9d60c404c925fa2f0c9a8484f';

/// A [StreamProvider.family] that filters the global [QuoteWebSocketNotifier]
/// stream to updates for a single [symbol].
///
/// The stream emits even if the notifier is in [AsyncLoading] state (no events
/// are lost — WS must be subscribed first via [QuoteWebSocketNotifier.subscribe]).
///
/// Example:
/// ```dart
/// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
///   upd.whenData((update) => handleTick(update));
/// });
/// ```

final class QuoteUpdateFamily extends $Family
    with $FunctionalFamilyOverride<Stream<WsQuoteUpdate>, String> {
  QuoteUpdateFamily._()
    : super(
        retry: null,
        name: r'quoteUpdateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A [StreamProvider.family] that filters the global [QuoteWebSocketNotifier]
  /// stream to updates for a single [symbol].
  ///
  /// The stream emits even if the notifier is in [AsyncLoading] state (no events
  /// are lost — WS must be subscribed first via [QuoteWebSocketNotifier.subscribe]).
  ///
  /// Example:
  /// ```dart
  /// ref.listen(quoteUpdateProvider('AAPL'), (_, upd) {
  ///   upd.whenData((update) => handleTick(update));
  /// });
  /// ```

  QuoteUpdateProvider call(String symbol) =>
      QuoteUpdateProvider._(argument: symbol, from: this);

  @override
  String toString() => r'quoteUpdateProvider';
}
