import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:syncfusion_flutter_charts/charts.dart';

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

/// Data adapter for Syncfusion CandlestickSeries.
class _CandleChartData {
  _CandleChartData({
    required this.x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime x;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
}

/// Renders candles using Syncfusion Flutter Charts.
///
/// Layout:
///   - Top 70%: CandlestickSeries (OHLC)
///   - Bottom 30%: ColumnSeries (volume bars, colour matches candle direction)
///
/// Long-press shows crosshair with OHLCV tooltip.
/// Pinch-to-zoom and pan are enabled.
class _ChartView extends StatefulWidget {
  const _ChartView({required this.candles, required this.period});

  final List<Candle> candles;
  final _Period period;

  @override
  State<_ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<_ChartView> {
  late TrackballBehavior _trackballBehavior;
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      lineColor: Colors.grey.withValues(alpha: 0.5),
      lineWidth: 1,
      lineDashArray: const [3, 3],
      tooltipAlignment: ChartAlignment.center,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
    );
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.xy,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
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

    // Convert Candle entities to chart data
    final chartData = widget.candles
        .map((c) => _CandleChartData(
              x: c.t,
              open: c.o.toDouble(),
              high: c.h.toDouble(),
              low: c.l.toDouble(),
              close: c.c.toDouble(),
              volume: c.v,
            ))
        .toList();

    // Calculate max volume for secondary axis scaling
    final maxVolume = chartData.isNotEmpty
        ? chartData
            .map((d) => d.volume)
            .reduce((a, b) => a > b ? a : b)
            .toDouble()
        : 1000000.0;

    final bullishColor = const Color(0xFF0DC582); // Green
    final bearishColor = const Color(0xFFFF4747); // Red

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          intervalType: _getIntervalType(widget.period.apiPeriod),
          interval: _getInterval(widget.period.apiPeriod).toDouble(),
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          labelStyle: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          dateFormat: _getDateFormat(widget.period.apiPeriod),
        ),
        primaryYAxis: NumericAxis(
          labelPosition: ChartDataLabelPosition.outside,
          opposedPosition: true,
          majorGridLines: MajorGridLines(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          axisLine: const AxisLine(width: 0),
          labelStyle: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          numberFormat: intl.NumberFormat('0.00#'),
        ),
        axes: [
          NumericAxis(
            name: 'volumeAxis',
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(width: 0),
            maximum: maxVolume * 1.5,
            labelStyle: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            numberFormat: intl.NumberFormat('0.##a'),
            opposedPosition: true,
          ),
        ],
        series: <CartesianSeries>[
          // Candlestick series
          CandleSeries<_CandleChartData, DateTime>(
            dataSource: chartData,
            xValueMapper: (_CandleChartData data, _) => data.x,
            openValueMapper: (_CandleChartData data, _) => data.open,
            highValueMapper: (_CandleChartData data, _) => data.high,
            lowValueMapper: (_CandleChartData data, _) => data.low,
            closeValueMapper: (_CandleChartData data, _) => data.close,
            bearColor: bearishColor,
            bullColor: bullishColor,
          ),
          // Volume series
          ColumnSeries<_CandleChartData, DateTime>(
            dataSource: chartData,
            xValueMapper: (_CandleChartData data, _) => data.x,
            yValueMapper: (_CandleChartData data, _) => data.volume.toDouble(),
            yAxisName: 'volumeAxis',
            pointColorMapper: (_CandleChartData data, _) {
              return data.close >= data.open ? bullishColor : bearishColor;
            },
            opacity: 0.4,
            width: 0.6,
          ),
        ],
        trackballBehavior: _trackballBehavior,
        zoomPanBehavior: _zoomPanBehavior,
      ),
    );
  }

  /// Determine interval type based on period.
  DateTimeIntervalType _getIntervalType(String period) {
    return switch (period) {
      '1min' || '5min' || '15min' || '30min' => DateTimeIntervalType.minutes,
      '60min' || '1h' => DateTimeIntervalType.hours,
      '1d' => DateTimeIntervalType.days,
      '1w' => DateTimeIntervalType.days,  // Use days for weekly; interval=7
      '1mo' => DateTimeIntervalType.months,
      _ => DateTimeIntervalType.days,
    };
  }

  /// Determine interval value for better label spacing.
  int _getInterval(String period) {
    return switch (period) {
      '1min' => 30,
      '5min' => 60,
      '15min' => 120,
      '30min' => 240,
      '60min' || '1h' => 4,
      '1d' => 5,
      '1w' => 7,  // 7 days for weekly
      '1mo' => 3,
      _ => 1,
    };
  }

  /// Get date format for X-axis labels.
  intl.DateFormat _getDateFormat(String period) {
    return switch (period) {
      '1min' || '5min' || '15min' || '30min' => intl.DateFormat('HH:mm'),
      '60min' || '1h' => intl.DateFormat('HH:mm'),
      '1d' => intl.DateFormat('MM-dd'),
      '1w' => intl.DateFormat('MM-dd'),
      '1mo' => intl.DateFormat('yyyy-MM'),
      _ => intl.DateFormat('yyyy-MM-dd'),
    };
  }
}
