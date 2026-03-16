/// Trading colour scheme selection enum.
///
/// Controls whether price increases are displayed as green or red.
/// User preference is persisted via SharedPreferences.
enum TradingColorScheme {
  /// Green = price up, Red = price down (Chinese/Asian convention, default).
  greenUp,

  /// Red = price up, Green = price down (Western convention).
  redUp;

  static TradingColorScheme fromString(String value) {
    return TradingColorScheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TradingColorScheme.greenUp,
    );
  }
}
