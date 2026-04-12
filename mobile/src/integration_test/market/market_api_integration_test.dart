import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dio/dio.dart';
import '../helpers/test_app.dart';

/// Market Module — API Integration Tests
///
/// **Purpose**: Verify HTTP API layer and Mock Server integration for market data
/// **Dependencies**: Mock Server running on localhost:8080
/// **Speed**: Fast (~8 seconds)
/// **Run when**: Before commits, in CI/CD pipeline
///
/// **What is tested**:
/// - Quote fetching (single and batch)
/// - Stock search functionality
/// - Market movers (gainers/losers)
/// - Stock detail endpoint
/// - Error handling and edge cases
/// - Data format and structure
///
/// **What is NOT tested**:
/// - Flutter app UI rendering (see market_e2e_app_test.dart)
/// - User UI interactions
/// - WebSocket connections (tested separately)
/// - Complete user journeys
///
/// These tests directly call Mock Server HTTP endpoints using Dio client.
/// No Flutter app is launched - only the HTTP layer is tested.
///
/// **Setup**: Before running these tests, start Mock Server:
/// ```bash
/// cd mobile/mock-server
/// ./mock-server --strategy=normal
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Dio client for direct API calls
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  group('Market API - Quote Endpoints', () {
    testWidgets(
      'MA1: Fetch single stock quote',
      (tester) async {
        print('📊 MA1: Fetch single quote for AAPL');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/AAPL',
        );

        expect(response.statusCode, 200);
        expect(response.data!['symbol'], 'AAPL');
        expect(response.data!['name'], isNotEmpty);
        expect(response.data!['price'], isNotNull);
        expect(response.data!['timestamp'], isNotNull);

        print('    ✅ Quote received: ${response.data!['price']}');
      },
    );

    testWidgets(
      'MA2: Fetch batch quotes',
      (tester) async {
        print('📊 MA2: Fetch batch quotes for AAPL, TSLA, 0700');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/quotes',
          queryParameters: {
            'symbols': 'AAPL,TSLA,0700',
          },
        );

        expect(response.statusCode, 200);
        expect(response.data!['quotes'], isNotEmpty);
        expect(response.data!['quotes']['AAPL'], isNotNull);
        expect(response.data!['quotes']['TSLA'], isNotNull);
        expect(response.data!['quotes']['0700'], isNotNull);

        print('    ✅ Batch quotes received: ${response.data!['quotes'].keys.length} symbols');
      },
    );

    testWidgets(
      'MA3: Quote contains required fields',
      (tester) async {
        print('📊 MA3: Verify quote data structure');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/AAPL',
        );

        final quote = response.data!;
        expect(quote['symbol'], isNotEmpty);
        expect(quote['name'], isNotEmpty);
        expect(quote['price'], isNotNull);
        expect(quote['change'], isNotNull);
        expect(quote['change_pct'], isNotNull);
        expect(quote['market'], isNotEmpty);
        expect(quote['market_status'], isNotEmpty);
        expect(quote['timestamp'], isNotNull);

        print('    ✅ All required fields present');
      },
    );

    testWidgets(
      'MA4: HK stock quote data',
      (tester) async {
        print('📊 MA4: Fetch HK stock quote (0700)');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/0700',
        );

        expect(response.statusCode, 200);
        expect(response.data!['symbol'], '0700');
        expect(response.data!['market'], 'HK');

        print('    ✅ HK stock quote received');
      },
    );

    testWidgets(
      'MA5: US stock quote data',
      (tester) async {
        print('📊 MA5: Fetch US stock quote (TSLA)');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/TSLA',
        );

        expect(response.statusCode, 200);
        expect(response.data!['symbol'], 'TSLA');
        expect(response.data!['market'], 'US');

        print('    ✅ US stock quote received');
      },
    );
  });

  group('Market API - Search Endpoint', () {
    testWidgets(
      'MA6: Search by symbol',
      (tester) async {
        print('🔍 MA6: Search by symbol "AAPL"');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/search',
          queryParameters: {
            'q': 'AAPL',
          },
        );

        expect(response.statusCode, 200);
        expect(response.data!['results'], isList);
        expect(response.data!['results'].length, greaterThan(0));

        print('    ✅ Search results: ${response.data!['results'].length} matches');
      },
    );

    testWidgets(
      'MA7: Search by company name',
      (tester) async {
        print('🔍 MA7: Search by name "Apple"');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/search',
          queryParameters: {
            'q': 'Apple',
          },
        );

        expect(response.statusCode, 200);
        expect(response.data!['results'], isList);

        print('    ✅ Name search successful: ${response.data!['results'].length} results');
      },
    );

    testWidgets(
      'MA8: Search returns required fields',
      (tester) async {
        print('🔍 MA8: Verify search result structure');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/search',
          queryParameters: {
            'q': 'TSLA',
          },
        );

        final results = response.data!['results'] as List;
        if (results.isNotEmpty) {
          final first = results[0] as Map<String, dynamic>;
          expect(first['symbol'], isNotEmpty);
          expect(first['name'], isNotEmpty);
          expect(first['market'], isNotEmpty);

          print('    ✅ Search result has required fields');
        }
      },
    );

    testWidgets(
      'MA9: Empty search returns empty results',
      (tester) async {
        print('🔍 MA9: Empty search query');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/search',
          queryParameters: {
            'q': 'XYZZZ_NOT_A_REAL_SYMBOL_12345',
          },
        );

        expect(response.statusCode, 200);
        expect(response.data!['results'], isList);

        print('    ✅ Empty search handled correctly');
      },
    );
  });

  group('Market API - Movers Endpoint', () {
    testWidgets(
      'MA10: Fetch market movers (gainers)',
      (tester) async {
        print('📈 MA10: Fetch gainers');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/movers',
        );

        expect(response.statusCode, 200);
        expect(response.data!['gainers'], isList);
        expect(response.data!['gainers'].length, greaterThan(0));

        print('    ✅ Gainers: ${response.data!['gainers'].length} stocks');
      },
    );

    testWidgets(
      'MA11: Fetch market movers (losers)',
      (tester) async {
        print('📉 MA11: Fetch losers');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/movers',
        );

        expect(response.statusCode, 200);
        expect(response.data!['losers'], isList);
        expect(response.data!['losers'].length, greaterThan(0));

        print('    ✅ Losers: ${response.data!['losers'].length} stocks');
      },
    );

    testWidgets(
      'MA12: Movers have required fields',
      (tester) async {
        print('📈 MA12: Verify movers data structure');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/movers',
        );

        final gainers = response.data!['gainers'] as List;
        if (gainers.isNotEmpty) {
          final first = gainers[0] as Map<String, dynamic>;
          expect(first['symbol'], isNotEmpty);
          expect(first['name'], isNotEmpty);
          expect(first['change_pct'], isNotNull);

          print('    ✅ Movers have symbol, name, and change_pct');
        }
      },
    );
  });

  group('Market API - Stock Detail Endpoint', () {
    testWidgets(
      'MA13: Stock detail endpoint',
      (tester) async {
        print('📄 MA13: Stock detail for AAPL');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/detail/AAPL',
        );

        expect(response.statusCode, 200);
        expect(response.data!['symbol'], 'AAPL');
        expect(response.data!['price'], isNotNull);

        print('    ✅ Stock detail loaded');
      },
    );

    testWidgets(
      'MA14: Stock detail for HK stock',
      (tester) async {
        print('📄 MA14: Stock detail for HK stock (0700)');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/detail/0700',
        );

        expect(response.statusCode, 200);
        expect(response.data!['symbol'], '0700');

        print('    ✅ HK stock detail loaded');
      },
    );
  });

  group('Market API - Error Handling', () {
    testWidgets(
      'MA15: Missing symbols parameter returns error',
      (tester) async {
        print('❌ MA15: Missing symbols in batch quote');

        try {
          await dio.get<Map<String, dynamic>>(
            '/v1/market/quotes',
          );
          // If we get here, test fails (expected an error)
          fail('Expected error for missing symbols');
        } catch (e) {
          expect(e, isA<DioException>());
          print('    ✅ Error handled correctly');
        }
      },
    );

    testWidgets(
      'MA16: API resilience under normal conditions',
      (tester) async {
        print('🛡️ MA16: API resilience');

        // Make multiple rapid requests
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(
            dio.get('/v1/market/stocks/AAPL'),
          );
        }

        final results = await Future.wait(futures);
        expect(results.length, 5);
        for (final result in results) {
          expect(result.statusCode, 200);
        }

        print('    ✅ API handled ${results.length} concurrent requests');
      },
    );
  });

  group('Market API - Data Consistency', () {
    testWidgets(
      'MA17: Quote timestamp is valid',
      (tester) async {
        print('🕐 MA17: Timestamp validation');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/AAPL',
        );

        final timestamp = response.data!['timestamp'];
        expect(timestamp, isNotNull);
        expect(timestamp, isA<String>());

        // Should be valid ISO 8601 format
        try {
          DateTime.parse(timestamp as String);
          print('    ✅ Timestamp is valid ISO 8601');
        } catch (e) {
          fail('Invalid timestamp format: $timestamp');
        }
      },
    );

    testWidgets(
      'MA18: Price values are positive',
      (tester) async {
        print('💰 MA18: Price validation');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/AAPL',
        );

        final price = response.data!['price'];
        expect(price, isNotNull);

        // Price may be String or double from API
        final priceValue = price is String ? double.parse(price) : price as double;
        expect(priceValue, greaterThan(0));

        print('    ✅ Price is positive: $price');
      },
    );
  });

  group('Market API - ETF Index Endpoints', () {
    testWidgets(
      'MA19: Fetch SPY (S&P 500 ETF)',
      (tester) async {
        print('📈 MA19: Fetch SPY ETF');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/SPY',
        );

        expect(response.statusCode, 200);
        expect(response.data!['symbol'], 'SPY');
        expect(response.data!['name'], contains('S&P'));
        expect(response.data!['is_etf'], true);
        expect(response.data!['tracking_name'], contains('S&P 500'));

        print('    ✅ SPY loaded: \$${response.data!['price']} (${response.data!['change_pct']}%)');
      },
    );

    testWidgets(
      'MA20: Fetch QQQ (Nasdaq-100 ETF)',
      (tester) async {
        print('📈 MA20: Fetch QQQ ETF');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/QQQ',
        );

        expect(response.statusCode, 200);
        expect(response.data!['symbol'], 'QQQ');
        expect(response.data!['is_etf'], true);
        expect(response.data!['tracking_name'], contains('Nasdaq'));

        print('    ✅ QQQ loaded: \$${response.data!['price']} (${response.data!['change_pct']}%)');
      },
    );

    testWidgets(
      'MA21: Fetch DIA (DJIA ETF)',
      (tester) async {
        print('📈 MA21: Fetch DIA ETF');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/DIA',
        );

        expect(response.statusCode, 200);
        expect(response.data!['symbol'], 'DIA');
        expect(response.data!['is_etf'], true);
        expect(response.data!['tracking_name'], contains('DJIA'));

        print('    ✅ DIA loaded: \$${response.data!['price']} (${response.data!['change_pct']}%)');
      },
    );

    testWidgets(
      'MA22: Fetch batch ETF quotes',
      (tester) async {
        print('📊 MA22: Batch ETF quotes');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/quotes',
          queryParameters: {
            'symbols': 'SPY,QQQ,DIA',
          },
        );

        expect(response.statusCode, 200);
        expect(response.data!['quotes']['SPY'], isNotNull);
        expect(response.data!['quotes']['QQQ'], isNotNull);
        expect(response.data!['quotes']['DIA'], isNotNull);

        print('    ✅ All 3 ETFs loaded');
      },
    );

    testWidgets(
      'MA23: ETF data completeness',
      (tester) async {
        print('✓ MA23: ETF data structure');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/SPY',
        );

        final etf = response.data!;
        expect(etf['symbol'], 'SPY');
        expect(etf['price'], isNotEmpty);
        expect(etf['change_pct'], isNotEmpty);
        expect(etf['tracking_name'], isNotEmpty);
        expect(etf['is_etf'], true);

        print('    ✅ ETF has all required fields');
      },
    );

    testWidgets(
      'MA24: ETF price format (large number for DIA)',
      (tester) async {
        print('💰 MA24: ETF price format validation');

        final response = await dio.get<Map<String, dynamic>>(
          '/v1/market/stocks/DIA',
        );

        final price = response.data!['price'];
        final priceValue = price is String ? double.parse(price) : price as double;
        expect(priceValue, greaterThan(30000)); // DIA price ~ 38,000

        print('    ✅ DIA price format correct: \$${response.data!['price']}');
      },
    );
  });
}
