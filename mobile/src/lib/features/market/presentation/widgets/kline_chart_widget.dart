import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../application/kline_realtime_notifier.dart';
import '../../application/stock_detail_notifier.dart';
import '../../data/market_data_repository_impl.dart';
import '../../domain/entities/candle.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Period definition
// ─────────────────────────────────────────────────────────────────────────────

class _Period {
  const _Period(this.label, this.apiPeriod, this.limit);
  final String label;
  final String apiPeriod;
  final int limit;

  bool get isIntraday => apiPeriod == '1min';
}

const _kPeriods = [
  _Period('分时', '1min', 390),
  _Period('1W',  '1d',   5),
  _Period('1M',  '1d',   22),
  _Period('3M',  '1d',   66),
  _Period('1Y',  '1d',   252),
  _Period('All', '1d',   0),
];

// ─────────────────────────────────────────────────────────────────────────────
// Data provider
// ─────────────────────────────────────────────────────────────────────────────

final _klineDataProvider = FutureProvider.autoDispose
    .family<List<Candle>, KlineParams>((ref, params) async {
  // For 1min period, use KlineRealtimeNotifier for real-time updates
  if (params.period == '1min') {
    return ref.watch(klineRealtimeNotifierProvider(params).future);
  }

  // Other periods: static REST data only
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

String _defaultFrom(String period) {
  final now = DateTime.now().toUtc();
  final d = switch (period) {
    '1min' || '5min' || '15min' || '30min' || '60min' => now.subtract(const Duration(days: 1)),
    '1d'   => now.subtract(const Duration(days: 365 * 5)),
    '1w'   => now.subtract(const Duration(days: 365 * 10)),
    _      => now.subtract(const Duration(days: 365)),
  };
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class _OhlcvInfo {
  const _OhlcvInfo({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.change,
    required this.changePercent,
    required this.isUp,
  });

  final String time;
  final Decimal open;
  final Decimal high;
  final Decimal low;
  final Decimal close;
  final int volume;
  final Decimal change;
  final Decimal changePercent;
  final bool isUp;
}

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

class _MaPoint {
  const _MaPoint(this.x, this.y);
  final DateTime x;
  final double y;
}

// ─────────────────────────────────────────────────────────────────────────────
// KLineChartWidget
// ─────────────────────────────────────────────────────────────────────────────

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
        SizedBox(
          height: 300,
          child: klineAsync.when(
            loading: () => _buildPlaceholder(context, loading: true),
            error: (_, __) => _buildPlaceholder(context, loading: false),
            data: (candles) => _ChartView(candles: candles, period: _period),
          ),
        ),
        const SizedBox(height: 12),
        // Period selector
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildPlaceholder(BuildContext context, {required bool loading}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: loading
            ? const CircularProgressIndicator.adaptive()
            : Text(
                'K线数据加载失败',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart view
// ─────────────────────────────────────────────────────────────────────────────

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

  _OhlcvInfo? _hoveredInfo;
  int? _lastHoveredIdx;
  double? _crosshairX;
  double? _crosshairY;

  // MA calculation cache
  List<_MaPoint>? _cachedMa5;
  List<_MaPoint>? _cachedMa10;
  List<_MaPoint>? _cachedMa20;
  int? _cachedDataLength;

  static const _bullish = Color(0xFF0DC582);
  static const _bearish = Color(0xFFFF4747);
  static const _ma5Color = Color(0xFFFFB800);
  static const _ma10Color = Color(0xFF2196F3);
  static const _ma20Color = Color(0xFFE040FB);

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
      enableDoubleTapZooming: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? Colors.white70 : Colors.black54;
    final markerColor = isDark ? Colors.white : Colors.black87;

    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      // Hide Syncfusion's own line — we draw our own overlay
      lineColor: Colors.transparent,
      lineWidth: 0,
      tooltipDisplayMode: TrackballDisplayMode.none,
      shouldAlwaysShow: false,
      hideDelay: 3000,
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.hidden,
      ),
    );
  }

  void _onTrackballChanged(TrackballArgs args) {
    final point = args.chartPointInfo;
    final idx = point.dataPointIndex ?? -1;
    if (idx < 0 || idx >= widget.candles.length) return;
    _lastHoveredIdx = idx;

    final c = widget.candles[idx];
    final prevClose = idx > 0 ? widget.candles[idx - 1].c : c.o;
    final change = c.c - prevClose;
    final changePercent = prevClose != Decimal.zero
        ? (change / prevClose).toDecimal(scaleOnInfinitePrecision: 10) * Decimal.fromInt(100)
        : Decimal.zero;

    setState(() {
      _crosshairX = point.xPosition;
      _crosshairY = point.yPosition;
      _hoveredInfo = _OhlcvInfo(
        time: _timeFormat(widget.period.apiPeriod).format(c.t.toLocal()),
        open: c.o,
        high: c.h,
        low: c.l,
        close: c.c,
        volume: c.v,
        change: change,
        changePercent: changePercent,
        isUp: c.c >= c.o,
      );
    });
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

    final maxVolume = chartData
        .map((d) => d.volume)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    // Default info bar: latest candle
    final latest = widget.candles.last;
    final prevClose = widget.candles.length > 1
        ? widget.candles[widget.candles.length - 2].c
        : latest.o;
    final latestChange = latest.c - prevClose;
    final latestChangePct = prevClose != Decimal.zero
        ? (latestChange / prevClose).toDecimal(scaleOnInfinitePrecision: 10) * Decimal.fromInt(100)
        : Decimal.zero;
    final defaultInfo = _OhlcvInfo(
      time: _timeFormat(widget.period.apiPeriod).format(latest.t.toLocal()),
      open: latest.o,
      high: latest.h,
      low: latest.l,
      close: latest.c,
      volume: latest.v,
      change: latestChange,
      changePercent: latestChangePct,
      isUp: latest.c >= latest.o,
    );
    final info = _hoveredInfo ?? defaultInfo;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OhlcvInfoBar(info: info, isHovering: _hoveredInfo != null),
          const SizedBox(height: 4),
          Expanded(
            child: Stack(
              children: [
                SfCartesianChart(
                plotAreaBorderWidth: 0,
                onTrackballPositionChanging: _onTrackballChanged,
                onChartTouchInteractionUp: (_) {
                  if (_hoveredInfo != null || _crosshairX != null) {
                    setState(() {
                      _hoveredInfo = null;
                      _lastHoveredIdx = null;
                      _crosshairX = null;
                      _crosshairY = null;
                    });
                  }
                },
                primaryXAxis: DateTimeAxis(
                  intervalType: _getIntervalType(widget.period.apiPeriod),
                  interval: _getInterval(widget.period.apiPeriod).toDouble(),
                  majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  dateFormat: _getDateFormat(widget.period.apiPeriod),
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                ),
                primaryYAxis: NumericAxis(
                  labelPosition: ChartDataLabelPosition.outside,
                  opposedPosition: true,
                  desiredIntervals: 4,
                  majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  axisLine: const AxisLine(width: 0),
                  labelStyle: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  numberFormat: intl.NumberFormat('0.00#'),
                  // 分时图: 昨收基准线
                  plotBands: widget.period.isIntraday
                      ? [
                          PlotBand(
                            start: widget.candles.first.o.toDouble(),
                            end: widget.candles.first.o.toDouble(),
                            borderColor: Colors.grey.withValues(alpha: 0.6),
                            borderWidth: 1,
                            dashArray: const [4, 4],
                          ),
                        ]
                      : [],
                ),
                axes: [
                  NumericAxis(
                    name: 'volumeAxis',
                    majorGridLines: const MajorGridLines(width: 0),
                    axisLine: const AxisLine(width: 0),
                    maximum: maxVolume * 1.5,
                    desiredIntervals: 2,
                    isVisible: false, // 隐藏volume轴标签，避免与price轴叠压
                    opposedPosition: true,
                  ),
                ],
                series: _buildSeries(chartData, maxVolume),
                trackballBehavior: _trackballBehavior,
                zoomPanBehavior: _zoomPanBehavior,
                legend: Legend(
                  isVisible: !widget.period.isIntraday,
                  position: LegendPosition.top,
                  alignment: ChartAlignment.near,
                  textStyle: const TextStyle(fontSize: 9),
                  iconHeight: 8,
                  iconWidth: 16,
                ),
                ), // SfCartesianChart
                if (_crosshairX != null)
                  _CrosshairOverlay(x: _crosshairX!, y: _crosshairY),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<CartesianSeries> _buildSeries(List<_CandleChartData> chartData, double maxVolume) {
    if (widget.period.isIntraday) {
      return _buildIntradaySeries(chartData);
    }
    return _buildKlineSeries(chartData);
  }

  /// 分时图: 折线 + 渐变填充 + 成交量
  List<CartesianSeries> _buildIntradaySeries(List<_CandleChartData> chartData) {
    final refPrice = chartData.isNotEmpty ? chartData.first.open : 0.0;
    final lastPrice = chartData.isNotEmpty ? chartData.last.close : 0.0;
    final lineColor = lastPrice >= refPrice ? _bullish : _bearish;

    return [
      SplineAreaSeries<_CandleChartData, DateTime>(
        dataSource: chartData,
        xValueMapper: (d, _) => d.x,
        yValueMapper: (d, _) => d.close,
        borderColor: lineColor,
        borderWidth: 1.5,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.25),
            lineColor.withValues(alpha: 0.0),
          ],
        ),
        splineType: SplineType.monotonic,
        enableTooltip: false,
      ),
      ColumnSeries<_CandleChartData, DateTime>(
        dataSource: chartData,
        xValueMapper: (d, _) => d.x,
        yValueMapper: (d, _) => d.volume.toDouble(),
        yAxisName: 'volumeAxis',
        color: lineColor.withValues(alpha: 0.35),
        width: 0.8,
        enableTooltip: false,
      ),
    ];
  }

  /// 日K/周K/月K: 蜡烛图 + MA均线 + 成交量
  List<CartesianSeries> _buildKlineSeries(List<_CandleChartData> chartData) {
    // Use cached MA values if data hasn't changed
    if (_cachedDataLength != chartData.length) {
      _cachedMa5 = _calcMA(chartData, 5);
      _cachedMa10 = _calcMA(chartData, 10);
      _cachedMa20 = _calcMA(chartData, 20);
      _cachedDataLength = chartData.length;
    }

    final ma5 = _cachedMa5!;
    final ma10 = _cachedMa10!;
    final ma20 = _cachedMa20!;

    // Adaptive candle width: fewer candles → narrower to avoid oversized bars
    final count = chartData.length;
    final candleWidth = count <= 10 ? 0.4 : count <= 30 ? 0.6 : 0.8;

    return [
      CandleSeries<_CandleChartData, DateTime>(
        dataSource: chartData,
        xValueMapper: (d, _) => d.x,
        openValueMapper: (d, _) => d.open,
        highValueMapper: (d, _) => d.high,
        lowValueMapper: (d, _) => d.low,
        closeValueMapper: (d, _) => d.close,
        width: candleWidth,
        bearColor: _bearish,
        bullColor: _bullish,
        enableTooltip: false,
      ),
      // MA5
      FastLineSeries<_MaPoint, DateTime>(
        dataSource: ma5,
        xValueMapper: (p, _) => p.x,
        yValueMapper: (p, _) => p.y,
        color: _ma5Color,
        width: 1,
        name: 'MA5',
        enableTooltip: false,
      ),
      // MA10
      FastLineSeries<_MaPoint, DateTime>(
        dataSource: ma10,
        xValueMapper: (p, _) => p.x,
        yValueMapper: (p, _) => p.y,
        color: _ma10Color,
        width: 1,
        name: 'MA10',
        enableTooltip: false,
      ),
      // MA20
      FastLineSeries<_MaPoint, DateTime>(
        dataSource: ma20,
        xValueMapper: (p, _) => p.x,
        yValueMapper: (p, _) => p.y,
        color: _ma20Color,
        width: 1,
        name: 'MA20',
        enableTooltip: false,
      ),
      // Volume
      ColumnSeries<_CandleChartData, DateTime>(
        dataSource: chartData,
        xValueMapper: (d, _) => d.x,
        yValueMapper: (d, _) => d.volume.toDouble(),
        yAxisName: 'volumeAxis',
        pointColorMapper: (d, _) =>
            d.close >= d.open ? _bullish.withValues(alpha: 0.4) : _bearish.withValues(alpha: 0.4),
        width: 0.6,
        enableTooltip: false,
      ),
    ];
  }

  List<_MaPoint> _calcMA(List<_CandleChartData> data, int period) {
    if (data.length < period) return [];
    final result = <_MaPoint>[];
    double sum = 0;
    for (int i = 0; i < data.length; i++) {
      sum += data[i].close;
      if (i >= period) sum -= data[i - period].close;
      if (i >= period - 1) {
        result.add(_MaPoint(data[i].x, sum / period));
      }
    }
    return result;
  }

  intl.DateFormat _timeFormat(String period) => switch (period) {
        '1min' || '5min' || '15min' || '30min' || '60min' || '1h' =>
          intl.DateFormat('MM-dd HH:mm'),
        '1d' || '1w' => intl.DateFormat('yyyy-MM-dd'),
        '1mo'        => intl.DateFormat('yyyy-MM'),
        _            => intl.DateFormat('yyyy-MM-dd'),
      };

  DateTimeIntervalType _getIntervalType(String period) => switch (period) {
        '1min' || '5min' || '15min' || '30min' => DateTimeIntervalType.minutes,
        '60min' || '1h'                         => DateTimeIntervalType.hours,
        '1d'                                    => DateTimeIntervalType.days,
        '1w'                                    => DateTimeIntervalType.days,
        '1mo'                                   => DateTimeIntervalType.months,
        _                                       => DateTimeIntervalType.days,
      };

  int _getInterval(String period) {
    final limit = widget.candles.length;
    return switch (period) {
      '1min'          => 60,
      '5min'          => 60,
      '15min'         => 60,
      '30min'         => 120,
      '60min' || '1h' => 4,
      '1d'            => limit <= 10 ? 1 : limit <= 30 ? 5 : limit <= 90 ? 15 : limit <= 260 ? 40 : 60,
      '1w'            => 7,  // unit: days, 7 = weekly label
      '1mo'           => 3,
      _               => 1,
    };
  }

  intl.DateFormat _getDateFormat(String period) => switch (period) {
        '1min' || '5min' || '15min' || '30min' => intl.DateFormat('HH:mm'),
        '60min' || '1h'                         => intl.DateFormat('HH:mm'),
        '1d' || '1w'                            => intl.DateFormat('MM-dd'),
        '1mo'                                   => intl.DateFormat('yyyy-MM'),
        _                                       => intl.DateFormat('yyyy-MM-dd'),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// OHLCV info bar
// ─────────────────────────────────────────────────────────────────────────────

class _OhlcvInfoBar extends StatelessWidget {
  const _OhlcvInfoBar({required this.info, required this.isHovering});

  final _OhlcvInfo info;
  final bool isHovering;

  @override
  Widget build(BuildContext context) {
    final priceColor = info.isUp ? const Color(0xFF0DC582) : const Color(0xFFFF4747);
    final changeColor = info.change >= Decimal.zero ? const Color(0xFF0DC582) : const Color(0xFFFF4747);
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final priceFmt = intl.NumberFormat('0.00##');
    final volFmt = intl.NumberFormat.compact();
    final changePctStr =
        '${info.changePercent >= Decimal.zero ? '+' : ''}${info.changePercent.toStringAsFixed(2)}%';
    final changeStr =
        '${info.change >= Decimal.zero ? '+' : ''}${priceFmt.format(info.change.toDouble())}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: isHovering
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time + 涨跌幅 row
          Row(
            children: [
              Text(
                info.time,
                style: TextStyle(fontSize: 10, color: labelColor),
              ),
              const SizedBox(width: 8),
              Text(
                changeStr,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: changeColor),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  changePctStr,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: changeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // OHLCV row
          Row(
            children: [
              _InfoCell(label: '开', value: priceFmt.format(info.open.toDouble()), color: priceColor),
              const SizedBox(width: 10),
              _InfoCell(label: '高', value: priceFmt.format(info.high.toDouble()), color: priceColor),
              const SizedBox(width: 10),
              _InfoCell(label: '低', value: priceFmt.format(info.low.toDouble()), color: priceColor),
              const SizedBox(width: 10),
              _InfoCell(label: '收', value: priceFmt.format(info.close.toDouble()), color: priceColor),
              const SizedBox(width: 10),
              _InfoCell(label: '量', value: volFmt.format(info.volume), color: labelColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom crosshair overlay (replaces Syncfusion's broken trackball line)
// ─────────────────────────────────────────────────────────────────────────────

class _CrosshairOverlay extends StatelessWidget {
  const _CrosshairOverlay({required this.x, this.y});

  final double x;
  final double? y;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black.withValues(alpha: 0.6);

    return Positioned.fill(
      child: CustomPaint(
        painter: _CrosshairPainter(x: x, y: y, color: color),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  const _CrosshairPainter({required this.x, this.y, required this.color});

  final double x;
  final double? y;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashLen = 4.0;
    const gapLen = 3.0;

    // Vertical dashed line
    _drawDashedLine(canvas, paint, Offset(x, 0), Offset(x, size.height), dashLen, gapLen);

    // Horizontal dashed line (only if y is available)
    if (y != null && y! > 0 && y! < size.height) {
      _drawDashedLine(canvas, paint, Offset(0, y!), Offset(size.width, y!), dashLen, gapLen);

      // Dot at intersection
      canvas.drawCircle(
        Offset(x, y!),
        4,
        Paint()..color = color..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y!),
        4,
        Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end, double dash, double gap) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = (dx * dx + dy * dy) > 0 ? (dx * dx + dy * dy) : 1.0;
    final total = len < 1 ? 1.0 : len;
    // Use distance
    final dist = (Offset(dx, dy)).distance;
    if (dist == 0) return;
    final ux = dx / dist;
    final uy = dy / dist;
    double traveled = 0;
    bool drawing = true;
    var cur = start;
    while (traveled < dist) {
      final segLen = drawing ? dash : gap;
      final next = traveled + segLen;
      final endDist = next > dist ? dist : next;
      final endPt = Offset(start.dx + ux * endDist, start.dy + uy * endDist);
      if (drawing) canvas.drawLine(cur, endPt, paint);
      cur = endPt;
      traveled = endDist;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.x != x || old.y != y || old.color != color;
}
