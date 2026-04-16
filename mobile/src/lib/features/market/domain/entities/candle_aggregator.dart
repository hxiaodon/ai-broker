import 'package:decimal/decimal.dart';

import 'candle.dart';
import 'quote.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AggregationResult
// ─────────────────────────────────────────────────────────────────────────────

/// Result of processing a single tick through the aggregator.
///
/// Either:
/// - `inProgress` — current candle is still being built (same minute)
/// - `completed` — minute boundary crossed, a new candle was finalized
class AggregationResult {
  const AggregationResult._({this.candle, required this.isCompleted});

  /// The completed candle (only present when `isCompleted == true`).
  final Candle? candle;

  /// Whether a candle was completed (minute boundary crossed).
  final bool isCompleted;

  /// Current candle is still being built.
  factory AggregationResult.inProgress() =>
      const AggregationResult._(isCompleted: false);

  /// A candle was completed and a new one started.
  factory AggregationResult.completed(Candle candle) =>
      AggregationResult._(candle: candle, isCompleted: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// CandleAggregator
// ─────────────────────────────────────────────────────────────────────────────

/// Aggregates WebSocket ticks into 1-minute OHLCV candles.
///
/// ## Algorithm
/// - Uses tick timestamp (server time) to detect minute boundaries
/// - Accumulates OHLCV: open on first tick, high/low track extremes, close on last tick
/// - Volume is cumulative daily volume (not per-minute delta)
///
/// ## Usage
/// ```dart
/// final aggregator = CandleAggregator();
///
/// for (final tick in tickStream) {
///   final result = aggregator.processTick(tick);
///   if (result.isCompleted) {
///     // Append completed candle to chart
///     candles.add(result.candle!);
///   } else {
///     // Update last candle in-place
///     candles[candles.length - 1] = aggregator.currentCandle;
///   }
/// }
/// ```
class CandleAggregator {
  /// Current minute being aggregated (UTC, truncated to minute).
  DateTime? _currentMinute;

  /// OHLCV accumulation for current candle.
  Decimal? _open;
  Decimal? _high;
  Decimal? _low;
  Decimal? _close;
  int _volume = 0;
  int _tradeCount = 0;

  /// Process a single tick and return aggregation result.
  ///
  /// Returns:
  /// - `AggregationResult.inProgress()` if tick belongs to current minute
  /// - `AggregationResult.completed(candle)` if minute boundary crossed
  ///
  /// Note: Uses client-side UTC time for minute boundary detection.
  /// In production, server-side timestamp would be more accurate.
  AggregationResult processTick(Quote tick) {
    // Use client UTC time for minute boundary detection
    final tickTime = DateTime.now().toUtc();
    final tickMinute = _truncateToMinute(tickTime);

    // First tick or minute boundary crossed
    if (_currentMinute == null || tickMinute != _currentMinute) {
      final completed = _finalizeCandle();
      _startNewMinute(tickMinute, tick);

      return completed != null
          ? AggregationResult.completed(completed)
          : AggregationResult.inProgress();
    }

    // Update current candle (same minute)
    _accumulateTick(tick);
    return AggregationResult.inProgress();
  }

  /// Get the current candle being built (for in-place updates).
  ///
  /// Returns null if no candle has been started yet.
  Candle? get currentCandle {
    if (_currentMinute == null) return null;

    return Candle(
      t: _currentMinute!,
      o: _open!,
      h: _high!,
      l: _low!,
      c: _close!,
      v: _volume,
      n: _tradeCount,
    );
  }

  /// Reset aggregator state (e.g., after WebSocket reconnect).
  void reset() {
    _currentMinute = null;
    _open = null;
    _high = null;
    _low = null;
    _close = null;
    _volume = 0;
    _tradeCount = 0;
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────

  /// Truncate datetime to minute boundary (UTC).
  DateTime _truncateToMinute(DateTime dt) {
    return DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  /// Start a new candle with the first tick of a new minute.
  void _startNewMinute(DateTime minute, Quote tick) {
    _currentMinute = minute;
    _open = tick.price;
    _high = tick.price;
    _low = tick.price;
    _close = tick.price;
    _volume = tick.volume;
    _tradeCount = 1;
  }

  /// Accumulate a tick into the current candle.
  void _accumulateTick(Quote tick) {
    // Update high/low using Decimal comparison
    if (tick.price > _high!) _high = tick.price;
    if (tick.price < _low!) _low = tick.price;

    _close = tick.price;
    _volume = tick.volume; // Cumulative daily volume (not delta)
    _tradeCount++;
  }

  /// Finalize the current candle (called when minute boundary crossed).
  ///
  /// Returns null if no candle was being built.
  Candle? _finalizeCandle() {
    if (_currentMinute == null) return null;

    return Candle(
      t: _currentMinute!,
      o: _open!,
      h: _high!,
      l: _low!,
      c: _close!,
      v: _volume,
      n: _tradeCount,
    );
  }
}
