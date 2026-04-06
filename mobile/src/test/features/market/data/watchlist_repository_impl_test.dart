import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/data/local/watchlist_local_datasource.dart';
import 'package:trading_app/features/market/data/remote/market_remote_data_source.dart';
import 'package:trading_app/features/market/data/remote/market_response_models.dart';
import 'package:trading_app/features/market/data/watchlist_repository_impl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockMarketRemoteDataSource extends Mock
    implements MarketRemoteDataSource {}

class MockWatchlistLocalDataSource extends Mock
    implements WatchlistLocalDataSource {}

class MockTokenService extends Mock implements TokenService {}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

QuoteDto makeQuoteDto(String symbol, {String market = 'US'}) => QuoteDto(
      symbol: symbol,
      name: '$symbol Inc.',
      nameZh: '',
      market: market,
      price: '150.0000',
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

WatchlistResponseDto makeWatchlistDto(List<String> symbols) =>
    WatchlistResponseDto(
      symbols: symbols,
      quotes: {for (final s in symbols) s: makeQuoteDto(s)},
      asOf: '2026-04-06T10:00:00.000Z',
    );

QuotesResponseDto makeQuotesDto(List<String> symbols) => QuotesResponseDto(
      quotes: {for (final s in symbols) s: makeQuoteDto(s)},
      asOf: '2026-04-06T10:00:00.000Z',
    );

// ─────────────────────────────────────────────────────────────────────────────
// Test suite
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() => AppLogger.init());

  late MockMarketRemoteDataSource mockRemote;
  late MockWatchlistLocalDataSource mockLocal;
  late MockTokenService mockToken;
  late WatchlistRepositoryImpl sut;

  setUp(() {
    mockRemote = MockMarketRemoteDataSource();
    mockLocal = MockWatchlistLocalDataSource();
    mockToken = MockTokenService();
    sut = WatchlistRepositoryImpl(
      remote: mockRemote,
      local: mockLocal,
      tokenService: mockToken,
    );
  });

  // ─── getWatchlist — registered ─────────────────────────────────────────────

  group('getWatchlist() — registered', () {
    setUp(() {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
    });

    test('fetches watchlist from server and returns Watchlist in server order',
        () async {
      when(() => mockRemote.getWatchlist()).thenAnswer(
        (_) async => makeWatchlistDto(['AAPL', 'TSLA', 'MSFT']),
      );
      when(() => mockLocal.saveItems(any())).thenAnswer((_) async {});

      final result = await sut.getWatchlist();

      expect(result.map((q) => q.symbol), ['AAPL', 'TSLA', 'MSFT']);
    });

    test('syncs server symbol order to local Hive mirror', () async {
      when(() => mockRemote.getWatchlist()).thenAnswer(
        (_) async => makeWatchlistDto(['AAPL', 'TSLA']),
      );

      final captured = <List<WatchlistItem>>[];
      when(() => mockLocal.saveItems(any())).thenAnswer((inv) async {
        captured.add(inv.positionalArguments.first as List<WatchlistItem>);
      });

      await sut.getWatchlist();

      expect(captured.single.map((e) => e.symbol), ['AAPL', 'TSLA']);
      expect(captured.single.first.market, 'US');
    });

    test('does NOT call local.getItems() in registered mode', () async {
      when(() => mockRemote.getWatchlist())
          .thenAnswer((_) async => makeWatchlistDto(['AAPL']));
      when(() => mockLocal.saveItems(any())).thenAnswer((_) async {});

      await sut.getWatchlist();

      verifyNever(() => mockLocal.getItems());
    });
  });

  // ─── getWatchlist — guest ─────────────────────────────────────────────────

  group('getWatchlist() — guest', () {
    setUp(() {
      when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);
    });

    test('returns empty list when local has no items', () async {
      when(() => mockLocal.getItems()).thenAnswer((_) async => []);

      final result = await sut.getWatchlist();

      expect(result, isEmpty);
      verifyNever(() => mockRemote.getQuotes(any()));
    });

    test('fetches quotes for local symbols and returns in local order',
        () async {
      when(() => mockLocal.getItems()).thenAnswer((_) async => [
            const WatchlistItem(symbol: 'AAPL', market: 'US'),
            const WatchlistItem(symbol: 'TSLA', market: 'US'),
          ]);
      when(() => mockRemote.getQuotes(any())).thenAnswer(
        (inv) async => makeQuotesDto(
          (inv.positionalArguments.first as List<String>),
        ),
      );

      final result = await sut.getWatchlist();

      expect(result.map((q) => q.symbol), ['AAPL', 'TSLA']);
      verify(() => mockRemote.getQuotes(['AAPL', 'TSLA'])).called(1);
      verifyNever(() => mockRemote.getWatchlist());
    });

    test('batches > 50 symbols into multiple getQuotes calls', () async {
      // Create 55 symbols
      final symbols = List.generate(55, (i) => 'S${i.toString().padLeft(3, '0')}');
      when(() => mockLocal.getItems()).thenAnswer(
        (_) async => symbols
            .map((s) => WatchlistItem(symbol: s, market: 'US'))
            .toList(),
      );
      when(() => mockRemote.getQuotes(any())).thenAnswer(
        (inv) async => makeQuotesDto(
          (inv.positionalArguments.first as List<String>),
        ),
      );

      await sut.getWatchlist();

      // First batch: 50 symbols, second batch: 5 symbols
      verify(() => mockRemote.getQuotes(any())).called(2);
    });

    test('empty token string is treated as guest', () async {
      when(() => mockToken.getAccessToken()).thenAnswer((_) async => '');
      when(() => mockLocal.getItems()).thenAnswer((_) async => []);

      final result = await sut.getWatchlist();

      expect(result, isEmpty);
      verifyNever(() => mockRemote.getWatchlist());
    });
  });

  // ─── addToWatchlist ────────────────────────────────────────────────────────

  group('addToWatchlist()', () {
    test('registered: calls server AND updates local', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockRemote.addToWatchlist(
            symbol: any(named: 'symbol'),
            market: any(named: 'market'),
          )).thenAnswer((_) async {});
      when(() => mockLocal.getItems()).thenAnswer((_) async => []);
      when(() => mockLocal.saveItems(any())).thenAnswer((_) async {});

      await sut.addToWatchlist(symbol: 'AAPL', market: 'US');

      verify(() => mockRemote.addToWatchlist(symbol: 'AAPL', market: 'US'))
          .called(1);
      verify(() => mockLocal.saveItems(any())).called(1);
    });

    test('registered: does not add duplicate symbol to local', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockRemote.addToWatchlist(
            symbol: any(named: 'symbol'),
            market: any(named: 'market'),
          )).thenAnswer((_) async {});
      // Symbol already exists locally
      when(() => mockLocal.getItems()).thenAnswer((_) async => [
            const WatchlistItem(symbol: 'AAPL', market: 'US'),
          ]);

      await sut.addToWatchlist(symbol: 'AAPL', market: 'US');

      verifyNever(() => mockLocal.saveItems(any()));
    });

    test('guest: only updates local, does NOT call server', () async {
      when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);
      when(() => mockLocal.getItems()).thenAnswer((_) async => []);
      when(() => mockLocal.saveItems(any())).thenAnswer((_) async {});

      await sut.addToWatchlist(symbol: 'AAPL', market: 'US');

      verifyNever(() => mockRemote.addToWatchlist(
            symbol: any(named: 'symbol'),
            market: any(named: 'market'),
          ));
      verify(() => mockLocal.saveItems(any())).called(1);
    });
  });

  // ─── removeFromWatchlist ───────────────────────────────────────────────────

  group('removeFromWatchlist()', () {
    test('registered: calls server AND removes from local', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockRemote.removeFromWatchlist(any()))
          .thenAnswer((_) async {});
      when(() => mockLocal.getItems()).thenAnswer((_) async => [
            const WatchlistItem(symbol: 'AAPL', market: 'US'),
            const WatchlistItem(symbol: 'TSLA', market: 'US'),
          ]);
      when(() => mockLocal.saveItems(any())).thenAnswer((_) async {});

      await sut.removeFromWatchlist('AAPL');

      verify(() => mockRemote.removeFromWatchlist('AAPL')).called(1);
      final captured = verify(() => mockLocal.saveItems(captureAny()))
          .captured
          .first as List<WatchlistItem>;
      expect(captured.map((e) => e.symbol), ['TSLA']);
    });

    test('guest: only removes from local, does NOT call server', () async {
      when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);
      when(() => mockLocal.getItems()).thenAnswer((_) async => [
            const WatchlistItem(symbol: 'AAPL', market: 'US'),
          ]);
      when(() => mockLocal.saveItems(any())).thenAnswer((_) async {});

      await sut.removeFromWatchlist('AAPL');

      verifyNever(() => mockRemote.removeFromWatchlist(any()));
      verify(() => mockLocal.saveItems(any())).called(1);
    });
  });

  // ─── reorderWatchlist ─────────────────────────────────────────────────────

  group('reorderWatchlist()', () {
    setUp(() {
      when(() => mockLocal.saveItems(any())).thenAnswer((_) async {});
    });

    test('persists new order to local — no server call (registered)', () async {
      when(() => mockToken.getAccessToken())
          .thenAnswer((_) async => 'valid-jwt');
      when(() => mockLocal.getItems()).thenAnswer((_) async => [
            const WatchlistItem(symbol: 'AAPL', market: 'US'),
            const WatchlistItem(symbol: 'TSLA', market: 'US'),
            const WatchlistItem(symbol: 'MSFT', market: 'US'),
          ]);

      await sut.reorderWatchlist(['TSLA', 'AAPL', 'MSFT']);

      final captured =
          verify(() => mockLocal.saveItems(captureAny())).captured.first
              as List<WatchlistItem>;
      expect(captured.map((e) => e.symbol), ['TSLA', 'AAPL', 'MSFT']);
      verifyNever(() => mockRemote.addToWatchlist(
            symbol: any(named: 'symbol'),
            market: any(named: 'market'),
          ));
    });

    test('persists new order to local — no server call (guest)', () async {
      when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);
      when(() => mockLocal.getItems()).thenAnswer((_) async => [
            const WatchlistItem(symbol: 'AAPL', market: 'US'),
            const WatchlistItem(symbol: 'TSLA', market: 'US'),
          ]);

      await sut.reorderWatchlist(['TSLA', 'AAPL']);

      final captured =
          verify(() => mockLocal.saveItems(captureAny())).captured.first
              as List<WatchlistItem>;
      expect(captured.map((e) => e.symbol), ['TSLA', 'AAPL']);
    });

    test('unknown symbols in orderedSymbols are silently dropped', () async {
      when(() => mockToken.getAccessToken()).thenAnswer((_) async => null);
      when(() => mockLocal.getItems()).thenAnswer((_) async => [
            const WatchlistItem(symbol: 'AAPL', market: 'US'),
            const WatchlistItem(symbol: 'TSLA', market: 'US'),
          ]);

      await sut.reorderWatchlist(['TSLA', 'UNKNOWN', 'AAPL']);

      final captured =
          verify(() => mockLocal.saveItems(captureAny())).captured.first
              as List<WatchlistItem>;
      expect(captured.map((e) => e.symbol), ['TSLA', 'AAPL']);
    });
  });
}
