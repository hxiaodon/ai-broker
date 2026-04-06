import 'dart:convert';

import 'package:hive_ce/hive.dart';

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
  /// Returns an empty list if nothing has been saved yet.
  Future<List<WatchlistItem>> getItems() async {
    final box = await _box();
    final raw = box.get(_itemsKey) as String?;
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WatchlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Atomically replaces the stored list with [items].
  Future<void> saveItems(List<WatchlistItem> items) async {
    final box = await _box();
    await box.put(
      _itemsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  /// Removes all stored watchlist data.
  Future<void> clear() async {
    final box = await _box();
    await box.delete(_itemsKey);
  }
}
