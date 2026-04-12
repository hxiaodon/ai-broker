import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'core/config/environment_config.dart';
import 'core/logging/app_logger.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration (must be first!)
  EnvironmentConfig.initialize();
  final config = EnvironmentConfig.instance;

  // Initialize structured logger (must be before any AppLogger calls)
  AppLogger.init(verbose: config.enableDetailedLogging);
  AppLogger.info('App starting — Phase 1 skeleton (env: ${config.environmentName})');

  // Initialize Hive for local storage
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);
  AppLogger.debug('Hive initialized at ${appDocDir.path}');
  AppLogger.debug('Config: $config');

  // Phase 2: await Firebase.initializeApp();
  // Phase 2: await PushNotificationService().initialize();

  runApp(
    const ProviderScope(
      child: TradingApp(),
    ),
  );
}
