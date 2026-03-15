/// Extension methods on [DateTime] for UTC enforcement and market timezone display.
///
/// Per financial-coding-standards: always store/transmit UTC.
/// Convert to local timezone only at the display layer.
library;

extension DateTimeUtcExtensions on DateTime {
  /// Ensures this [DateTime] is in UTC.
  /// Throws [StateError] in debug mode if the datetime is not UTC.
  DateTime get ensureUtc {
    assert(isUtc, 'DateTime must be in UTC. Use DateTime.utc() constructor.');
    return this;
  }

  /// Formats as ISO 8601 UTC string.
  /// Example: '2024-01-15T09:30:00.000Z'
  String toIso8601UtcString() => toUtc().toIso8601String();

  /// Formats for display in US Eastern Time (ET) — NYSE/NASDAQ market hours.
  /// Note: actual timezone conversion requires the `timezone` package (Phase 2).
  /// Phase 1 returns UTC time with a 'UTC' suffix as a safe default.
  String toEasternTimeDisplay({String format = 'MM/dd HH:mm'}) {
    // TODO Phase 2: Use timezone package for proper ET conversion
    // final etZone = tz.getLocation('America/New_York');
    // return DateFormat(format).format(tz.TZDateTime.from(this, etZone));
    return '${_format(format)} UTC';
  }

  /// Formats for display in Hong Kong Time (HKT) — HKEX market hours.
  String toHongKongTimeDisplay({String format = 'MM/dd HH:mm'}) {
    // TODO Phase 2: Use timezone package for proper HKT conversion
    // final hktZone = tz.getLocation('Asia/Hong_Kong');
    final hkt = toUtc().add(const Duration(hours: 8)); // HKT = UTC+8 (no DST)
    return hkt._format(format);
  }

  /// Formats in user's local timezone for display.
  String toLocalDisplay({String format = 'yyyy-MM-dd HH:mm'}) =>
      toLocal()._format(format);

  /// Formats date only (no time).
  String toDateDisplay({String format = 'yyyy-MM-dd'}) =>
      toLocal()._format(format);

  /// Returns true if this datetime falls on a US market trading day.
  /// (Simplified check: Monday–Friday. Does not account for holidays.)
  bool get isUsMarketDay {
    final et = toUtc().subtract(const Duration(hours: 5)); // Approximate ET (no DST)
    return et.weekday >= DateTime.monday && et.weekday <= DateTime.friday;
  }

  /// Returns true if the US stock market is currently open (simplified).
  /// Actual check requires DST-aware Eastern Time conversion (Phase 2).
  bool get isUsMarketOpen {
    if (!isUsMarketDay) return false;
    final et = toUtc().subtract(const Duration(hours: 5));
    final minutes = et.hour * 60 + et.minute;
    return minutes >= 570 && minutes < 960; // 9:30–16:00 ET
  }

  String _format(String pattern) {
    final y = year.toString().padLeft(4, '0');
    final M = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    final H = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    final s = second.toString().padLeft(2, '0');
    return pattern
        .replaceAll('yyyy', y)
        .replaceAll('MM', M)
        .replaceAll('dd', d)
        .replaceAll('HH', H)
        .replaceAll('mm', m)
        .replaceAll('ss', s);
  }
}
