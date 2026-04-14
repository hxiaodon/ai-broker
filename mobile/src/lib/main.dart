import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'core/config/environment_config.dart';
import 'core/logging/app_logger.dart';
import 'core/errors/global_error_handler.dart';
import 'shared/widgets/error/error_boundary.dart';
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

  // Initialize global error handling + Sentry
  try {
    await GlobalErrorHandler.init(
      sentryDsn: const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '', // Empty DSN in debug mode (Sentry disabled)
      ),
      environment: config.environmentName,
    );
    AppLogger.info('GlobalErrorHandler initialized');
  } catch (e) {
    AppLogger.error('Failed to initialize GlobalErrorHandler: $e', error: e);
    // Continue anyway — Sentry integration is optional
  }

  // Phase 2: await Firebase.initializeApp();
  // Phase 2: await PushNotificationService().initialize();

  runApp(
    ErrorBoundary(
      child: ProviderScope(
        observers: [RiverpodObserver()],
        child: const TradingApp(),
      ),
    ),
  );
}

/// Observer for logging Riverpod provider state changes in debug mode.
class RiverpodObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    AppLogger.debug('Provider ${provider.name} added with value: $value');
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    AppLogger.debug(
      'Provider ${provider.name} updated: $previousValue → $newValue',
    );
  }

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) {
    AppLogger.debug('Provider ${provider.name} disposed');
  }
}
