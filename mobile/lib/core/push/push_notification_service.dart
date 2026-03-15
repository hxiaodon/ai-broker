/// Push notification service stub.
///
/// ## Phase 2 Implementation
/// This service will:
///   1. Initialize firebase_core (requires google-services.json / GoogleService-Info.plist)
///   2. Initialize firebase_messaging
///   3. Request notification permissions
///   4. Obtain FCM/APNs token and report to AMS service
///   5. Set up foreground message handler with flutter_local_notifications
///
/// ## Phase 1 (Stub)
/// The stub is a no-op that allows the rest of the app to compile and run.
/// Integrate this service in main.dart when Firebase is configured.
library;

import '../logging/app_logger.dart';

class PushNotificationService {
  PushNotificationService();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    // TODO Phase 2: await Firebase.initializeApp(); setup FirebaseMessaging
    AppLogger.info('PushNotificationService: stub mode, Firebase not configured');
    _initialized = true;
  }

  Future<String?> getToken() async {
    // TODO Phase 2: return await FirebaseMessaging.instance.getToken();
    return null;
  }

  Future<void> requestPermission() async {
    // TODO Phase 2: request notification permissions via FirebaseMessaging
    AppLogger.debug('PushNotificationService: permission request deferred (stub)');
  }
}
