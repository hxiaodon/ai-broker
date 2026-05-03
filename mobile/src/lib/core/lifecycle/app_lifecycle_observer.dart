import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../../features/market/application/quote_websocket_notifier.dart';

/// Wires app lifecycle events to platform-level services.
///
/// Currently handles:
/// - WebSocket pause/resume for market-data streaming
///   (`QuoteWebSocketNotifier.pause()` / `resume()`)
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
