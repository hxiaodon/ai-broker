import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:trading_app/features/market/domain/entities/candle.dart';

/// Minimal reproduction of the chart + trackball to verify touch events work.
void main() {
  final candles = List.generate(20, (i) {
    final base = 170.0 + i * 0.5;
    return Candle(
      t: DateTime.utc(2026, 4, 1).add(Duration(days: i)),
      o: Decimal.parse(base.toStringAsFixed(2)),
      h: Decimal.parse((base + 2).toStringAsFixed(2)),
      l: Decimal.parse((base - 1).toStringAsFixed(2)),
      c: Decimal.parse((base + 1).toStringAsFixed(2)),
      v: 1000000 + i * 100000,
      n: 100 + i * 10,
    );
  });

  testWidgets('Trackball shows on tap (no wrapper)', (tester) async {
    bool trackballFired = false;

    final trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.none,
      shouldAlwaysShow: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: SfCartesianChart(
              onTrackballPositionChanging: (TrackballArgs args) {
                trackballFired = true;
              },
              primaryXAxis: DateTimeAxis(),
              primaryYAxis: NumericAxis(),
              series: [
                CandleSeries<Candle, DateTime>(
                  dataSource: candles,
                  xValueMapper: (c, _) => c.t,
                  openValueMapper: (c, _) => c.o.toDouble(),
                  highValueMapper: (c, _) => c.h.toDouble(),
                  lowValueMapper: (c, _) => c.l.toDouble(),
                  closeValueMapper: (c, _) => c.c.toDouble(),
                ),
              ],
              trackballBehavior: trackball,
            ),
          ),
        ),
      ),
    );

    // Let the chart fully render
    await tester.pumpAndSettle();

    // Find the chart and tap in the middle of it
    final chartFinder = find.byType(SfCartesianChart);
    expect(chartFinder, findsOneWidget);

    final chartCenter = tester.getCenter(chartFinder);

    // Simulate a tap down + move (like finger touching and dragging)
    final gesture = await tester.startGesture(chartCenter);
    await tester.pump(const Duration(milliseconds: 50));

    // Move slightly to trigger trackball update
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump(const Duration(milliseconds: 50));

    await gesture.moveBy(const Offset(20, 0));
    await tester.pump(const Duration(milliseconds: 50));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(trackballFired, isTrue,
        reason: 'onTrackballPositionChanging should fire on touch');
  });

  testWidgets('Trackball shows on long press', (tester) async {
    bool trackballFired = false;

    final trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      tooltipDisplayMode: TrackballDisplayMode.none,
      shouldAlwaysShow: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: SfCartesianChart(
              onTrackballPositionChanging: (TrackballArgs args) {
                trackballFired = true;
              },
              primaryXAxis: DateTimeAxis(),
              primaryYAxis: NumericAxis(),
              series: [
                CandleSeries<Candle, DateTime>(
                  dataSource: candles,
                  xValueMapper: (c, _) => c.t,
                  openValueMapper: (c, _) => c.o.toDouble(),
                  highValueMapper: (c, _) => c.h.toDouble(),
                  lowValueMapper: (c, _) => c.l.toDouble(),
                  closeValueMapper: (c, _) => c.c.toDouble(),
                ),
              ],
              trackballBehavior: trackball,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final chartCenter = tester.getCenter(find.byType(SfCartesianChart));

    // Long press
    final gesture = await tester.startGesture(chartCenter);
    await tester.pump(const Duration(milliseconds: 600)); // long press threshold

    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 50));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(trackballFired, isTrue,
        reason: 'onTrackballPositionChanging should fire on long press');
  });

  testWidgets('Trackball works inside Column > Expanded (real layout)',
      (tester) async {
    bool trackballFired = false;

    final trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      lineColor: Colors.white,
      lineWidth: 1.5,
      tooltipDisplayMode: TrackballDisplayMode.none,
      shouldAlwaysShow: true,
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.visible,
        height: 10,
        width: 10,
        borderWidth: 2,
        color: Colors.white,
      ),
    );

    final zoomPan = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
      enableDoubleTapZooming: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text('OHLCV Info Bar placeholder'),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      onTrackballPositionChanging: (TrackballArgs args) {
                        trackballFired = true;
                      },
                      primaryXAxis: DateTimeAxis(),
                      primaryYAxis: NumericAxis(),
                      series: [
                        CandleSeries<Candle, DateTime>(
                          dataSource: candles,
                          xValueMapper: (c, _) => c.t,
                          openValueMapper: (c, _) => c.o.toDouble(),
                          highValueMapper: (c, _) => c.h.toDouble(),
                          lowValueMapper: (c, _) => c.l.toDouble(),
                          closeValueMapper: (c, _) => c.c.toDouble(),
                        ),
                      ],
                      trackballBehavior: trackball,
                      zoomPanBehavior: zoomPan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final chartCenter = tester.getCenter(find.byType(SfCartesianChart));

    // Simulate touch down + drag (like finger on screen)
    final gesture = await tester.startGesture(chartCenter);
    await tester.pump(const Duration(milliseconds: 50));

    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 50));

    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 50));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    expect(trackballFired, isTrue,
        reason:
            'Trackball should fire in Column>Expanded layout with ZoomPan');
  });
}
