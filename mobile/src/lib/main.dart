import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/logging/app_logger.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize structured logger
  AppLogger.init(verbose: false);
  AppLogger.info('App starting — Phase 1 skeleton');

  // Phase 2: await Firebase.initializeApp();
  // Phase 2: await PushNotificationService().initialize();

  runApp(
    const ProviderScope(
      child: TradingApp(),
    ),
  );
}
