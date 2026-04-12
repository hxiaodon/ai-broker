import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../../core/logging/app_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Value type
// ─────────────────────────────────────────────────────────────────────────────

/// A symbol-market pair stored in the local watchlist.
class WatchlistItem {
  const WatchlistItem({required this.symbol, required this.market});

  final String symbol;

  /// Market identifier: "US" or "HK".
  final String market;

  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
        symbol: json['symbol'] as String,
        market: json['market'] as String,
      );

  Map<String, dynamic> toJson() => {'symbol': symbol, 'market': market};

  @override
  String toString() => 'WatchlistItem($symbol, $market)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Data source
// ─────────────────────────────────────────────────────────────────────────────

/// Hive-backed local storage for the watchlist symbol list.
///
/// Stores an ordered list of [WatchlistItem] as a JSON string under a single
/// Hive box key.  All writes are atomic (replace the whole list).
///
/// Used by [WatchlistRepositoryImpl] as:
///   - Primary store for guest users (server is not called).
///   - Mirror / offline fallback for registered users (server is authoritative).
class WatchlistLocalDataSource {
  static const String _boxName = 'market_watchlist';
  static const String _itemsKey = 'items';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  /// Returns the stored watchlist items in their saved order.
  /// Returns default guest watchlist if nothing has been saved yet.
  Future<List<WatchlistItem>> getItems() async {
    try {
      final box = await _box();
      final raw = box.get(_itemsKey) as String?;
      if (raw == null || raw.isEmpty) {
        AppLogger.debug('WatchlistLocalDataSource: no items stored, returning defaults');
        // Return default watchlist for guest mode testing
        return const [
          WatchlistItem(symbol: 'SPY', market: 'US'),
          WatchlistItem(symbol: 'QQQ', market: 'US'),
          WatchlistItem(symbol: 'DIA', market: 'US'),
          WatchlistItem(symbol: 'AAPL', market: 'US'),
          WatchlistItem(symbol: 'TSLA', market: 'US'),
          WatchlistItem(symbol: '0700', market: 'HK'),
          WatchlistItem(symbol: '9988', market: 'HK'),
        ];
      }
      final list = jsonDecode(raw) as List<dynamic>;
      // If the stored list is empty, return default watchlist
      if (list.isEmpty) {
        AppLogger.debug('WatchlistLocalDataSource: empty list stored, returning defaults');
        return const [
          WatchlistItem(symbol: 'SPY', market: 'US'),
          WatchlistItem(symbol: 'QQQ', market: 'US'),
          WatchlistItem(symbol: 'DIA', market: 'US'),
          WatchlistItem(symbol: 'AAPL', market: 'US'),
          WatchlistItem(symbol: 'TSLA', market: 'US'),
          WatchlistItem(symbol: '0700', market: 'HK'),
          WatchlistItem(symbol: '9988', market: 'HK'),
        ];
      }
      return list
          .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      AppLogger.error(
        'WatchlistLocalDataSource: getItems failed',
        error: e,
        stackTrace: stack,
      );
      // Return default list rather than throwing to keep UI functional
      return const [
        WatchlistItem(symbol: 'SPY', market: 'US'),
        WatchlistItem(symbol: 'QQQ', market: 'US'),
        WatchlistItem(symbol: 'DIA', market: 'US'),
        WatchlistItem(symbol: 'AAPL', market: 'US'),
        WatchlistItem(symbol: 'TSLA', market: 'US'),
        WatchlistItem(symbol: '0700', market: 'HK'),
        WatchlistItem(symbol: '9988', market: 'HK'),
      ];
    }
  }

  /// Atomically replaces the stored list with [items].
  Future<void> saveItems(List<WatchlistItem> items) async {
    try {
      final box = await _box();
      await box.put(
        _itemsKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
      AppLogger.debug('WatchlistLocalDataSource: saved ${items.length} items');
    } catch (e, stack) {
      AppLogger.error(
        'WatchlistLocalDataSource: saveItems failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Removes all stored watchlist data.
  Future<void> clear() async {
    try {
      final box = await _box();
      await box.delete(_itemsKey);
      AppLogger.debug('WatchlistLocalDataSource: cleared all items');
    } catch (e, stack) {
      AppLogger.error(
        'WatchlistLocalDataSource: clear failed',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
