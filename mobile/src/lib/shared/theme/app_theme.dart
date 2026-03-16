import 'package:flutter/material.dart';
import 'color_tokens.dart';
import 'trading_color_scheme.dart';

/// Application theme builder.
///
/// Provides dark-first ThemeData configured for financial trading UI:
///   - Material 3 design system
///   - Dark background optimised for reading prices at a glance
///   - Supports [TradingColorScheme.greenUp] (default) and [redUp]
class AppTheme {
  AppTheme._();

  static ThemeData build({
    required TradingColorScheme colorScheme,
    Brightness brightness = Brightness.dark,
  }) {
    final tokens = colorScheme == TradingColorScheme.greenUp
        ? ColorTokens.greenUp
        : ColorTokens.redUp;

    final colorSchemeData = _buildColorScheme(tokens, brightness);
    final textTheme = _buildTextTheme(tokens);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorSchemeData,
      scaffoldBackgroundColor: tokens.background,
      textTheme: textTheme,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: tokens.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Navigation bar (bottom tab)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.primary.withAlpha(40),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: tokens.primary);
          }
          return IconThemeData(color: tokens.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = textTheme.labelSmall;
          if (states.contains(WidgetState.selected)) {
            return base?.copyWith(color: tokens.primary);
          }
          return base?.copyWith(color: tokens.onSurfaceVariant);
        }),
      ),

      // Card
      cardTheme: CardThemeData(
        color: tokens.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.divider, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: tokens.onSurfaceVariant),
        hintStyle: TextStyle(color: tokens.onSurfaceVariant),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: tokens.divider,
        thickness: 0.5,
        space: 0,
      ),
    );
  }

  static ColorScheme _buildColorScheme(ColorTokens tokens, Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.primaryContainer,
      onPrimaryContainer: tokens.onPrimary,
      secondary: tokens.primary,
      onSecondary: tokens.onPrimary,
      secondaryContainer: tokens.surfaceVariant,
      onSecondaryContainer: tokens.onSurface,
      tertiary: tokens.priceUp,
      onTertiary: Colors.white,
      tertiaryContainer: tokens.positiveBackground,
      onTertiaryContainer: tokens.priceUp,
      error: tokens.error,
      onError: tokens.onError,
      errorContainer: tokens.negativeBackground,
      onErrorContainer: tokens.priceDown,
      surface: tokens.surface,
      onSurface: tokens.onSurface,
      onSurfaceVariant: tokens.onSurfaceVariant,
      outline: tokens.divider,
      outlineVariant: tokens.divider,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: tokens.onSurface,
      onInverseSurface: tokens.surface,
      inversePrimary: tokens.primaryContainer,
    );
  }

  static TextTheme _buildTextTheme(ColorTokens tokens) {
    return TextTheme(
      displayLarge: TextStyle(color: tokens.onBackground, fontSize: 57, fontWeight: FontWeight.w400),
      displayMedium: TextStyle(color: tokens.onBackground, fontSize: 45, fontWeight: FontWeight.w400),
      displaySmall: TextStyle(color: tokens.onBackground, fontSize: 36, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(color: tokens.onSurface, fontSize: 32, fontWeight: FontWeight.w600),
      headlineMedium: TextStyle(color: tokens.onSurface, fontSize: 28, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: tokens.onSurface, fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: tokens.onSurface, fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: tokens.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: tokens.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: tokens.onSurface, fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(color: tokens.onSurface, fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: tokens.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(color: tokens.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: tokens.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(color: tokens.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}
