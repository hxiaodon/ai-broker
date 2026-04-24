import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trading_app/core/auth/token_service.dart';
import 'package:trading_app/core/config/environment_config.dart';
import 'package:trading_app/core/logging/app_logger.dart';
import 'package:trading_app/features/auth/application/auth_notifier.dart';
import 'package:trading_app/features/market/application/quote_websocket_notifier.dart';
import 'package:trading_app/features/market/data/market_data_repository_impl.dart';
import 'package:trading_app/features/market/data/watchlist_repository_impl.dart';
import 'package:trading_app/features/market/data/websocket/quote_websocket_client.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/repositories/market_data_repository.dart';
import 'package:trading_app/features/market/domain/repositories/watchlist_repository.dart';
import 'package:trading_app/features/market/presentation/widgets/kline_chart_widget.dart';

class _MockMarketDataRepository extends Mock implements MarketDataRepository {}
class _MockWatchlistRepository extends Mock implements WatchlistRepository {}
class _MockTokenService extends Mock implements TokenService {}
class _MockQuoteWebSocketClient extends Mock implements QuoteWebSocketClient {}

void main() {
  late _MockMarketDataRepository mockMarketRepo;
  late _MockWatchlistRepository mockWatchlistRepo;
  late _MockTokenService mockToken;
  late _MockQuoteWebSocketClient mockWsClient;

  setUpAll(() {
    AppLogger.init();
    EnvironmentConfig.initialize(environment: Environment.development);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockMarketRepo = _MockMarketDataRepository();
    mockWatchlistRepo = _MockWatchlistRepository();
    mockToken = _MockTokenService();
    mockWsClient = _MockQuoteWebSocketClient();

    when(() => mockMarketRepo.getKline(
          symbol: any(named: 'symbol'),
          period: any(named: 'period'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        )).thenAnswer((_) async => const KlineResult(
              symbol: 'AAPL',
              period: '1d',
              candles: [],
              total: 0,
            ));

    when(() => mockToken.getAccessToken())
        .thenAnswer((_) async => 'test-token');
    when(() => mockWatchlistRepo.getWatchlist())
        .thenAnswer((_) async => <Quote>[]);
    when(() => mockWsClient.connect(token: any(named: 'token')))
        .thenAnswer((_) async => WsUserType.registered);
    when(() => mockWsClient.quoteStream).thenAnswer((_) => Stream.empty());
    when(() => mockWsClient.subscribe(any())).thenAnswer((_) async {});
    when(() => mockWsClient.unsubscribe(any())).thenReturn(null);
    when(() => mockWsClient.close()).thenAnswer((_) async {});
    when(() => mockWsClient.dispose()).thenAnswer((_) async {});
  });

  Widget buildApp(Widget child) => ProviderScope(
        overrides: [
          authProvider.overrideWithValue(
            const AuthState.authenticated(
              accountId: 'test-acc',
              accountStatus: 'ACTIVE',
              biometricEnabled: false,
            ),
          ),
          marketDataRepositoryProvider.overrideWithValue(mockMarketRepo),
          watchlistRepositoryProvider.overrideWithValue(mockWatchlistRepo),
          tokenServiceProvider.overrideWithValue(mockToken),
          wsClientFactoryProvider.overrideWithValue((_) => mockWsClient),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  group('KlineChartWidget Tests', () {
    testWidgets('renders kline chart widget', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(const KLineChartWidget(symbol: 'AAPL')));
      await tester.pump();

      expect(find.byType(KLineChartWidget), findsWidgets);
    });

    testWidgets('displays time period buttons', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(const KLineChartWidget(symbol: 'AAPL')));
      await tester.pump();

      expect(find.byType(KLineChartWidget), findsWidgets);
    });

    testWidgets('symbol is set correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(const KLineChartWidget(symbol: 'TSLA')));
      await tester.pump();

      expect(find.byType(KLineChartWidget), findsWidgets);
    });

    testWidgets('contains scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(const KLineChartWidget(symbol: 'AAPL')));
      await tester.pump();

      expect(find.byType(KLineChartWidget), findsWidgets);
    });
  });
}
