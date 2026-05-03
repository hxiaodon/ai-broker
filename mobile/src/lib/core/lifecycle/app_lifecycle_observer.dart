import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../routing/app_router.dart';
import '../routing/route_names.dart';
import '../../features/market/application/quote_websocket_notifier.dart';

/// Root-level observer wired to the Flutter engine lifecycle.
///
/// Responsibilities:
/// - WebSocket pause/resume when the app is backgrounded/foregrounded
/// - Deep link routing (App Links / Universal Links / custom scheme)
///
/// Place this widget at the root of the widget tree, wrapping [MaterialApp],
/// so it is always alive and never rebuilt during navigation.
class AppLifecycleObserver extends ConsumerStatefulWidget {
  const AppLifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─── Deep link handling ───────────────────────────────────────────────────

  Future<void> _initDeepLinks() async {
    // Initial link: app opened cold from a deep link tap.
    // Deferred to post-frame so the router is fully ready before navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final uri = await _appLinks.getInitialLink();
        if (uri != null && mounted) _handleDeepLink(uri);
      } on Object catch (e) {
        AppLogger.warning('DeepLink: getInitialLink error: ${e.runtimeType}');
      }
    });

    // Warm-start / foreground links (app already running).
    _deepLinkSub = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (Object e) =>
          AppLogger.warning('DeepLink: stream error: ${e.runtimeType}'),
    );
  }

  void _handleDeepLink(Uri uri) {
    final path = _resolvePath(uri);
    if (path == null) return;
    AppLogger.info('DeepLink: → $path');
    ref.read(appRouterProvider).go(path);
  }

  /// Maps an incoming URI to a GoRouter path.
  ///
  /// Supported schemes:
  /// - `https://app.trading.example.com/<path>` — App Links / Universal Links
  /// - `tradingapp://<path>` — custom scheme (fallback for non-HTTPS contexts)
  String? _resolvePath(Uri uri) {
    String rawPath;

    if (uri.scheme == 'https' && uri.host == 'app.trading.example.com') {
      rawPath = uri.path;
    } else if (uri.scheme == 'tradingapp') {
      // Two-slash form:  tradingapp://market/stock/AAPL → host=market, path=/stock/AAPL
      // Three-slash form: tradingapp:///market/stock/AAPL → host='',  path=/market/stock/AAPL
      rawPath =
          uri.host.isNotEmpty ? '/${uri.host}${uri.path}' : uri.path;
    } else {
      AppLogger.debug('DeepLink: unsupported scheme "${uri.scheme}" — ignoring');
      return null;
    }

    if (rawPath.isEmpty || rawPath == '/') return RouteNames.market;

    // Reject unknown prefixes — prevents navigating to arbitrary internal routes
    const knownPrefixes = [
      '/market', '/trading', '/portfolio', '/funding', '/settings', '/kyc',
    ];
    if (!knownPrefixes.any(rawPath.startsWith)) {
      AppLogger.warning('DeepLink: unknown path "$rawPath" — ignoring');
      return null;
    }

    // Order entry and confirm screens require state.extra params and cannot be
    // deep-linked directly. Land on the orders list instead.
    if (rawPath == RouteNames.orderEntry ||
        rawPath.startsWith('/trading/order/confirm')) {
      return RouteNames.tradingOrders;
    }

    return uri.query.isEmpty ? rawPath : '$rawPath?${uri.query}';
  }

  // ─── App lifecycle ────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // App fully backgrounded — disconnect WebSocket to save battery.
        // Subscribed symbols are remembered; resume() re-subscribes them.
        ref.read(quoteWebSocketProvider.notifier).pause();
        AppLogger.debug('AppLifecycle: paused — WebSocket suspended');

      case AppLifecycleState.resumed:
        // App back to foreground — reconnect and re-subscribe.
        // resume() is a no-op if pause() was never called.
        ref.read(quoteWebSocketProvider.notifier).resume();
        AppLogger.debug('AppLifecycle: resumed — WebSocket reconnecting');

      // Transient states (switching apps, incoming call, etc.) — no action.
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
