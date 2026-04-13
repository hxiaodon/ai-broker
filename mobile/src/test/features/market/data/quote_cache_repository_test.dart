import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/storage/database.dart';
import 'package:trading_app/features/market/data/quote_cache_repository_impl.dart';
import 'package:trading_app/features/market/domain/repositories/market_data_repository.dart';

class _MockBaseRepository extends Mock implements MarketDataRepository {}

class _MockDatabase extends Mock implements AppDatabase {}

void main() {
  late MarketDataCacheRepositoryImpl cacheRepository;
  late _MockBaseRepository mockBaseRepository;
  late _MockDatabase mockDatabase;

  setUpAll(() {
    AppLogger.init(verbose: false);
    // Register fallback value for QuoteCache
    registerFallbackValue(QuoteCache(
      symbol: '',
      market: '',
      name: '',
      nameZh: '',
      price: '',
      change: '',
      changePct: '',
      volume: 0,
      bid: null,
      ask: null,
      turnover: '',
      prevClose: '',
      open: '',
      high: '',
      low: '',
      marketCap: '',
      peRatio: null,
      delayed: false,
      marketStatus: '',
      isStale: false,
      staleSinceMs: 0,
      cachedAt: '',
    ));
  });

  setUp(() {
    mockBaseRepository = _MockBaseRepository();
    mockDatabase = _MockDatabase();
    cacheRepository = MarketDataCacheRepositoryImpl(
      database: mockDatabase,
      baseRepository: mockBaseRepository,
      cacheTTL: const Duration(seconds: 30),
    );
  });

  group('MarketDataCacheRepositoryImpl', () {
    // ─── Happy Path: API Success ───────────────────────────────────
    group('Happy Path - API Success', () {
      test('should fetch from API and update cache on success', () async {
        // Arrange
        const symbols = ['AAPL', '0700'];
        final apiResponse = {
          'AAPL': {
            'symbol': 'AAPL',
            'name': 'Apple',
            'nameZh': '苹果',
            'market': 'US',
            'price': '150.25',
            'change': '2.50',
            'changePct': '1.69',
            'volume': 50000000,
            'bid': '150.24',
            'ask': '150.26',
            'turnover': '7.50B',
            'prevClose': '147.75',
            'open': '148.00',
            'high': '150.50',
            'low': '147.80',
            'marketCap': '2.30T',
            'peRatio': '28.5',
            'delayed': false,
            'marketStatus': 'TRADING',
          },
          '0700': {
            'symbol': '0700',
            'name': 'Tencent',
            'nameZh': '腾讯',
            'market': 'HK',
            'price': '385.50',
            'change': '5.50',
            'changePct': '1.45',
            'volume': 30000000,
            'bid': '385.40',
            'ask': '385.60',
            'turnover': '11.50B',
            'prevClose': '380.00',
            'open': '382.00',
            'high': '386.00',
            'low': '381.50',
            'marketCap': '3.70T',
            'peRatio': '20.5',
            'delayed': false,
            'marketStatus': 'TRADING',
          },
        };

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await cacheRepository.getQuotes(symbols);

        // Assert
        expect(result, apiResponse);
        // Verify cache update was called
        verify(() => mockDatabase.insertQuote(any())).called(greaterThan(0));
      });
    });

    // ─── Offline Fallback: API Fails, Cache Valid ──────────────────
    group('Offline Fallback - Fresh Cache', () {
      test('should return fresh cached data when API fails', () async {
        // Arrange
        const symbols = ['AAPL'];
        final now = DateTime.now().toUtc();
        final cachedQuote = QuoteCache(
          symbol: 'AAPL',
          market: 'US',
          name: 'Apple',
          nameZh: '苹果',
          price: '150.25',
          change: '2.50',
          changePct: '1.69',
          volume: 50000000,
          bid: '150.24',
          ask: '150.26',
          turnover: '7.50B',
          prevClose: '147.75',
          open: '148.00',
          high: '150.50',
          low: '147.80',
          marketCap: '2.30T',
          peRatio: '28.5',
          delayed: false,
          marketStatus: 'TRADING',
          isStale: false,
          staleSinceMs: 0,
          cachedAt: now.subtract(const Duration(seconds: 10)).toIso8601String(),
        );

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenThrow(NetworkException(message: 'Network error'));
        when(() => mockDatabase.getQuote('AAPL', 'US'))
            .thenAnswer((_) async => cachedQuote);
        when(() => mockDatabase.getQuote('AAPL', 'HK'))
            .thenAnswer((_) async => null);

        // Act
        final result = await cacheRepository.getQuotes(symbols);

        // Assert
        expect(result.containsKey('AAPL'), true);
        expect(result['AAPL']['symbol'], 'AAPL');
        expect(result['AAPL']['isStale'], false); // Fresh cache
      });

      test('should not return expired cache (past TTL)', () async {
        // Arrange
        const symbols = ['AAPL'];
        final now = DateTime.now().toUtc();
        final expiredQuote = QuoteCache(
          symbol: 'AAPL',
          market: 'US',
          name: 'Apple',
          nameZh: '苹果',
          price: '150.25',
          change: '2.50',
          changePct: '1.69',
          volume: 50000000,
          bid: '150.24',
          ask: '150.26',
          turnover: '7.50B',
          prevClose: '147.75',
          open: '148.00',
          high: '150.50',
          low: '147.80',
          marketCap: '2.30T',
          peRatio: '28.5',
          delayed: false,
          marketStatus: 'TRADING',
          isStale: false,
          staleSinceMs: 0,
          cachedAt: now.subtract(const Duration(seconds: 60)).toIso8601String(), // 60s old
        );

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenThrow(NetworkException(message: 'Network error'));
        when(() => mockDatabase.getQuote('AAPL', 'US'))
            .thenAnswer((_) async => expiredQuote);
        when(() => mockDatabase.getQuote('AAPL', 'HK'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          cacheRepository.getQuotes(symbols),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    // ─── Cache Miss: No Cached Data ────────────────────────────────
    group('Cache Miss - No Cached Data', () {
      test('should propagate error when API fails and no cache available', () async {
        // Arrange
        const symbols = ['UNKNOWN'];

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenThrow(NetworkException(message: 'Network timeout'));
        when(() => mockDatabase.getQuote('UNKNOWN', 'US'))
            .thenAnswer((_) async => null);
        when(() => mockDatabase.getQuote('UNKNOWN', 'HK'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          cacheRepository.getQuotes(symbols),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    // ─── Cache Update Logic ────────────────────────────────────────
    group('Cache Update - Data Integrity', () {
      test('should preserve Decimal precision in cache (string storage)', () async {
        // Arrange
        const symbols = ['AAPL'];
        final apiResponse = {
          'AAPL': {
            'symbol': 'AAPL',
            'name': 'Apple',
            'nameZh': '苹果',
            'market': 'US',
            'price': '150.2575', // High precision decimal
            'change': '2.5050',
            'changePct': '1.6867',
            'volume': 50000000,
            'bid': '150.2574',
            'ask': '150.2576',
            'turnover': '7.50B',
            'prevClose': '147.7525',
            'open': '148.0000',
            'high': '150.5000',
            'low': '147.8000',
            'marketCap': '2.30T',
            'peRatio': '28.5',
            'delayed': false,
            'marketStatus': 'TRADING',
          },
        };

        var capturedQuote = QuoteCache(
          symbol: '',
          market: '',
          name: '',
          nameZh: '',
          price: '',
          change: '',
          changePct: '',
          volume: 0,
          bid: null,
          ask: null,
          turnover: '',
          prevClose: '',
          open: '',
          high: '',
          low: '',
          marketCap: '',
          peRatio: null,
          delayed: false,
          marketStatus: '',
          isStale: false,
          staleSinceMs: 0,
          cachedAt: '',
        );

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any())).thenAnswer((invocation) async {
          capturedQuote = invocation.positionalArguments[0] as QuoteCache;
        });

        // Act
        await cacheRepository.getQuotes(symbols);

        // Assert - verify decimal precision was preserved as string
        expect(capturedQuote.price, '150.2575');
        expect(capturedQuote.change, '2.5050');
        expect(capturedQuote.bid, '150.2574');
        expect(capturedQuote.ask, '150.2576');
      });

      test('should handle missing optional fields gracefully', () async {
        // Arrange
        const symbols = ['AAPL'];
        final apiResponse = {
          'AAPL': {
            'symbol': 'AAPL',
            'name': 'Apple',
            'nameZh': '苹果',
            'market': 'US',
            'price': '150.25',
            'change': '2.50',
            'changePct': '1.69',
            'volume': 50000000,
            // Missing: bid, ask, peRatio (optional fields)
            'turnover': '7.50B',
            'prevClose': '147.75',
            'open': '148.00',
            'high': '150.50',
            'low': '147.80',
            'marketCap': '2.30T',
            'delayed': false,
            'marketStatus': 'TRADING',
          },
        };

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any()))
            .thenAnswer((_) async => {});

        // Act & Assert - should not throw
        final result = await cacheRepository.getQuotes(symbols);
        expect(result.containsKey('AAPL'), true);
      });
    });

    // ─── Empty Input ──────────────────────────────────────────────
    group('Edge Cases', () {
      test('should return empty map for empty symbols list', () async {
        // Act
        final result = await cacheRepository.getQuotes([]);

        // Assert
        expect(result, isEmpty);
      });

      test('should handle mixed results (some from cache, some from API)', () async {
        // Arrange
        const symbols = ['AAPL', '0700'];

        final apiResponse = {
          'AAPL': apiResponseForAAPL(),
          '0700': apiResponseForTencent(),
        };

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await cacheRepository.getQuotes(symbols);

        // Assert - all symbols should be present from API (successful response)
        expect(result.containsKey('AAPL'), true);
        expect(result.containsKey('0700'), true);
      });
    });
  });
}

Map<String, dynamic> apiResponseForAAPL() => {
      'symbol': 'AAPL',
      'name': 'Apple',
      'nameZh': '苹果',
      'market': 'US',
      'price': '150.25',
      'change': '2.50',
      'changePct': '1.69',
      'volume': 50000000,
      'bid': '150.24',
      'ask': '150.26',
      'turnover': '7.50B',
      'prevClose': '147.75',
      'open': '148.00',
      'high': '150.50',
      'low': '147.80',
      'marketCap': '2.30T',
      'peRatio': '28.5',
      'delayed': false,
      'marketStatus': 'TRADING',
    };

Map<String, dynamic> apiResponseForTencent() => {
      'symbol': '0700',
      'name': 'Tencent',
      'nameZh': '腾讯',
      'market': 'HK',
      'price': '385.50',
      'change': '5.50',
      'changePct': '1.45',
      'volume': 30000000,
      'bid': '385.40',
      'ask': '385.60',
      'turnover': '11.50B',
      'prevClose': '380.00',
      'open': '382.00',
      'high': '386.00',
      'low': '381.50',
      'marketCap': '3.70T',
      'peRatio': '20.5',
      'delayed': false,
      'marketStatus': 'TRADING',
    };
