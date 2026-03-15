import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/trading_color_scheme.dart';

/// Root widget of the Trading App.
///
/// Injects [appRouterProvider] (go_router) and the dark theme.
/// Theme selection (red-up / green-up) will be driven by [ThemeNotifier]
/// in Phase 2 once SharedPreferences is wired.
class TradingApp extends ConsumerWidget {
  const TradingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Trading App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(
        colorScheme: TradingColorScheme.greenUp,
        brightness: Brightness.light,
      ),
      darkTheme: AppTheme.build(
        colorScheme: TradingColorScheme.greenUp,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark, // Dark-first per design spec
      routerConfig: router,
    );
  }
}
