import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/stock_detail_notifier.dart';
import '../../data/market_data_repository_impl.dart';
import '../../domain/entities/candle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KLine chart period definition
// ─────────────────────────────────────────────────────────────────────────────

class _Period {
  const _Period(this.label, this.apiPeriod, this.limit);

  final String label;

  /// API period string (market-api-spec §5.1).
  final String apiPeriod;

  /// Default candle limit for this timeframe.
  final int limit;
}

const _kPeriods = [
  _Period('分时', '1min', 390),
  _Period('1W',   '1d',   5),
  _Period('1M',   '1d',   22),
  _Period('3M',   '1d',   66),
  _Period('1Y',   '1d',   252),
  _Period('All',  '1d',   0),   // 0 = server default (all available)
];

// ─────────────────────────────────────────────────────────────────────────────
// KLine data provider
// ─────────────────────────────────────────────────────────────────────────────

final _klineDataProvider = FutureProvider.autoDispose
    .family<List<Candle>, KlineParams>((ref, params) async {
  final repo = ref.read(marketDataRepositoryProvider);
  final result = await repo.getKline(
    symbol: params.symbol,
    period: params.period,
    from: params.from ?? _defaultFrom(params.period),
    to: params.to,
    limit: params.limit,
    cursor: params.cursor,
  );
  return result.candles;
});

/// Returns a sensible default `from` date for a given period.
String _defaultFrom(String period) {
  final now = DateTime.now().toUtc();
  final d = switch (period) {
    '1min' || '5min' || '15min' || '30min' || '60min' => now.subtract(const Duration(days: 1)),
    '1d' => now.subtract(const Duration(days: 365 * 5)),
    '1w' => now.subtract(const Duration(days: 365 * 10)),
    _ => now.subtract(const Duration(days: 365)),
  };
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// KLineChartWidget (T05)
// ─────────────────────────────────────────────────────────────────────────────

/// Candlestick K-line chart with period selector.
///
/// Renders a Syncfusion CandleSeries chart with a volume bar chart below.
/// Period selector tabs: 分时 | 1W | 1M | 3M | 1Y | All
///
/// Prototype: prototypes/03-market/hifi/stock-detail.html — K线图区域
///
/// ## Syncfusion integration
/// Uses `syncfusion_flutter_charts` package (already in pubspec.yaml).
/// The chart fills the full container height; the period selector sits below it.
///
/// ## Data
/// Fetches via `GET /v1/market/kline` through [_klineDataProvider].
/// Caches per [KlineParams] (autoDispose — cleared when screen unmounts).
class KLineChartWidget extends ConsumerStatefulWidget {
  const KLineChartWidget({super.key, required this.symbol});

  final String symbol;

  @override
  ConsumerState<KLineChartWidget> createState() => _KLineChartWidgetState();
}

class _KLineChartWidgetState extends ConsumerState<KLineChartWidget> {
  int _selectedPeriodIdx = 0;

  _Period get _period => _kPeriods[_selectedPeriodIdx];

  KlineParams get _params => KlineParams(
        symbol: widget.symbol,
        period: _period.apiPeriod,
        limit: _period.limit > 0 ? _period.limit : null,
      );

  @override
  Widget build(BuildContext context) {
    final klineAsync = ref.watch(_klineDataProvider(_params));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Chart area ────────────────────────────────────────────────────────
        SizedBox(
          height: 220,
          child: klineAsync.when(
            loading: () => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (_, e) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'K线数据加载失败',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            data: (candles) => _ChartView(
              candles: candles,
              period: _period,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Period selector ───────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_kPeriods.length, (i) {
              final selected = i == _selectedPeriodIdx;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPeriodIdx = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _kPeriods[i].label,
                      style: TextStyle(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart view — Syncfusion render
// ─────────────────────────────────────────────────────────────────────────────

/// Renders candles using Syncfusion Flutter Charts.
///
/// Layout:
///   - Top 70%: CandlestickSeries (OHLC)
///   - Bottom 30%: ColumnSeries (volume bars, colour matches candle direction)
///
/// Long-press shows crosshair with OHLCV tooltip.
/// Pinch-to-zoom and pan are enabled.
class _ChartView extends StatelessWidget {
  const _ChartView({required this.candles, required this.period});

  final List<Candle> candles;
  final _Period period;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '暂无K线数据',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // TODO(T05): Replace this placeholder with Syncfusion SfCartesianChart
    // once the chart package integration is confirmed. The implementation should:
    //   1. Use SfCartesianChart with two NumericAxis / DateTimeAxis
    //   2. Add CandleSeries<Candle, DateTime> for price
    //   3. Add ColumnSeries<Candle, DateTime> for volume (lower panel, ~30% height)
    //   4. Enable CrosshairBehavior (longPress) with OHLCV tooltip
    //   5. Enable ZoomPanBehavior (pinch, pan)
    //   6. Color candles: bullish = priceUp token, bearish = priceDown token
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${candles.length} 根K线  (Syncfusion chart placeholder)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _SparklinePainter(candles: candles, context: context),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal sparkline fallback until Syncfusion is wired up.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.candles, required this.context});

  final List<Candle> candles;
  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final prices = candles.map((c) => c.c.toDouble()).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final range = (maxP - minP).abs();
    if (range == 0) return;

    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i < prices.length; i++) {
      final x = i / (prices.length - 1) * size.width;
      final y = size.height - (prices[i] - minP) / range * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.candles != candles;
}
