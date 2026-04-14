import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/market/data/market_data_repository_impl.dart';
import 'package:trading_app/features/market/data/remote/market_remote_data_source.dart';
import 'package:trading_app/features/market/data/remote/market_response_models.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/entities/search_result.dart';

// Mocks
class MockMarketRemoteDataSource extends Mock implements MarketRemoteDataSource {}

void main() {
  late MarketDataRepositoryImpl repository;
  late MockMarketRemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    AppLogger.init();
  });

  setUp(() {
    mockRemoteDataSource = MockMarketRemoteDataSource();
    repository = MarketDataRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('MarketDataRepositoryImpl - getQuotes', () {
    test('getQuotes returns quote map for valid symbols', () async {
      final mockDto = QuotesResponseDto(
        quotes: {
          'AAPL': QuoteDto(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            nameZh: '苹果公司',
            market: 'US',
            price: '150.25',
            change: '1.50',
            changePct: '1.0067',
            volume: 50000000,
            turnover: '7.5B',
            prevClose: '148.75',
            open: '149.00',
            high: '151.00',
            low: '149.50',
            marketCap: '2.8T',
            delayed: false,
            marketStatus: 'REGULAR',
          ),
          'TSLA': QuoteDto(
            symbol: 'TSLA',
            name: 'Tesla Inc.',
            nameZh: '特斯拉公司',
            market: 'US',
            price: '245.80',
            change: '-2.00',
            changePct: '-0.8081',
            volume: 30000000,
            turnover: '7.4B',
            prevClose: '247.80',
            open: '246.00',
            high: '248.00',
            low: '244.00',
            marketCap: '780B',
            delayed: false,
            marketStatus: 'REGULAR',
          ),
        },
        asOf: '2024-01-15T10:30:00.000Z',
      );

      when(() => mockRemoteDataSource.getQuotes(['AAPL', 'TSLA']))
          .thenAnswer((_) async => mockDto);

      final result = await repository.getQuotes(['AAPL', 'TSLA']);

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('AAPL'), true);
      expect(result.containsKey('TSLA'), true);
      verify(() => mockRemoteDataSource.getQuotes(['AAPL', 'TSLA'])).called(1);
    });

    test('getQuotes works with single symbol', () async {
      final mockDto = QuotesResponseDto(
        quotes: {
          'GOOGL': QuoteDto(
            symbol: 'GOOGL',
            name: 'Alphabet Inc.',
            nameZh: '字母公司',
            market: 'US',
            price: '140.00',
            change: '0.70',
            changePct: '0.5035',
            volume: 20000000,
            turnover: '2.8B',
            prevClose: '139.30',
            open: '139.50',
            high: '141.00',
            low: '139.50',
            marketCap: '1.8T',
            delayed: false,
            marketStatus: 'REGULAR',
          ),
        },
        asOf: '2024-01-15T10:30:00.000Z',
      );

      when(() => mockRemoteDataSource.getQuotes(['GOOGL']))
          .thenAnswer((_) async => mockDto);

      final result = await repository.getQuotes(['GOOGL']);

      expect(result.containsKey('GOOGL'), true);
      verify(() => mockRemoteDataSource.getQuotes(['GOOGL'])).called(1);
    });

    test('getQuotes preserves Decimal precision in prices', () async {
      final mockDto = QuotesResponseDto(
        quotes: {
          'BRK.A': QuoteDto(
            symbol: 'BRK.A',
            name: 'Berkshire Hathaway',
            nameZh: '伯克希尔哈撒韦',
            market: 'US',
            price: '599999.9999',
            change: '0.0001',
            changePct: '0.0000',
            volume: 100,
            turnover: '60M',
            prevClose: '599999.9998',
            open: '600000.0000',
            high: '600000.0000',
            low: '599900.0000',
            marketCap: '900B',
            delayed: false,
            marketStatus: 'REGULAR',
          ),
        },
        asOf: '2024-01-15T10:30:00.000Z',
      );

      when(() => mockRemoteDataSource.getQuotes(['BRK.A']))
          .thenAnswer((_) async => mockDto);

      final result = await repository.getQuotes(['BRK.A']);

      expect(result.containsKey('BRK.A'), true);
      // Result is a Map with Quote domain objects
      final brk = result['BRK.A'] as Quote;
      expect(brk.symbol, 'BRK.A');
      // Verify price precision (Decimal type preserves precision)
      expect(brk.price.toString(), '599999.9999');
    });
  });

  group('MarketDataRepositoryImpl - getKline', () {
    test('getKline returns KlineResult with candles', () async {
      final mockDto = KlineResponseDto(
        symbol: 'AAPL',
        period: '1d',
        candles: [
          CandleDto(
            t: '2024-01-15T00:00:00Z',
            o: '150.00',
            h: '151.50',
            l: '149.50',
            c: '150.25',
            v: 50000000,
            n: 1000,
          ),
          CandleDto(
            t: '2024-01-16T00:00:00Z',
            o: '150.25',
            h: '152.00',
            l: '150.00',
            c: '151.75',
            v: 55000000,
            n: 1100,
          ),
        ],
        total: 250,
      );

      when(() => mockRemoteDataSource.getKline(
            symbol: 'AAPL',
            period: '1d',
            from: '2024-01-01',
            to: '2024-01-31',
            limit: null,
            cursor: null,
          )).thenAnswer((_) async => mockDto);

      final result = await repository.getKline(
        symbol: 'AAPL',
        period: '1d',
        from: '2024-01-01',
        to: '2024-01-31',
      );

      expect(result.symbol, 'AAPL');
      expect(result.period, '1d');
      expect(result.candles.length, 2);
    });

    test('getKline supports pagination with cursor', () async {
      final mockDto = KlineResponseDto(
        symbol: 'TSLA',
        period: '1h',
        candles: [],
        nextCursor: 'cursor_abc123',
        total: 100,
      );

      when(() => mockRemoteDataSource.getKline(
            symbol: 'TSLA',
            period: '1h',
            from: '2024-01-15',
            to: null,
            limit: 100,
            cursor: 'cursor_prev',
          )).thenAnswer((_) async => mockDto);

      final result = await repository.getKline(
        symbol: 'TSLA',
        period: '1h',
        from: '2024-01-15',
        limit: 100,
        cursor: 'cursor_prev',
      );

      expect(result.nextCursor, 'cursor_abc123');
    });
  });

  group('MarketDataRepositoryImpl - searchStocks', () {
    test('searchStocks returns search results for query', () async {
      final mockDto = SearchResponseDto(
        results: [
          SearchResultDto(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            nameZh: '苹果公司',
            market: 'US',
            price: '150.25',
            changePct: '1.0067',
            delayed: false,
          ),
          SearchResultDto(
            symbol: 'APPL',
            name: 'Applied Industrial Properties',
            nameZh: '应用工业地产',
            market: 'US',
            price: '30.00',
            changePct: '0.5000',
            delayed: false,
          ),
        ],
        total: 2,
      );

      when(() => mockRemoteDataSource.searchStocks(
            q: 'AAPL',
            market: null,
            limit: null,
          )).thenAnswer((_) async => mockDto);

      final results = await repository.searchStocks(q: 'AAPL');

      expect(results.length, 2);
      expect(results[0].symbol, 'AAPL');
      expect(results[0].name, 'Apple Inc.');
    });

    test('searchStocks filters by market', () async {
      final mockDto = SearchResponseDto(
        results: [
          SearchResultDto(
            symbol: '0700',
            name: 'Tencent Holdings',
            nameZh: '腾讯控股',
            market: 'HK',
            price: '150.50',
            changePct: '0.3333',
            delayed: false,
          ),
        ],
        total: 1,
      );

      when(() => mockRemoteDataSource.searchStocks(
            q: 'Tencent',
            market: 'HK',
            limit: null,
          )).thenAnswer((_) async => mockDto);

      final results = await repository.searchStocks(
        q: 'Tencent',
        market: 'HK',
      );

      expect(results.length, 1);
      expect(results[0].market, 'HK');
    });

    test('searchStocks respects limit parameter', () async {
      final mockDto = SearchResponseDto(
        results: [
          SearchResultDto(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            nameZh: '苹果公司',
            market: 'US',
            price: '150.25',
            changePct: '1.0067',
            delayed: false,
          ),
        ],
        total: 1,
      );

      when(() => mockRemoteDataSource.searchStocks(
            q: 'A',
            market: null,
            limit: 10,
          )).thenAnswer((_) async => mockDto);

      final results = await repository.searchStocks(
        q: 'A',
        limit: 10,
      );

      expect(results.length, 1);
      verify(() => mockRemoteDataSource.searchStocks(
            q: 'A',
            market: null,
            limit: 10,
          )).called(1);
    });

    test('searchStocks returns empty list for no matches', () async {
      final mockDto = SearchResponseDto(results: [], total: 0);

      when(() => mockRemoteDataSource.searchStocks(
            q: 'XYZZZZ',
            market: null,
            limit: null,
          )).thenAnswer((_) async => mockDto);

      final results = await repository.searchStocks(q: 'XYZZZZ');

      expect(results.length, 0);
    });
  });

  group('MarketDataRepositoryImpl - getMovers', () {
    test('getMovers returns top gainers', () async {
      final mockDto = MoversResponseDto(
        type: 'gainers',
        market: 'US',
        items: [
          MoverItemDto(
            rank: 1,
            symbol: 'STOCK1',
            name: 'Stock One',
            nameZh: '股票一号',
            price: '100.00',
            change: '10.50',
            changePct: '10.5000',
            volume: 5000000,
            turnover: '500M',
            marketStatus: 'REGULAR',
          ),
          MoverItemDto(
            rank: 2,
            symbol: 'STOCK2',
            name: 'Stock Two',
            nameZh: '股票二号',
            price: '50.00',
            change: '4.15',
            changePct: '8.3000',
            volume: 3000000,
            turnover: '150M',
            marketStatus: 'REGULAR',
          ),
        ],
        asOf: '2024-01-15T10:30:00.000Z',
      );

      when(() => mockRemoteDataSource.getMovers(
            type: 'gainers',
            market: 'US',
          )).thenAnswer((_) async => mockDto);

      final movers = await repository.getMovers(
        type: 'gainers',
        market: 'US',
      );

      expect(movers.length, 2);
      expect(movers[0].symbol, 'STOCK1');
    });

    test('getMovers works with default parameters', () async {
      final mockDto = MoversResponseDto(
        type: 'gainers',
        market: 'US',
        items: [],
        asOf: '2024-01-15T10:30:00.000Z',
      );

      when(() => mockRemoteDataSource.getMovers(
            type: null,
            market: null,
          )).thenAnswer((_) async => mockDto);

      final movers = await repository.getMovers();

      expect(movers.length, 0);
      verify(() => mockRemoteDataSource.getMovers(
            type: null,
            market: null,
          )).called(1);
    });
  });

  group('MarketDataRepositoryImpl - getStockDetail', () {
    test('getStockDetail returns complete stock information', () async {
      final mockDto = StockDetailDto(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        nameZh: '苹果公司',
        market: 'US',
        price: '150.25',
        change: '1.50',
        changePct: '1.0067',
        open: '149.00',
        high: '151.00',
        low: '149.50',
        prevClose: '148.75',
        volume: 50000000,
        turnover: '7.5B',
        delayed: false,
        marketStatus: 'REGULAR',
        marketCap: '2800000000000',
        peRatio: '25.5',
        pbRatio: '42.3',
        dividendYield: '0.5',
        sector: 'Technology',
        exchange: 'NASDAQ',
      );

      when(() => mockRemoteDataSource.getStockDetail('AAPL'))
          .thenAnswer((_) async => mockDto);

      final detail = await repository.getStockDetail('AAPL');

      expect(detail.symbol, 'AAPL');
      expect(detail.name, 'Apple Inc.');
      expect(detail.sector, 'Technology');
    });
  });

  group('MarketDataRepositoryImpl - getNews', () {
    test('getNews returns news articles with pagination', () async {
      final mockDto = NewsResponseDto(
        symbol: 'AAPL',
        news: [
          NewsArticleDto(
            id: 'news_1',
            title: 'Apple releases new iPhone',
            source: 'Reuters',
            publishedAt: '2024-01-15T10:00:00Z',
            url: 'https://example.com/news/1',
            summary: 'Apple announced a new iPhone model',
          ),
        ],
        page: 1,
        pageSize: 10,
        total: 100,
      );

      when(() => mockRemoteDataSource.getNews(
            'AAPL',
            page: 1,
            pageSize: 10,
          )).thenAnswer((_) async => mockDto);

      final result = await repository.getNews(
        'AAPL',
        page: 1,
        pageSize: 10,
      );

      expect(result.articles.length, 1);
      expect(result.total, 100);
      expect(result.page, 1);
    });

    test('getNews supports pagination', () async {
      final mockDto = NewsResponseDto(
        symbol: 'TSLA',
        news: [],
        page: 2,
        pageSize: 10,
        total: 100,
      );

      when(() => mockRemoteDataSource.getNews(
            'TSLA',
            page: 2,
            pageSize: 10,
          )).thenAnswer((_) async => mockDto);

      final result = await repository.getNews(
        'TSLA',
        page: 2,
        pageSize: 10,
      );

      expect(result.page, 2);
      expect(result.articles.length, 0);
    });
  });

  group('MarketDataRepositoryImpl - getFinancials', () {
    test('getFinancials returns financial data', () async {
      final mockDto = FinancialsResponseDto(
        symbol: 'AAPL',
        nextEarningsDate: '2024-04-25',
        nextEarningsQuarter: 'Q2 2024',
        quarters: [
          FinancialsQuarterDto(
            period: 'Q1 2024',
            reportDate: '2024-01-30',
            revenue: '383285000000',
            netIncome: '99803000000',
            eps: '6.05',
            epsEstimate: '5.90',
            revenueGrowth: '2.1',
            netIncomeGrowth: '8.8',
          ),
        ],
      );

      when(() => mockRemoteDataSource.getFinancials('AAPL'))
          .thenAnswer((_) async => mockDto);

      final financials = await repository.getFinancials('AAPL');

      expect(financials.symbol, 'AAPL');
      expect(financials.nextEarningsDate, '2024-04-25');
    });
  });

  group('MarketDataRepositoryImpl - watchlist operations', () {
    test('getWatchlist returns user watchlist', () async {
      final mockDto = WatchlistResponseDto(
        symbols: ['AAPL', 'TSLA', 'GOOGL'],
        quotes: {
          'AAPL': QuoteDto(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            nameZh: '苹果公司',
            market: 'US',
            price: '150.25',
            change: '1.50',
            changePct: '1.0067',
            volume: 50000000,
            turnover: '7.5B',
            prevClose: '148.75',
            open: '149.00',
            high: '151.00',
            low: '149.50',
            marketCap: '2.8T',
            delayed: false,
            marketStatus: 'REGULAR',
          ),
          'TSLA': QuoteDto(
            symbol: 'TSLA',
            name: 'Tesla Inc.',
            nameZh: '特斯拉公司',
            market: 'US',
            price: '245.80',
            change: '-2.00',
            changePct: '-0.8081',
            volume: 30000000,
            turnover: '7.4B',
            prevClose: '247.80',
            open: '246.00',
            high: '248.00',
            low: '244.00',
            marketCap: '780B',
            delayed: false,
            marketStatus: 'REGULAR',
          ),
          'GOOGL': QuoteDto(
            symbol: 'GOOGL',
            name: 'Alphabet Inc.',
            nameZh: '字母公司',
            market: 'US',
            price: '140.00',
            change: '0.70',
            changePct: '0.5035',
            volume: 20000000,
            turnover: '2.8B',
            prevClose: '139.30',
            open: '139.50',
            high: '141.00',
            low: '139.50',
            marketCap: '1.8T',
            delayed: false,
            marketStatus: 'REGULAR',
          ),
        },
        asOf: '2024-01-15T10:30:00.000Z',
      );

      when(() => mockRemoteDataSource.getWatchlist())
          .thenAnswer((_) async => mockDto);

      final watchlist = await repository.getWatchlist();

      expect(watchlist, isNotEmpty);
      expect(watchlist.length, 3);
    });

    test('addToWatchlist calls remote with correct parameters', () async {
      when(() => mockRemoteDataSource.addToWatchlist(
            symbol: 'AAPL',
            market: 'US',
          )).thenAnswer((_) async {});

      await repository.addToWatchlist(symbol: 'AAPL', market: 'US');

      verify(() => mockRemoteDataSource.addToWatchlist(
            symbol: 'AAPL',
            market: 'US',
          )).called(1);
    });

    test('removeFromWatchlist calls remote with symbol', () async {
      when(() => mockRemoteDataSource.removeFromWatchlist('AAPL'))
          .thenAnswer((_) async {});

      await repository.removeFromWatchlist('AAPL');

      verify(() => mockRemoteDataSource.removeFromWatchlist('AAPL')).called(1);
    });
  });
}
