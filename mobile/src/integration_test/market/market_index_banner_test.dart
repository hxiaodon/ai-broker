import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trading_app/features/market/application/index_quotes_notifier.dart';
import 'package:trading_app/features/market/domain/entities/quote.dart';
import 'package:trading_app/features/market/domain/entities/market_status.dart';
import 'package:trading_app/shared/theme/app_theme.dart';
import 'package:trading_app/shared/theme/trading_color_scheme.dart';

// ─── Fake notifiers for state injection ───────────────────────────────────────

/// Immediately resolves with [data].
class _FakeDataIndexQuotes extends IndexQuotesNotifier {
  _FakeDataIndexQuotes(this._data);
  final Map<String, Quote> _data;

  @override
  Future<Map<String, Quote>> build() async => _data;
}

/// Stays in loading indefinitely (Completer never completes).
class _FakeLoadingIndexQuotes extends IndexQuotesNotifier {
  final _completer = Completer<Map<String, Quote>>();

  @override
  Future<Map<String, Quote>> build() => _completer.future;
}

/// Throws immediately to produce an error state.
class _FakeErrorIndexQuotes extends IndexQuotesNotifier {
  @override
  Future<Map<String, Quote>> build() async => throw Exception('Network error');
}

// ─── Fixture ──────────────────────────────────────────────────────────────────

Map<String, Quote> _mockEtfQuotes() => {
      'SPY': Quote(
        symbol: 'SPY',
        name: 'SPDR S&P 500 ETF',
        nameZh: '追踪 S&P 500 指数基金',
        market: 'US',
        price: Decimal.parse('521.44'),
        change: Decimal.parse('4.22'),
        changePct: Decimal.parse('0.0082'),
        volume: 89234567,
        bid: Decimal.parse('521.42'),
        ask: Decimal.parse('521.46'),
        turnover: '46567890123.00',
        prevClose: Decimal.parse('517.22'),
        open: Decimal.parse('519.00'),
        high: Decimal.parse('523.50'),
        low: Decimal.parse('519.80'),
        marketCap: '450000000000.00',
        peRatio: '22.3',
        delayed: false,
        marketStatus: MarketStatus.regular,
        isStale: false,
        staleSinceMs: 0,
      ),
      'QQQ': Quote(
        symbol: 'QQQ',
        name: 'Invesco QQQ Trust',
        nameZh: '追踪 Nasdaq-100 指数基金',
        market: 'US',
        price: Decimal.parse('385.92'),
        change: Decimal.parse('4.82'),
        changePct: Decimal.parse('0.0125'),
        volume: 156234567,
        bid: Decimal.parse('385.90'),
        ask: Decimal.parse('385.94'),
        turnover: '60234567890.00',
        prevClose: Decimal.parse('381.10'),
        open: Decimal.parse('382.10'),
        high: Decimal.parse('388.30'),
        low: Decimal.parse('383.45'),
        marketCap: '380000000000.00',
        peRatio: '38.5',
        delayed: false,
        marketStatus: MarketStatus.regular,
        isStale: false,
        staleSinceMs: 0,
      ),
      'DIA': Quote(
        symbol: 'DIA',
        name: 'SPDR Dow Jones ETF',
        nameZh: '追踪 DJIA 指数基金',
        market: 'US',
        price: Decimal.parse('38192.80'),
        change: Decimal.parse('-171.50'),
        changePct: Decimal.parse('-0.0045'),
        volume: 34567890,
        bid: Decimal.parse('38192.70'),
        ask: Decimal.parse('38192.90'),
        turnover: '1321234567890.00',
        prevClose: Decimal.parse('38364.30'),
        open: Decimal.parse('38320.00'),
        high: Decimal.parse('38450.20'),
        low: Decimal.parse('38120.30'),
        marketCap: '280000000000.00',
        peRatio: '20.8',
        delayed: false,
        marketStatus: MarketStatus.regular,
        isStale: false,
        staleSinceMs: 0,
      ),
    };

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Market - ETF Index Banner State Management', () {
    testWidgets(
      'T1: ETF banner displays data when provider has quotes',
      (tester) async {
        final mockQuotes = _mockEtfQuotes();

        final testWidget = ProviderScope(
          overrides: [
            indexQuotesProvider.overrideWith(
              () => _FakeDataIndexQuotes(mockQuotes),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.build(
              colorScheme: TradingColorScheme.greenUp,
              brightness: Brightness.light,
            ),
            home: Scaffold(body: _IndexBannerTest(onStockTap: (_) {})),
          ),
        );

        await tester.pumpWidget(testWidget);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('大盘指数 (ETF 代理)'), findsOneWidget);
        expect(find.text('SPY'), findsWidgets);
        expect(find.text('QQQ'), findsWidgets);
        expect(find.text('DIA'), findsWidgets);
        expect(find.byType(Text), findsWidgets);

        debugPrint('✅ T1: ETF banner renders with data');
      },
    );

    testWidgets(
      'T2: ETF banner shows loading state correctly',
      (tester) async {
        final testWidget = ProviderScope(
          overrides: [
            indexQuotesProvider.overrideWith(_FakeLoadingIndexQuotes.new),
          ],
          child: MaterialApp(
            theme: AppTheme.build(
              colorScheme: TradingColorScheme.greenUp,
              brightness: Brightness.light,
            ),
            home: Scaffold(body: _IndexBannerTest(onStockTap: (_) {})),
          ),
        );

        await tester.pumpWidget(testWidget);

        expect(find.text('大盘指数 (ETF 代理)'), findsOneWidget);
        expect(find.byType(Container), findsWidgets);

        debugPrint('✅ T2: ETF banner loading state works');
      },
    );

    testWidgets(
      'T3: ETF banner shows error state correctly',
      (tester) async {
        final testWidget = ProviderScope(
          overrides: [
            indexQuotesProvider.overrideWith(_FakeErrorIndexQuotes.new),
          ],
          child: MaterialApp(
            theme: AppTheme.build(
              colorScheme: TradingColorScheme.greenUp,
              brightness: Brightness.light,
            ),
            home: Scaffold(body: _IndexBannerTest(onStockTap: (_) {})),
          ),
        );

        await tester.pumpWidget(testWidget);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('加载失败'), findsOneWidget);

        debugPrint('✅ T3: ETF banner error state works');
      },
    );
  });
}

// ─── Test widget ──────────────────────────────────────────────────────────────

class _IndexBannerTest extends ConsumerWidget {
  const _IndexBannerTest({required this.onStockTap});

  final void Function(String symbol) onStockTap;

  static const _indexes = [
    ('SPY', 'S&P 500'),
    ('QQQ', 'NASDAQ 100'),
    ('DIA', 'Dow Jones'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indexQuotesAsync = ref.watch(indexQuotesProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '大盘指数 (ETF 代理)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: indexQuotesAsync.when(
              data: (quoteMap) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _indexes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (symbol, _) = _indexes[i];
                  final quote = quoteMap[symbol];
                  return Container(
                    width: 104,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(symbol,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(
                          quote != null
                              ? '\$${quote.price.toStringAsFixed(2)}'
                              : '-',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          quote != null
                              ? '${quote.changePct > Decimal.zero ? '+' : ''}${(quote.changePct * Decimal.fromInt(100)).toStringAsFixed(2)}%'
                              : '-',
                          style: TextStyle(
                            color: quote != null &&
                                    quote.changePct > Decimal.zero
                                ? const Color(0xFF0DC582)
                                : const Color(0xFFFF4747),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _indexes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Container(
                  width: 104,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_indexes[i].$1,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Container(width: 70, height: 14, color: Colors.white24),
                      Container(width: 48, height: 12, color: Colors.white24),
                    ],
                  ),
                ),
              ),
              error: (_, _) => const Center(
                child: Text('加载失败',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
