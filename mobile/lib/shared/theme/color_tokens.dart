import 'package:flutter/material.dart';

/// Semantic colour tokens for trading application.
///
/// Use these instead of hardcoded [Color] values in widgets.
/// Supports two trading colour schemes:
///   - [redUp]: Red = price up, Green = price down (Western convention)
///   - [greenUp]: Green = price up, Red = price down (Chinese/Asian convention)
class ColorTokens {
  const ColorTokens({
    required this.priceUp,
    required this.priceDown,
    required this.priceNeutral,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.surface,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.divider,
    required this.cardBackground,
    required this.positiveBackground,
    required this.negativeBackground,
  });

  final Color priceUp;
  final Color priceDown;
  final Color priceNeutral;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color surface;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color onError;
  final Color divider;
  final Color cardBackground;
  final Color positiveBackground;
  final Color negativeBackground;

  /// Red-up colour set: green = up (Chinese market convention).
  static const greenUp = ColorTokens(
    priceUp: Color(0xFF0DC582),    // Bright green — price rise
    priceDown: Color(0xFFFF4747),  // Red — price fall
    priceNeutral: Color(0xFF8A8D9F),
    primary: Color(0xFF1A73E8),
    primaryContainer: Color(0xFF1557B0),
    onPrimary: Colors.white,
    surface: Color(0xFF1A1C2A),
    surfaceVariant: Color(0xFF242638),
    onSurface: Color(0xFFF0F0F5),
    onSurfaceVariant: Color(0xFFB0B3C8),
    background: Color(0xFF0F1120),
    onBackground: Color(0xFFF0F0F5),
    error: Color(0xFFFF4747),
    onError: Colors.white,
    divider: Color(0xFF2C2E3E),
    cardBackground: Color(0xFF1A1C2A),
    positiveBackground: Color(0xFF0D2A1E),
    negativeBackground: Color(0xFF2A0D0D),
  );

  /// Red-up colour set: red = up (Western market convention).
  static const redUp = ColorTokens(
    priceUp: Color(0xFFFF4747),    // Red — price rise
    priceDown: Color(0xFF0DC582),  // Green — price fall
    priceNeutral: Color(0xFF8A8D9F),
    primary: Color(0xFF1A73E8),
    primaryContainer: Color(0xFF1557B0),
    onPrimary: Colors.white,
    surface: Color(0xFF1A1C2A),
    surfaceVariant: Color(0xFF242638),
    onSurface: Color(0xFFF0F0F5),
    onSurfaceVariant: Color(0xFFB0B3C8),
    background: Color(0xFF0F1120),
    onBackground: Color(0xFFF0F0F5),
    error: Color(0xFFFF4747),
    onError: Colors.white,
    divider: Color(0xFF2C2E3E),
    cardBackground: Color(0xFF1A1C2A),
    positiveBackground: Color(0xFF2A0D0D),
    negativeBackground: Color(0xFF0D2A1E),
  );
}
