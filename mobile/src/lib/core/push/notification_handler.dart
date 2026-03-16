/// Notification routing handler stub.
///
/// ## Phase 2 Implementation
/// Handles:
///   - Order fill notifications → navigate to order detail
///   - Fund transfer notifications → navigate to funding screen
///   - Security alerts → navigate to security settings
///   - KYC status updates → navigate to KYC flow
///
/// ## Phase 1 (Stub)
/// No-op until FirebaseMessaging and go_router are wired together.
library;

import '../logging/app_logger.dart';

class NotificationHandler {
  NotificationHandler();

  void setupForegroundHandler() {
    // TODO Phase 2: FirebaseMessaging.onMessage.listen(_handleForeground);
    AppLogger.debug('NotificationHandler: foreground handler stub registered');
  }

  void setupBackgroundHandler() {
    // TODO Phase 2: FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    AppLogger.debug('NotificationHandler: background handler stub registered');
  }

  void handleNotificationTap(Map<String, dynamic> data) {
    // TODO Phase 2: route based on data['type'] using the global go_router ref
    AppLogger.debug('NotificationHandler: tap received (stub) data=$data');
  }
}
