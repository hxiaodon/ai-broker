import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:trading_app/core/network/connectivity_service.dart';
import 'package:trading_app/features/market/data/remote/market_remote_data_source.dart';

void main() {
  test('Test quotes API with localhost', () async {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    final dataSource = MarketRemoteDataSource(dio, ConnectivityService(Connectivity()));

    try {
      final result = await dataSource.getQuotes(['AAPL', 'TSLA', '0700', '9988']);
      print('✅ API call successful');
      print('Quotes count: ${result.quotes.length}');
      print('as_of: ${result.asOf}');
      print('Symbols: ${result.quotes.keys.join(", ")}');

      expect(result.quotes.length, 4);
      expect(result.quotes.containsKey('AAPL'), true);
      expect(result.quotes.containsKey('TSLA'), true);
      expect(result.quotes.containsKey('0700'), true);
      expect(result.quotes.containsKey('9988'), true);
    } catch (e, stack) {
      print('❌ API call failed: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  });
}
