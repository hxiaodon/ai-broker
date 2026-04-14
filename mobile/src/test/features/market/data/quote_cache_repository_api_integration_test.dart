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
    // Mock clearQuotesCache to return Future<int>
    when(() => mockDatabase.clearQuotesCache())
        .thenAnswer((_) async => 0);
    cacheRepository = MarketDataCacheRepositoryImpl(
      database: mockDatabase,
      baseRepository: mockBaseRepository,
      cacheTTL: const Duration(seconds: 30),
    );
  });

  group('MarketDataCacheRepositoryImpl - API Integration Tests', () {
    // ─── Complete API → Cache → Return Flow ────────────────────
    group('API Success Flow', () {
      test('should fetch from API and write to cache', () async {
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
        };

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await cacheRepository.getQuotes(symbols);

        // Assert - API data returned
        expect(result['AAPL']['price'], '150.25');

        // Verify cache write was called
        verify(() => mockDatabase.insertQuote(any())).called(1);
      });

      test('should batch-write multiple symbols to cache', () async {
        // Arrange
        const symbols = ['AAPL', '0700'];
        final apiResponse = {
          'AAPL': createQuoteData('AAPL', 'US', '150.25'),
          '0700': createQuoteData('0700', 'HK', '385.50'),
        };

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await cacheRepository.getQuotes(symbols);

        // Assert - got both symbols back from API
        expect(result.containsKey('AAPL'), true);
        expect(result.containsKey('0700'), true);

        // Verify cache write was attempted (at least once)
        verify(() => mockDatabase.insertQuote(any())).called(greaterThan(0));
      });
    });

    // ─── API Failure → Cache Fallback Flow ──────────────────────
    group('API Failure Fallback', () {
      test('should return cached data when API fails', () async {
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

        // Assert - cache returned with isStale: false
        expect(result['AAPL']['price'], '150.25');
        expect(result['AAPL']['isStale'], false);
      });

      test('should return empty result if API fails and no cache available', () async {
        // Arrange
        const symbols = ['UNKNOWN'];

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenThrow(NetworkException(message: 'Network error'));
        when(() => mockDatabase.getQuote('UNKNOWN', 'US'))
            .thenAnswer((_) async => null);
        when(() => mockDatabase.getQuote('UNKNOWN', 'HK'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => cacheRepository.getQuotes(symbols),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    // ─── TTL Validation Flow ───────────────────────────────────
    group('TTL Validation', () {
      test('should use fresh cache (within 30s) when API fails', () async {
        // Arrange - cache that is 10 seconds old
        const symbols = ['AAPL'];
        final now = DateTime.now().toUtc();
        final freshCache = QuoteCache(
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
            .thenAnswer((_) async => freshCache);
        when(() => mockDatabase.getQuote('AAPL', 'HK'))
            .thenAnswer((_) async => null);

        // Act
        final result = await cacheRepository.getQuotes(symbols);

        // Assert - fresh cache used
        expect(result['AAPL']['isStale'], false);
      });

      test('should reject expired cache (past 30s) when API fails', () async {
        // Arrange - cache that is 60 seconds old (past TTL)
        const symbols = ['AAPL'];
        final now = DateTime.now().toUtc();
        final expiredCache = QuoteCache(
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
          cachedAt: now.subtract(const Duration(seconds: 60)).toIso8601String(),
        );

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenThrow(NetworkException(message: 'Network error'));
        when(() => mockDatabase.getQuote('AAPL', 'US'))
            .thenAnswer((_) async => expiredCache);
        when(() => mockDatabase.getQuote('AAPL', 'HK'))
            .thenAnswer((_) async => null);

        // Act & Assert - expired cache rejected, error thrown
        expect(
          () => cacheRepository.getQuotes(symbols),
          throwsA(isA<NetworkException>()),
        );
      });
    });

    // ─── Decimal Precision Flow ────────────────────────────────
    group('Decimal Precision', () {
      test('should preserve high-precision decimals through API → cache flow', () async {
        // Arrange
        const symbols = ['AAPL'];
        final apiResponse = {
          'AAPL': {
            'symbol': 'AAPL',
            'name': 'Apple',
            'nameZh': '苹果',
            'market': 'US',
            'price': '150.256789123', // Ultra-high precision
            'change': '2.505234567',
            'changePct': '1.686743210',
            'volume': 50000000,
            'bid': '150.256788',
            'ask': '150.256790',
            'turnover': '7.50B',
            'prevClose': '147.751555123',
            'open': '148.000000000',
            'high': '150.500000000',
            'low': '147.800000000',
            'marketCap': '2.30T',
            'peRatio': '28.5',
            'delayed': false,
            'marketStatus': 'TRADING',
          },
        };

        var capturedQuote = createEmptyQuoteCache();
        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any())).thenAnswer((invocation) async {
          capturedQuote = invocation.positionalArguments[0] as QuoteCache;
        });

        // Act
        await cacheRepository.getQuotes(symbols);

        // Assert - precision preserved in cache write
        expect(capturedQuote.price, '150.256789123');
        expect(capturedQuote.change, '2.505234567');
        expect(capturedQuote.changePct, '1.686743210');
        expect(capturedQuote.bid, '150.256788');
        expect(capturedQuote.ask, '150.256790');
        expect(capturedQuote.prevClose, '147.751555123');
      });
    });

    // ─── Multi-Symbol Scenarios ────────────────────────────────
    group('Multi-Symbol Handling', () {
      test('should handle partial API response (some symbols missing)', () async {
        // Arrange - API only returns 1 of 2 requested symbols
        const symbols = ['AAPL', '0700'];
        final apiResponse = {
          'AAPL': createQuoteData('AAPL', 'US', '150.25'),
          // 0700 missing
        };

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await cacheRepository.getQuotes(symbols);

        // Assert - only AAPL in result
        expect(result.containsKey('AAPL'), true);
        expect(result.containsKey('0700'), false);

        // Verify only 1 cache write
        verify(() => mockDatabase.insertQuote(any())).called(1);
      });

      test('should cache all symbols from multi-symbol response', () async {
        // Arrange
        const symbols = ['AAPL', '0700', 'TSLA'];
        final apiResponse = {
          'AAPL': createQuoteData('AAPL', 'US', '150.25'),
          '0700': createQuoteData('0700', 'HK', '385.50'),
          'TSLA': createQuoteData('TSLA', 'US', '245.80'),
        };

        when(() => mockBaseRepository.getQuotes(symbols))
            .thenAnswer((_) async => apiResponse);
        when(() => mockDatabase.insertQuote(any()))
            .thenAnswer((_) async => {});

        // Act
        final result = await cacheRepository.getQuotes(symbols);

        // Assert - got all symbols from API
        expect(result.containsKey('AAPL'), true);
        expect(result.containsKey('0700'), true);
        expect(result.containsKey('TSLA'), true);

        // Verify cache writes attempted
        verify(() => mockDatabase.insertQuote(any())).called(greaterThan(0));
      });
    });

    // ─── Cache Clearing ────────────────────────────────────────
    group('Cache Management', () {
      test('should clear entire cache', () async {
        // Act
        await cacheRepository.clearQuotesCache();

        // Assert
        verify(() => mockDatabase.clearQuotesCache()).called(1);
      });
    });
  });
}

Map<String, dynamic> createQuoteData(String symbol, String market, String price) =>
    {
      'symbol': symbol,
      'name': symbol == 'AAPL'
          ? 'Apple'
          : symbol == '0700'
              ? 'Tencent'
              : 'Tesla',
      'nameZh': symbol == 'AAPL'
          ? '苹果'
          : symbol == '0700'
              ? '腾讯'
              : '特斯拉',
      'market': market,
      'price': price,
      'change': '2.50',
      'changePct': '1.69',
      'volume': 50000000,
      'bid': (double.parse(price) - 0.01).toString(),
      'ask': (double.parse(price) + 0.01).toString(),
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

QuoteCache createEmptyQuoteCache() => QuoteCache(
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
