/// Environment-aware configuration for the Trading App.
///
/// This module centralizes all environment-dependent settings (API endpoints,
/// feature flags, etc.) and provides a single source of truth for different build
/// environments (dev, staging, production).
///
/// **Usage:**
/// - Development (local Mock Server):
///   ```bash
///   flutter run --dart-define=ENVIRONMENT=development
///   flutter test --dart-define=ENVIRONMENT=development
///   ```
///
/// - Staging:
///   ```bash
///   flutter run --dart-define=ENVIRONMENT=staging
///   ```
///
/// - Production:
///   ```bash
///   flutter run --dart-define=ENVIRONMENT=production
///   ```
///
/// **Configuration Precedence:**
/// 1. Explicit --dart-define overrides (highest priority)
/// 2. ENVIRONMENT-based defaults
/// 3. Hardcoded fallback values (lowest priority)
library;

import 'dart:io';

enum Environment {
  /// Local development with Mock Server running on localhost:8080
  development,

  /// Staging environment (pre-production)
  staging,

  /// Production environment (live trading)
  production;

  /// Parse environment from string (used in --dart-define)
  static Environment fromString(String? value) => switch (value?.toLowerCase()) {
        'staging' => Environment.staging,
        'production' => Environment.production,
        _ => Environment.development,
      };
}

/// Configuration class for environment-dependent settings.
///
/// All API endpoints and feature flags are defined here.
/// Access via [EnvironmentConfig.instance] singleton.
class EnvironmentConfig {
  /// Singleton instance — initialized on app startup
  static late final EnvironmentConfig _instance;

  /// Initialize the configuration (call this in main.dart)
  static void initialize({Environment? environment}) {
    _instance = EnvironmentConfig._internal(environment ?? _detectEnvironment());
  }

  /// Get the singleton instance
  static EnvironmentConfig get instance {
    try {
      return _instance;
    } catch (_) {
      throw StateError(
        'EnvironmentConfig not initialized. Call EnvironmentConfig.initialize() in main().',
      );
    }
  }

  final Environment environment;

  /// Private constructor for singleton pattern
  EnvironmentConfig._internal(this.environment);

  /// Detect environment from --dart-define or use default
  static Environment _detectEnvironment() {
    const envString = String.fromEnvironment('ENVIRONMENT');
    return Environment.fromString(envString);
  }

  /// ─── API Base URLs ────────────────────────────────────────────────────────

  /// Base URL for Market Data API (quotes, K-lines, watchlist)
  late final String marketBaseUrl = String.fromEnvironment(
    'MARKET_BASE_URL',
    defaultValue: _marketBaseUrlDefault,
  );

  String get _marketBaseUrlDefault => switch (environment) {
        Environment.development => _localhostUrl(),
        Environment.staging => 'https://api-staging.trading.example.com',
        Environment.production => 'https://api.trading.example.com',
      };

  /// Base URL for AMS API (authentication, KYC, accounts)
  late final String amsBaseUrl = String.fromEnvironment(
    'AMS_BASE_URL',
    defaultValue: _amsBaseUrlDefault,
  );

  String get _amsBaseUrlDefault => switch (environment) {
        Environment.development => _localhostUrl(),
        Environment.staging => 'https://ams-staging.trading.example.com',
        Environment.production => 'https://ams.trading.example.com',
      };

  /// WebSocket base URL for real-time market data
  late final String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: _wsBaseUrlDefault,
  );

  String get _wsBaseUrlDefault => switch (environment) {
        Environment.development => _localhostWsUrl(),
        Environment.staging => 'wss://ws-staging.trading.example.com',
        Environment.production => 'wss://ws.trading.example.com',
      };

  /// Get localhost URL based on platform (Android emulator uses 10.0.2.2)
  static String _localhostUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';  // Android emulator host IP
    }
    return 'http://localhost:8080';  // iOS simulator and physical devices
  }

  /// Get localhost WebSocket URL based on platform
  static String _localhostWsUrl() {
    if (Platform.isAndroid) {
      return 'ws://10.0.2.2:8080';  // Android emulator host IP
    }
    return 'ws://localhost:8080';  // iOS simulator and physical devices
  }

  /// ─── Feature Flags ────────────────────────────────────────────────────────

  /// Enable detailed logging in development/staging
  bool get enableDetailedLogging => environment != Environment.production;

  /// Enable performance monitoring
  bool get enablePerformanceMonitoring => environment != Environment.production;

  /// Show debug banners (dev only)
  bool get showDebugBanner => environment == Environment.development;

  /// ─── Timeout Configurations ───────────────────────────────────────────────

  /// HTTP request timeout (in seconds)
  int get httpTimeoutSeconds => 30;

  /// WebSocket connection timeout (in seconds)
  int get wsTimeoutSeconds => 10;

  /// ─── Utility Methods ──────────────────────────────────────────────────────

  /// Check if running in development
  bool get isDevelopment => environment == Environment.development;

  /// Check if running in staging
  bool get isStaging => environment == Environment.staging;

  /// Check if running in production
  bool get isProduction => environment == Environment.production;

  /// Get environment name for logging
  String get environmentName => environment.toString().split('.').last;

  /// Debug string representation
  @override
  String toString() => 'EnvironmentConfig('
      'environment=$environmentName, '
      'marketBaseUrl=$marketBaseUrl, '
      'amsBaseUrl=$amsBaseUrl, '
      'wsBaseUrl=$wsBaseUrl'
      ')';
}
