import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/data/local/watchlist_local_datasource.dart';

void main() {
  late WatchlistLocalDataSource sut;
  late Directory tempDir;

  setUpAll(() async {
    AppLogger.init();
    tempDir = await Directory.systemTemp.createTemp('hive_watchlist_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    // Start each test with a clean box.
    if (Hive.isBoxOpen('market_watchlist')) {
      await Hive.box<dynamic>('market_watchlist').clear();
    }
    sut = WatchlistLocalDataSource();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ── getItems ────────────────────────────────────────────────────────────────

  group('getItems()', () {
    test('returns empty list when box has no entry', () async {
      final items = await sut.getItems();
      expect(items, isEmpty);
    });

    test('returns items in saved order', () async {
      final saved = [
        const WatchlistItem(symbol: 'AAPL', market: 'US'),
        const WatchlistItem(symbol: 'TSLA', market: 'US'),
        const WatchlistItem(symbol: '0700', market: 'HK'),
      ];
      await sut.saveItems(saved);

      final result = await sut.getItems();
      expect(result.map((e) => e.symbol).toList(), ['AAPL', 'TSLA', '0700']);
    });

    test('preserves market field for each item', () async {
      await sut.saveItems([
        const WatchlistItem(symbol: 'AAPL', market: 'US'),
        const WatchlistItem(symbol: '0700', market: 'HK'),
      ]);

      final items = await sut.getItems();
      expect(items[0].market, 'US');
      expect(items[1].market, 'HK');
    });
  });

  // ── saveItems ────────────────────────────────────────────────────────────────

  group('saveItems()', () {
    test('overwrites the entire list on second call', () async {
      await sut.saveItems([
        const WatchlistItem(symbol: 'AAPL', market: 'US'),
        const WatchlistItem(symbol: 'TSLA', market: 'US'),
      ]);
      await sut.saveItems([
        const WatchlistItem(symbol: 'MSFT', market: 'US'),
      ]);

      final items = await sut.getItems();
      expect(items, hasLength(1));
      expect(items.first.symbol, 'MSFT');
    });

    test('persists an empty list', () async {
      await sut.saveItems([
        const WatchlistItem(symbol: 'AAPL', market: 'US'),
      ]);
      await sut.saveItems(const []);

      final items = await sut.getItems();
      expect(items, isEmpty);
    });
  });

  // ── clear ────────────────────────────────────────────────────────────────────

  group('clear()', () {
    test('removes stored items — getItems returns empty after clear', () async {
      await sut.saveItems([
        const WatchlistItem(symbol: 'AAPL', market: 'US'),
      ]);
      await sut.clear();

      final items = await sut.getItems();
      expect(items, isEmpty);
    });

    test('clear on already-empty box is a no-op', () async {
      await expectLater(sut.clear(), completes);
      expect(await sut.getItems(), isEmpty);
    });
  });
}
