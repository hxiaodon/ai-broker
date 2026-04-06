import 'dart:convert';
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/data/local/quote_local_cache.dart';
import 'package:trading_app/features/market/data/remote/market_response_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

QuoteDto makeQuoteDto(
  String symbol, {
  String market = 'US',
  String price = '150.0000',
}) =>
    QuoteDto(
      symbol: symbol,
      name: '$symbol Inc.',
      nameZh: '',
      market: market,
      price: price,
      change: '1.0000',
      changePct: '0.0067',
      volume: 1000000,
      turnover: '150M',
      prevClose: '149.0000',
      open: '149.5000',
      high: '151.0000',
      low: '148.5000',
      marketCap: '2.8T',
      delayed: false,
      marketStatus: 'REGULAR',
    );

CandleDto makeCandleDto(String t) => CandleDto(
      t: t,
      o: '150.0000',
      h: '151.0000',
      l: '149.0000',
      c: '150.5000',
      v: 100000,
      n: 1000,
    );

/// Write an entry with cachedAtMs=0 (epoch) so it is guaranteed to be expired.
Future<void> putExpiredQuote(String symbol, QuoteDto dto) async {
  final box = await Hive.openBox<dynamic>('market_quotes');
  await box.put(
    symbol,
    jsonEncode({'json': jsonEncode(dto.toJson()), 'cachedAtMs': 0}),
  );
}

Future<void> putExpiredKline(
  String symbol,
  String period,
  List<CandleDto> candles,
) async {
  final box = await Hive.openBox<dynamic>('market_kline');
  final key = QuoteLocalCache.klineKey(symbol, period);
  await box.put(
    key,
    jsonEncode({
      'json': jsonEncode(candles.map((c) => c.toJson()).toList()),
      'cachedAtMs': 0,
    }),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Test suite
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late QuoteLocalCache sut;
  late Directory tempDir;

  setUpAll(() async {
    AppLogger.init();
    tempDir = await Directory.systemTemp.createTemp('hive_quote_cache_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    for (final name in ['market_quotes', 'market_kline']) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<dynamic>(name).clear();
      }
    }
    sut = QuoteLocalCache();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ── Quote cache ─────────────────────────────────────────────────────────────

  group('Quote cache', () {
    test('getQuote() returns null when cache is empty', () async {
      expect(await sut.getQuote('AAPL'), isNull);
    });

    test('putQuote() + getQuote() returns a fresh Quote', () async {
      await sut.putQuote('AAPL', makeQuoteDto('AAPL', price: '150.0000'));

      final result = await sut.getQuote('AAPL');
      expect(result, isNotNull);
      expect(result!.symbol, 'AAPL');
      expect(result.price, Decimal.parse('150.0000'));
    });

    test('getQuote() returns null for an expired entry', () async {
      await putExpiredQuote('AAPL', makeQuoteDto('AAPL'));

      expect(await sut.getQuote('AAPL'), isNull);
    });

    test('getQuoteStale() returns the Quote even when expired', () async {
      await putExpiredQuote('AAPL', makeQuoteDto('AAPL', price: '200.0000'));

      final result = await sut.getQuoteStale('AAPL');
      expect(result, isNotNull);
      expect(result!.price, Decimal.parse('200.0000'));
    });

    test('getQuoteStale() returns null when cache has no entry', () async {
      expect(await sut.getQuoteStale('AAPL'), isNull);
    });

    test('putQuote() overwrites a previous entry for the same symbol', () async {
      await sut.putQuote('AAPL', makeQuoteDto('AAPL', price: '100.0000'));
      await sut.putQuote('AAPL', makeQuoteDto('AAPL', price: '200.0000'));

      final result = await sut.getQuote('AAPL');
      expect(result!.price, Decimal.parse('200.0000'));
    });

    test('different symbols are stored independently', () async {
      await sut.putQuote('AAPL', makeQuoteDto('AAPL', price: '150.0000'));
      await sut.putQuote('TSLA', makeQuoteDto('TSLA', price: '250.0000'));

      expect((await sut.getQuote('AAPL'))!.price, Decimal.parse('150.0000'));
      expect((await sut.getQuote('TSLA'))!.price, Decimal.parse('250.0000'));
    });

    test('clearQuotes() removes all quote entries', () async {
      await sut.putQuote('AAPL', makeQuoteDto('AAPL'));
      await sut.putQuote('TSLA', makeQuoteDto('TSLA'));

      await sut.clearQuotes();

      expect(await sut.getQuoteStale('AAPL'), isNull);
      expect(await sut.getQuoteStale('TSLA'), isNull);
    });
  });

  // ── K-line cache ─────────────────────────────────────────────────────────────

  group('K-line cache', () {
    test('getKline() returns null when cache is empty', () async {
      expect(await sut.getKline('AAPL', '1d'), isNull);
    });

    test('putKline() + getKline() returns fresh candles in order', () async {
      final candles = [
        makeCandleDto('2026-04-01T14:30:00.000Z'),
        makeCandleDto('2026-04-02T14:30:00.000Z'),
        makeCandleDto('2026-04-03T14:30:00.000Z'),
      ];
      await sut.putKline('AAPL', '1d', candles);

      final result = await sut.getKline('AAPL', '1d');
      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result.first.t, DateTime.parse('2026-04-01T14:30:00.000Z').toUtc());
    });

    test('getKline() returns null for an expired entry', () async {
      await putExpiredKline('AAPL', '1d', [makeCandleDto('2026-04-01T00:00:00.000Z')]);

      expect(await sut.getKline('AAPL', '1d'), isNull);
    });

    test('getKlineStale() returns candles even when expired', () async {
      await putExpiredKline('AAPL', '1d', [makeCandleDto('2026-04-01T00:00:00.000Z')]);

      final result = await sut.getKlineStale('AAPL', '1d');
      expect(result, isNotNull);
      expect(result!.length, 1);
    });

    test('getKlineStale() returns null when cache has no entry', () async {
      expect(await sut.getKlineStale('AAPL', '1d'), isNull);
    });

    test('different periods for same symbol are stored independently', () async {
      await sut.putKline('AAPL', '1d', [makeCandleDto('2026-04-01T00:00:00.000Z')]);
      await sut.putKline('AAPL', '5min', [
        makeCandleDto('2026-04-01T09:30:00.000Z'),
        makeCandleDto('2026-04-01T09:35:00.000Z'),
      ]);

      expect((await sut.getKline('AAPL', '1d'))!.length, 1);
      expect((await sut.getKline('AAPL', '5min'))!.length, 2);
    });

    test('clearKline() removes all K-line entries', () async {
      await sut.putKline('AAPL', '1d', [makeCandleDto('2026-04-01T00:00:00.000Z')]);
      await sut.putKline('TSLA', '1d', [makeCandleDto('2026-04-01T00:00:00.000Z')]);

      await sut.clearKline();

      expect(await sut.getKlineStale('AAPL', '1d'), isNull);
      expect(await sut.getKlineStale('TSLA', '1d'), isNull);
    });

    test('klineKey() format is symbol_period', () {
      expect(QuoteLocalCache.klineKey('AAPL', '1d'), 'AAPL_1d');
      expect(QuoteLocalCache.klineKey('0700', '5min'), '0700_5min');
    });
  });
}
