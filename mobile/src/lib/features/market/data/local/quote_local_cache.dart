import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/candle.dart';
import '../../domain/entities/quote.dart';
import '../mappers/market_mappers.dart';
import '../remote/market_response_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cache entry value objects
// ─────────────────────────────────────────────────────────────────────────────

class _CacheEntry {
  const _CacheEntry({required this.json, required this.cachedAtMs});

  final String json;
  final int cachedAtMs;

  factory _CacheEntry.fromMap(Map<String, dynamic> m) => _CacheEntry(
        json: m['json'] as String,
        cachedAtMs: m['cachedAtMs'] as int,
      );

  Map<String, dynamic> toMap() => {'json': json, 'cachedAtMs': cachedAtMs};
}

// ─────────────────────────────────────────────────────────────────────────────
// QuoteLocalCache
// ─────────────────────────────────────────────────────────────────────────────

/// Hive-backed local cache for market quote snapshots and K-line data.
///
/// ## Cache keys and TTLs
/// | Data       | Hive box          | Key              | TTL       |
/// |------------|-------------------|------------------|-----------|
/// | Quote      | `market_quotes`   | symbol (e.g. `AAPL`) | 5 min |
/// | K-line     | `market_kline`    | `${symbol}_${period}` | 60 min |
///
/// ## Offline mode
/// When a stale (expired) entry is present but no fresh data is available,
/// callers can request the stale value explicitly via [getQuoteStale] /
/// [getKlineStale].  The UI should display an "offline" indicator alongside
/// stale cached data (see T18 acceptance criteria).
///
/// ## Serialisation
/// Values are stored as JSON-encoded [QuoteDto] / [CandleDto] (the DTO layer
/// is already json_serializable).  Domain entities are produced by applying
/// the standard DTO → entity mappers, keeping this class in the data layer.
class QuoteLocalCache {
  static const _quoteBoxName = 'market_quotes';
  static const _klineBoxName = 'market_kline';

  static const Duration _quoteTtl = Duration(minutes: 5);
  static const Duration _klineTtl = Duration(hours: 1);

  // ─── Quote ────────────────────────────────────────────────────────────────

  /// Returns the cached [Quote] for [symbol] if the entry is still fresh.
  /// Returns null when missing or expired.
  Future<Quote?> getQuote(String symbol) async {
    final entry = await _readEntry(_quoteBoxName, symbol);
    if (entry == null || _isExpired(entry.cachedAtMs, _quoteTtl)) return null;
    return _quoteFromEntry(entry);
  }

  /// Returns the cached [Quote] for [symbol] even if the entry has expired.
  /// Returns null when the cache has no entry at all.
  ///
  /// Use this for offline / no-connectivity scenarios.
  Future<Quote?> getQuoteStale(String symbol) async {
    final entry = await _readEntry(_quoteBoxName, symbol);
    if (entry == null) return null;
    return _quoteFromEntry(entry);
  }

  /// Stores [dto] for [symbol], stamping it with the current time.
  Future<void> putQuote(String symbol, QuoteDto dto) async {
    final entry = _CacheEntry(
      json: jsonEncode(dto.toJson()),
      cachedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _writeEntry(_quoteBoxName, symbol, entry);
    AppLogger.debug('QuoteLocalCache: put quote $symbol');
  }

  /// Removes all quote cache entries.
  Future<void> clearQuotes() async {
    final box = await Hive.openBox<dynamic>(_quoteBoxName);
    await box.clear();
  }

  // ─── K-line ───────────────────────────────────────────────────────────────

  /// Cache key for K-line data.
  ///
  /// [period] must be one of: 1min, 5min, 15min, 30min, 60min, 1d, 1w, 1mo.
  static String klineKey(String symbol, String period) =>
      '${symbol}_$period';

  /// Returns cached candles for [symbol] at [period] if still fresh.
  /// Returns null when missing or expired.
  Future<List<Candle>?> getKline(String symbol, String period) async {
    final key = klineKey(symbol, period);
    final entry = await _readEntry(_klineBoxName, key);
    if (entry == null || _isExpired(entry.cachedAtMs, _klineTtl)) return null;
    return _candlesFromEntry(entry);
  }

  /// Returns cached candles for [symbol] at [period] even if expired.
  /// Returns null when the cache has no entry.
  Future<List<Candle>?> getKlineStale(String symbol, String period) async {
    final key = klineKey(symbol, period);
    final entry = await _readEntry(_klineBoxName, key);
    if (entry == null) return null;
    return _candlesFromEntry(entry);
  }

  /// Stores [candles] (DTO list) for [symbol] at [period].
  Future<void> putKline(
    String symbol,
    String period,
    List<CandleDto> candles,
  ) async {
    final key = klineKey(symbol, period);
    final entry = _CacheEntry(
      json: jsonEncode(candles.map((c) => c.toJson()).toList()),
      cachedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _writeEntry(_klineBoxName, key, entry);
    AppLogger.debug('QuoteLocalCache: put kline $symbol $period '
        '(${candles.length} candles)');
  }

  /// Removes all K-line cache entries.
  Future<void> clearKline() async {
    final box = await Hive.openBox<dynamic>(_klineBoxName);
    await box.clear();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<_CacheEntry?> _readEntry(String boxName, String key) async {
    try {
      final box = await Hive.openBox<dynamic>(boxName);
      final raw = box.get(key) as String?;
      if (raw == null || raw.isEmpty) return null;
      return _CacheEntry.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      AppLogger.warning('QuoteLocalCache: read error [$boxName/$key]: $e');
      return null;
    }
  }

  Future<void> _writeEntry(
    String boxName,
    String key,
    _CacheEntry entry,
  ) async {
    try {
      final box = await Hive.openBox<dynamic>(boxName);
      await box.put(key, jsonEncode(entry.toMap()));
    } catch (e) {
      AppLogger.warning('QuoteLocalCache: write error [$boxName/$key]: $e');
    }
  }

  bool _isExpired(int cachedAtMs, Duration ttl) {
    final age = DateTime.now().millisecondsSinceEpoch - cachedAtMs;
    return age > ttl.inMilliseconds;
  }

  Quote _quoteFromEntry(_CacheEntry entry) {
    final map = jsonDecode(entry.json) as Map<String, dynamic>;
    return QuoteDto.fromJson(map).toDomain();
  }

  List<Candle> _candlesFromEntry(_CacheEntry entry) {
    final list = jsonDecode(entry.json) as List<dynamic>;
    return list
        .map((e) => CandleDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
  }
}
