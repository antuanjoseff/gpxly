// lib/screens/elevations/widgets/elevation_chart_widget.dart (BLOC 1 DE 3)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:senda/screens/elevations/painters/selection_painter.dart';
import 'package:senda/screens/elevations/utils/chart_utils.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/utils/distance_utils.dart';

class ElevationChartWidget extends ConsumerStatefulWidget {
  final List<double> pastDists;
  final List<double> pastAlts;
  final List<double> futureDistsGlobal;
  final List<double> futureAlts;
  final Color realColor;
  final Color importedColor;
  final Color graphNeedleColor;
  final Color sliderStartNeedleColor;
  final Color sliderEndNeedleColor;
  final List<double> recordedWaypointGlobalDists;
  final List<double> importedWaypointGlobalDists;

  const ElevationChartWidget({
    super.key,
    required this.pastDists,
    required this.pastAlts,
    required this.futureDistsGlobal,
    required this.futureAlts,
    required this.realColor,
    required this.importedColor,
    required this.graphNeedleColor,
    required this.sliderStartNeedleColor,
    required this.sliderEndNeedleColor,
    required this.recordedWaypointGlobalDists,
    required this.importedWaypointGlobalDists,
  });

  @override
  ConsumerState<ElevationChartWidget> createState() =>
      _ElevationChartWidgetState();
}

class _ElevationChartWidgetState extends ConsumerState<ElevationChartWidget> {
  int _draggingNeedle = -1;
  int? _localStartIdx;
  int? _localEndIdx;
  int? _localGraphIdx;

  DateTime _lastThrottleTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _throttleDurationMs = 32;

  @override
  void didUpdateWidget(covariant ElevationChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentSelection = ref.read(elevationSelectionProvider);
    if (_draggingNeedle == -1) {
      setState(() {
        _localStartIdx = currentSelection.startTrackIndex;
        _localEndIdx = currentSelection.endTrackIndex;
        _localGraphIdx = currentSelection.singlePointIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pastDists = widget.pastDists;
    final pastAlts = widget.pastAlts;
    final futureDists = widget.futureDistsGlobal;
    final futureAlts = widget.futureAlts;

    if (pastDists.isEmpty && futureDists.isEmpty) {
      return const SizedBox.shrink();
    }

    final safePastLength = (pastDists.length == pastAlts.length)
        ? pastDists.length
        : 0;
    final safeFutureLength = (futureDists.length == futureAlts.length)
        ? futureDists.length
        : 0;

    final safePastDists = pastDists.take(safePastLength).toList();
    final safePastAlts = pastAlts.take(safePastLength).toList();
    final safeFutureDists = futureDists.take(safeFutureLength).toList();
    final safeFutureAlts = futureAlts.take(safeFutureLength).toList();

    final globalDists = <double>[...safePastDists, ...safeFutureDists];
    final globalAlts = <double>[...safePastAlts, ...safeFutureAlts];

    if (globalDists.isEmpty || globalAlts.isEmpty) {
      return const SizedBox.shrink();
    }

    final minAlt = globalAlts.reduce((a, b) => a < b ? a : b);
    final maxAlt = globalAlts.reduce((a, b) => a > b ? a : b);
    final diff = (maxAlt - minAlt).abs();

    final double paddingRange = diff < 10 ? 10 : diff;

    // 🚀 COIXÍ DE SEGURETAT SUPERIOR: Deixem un 35% lliure al sostre per als tooltips fixos
    final forcedMinY = minAlt - (paddingRange * 0.10);
    final forcedMaxY = maxAlt + (paddingRange * 0.35);

    const double globalTopReserved = 28.0;
    const double globalBottomReserved = 16.0;

    final maxDist = globalDists.last > 0 ? globalDists.last : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double mapX(double dist) {
          if (maxDist == 0) return 0;
          return (dist / maxDist) * width;
        }

        int clampIndex(int? idx) {
          if (idx == null || idx < 0 || idx >= globalDists.length) return -1;
          return idx;
        }

        final graphIdx = clampIndex(_localGraphIdx);
        final startIdx = clampIndex(_localStartIdx);
        final endIdx = clampIndex(_localEndIdx);

        final graphX = graphIdx >= 0 ? mapX(globalDists[graphIdx]) : null;
        final startX = startIdx >= 0 ? mapX(globalDists[startIdx]) : null;
        final endX = endIdx >= 0 ? mapX(globalDists[endIdx]) : null;

        final currentMode = ref.watch(elevationSelectionProvider).mode;
        // lib/screens/elevations/widgets/elevation_chart_widget.dart (BLOC 2 DE 3)
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (_) {
            final int totalPoints = globalDists.length;
            final int sIdx = (totalPoints * 0.25).floor().clamp(
              0,
              totalPoints - 1,
            );
            final int eIdx = (totalPoints * 0.75).floor().clamp(
              0,
              totalPoints - 1,
            );

            ref
                .read(elevationSelectionProvider.notifier)
                .setManualRange(sIdx, eIdx);

            setState(() {
              _draggingNeedle = 0;
              _localStartIdx = sIdx;
              _localEndIdx = eIdx;
              _localGraphIdx = null;
              _draggingNeedle = -1;
            });
          },
          onTapUp: (details) {
            final x = details.localPosition.dx;
            final touchedStart = startX != null && (x - startX).abs() < 30;
            final touchedEnd = endX != null && (x - endX).abs() < 30;
            if (!touchedStart && !touchedEnd) {
              final idx = ChartLogic.calculateIndexFromX(x, width, globalDists);
              if (currentMode == SelectionMode.range) {
                ref.read(elevationSelectionProvider.notifier).clearSelection();
                setState(() {
                  _localStartIdx = null;
                  _localEndIdx = null;
                  _localGraphIdx = null;
                });
              } else {
                ref
                    .read(elevationSelectionProvider.notifier)
                    .setSinglePoint(idx);
                setState(() {
                  _localGraphIdx = idx;
                });
              }
              setState(() => _draggingNeedle = -1);
            }
          },
          onPanDown: (details) {
            final x = details.localPosition.dx;
            final touchedStart = startX != null && (x - startX).abs() < 30;
            final touchedEnd = endX != null && (x - endX).abs() < 30;
            setState(() {
              if (touchedStart) {
                _draggingNeedle = 1;
              } else if (touchedEnd) {
                _draggingNeedle = 2;
              } else {
                _draggingNeedle = 3;
                final idx = ChartLogic.calculateIndexFromX(
                  x,
                  width,
                  globalDists,
                );
                _localStartIdx = null;
                _localEndIdx = null;
                _localGraphIdx = idx;
                ref
                    .read(elevationSelectionProvider.notifier)
                    .setSinglePoint(idx);
              }
            });
          },
          onPanUpdate: (details) {
            if (_draggingNeedle == -1 || _draggingNeedle == 0) return;
            final x = details.localPosition.dx;
            final idx = ChartLogic.calculateIndexFromX(x, width, globalDists);

            // 1. ACTUALITZACIÓ LOCAL VISUAL (Sempre a màxima velocitat a la pantalla)
            if (_draggingNeedle == 1) {
              final actualEnd = endIdx >= 0 ? endIdx : idx;
              setState(() {
                if (idx > actualEnd) {
                  _localStartIdx = actualEnd;
                  _localEndIdx = idx;
                  _draggingNeedle = 2;
                } else {
                  _localStartIdx = idx;
                  _localEndIdx = actualEnd;
                }
              });
            } else if (_draggingNeedle == 2) {
              final actualStart = startIdx >= 0 ? startIdx : idx;
              setState(() {
                if (idx < actualStart) {
                  _localStartIdx = idx;
                  _localEndIdx = actualStart;
                  _draggingNeedle = 1;
                } else {
                  _localStartIdx = actualStart;
                  _localEndIdx = idx;
                }
              });
            } else if (_draggingNeedle == 3) {
              setState(() {
                _localGraphIdx = idx;
              });
            }

            // 2. FILTRE THROTTLE: Enviem la informació a la barra negra de dades de forma controlada cada 32ms
            // D'aquesta manera evitem asfixiar el fil d'execució de dades geomètriques de Senda
            final now = DateTime.now();
            if (now.difference(_lastThrottleTime).inMilliseconds >=
                _throttleDurationMs) {
              _lastThrottleTime = now;

              if (_localStartIdx != null &&
                  _localEndIdx != null &&
                  _draggingNeedle != 3) {
                ref
                    .read(elevationSelectionProvider.notifier)
                    .setManualRange(_localStartIdx!, _localEndIdx!);
              } else if (_localGraphIdx != null && _draggingNeedle == 3) {
                ref
                    .read(elevationSelectionProvider.notifier)
                    .setSinglePoint(_localGraphIdx!);
              }
            }
          },

          onPanEnd: (_) {
            if (_localStartIdx != null &&
                _localEndIdx != null &&
                _draggingNeedle != 3 &&
                _draggingNeedle != -1) {
              ref
                  .read(elevationSelectionProvider.notifier)
                  .setManualRange(_localStartIdx!, _localEndIdx!);
            } else if (_localGraphIdx != null && _draggingNeedle == 3) {
              ref
                  .read(elevationSelectionProvider.notifier)
                  .setSinglePoint(_localGraphIdx!);
            }
            setState(() => _draggingNeedle = -1);
          },
          onPanCancel: () => setState(() => _draggingNeedle = -1),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: globalBottomReserved,
                child: Container(color: Colors.white),
              ),
              // Capa 1: El gràfic de línies de fons de FL Chart (Amb fons gris)
              Positioned.fill(
                child: LineChart(
                  _buildChartData(
                    context: context,
                    pastAlts: safePastAlts,
                    pastDists: safePastDists,
                    futureAlts: safeFutureAlts,
                    futureDists: safeFutureDists,
                    trackColor: widget.realColor,
                    importedTrackColor: widget.importedColor,
                    forcedMinY: forcedMinY,
                    forcedMaxY: forcedMaxY,
                    maxDist: maxDist,
                    topReservedSize: globalTopReserved,
                    bottomReservedSize: globalBottomReserved,
                  ),
                ),
              ),
              // Capa 2: Les agulles verticals i bafarades simètriques fixes/mòbils del SelectionPainter
              Positioned.fill(
                child: CustomPaint(
                  painter: SelectionPainter(
                    graphX: graphX,
                    graphIndex: graphIdx,
                    startX: startX,
                    startIndex: startIdx,
                    endX: endX,
                    endIndex: endIdx,
                    distances: globalDists,
                    altitudes: globalAlts,
                    graphNeedleColor: widget.graphNeedleColor,
                    sliderStartNeedleColor: widget.sliderStartNeedleColor,
                    sliderEndNeedleColor: widget.sliderEndNeedleColor,
                    recordedWaypointGlobalDists:
                        widget.recordedWaypointGlobalDists,
                    importedWaypointGlobalDists:
                        widget.importedWaypointGlobalDists,
                    recordedWaypointColor: AppColors.recordingTrackColor,
                    importedWaypointColor: AppColors.routeTrackColor,
                    topReserved: globalTopReserved,
                    bottomReserved: globalBottomReserved,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // lib/screens/elevations/widgets/elevation_chart_widget.dart (BLOC 3 DE 3)
  LineChartData _buildChartData({
    required BuildContext context,
    required List<double> pastAlts,
    required List<double> pastDists,
    required List<double> futureAlts,
    required List<double> futureDists,
    required Color trackColor,
    required Color importedTrackColor,
    required double forcedMinY,
    required double forcedMaxY,
    required double maxDist,
    required double topReservedSize,
    required double bottomReservedSize,
  }) {
    final int safePastCount = (pastDists.length == pastAlts.length)
        ? pastDists.length
        : 0;
    final int safeFutureCount = (futureDists.length == futureAlts.length)
        ? futureDists.length
        : 0;

    final List<FlSpot> pastSpots = [
      for (int i = 0; i < safePastCount; i++) FlSpot(pastDists[i], pastAlts[i]),
    ];
    final List<FlSpot> futureSpots = [
      for (int i = 0; i < safeFutureCount; i++)
        FlSpot(futureDists[i], futureAlts[i]),
    ];

    final List<FlSpot> allSpots = [...pastSpots, ...futureSpots];
    final currentSelection = ref.read(elevationSelectionProvider);
    final int? sIdx = currentSelection.startTrackIndex;
    final int? eIdx = currentSelection.endTrackIndex;
    final bool showRangeArea =
        currentSelection.mode == SelectionMode.range &&
        sIdx != null &&
        eIdx != null;

    final List<FlSpot> rangeSelectedSpots = [];
    if (showRangeArea && allSpots.isNotEmpty) {
      final startClamp = sIdx!.clamp(0, allSpots.length - 1);
      final endClamp = eIdx!.clamp(0, allSpots.length - 1);
      final int actualStart = startClamp < endClamp ? startClamp : endClamp;
      final int actualEnd = startClamp > endClamp ? startClamp : endClamp;

      for (int i = actualStart; i <= actualEnd; i++) {
        rangeSelectedSpots.add(allSpots[i]);
      }
    }

    // 🚀 LÍNIES FINES NETES: Cap d'elles pintarà un degradat individual propi
    LineChartBarData buildBar(List<FlSpot> spots, Color color) {
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.3,
        isStrokeCapRound: true,
        preventCurveOverShooting: true,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        color: color,
        belowBarData: BarAreaData(show: false),
      );
    }

    return LineChartData(
      minY: forcedMinY,
      maxY: forcedMaxY,
      minX: 0,
      backgroundColor: Colors.grey.shade100.withAlpha(
        130,
      ), // Fons translúcid elegant de control
      maxX: maxDist,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      clipData: const FlClipData.none(),
      titlesData: FlTitlesData(
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: topReservedSize,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false, reservedSize: 0),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false, reservedSize: 0),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: bottomReservedSize,
            interval: maxDist > 0 ? maxDist / 2 : 1.0,
            getTitlesWidget: (value, meta) {
              if (value > maxDist + 0.1) return const SizedBox();
              final isFirst = value == 0;
              final isLast = (maxDist - value).abs() < 0.001;

              final fullText = formatDistance(value);
              final parts = fullText.split(' ');
              final numberPart = parts.isNotEmpty ? parts[0] : fullText;
              final unitPart = parts.length > 1 ? parts[1] : '';

              const textStyle = TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              );

              Widget label = Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(text: numberPart, style: textStyle),
                      if (unitPart.isNotEmpty)
                        TextSpan(
                          text: " $unitPart",
                          style: textStyle.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
              );

              if (isFirst || isLast) {
                final tp = TextPainter(
                  text: TextSpan(
                    text: "$numberPart $unitPart",
                    style: textStyle,
                  ),
                  textDirection: TextDirection.ltr,
                )..layout();
                double dx = isFirst
                    ? (tp.width / 2) + 4.0
                    : -(tp.width / 2) - 4.0;
                return SideTitleWidget(
                  meta: meta,
                  space: 2,
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: label,
                  ),
                );
              }
              return SideTitleWidget(meta: meta, space: 2, child: label);
            },
          ),
        ),
      ),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        // 🚀 CAPA DE FONS 1: DEGRADAT ÚNIC GENERAL (Es desactiva automàticament en seleccionar)
        if (!showRangeArea && allSpots.isNotEmpty)
          LineChartBarData(
            spots: allSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: trackColor.withAlpha(28),
              cutOffY: forcedMinY,
              applyCutOffY: true,
            ),
          ),
        // 🚀 CAPA DE FONS 2: DEGRADAT ÚNIC DEL RANG SELECCIONAT (S'encén de forma paral·lela)
        if (showRangeArea && rangeSelectedSpots.isNotEmpty)
          LineChartBarData(
            spots: rangeSelectedSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [trackColor.withAlpha(191), trackColor.withAlpha(38)],
              ),
              cutOffY: forcedMinY,
              applyCutOffY: true,
            ),
          ),
        // 🚀 CAPA SUPERIOR: LES LÍNIES FINES DE COLOR
        if (pastSpots.isNotEmpty) buildBar(pastSpots, trackColor),
        if (futureSpots.isNotEmpty) buildBar(futureSpots, importedTrackColor),
      ],
    );
  }
}
