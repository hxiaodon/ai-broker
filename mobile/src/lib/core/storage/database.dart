import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

/// Quote snapshot cached for offline access.
/// Updated via market data API responses.
@DataClassName('QuoteCache')
class QuoteCaches extends Table {
  /// Stock symbol (e.g., 'AAPL', '00700')
  TextColumn get symbol => text()();

  /// Market: "US" or "HK"
  TextColumn get market => text()();

  /// Company name (English)
  TextColumn get name => text()();

  /// Company name (Chinese). Empty string if not available.
  TextColumn get nameZh => text()();

  /// Latest trade price (stored as string to preserve Decimal precision)
  TextColumn get price => text()();

  /// Price change vs previous close
  TextColumn get change => text()();

  /// Percentage change (2 decimal places)
  TextColumn get changePct => text()();

  /// Daily volume (in shares)
  IntColumn get volume => integer()();

  /// Best bid price. Null when market closed.
  TextColumn get bid => text().nullable()();

  /// Best ask price. Null when market closed.
  TextColumn get ask => text().nullable()();

  /// Daily turnover (with unit suffix, e.g., "8.24B")
  TextColumn get turnover => text()();

  /// Previous regular-session close
  TextColumn get prevClose => text()();

  /// Daily open price
  TextColumn get open => text()();

  /// Daily high price
  TextColumn get high => text()();

  /// Daily low price
  TextColumn get low => text()();

  /// Market cap (with unit suffix, e.g., "2.80T")
  TextColumn get marketCap => text()();

  /// P/E ratio (TTM). Null for stocks with no earnings.
  TextColumn get peRatio => text().nullable()();

  /// True if quote is delayed 15 minutes (guest user)
  BoolColumn get delayed => boolean()();

  /// Current market trading status ("PRE", "TRADING", "AFTER", "CLOSED")
  TextColumn get marketStatus => text()();

  /// True when data has not been refreshed within 1 second
  BoolColumn get isStale => boolean().withDefault(Constant(false))();

  /// Duration in milliseconds that quote has been stale
  IntColumn get staleSinceMs => integer().withDefault(Constant(0))();

  /// Timestamp when this cache was last updated (UTC, ISO8601)
  TextColumn get cachedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {symbol, market};
}

/// Drift database definition.
///
/// Tables:
/// - QuoteCaches: Real-time quote snapshots for offline access
///
/// Run `dart run build_runner build` to regenerate `database.g.dart`.
@DriftDatabase(tables: [QuoteCaches])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Quote cache DAOs
  /// Save or update a quote snapshot in cache
  Future<void> insertQuote(QuoteCache quote) =>
      into(quoteCaches).insertOnConflictUpdate(quote);

  /// Get cached quote by symbol and market
  Future<QuoteCache?> getQuote(String symbol, String market) =>
      (select(quoteCaches)
            ..where((t) => t.symbol.equals(symbol) & t.market.equals(market)))
          .getSingleOrNull();

  /// Get all cached quotes for a market
  Future<List<QuoteCache>> getQuotesByMarket(String market) =>
      (select(quoteCaches)..where((t) => t.market.equals(market)))
          .get();

  /// Get all cached quotes
  Future<List<QuoteCache>> getAllQuotes() => select(quoteCaches).get();

  /// Delete quote from cache
  Future<int> deleteQuote(String symbol, String market) =>
      (delete(quoteCaches)
            ..where((t) => t.symbol.equals(symbol) & t.market.equals(market)))
          .go();

  /// Clear all quotes from cache
  Future<int> clearQuotesCache() => delete(quoteCaches).go();

  /// Get quotes cached after a certain timestamp (for cache freshness checks)
  Future<List<QuoteCache>> getQuotesCachedAfter(DateTime timestamp) =>
      (select(quoteCaches)
            ..where((t) => t.cachedAt.isBiggerThanValue(timestamp.toIso8601String())))
          .get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'trading_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
