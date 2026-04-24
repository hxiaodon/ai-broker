import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/core/errors/app_exception.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/core/network/connectivity_service.dart';
import 'package:trading_app/features/portfolio/data/portfolio_repository_impl.dart';
import 'package:trading_app/features/portfolio/data/remote/portfolio_remote_data_source.dart';
import 'package:trading_app/features/portfolio/domain/entities/position_detail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Portfolio Module — API Integration Tests
///
/// **Purpose**: Verify HTTP API layer against the running Mock Server.
/// **Dependencies**: Mock Server on localhost:8080 (`cd mock-server && go run .`)
/// **Speed**: Fast (~15 seconds)
/// **Run when**: Before pushing changes
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  const baseUrl = 'http://localhost:8080';
  const auth = 'Bearer test-token-portfolio';

  setUpAll(() {
    AppLogger.init();
    dio = Dio(BaseOptions(baseUrl: baseUrl));
    dio.options.headers['Authorization'] = auth;
    // Disable Dio error throwing for 4xx — we test status codes manually
    dio.options.validateStatus = (status) => true;
  });

  // ── Portfolio REST Endpoints ───────────────────────────────────────────────

  group('Portfolio REST Endpoints', () {
    testWidgets(
      'TPA1: GET /api/v1/positions returns positions array with >= 2 entries',
      (tester) async {
        final resp = await dio.get<Map<String, dynamic>>('/api/v1/positions');
        expect(resp.statusCode, 200);
        final positions = resp.data!['positions'] as List;
        expect(positions.length, greaterThanOrEqualTo(2));
        expect((positions.first as Map).containsKey('symbol'), isTrue);
        print(
          '✅ TPA1: GET /positions returned ${positions.length} positions',
        );
      },
    );

    testWidgets(
      'TPA2: GET /api/v1/positions/AAPL returns company_name, sector, cost fields',
      (tester) async {
        final resp =
            await dio.get<Map<String, dynamic>>('/api/v1/positions/AAPL');
        expect(resp.statusCode, 200);
        final data = resp.data!;

        // Company and sector fields (added to mock server for portfolio detail)
        expect(data['company_name'], 'Apple Inc.',
            reason: 'company_name must match mock server preset');
        expect(data['sector'], 'Technology');

        // Financial decimal strings must be non-empty and parseable
        expect(data['cost_basis'], isNotEmpty);
        expect(data['avg_cost'], isNotEmpty);
        expect(Decimal.tryParse(data['avg_cost'] as String), isNotNull,
            reason: 'avg_cost must be a valid decimal string');
        expect(Decimal.tryParse(data['cost_basis'] as String), isNotNull,
            reason: 'cost_basis must be a valid decimal string');
        print(
          '✅ TPA2: GET /positions/AAPL company_name="${data['company_name']}" '
          'sector="${data['sector']}"',
        );
      },
    );

    testWidgets(
      'TPA3: GET /api/v1/positions/AAPL returns recent_trades array',
      (tester) async {
        final resp =
            await dio.get<Map<String, dynamic>>('/api/v1/positions/AAPL');
        expect(resp.statusCode, 200);
        final trades = resp.data!['recent_trades'] as List?;
        expect(trades, isNotNull, reason: 'recent_trades field must be present');
        // May be empty or have entries — both are valid
        if (trades!.isNotEmpty) {
          final first = trades.first as Map;
          expect(first.containsKey('trade_id'), isTrue);
          expect(first.containsKey('side'), isTrue);
          expect(first.containsKey('quantity'), isTrue);
          expect(first.containsKey('price'), isTrue);
          expect(first.containsKey('executed_at'), isTrue);
          expect(
            ['BUY', 'SELL'].contains(first['side']),
            isTrue,
            reason: 'side must be BUY or SELL',
          );
        }
        print(
          '✅ TPA3: GET /positions/AAPL recent_trades has ${trades.length} records',
        );
      },
    );

    testWidgets(
      'TPA4: GET /api/v1/positions/AAPL has wash_sale_status field',
      (tester) async {
        final resp =
            await dio.get<Map<String, dynamic>>('/api/v1/positions/AAPL');
        expect(resp.statusCode, 200);
        final washSaleStatus = resp.data!['wash_sale_status'] as String?;
        expect(washSaleStatus, isNotNull,
            reason: 'wash_sale_status must be present');
        expect(
          ['clean', 'flagged'].contains(washSaleStatus),
          isTrue,
          reason: 'wash_sale_status must be "clean" or "flagged"',
        );
        print('✅ TPA4: wash_sale_status = "$washSaleStatus"');
      },
    );

    testWidgets(
      'TPA5: GET /api/v1/positions/NONEXIST returns 404 POSITION_NOT_FOUND',
      (tester) async {
        final resp = await dio
            .get<Map<String, dynamic>>('/api/v1/positions/NONEXIST_SYMBOL');
        expect(resp.statusCode, 404);
        expect(resp.data!['error_code'], 'POSITION_NOT_FOUND');
        print('✅ TPA5: NONEXIST → 404 POSITION_NOT_FOUND');
      },
    );

    testWidgets(
      'TPA6: GET /api/v1/portfolio/summary returns parseable decimal fields',
      (tester) async {
        final resp =
            await dio.get<Map<String, dynamic>>('/api/v1/portfolio/summary');
        expect(resp.statusCode, 200);
        final data = resp.data!;

        for (final field in [
          'total_equity',
          'cash_balance',
          'buying_power',
          'day_pnl',
        ]) {
          final val = data[field] as String?;
          expect(val, isNotNull, reason: '$field must be present');
          expect(
            Decimal.tryParse(val!),
            isNotNull,
            reason: '$field must be a valid decimal string, got "$val"',
          );
        }
        print(
          '✅ TPA6: portfolio/summary total_equity=${data['total_equity']} '
          'cash_balance=${data['cash_balance']}',
        );
      },
    );
  });

  // ── Portfolio Repository Integration ──────────────────────────────────────

  group('Portfolio Repository Integration', () {
    late PortfolioRepositoryImpl repo;

    setUpAll(() {
      final repoDio = Dio(BaseOptions(baseUrl: baseUrl));
      repoDio.options.headers['Authorization'] = auth;
      repo = PortfolioRepositoryImpl(
        remote: PortfolioRemoteDataSource(
          dio: repoDio,
          connectivity: _AlwaysConnected(),
        ),
      );
    });

    testWidgets(
      'TPA7: getPositionDetail(AAPL) returns PositionDetail domain object',
      (tester) async {
        final detail = await repo.getPositionDetail('AAPL');
        expect(detail, isA<PositionDetail>());
        expect(detail.symbol, 'AAPL');
        expect(detail.companyName, 'Apple Inc.');
        expect(detail.sector, 'Technology');
        expect(detail.unrealizedPnl, greaterThan(Decimal.zero));
        expect(detail.costBasis, greaterThan(Decimal.zero));
        expect(detail.avgCost, greaterThan(Decimal.zero));
        // Decimal precision — must not lose precision
        expect(detail.avgCost.scale, greaterThanOrEqualTo(2),
            reason:
                'avgCost must retain at least 2 decimal places (financial precision)');
        print(
          '✅ TPA7: getPositionDetail(AAPL) returned domain object '
          'unrealizedPnl=${detail.unrealizedPnl} costBasis=${detail.costBasis}',
        );
      },
    );

    testWidgets(
      'TPA8: getPositionDetail(NONEXIST) throws ServerException (not generic Exception)',
      (tester) async {
        try {
          await repo.getPositionDetail('NONEXIST_SYMBOL');
          fail('Expected ServerException to be thrown');
        } on ServerException catch (e) {
          expect(e.statusCode, 404);
          print('✅ TPA8: NONEXIST throws ServerException(404): ${e.message}');
        } on Exception catch (e) {
          fail('Expected ServerException but got: ${e.runtimeType}');
        }
      },
    );
  });

  // ── Trading WS — Position & Portfolio Channels ────────────────────────────

  group('Trading WS — Position & Portfolio Channels', () {
    testWidgets(
      'TPA9: WS /ws/trading receives portfolio.summary update within 5s',
      (tester) async {
        final channel = WebSocketChannel.connect(
          Uri.parse('ws://localhost:8080/ws/trading'),
        );

        // S-04: auth is sent as first message (not in URL)
        channel.sink.add(
          jsonEncode({'type': 'auth', 'token': 'test-token-portfolio'}),
        );

        bool received = false;
        final completer = Future<bool>(() async {
          await for (final msg in channel.stream.timeout(
            const Duration(seconds: 5),
            onTimeout: (sink) => sink.close(),
          )) {
            if (msg is String) {
              final decoded = jsonDecode(msg) as Map<String, dynamic>;
              final ch = decoded['channel'] as String?;
              if (ch == 'portfolio.summary' || ch == 'position.updated') {
                received = true;
                break;
              }
            }
          }
          return received;
        });

        await completer;
        await channel.sink.close();

        expect(received, isTrue,
            reason:
                'Mock Server must push portfolio.summary within 5s (check mock-server is running)');
        print('✅ TPA9: Received WS portfolio update from trading channel');
      },
    );
  });
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Stub connectivity that always reports connected.
class _AlwaysConnected extends ConnectivityService {
  _AlwaysConnected() : super(Connectivity());

  @override
  Future<bool> get isConnected async => true;
}
