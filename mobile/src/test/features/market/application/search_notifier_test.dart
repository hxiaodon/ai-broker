import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/application/search_notifier.dart';
import 'package:trading_app/features/market/data/market_data_repository_impl.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/features/market/domain/entities/mover_item.dart';
import 'package:trading_app/features/market/domain/entities/search_result.dart';
import 'package:trading_app/features/market/domain/repositories/market_data_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockMarketDataRepository extends Mock implements MarketDataRepository {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

SearchResult makeResult(String symbol) => SearchResult(
      symbol: symbol,
      name: '$symbol Inc.',
      nameZh: '',
      market: 'US',
      price: Decimal.parse('150.0000'),
      changePct: Decimal.parse('0.67'),
      delayed: false,
    );

MoverItem makeMover(String symbol, {int rank = 1}) => MoverItem(
      rank: rank,
      symbol: symbol,
      name: '$symbol Inc.',
      nameZh: '',
      price: Decimal.parse('150.0000'),
      change: Decimal.parse('1.0000'),
      changePct: Decimal.parse('0.67'),
      volume: 5000000,
      turnover: '750M',
      marketStatus: MarketStatus.regular,
    );

ProviderContainer buildContainer({
  required MockMarketDataRepository mockRepo,
  required SharedPreferences prefs,
}) {
  return ProviderContainer(
    overrides: [
      marketDataRepositoryProvider.overrideWith((_) => mockRepo),
      sharedPreferencesProvider.overrideWith((_) async => prefs),
    ],
  );
}

/// Activates [searchProvider] and waits for `_init()` to complete.
///
/// Returns a [ProviderSubscription] that keeps the provider alive.
/// The caller must call `sub.close()` (or just `container.dispose()`) in tearDown.
ProviderSubscription<SearchState> activateSearch(ProviderContainer container) {
  return container.listen(searchProvider, (_, _) {});
}

/// Waits long enough for mock-backed async calls to settle.
Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 30));

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() => AppLogger.init());

  late MockMarketDataRepository mockRepo;
  late SharedPreferences prefs;

  setUp(() async {
    mockRepo = MockMarketDataRepository();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // Default stubs — safe fallbacks
    when(() => mockRepo.getMovers(
          type: any(named: 'type'),
          market: any(named: 'market'),
        )).thenAnswer((_) async => []);
    when(() => mockRepo.searchStocks(
          q: any(named: 'q'),
          market: any(named: 'market'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => []);
  });

  // ─── Initial state ────────────────────────────────────────────────────────

  group('initial state', () {
    test('starts with empty query and empty results', () async {
      final container = buildContainer(mockRepo: mockRepo, prefs: prefs);
      addTearDown(container.dispose);
      activateSearch(container);
      await pump();

      final state = container.read(searchProvider);
      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isEmptyQuery, isTrue);
    });

    test('loads hot stocks on init', () async {
      when(() => mockRepo.getMovers(
            type: any(named: 'type'),
            market: any(named: 'market'),
          )).thenAnswer(
        (_) async =>
            [makeMover('AAPL', rank: 1), makeMover('TSLA', rank: 2)],
      );

      final container = buildContainer(mockRepo: mockRepo, prefs: prefs);
      addTearDown(container.dispose);
      activateSearch(container);
      await pump();

      final state = container.read(searchProvider);
      expect(state.hotStocks.map((r) => r.symbol), ['AAPL', 'TSLA']);
    });

    test('hot stocks failure is silently swallowed', () async {
      when(() => mockRepo.getMovers(
            type: any(named: 'type'),
            market: any(named: 'market'),
          )).thenThrow(Exception('network error'));

      final container = buildContainer(mockRepo: mockRepo, prefs: prefs);
      addTearDown(container.dispose);
      activateSearch(container);
      await pump();

      final state = container.read(searchProvider);
      expect(state.hotStocks, isEmpty);
      expect(state.error, isNull);
    });

    test('loads history from SharedPreferences on init', () async {
      SharedPreferences.setMockInitialValues({
        'search_history_symbols': ['AAPL', 'TSLA'],
      });
      prefs = await SharedPreferences.getInstance();

      final container = buildContainer(mockRepo: mockRepo, prefs: prefs);
      addTearDown(container.dispose);
      activateSearch(container);
      await pump();

      expect(container.read(searchProvider).history, ['AAPL', 'TSLA']);
    });
  });

  // ─── updateQuery — debounce ───────────────────────────────────────────────

  group('updateQuery()', () {
    late ProviderContainer container;

    setUp(() async {
      container = buildContainer(mockRepo: mockRepo, prefs: prefs);
      activateSearch(container);
      await pump();
    });

    tearDown(() => container.dispose());

    test('empty query clears results immediately without network call',
        () async {
      container.read(searchProvider.notifier).updateQuery('');

      final state = container.read(searchProvider);
      expect(state.query, '');
      expect(state.results, isEmpty);
      expect(state.isLoading, isFalse);
      verifyNever(() => mockRepo.searchStocks(
            q: any(named: 'q'),
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          ));
    });

    test('query sets isLoading=true before debounce fires', () async {
      container.read(searchProvider.notifier).updateQuery('AAPL');

      expect(container.read(searchProvider).isLoading, isTrue);
      // Timer not fired yet
      verifyNever(() => mockRepo.searchStocks(
            q: any(named: 'q'),
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          ));
    });

    test('search fires after 300ms debounce', () async {
      when(() => mockRepo.searchStocks(
            q: 'AAPL',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [makeResult('AAPL')]);

      container.read(searchProvider.notifier).updateQuery('AAPL');

      // Wait past the 300ms debounce
      await Future<void>.delayed(const Duration(milliseconds: 350));

      final state = container.read(searchProvider);
      expect(state.results.map((r) => r.symbol), contains('AAPL'));
      expect(state.isLoading, isFalse);
    });

    test('rapid typing debounces — only last query triggers search', () async {
      when(() => mockRepo.searchStocks(
            q: 'TSLA',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [makeResult('TSLA')]);

      final notifier = container.read(searchProvider.notifier);
      notifier.updateQuery('T');
      notifier.updateQuery('TS');
      notifier.updateQuery('TSL');
      notifier.updateQuery('TSLA');

      await Future<void>.delayed(const Duration(milliseconds: 350));

      // Only final query fires search
      verify(() => mockRepo.searchStocks(
            q: 'TSLA',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).called(1);
      verifyNever(() => mockRepo.searchStocks(
            q: 'T',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          ));
      verifyNever(() => mockRepo.searchStocks(
            q: 'TS',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          ));
    });

    test('stale search results are discarded when query changes mid-flight',
        () async {
      final aaplCompleter = Completer<List<SearchResult>>();

      when(() => mockRepo.searchStocks(
            q: 'AAPL',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) => aaplCompleter.future);
      when(() => mockRepo.searchStocks(
            q: 'TSLA',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [makeResult('TSLA')]);

      final notifier = container.read(searchProvider.notifier);

      notifier.updateQuery('AAPL');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      // AAPL search is in-flight; user changes query
      notifier.updateQuery('TSLA');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      // Now complete the stale AAPL response
      aaplCompleter.complete([makeResult('AAPL')]);
      await pump();

      final state = container.read(searchProvider);
      expect(state.query, 'TSLA');
      expect(state.results.map((r) => r.symbol), contains('TSLA'));
      expect(state.results.any((r) => r.symbol == 'AAPL'), isFalse);
    });
  });

  // ─── Minimum input length ─────────────────────────────────────────────────

  group('minimum input length', () {
    late ProviderContainer container;

    setUp(() async {
      container = buildContainer(mockRepo: mockRepo, prefs: prefs);
      activateSearch(container);
      await pump();
    });

    tearDown(() => container.dispose());

    test('1 ASCII char meets minimum — search fires', () async {
      when(() => mockRepo.searchStocks(
            q: 'A',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [makeResult('AAPL')]);

      container.read(searchProvider.notifier).updateQuery('A');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      verify(() => mockRepo.searchStocks(
            q: 'A',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).called(1);
    });

    test('1 Chinese char does NOT meet minimum — no search fires', () async {
      container.read(searchProvider.notifier).updateQuery('苹');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      verifyNever(() => mockRepo.searchStocks(
            q: any(named: 'q'),
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          ));
      expect(container.read(searchProvider).isLoading, isFalse);
    });

    test('2 Chinese chars meets minimum — search fires', () async {
      when(() => mockRepo.searchStocks(
            q: '苹果',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [makeResult('AAPL')]);

      container.read(searchProvider.notifier).updateQuery('苹果');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      verify(() => mockRepo.searchStocks(
            q: '苹果',
            market: any(named: 'market'),
            limit: any(named: 'limit'),
          )).called(1);
    });
  });

  // ─── History management ───────────────────────────────────────────────────

  group('history management', () {
    late ProviderContainer container;

    setUp(() async {
      container = buildContainer(mockRepo: mockRepo, prefs: prefs);
      activateSearch(container);
      await pump();
    });

    tearDown(() => container.dispose());

    test('addToHistory prepends symbol and persists', () async {
      await container.read(searchProvider.notifier).addToHistory('AAPL');
      await container.read(searchProvider.notifier).addToHistory('TSLA');

      final history = container.read(searchProvider).history;
      expect(history.first, 'TSLA'); // newest first
      expect(history, containsAll(['TSLA', 'AAPL']));
      expect(prefs.getStringList('search_history_symbols'),
          containsAllInOrder(['TSLA', 'AAPL']));
    });

    test('addToHistory deduplicates — re-added entry moves to front', () async {
      final notifier = container.read(searchProvider.notifier);
      await notifier.addToHistory('AAPL');
      await notifier.addToHistory('TSLA');
      await notifier.addToHistory('AAPL'); // re-add

      final history = container.read(searchProvider).history;
      expect(history.first, 'AAPL');
      expect(history.where((s) => s == 'AAPL').length, 1);
    });

    test('addToHistory trims to 10 items', () async {
      final notifier = container.read(searchProvider.notifier);
      for (var i = 1; i <= 11; i++) {
        await notifier.addToHistory('S$i');
      }
      expect(container.read(searchProvider).history.length, 10);
    });

    test('removeFromHistory removes single entry', () async {
      final notifier = container.read(searchProvider.notifier);
      await notifier.addToHistory('AAPL');
      await notifier.addToHistory('TSLA');
      await notifier.addToHistory('MSFT');
      await notifier.removeFromHistory('TSLA');

      final history = container.read(searchProvider).history;
      expect(history, containsAllInOrder(['MSFT', 'AAPL']));
      expect(history, isNot(contains('TSLA')));
    });

    test('clearHistory empties list and persists', () async {
      final notifier = container.read(searchProvider.notifier);
      await notifier.addToHistory('AAPL');
      await notifier.addToHistory('TSLA');
      await notifier.clearHistory();

      expect(container.read(searchProvider).history, isEmpty);
      expect(prefs.getStringList('search_history_symbols'), isEmpty);
    });

    test('history loaded from prefs on init', () async {
      SharedPreferences.setMockInitialValues({
        'search_history_symbols': ['MSFT', 'GOOG'],
      });
      final freshPrefs = await SharedPreferences.getInstance();
      final freshContainer = buildContainer(mockRepo: mockRepo, prefs: freshPrefs);
      addTearDown(freshContainer.dispose);
      activateSearch(freshContainer);
      await pump();

      expect(freshContainer.read(searchProvider).history, ['MSFT', 'GOOG']);
    });
  });

  // ─── SearchState computed properties ─────────────────────────────────────

  group('SearchState computed properties', () {
    test('isEmptyQuery is true when query is empty', () {
      const state = SearchState();
      expect(state.isEmptyQuery, isTrue);
    });

    test('isEmptyResult is true when query set, not loading, no results', () {
      const state = SearchState(query: 'AAPL', isLoading: false);
      expect(state.isEmptyResult, isTrue);
    });

    test('isEmptyResult is false while loading', () {
      const state = SearchState(query: 'AAPL', isLoading: true);
      expect(state.isEmptyResult, isFalse);
    });

    test('isEmptyResult is false when results present', () {
      final state =
          SearchState(query: 'AAPL', results: [makeResult('AAPL')]);
      expect(state.isEmptyResult, isFalse);
    });

    test('isEmptyResult is false when error present', () {
      const state = SearchState(
          query: 'AAPL', isLoading: false, error: 'some error');
      expect(state.isEmptyResult, isFalse);
    });
  });

  group('SearchState.isHkQuery', () {
    test('pure numeric 1-5 digits detected as HK query', () {
      for (final code in ['7', '70', '700', '0700', '00700']) {
        expect(
          SearchState(query: code).isHkQuery, isTrue,
          reason: '"$code" should be detected as HK code',
        );
      }
    });

    test('6+ digit numeric NOT detected as HK query', () {
      expect(SearchState(query: '007003').isHkQuery, isFalse);
    });

    test('Chinese characters detected as HK query', () {
      for (final q in ['腾讯', '阿里巴巴', '建设银行', '腾讯控股']) {
        expect(
          SearchState(query: q).isHkQuery, isTrue,
          reason: '"$q" contains Chinese chars — should be HK query',
        );
      }
    });

    test('US ticker symbols NOT detected as HK query', () {
      for (final ticker in ['AAPL', 'MSFT', 'TSLA', 'SPY', 'QQQ']) {
        expect(
          SearchState(query: ticker).isHkQuery, isFalse,
          reason: '"$ticker" is a US ticker — should not be HK query',
        );
      }
    });

    test('mixed alphanumeric NOT detected as HK query', () {
      expect(SearchState(query: 'BABA').isHkQuery, isFalse);
      expect(SearchState(query: '9MSFT').isHkQuery, isFalse);
    });

    test('empty query NOT detected as HK query', () {
      expect(const SearchState().isHkQuery, isFalse);
    });

    test('whitespace-padded HK code detected', () {
      expect(SearchState(query: '  0700  ').isHkQuery, isTrue);
    });
  });
}
