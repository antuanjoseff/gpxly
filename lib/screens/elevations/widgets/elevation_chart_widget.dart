// lib/screens/elevations/widgets/elevation_chart_widget.dart (BLOC 1 DE 3)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/notifiers/elevation_selection_provider.dart';
import 'package:strack_rec/theme/app_dimensions.dart';
import 'package:strack_rec/utils/distance_utils.dart';
import 'package:strack_rec/screens/elevations/painters/selection_painter.dart';
import 'package:strack_rec/screens/elevations/utils/chart_utils.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';

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
  final int? autoGraphIndex;

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
    this.autoGraphIndex,
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
  DateTime _lastStatsThrottleTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _statsThrottleDurationMs = 200;

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

  Widget _buildFlutterTooltip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  // lib/screens/elevations/widgets/elevation_chart_widget.dart (BLOC 2 DE 3)
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

    final displayPastDists = pastDists.take(safePastLength).toList();
    final displayPastAlts = pastAlts.take(safePastLength).toList();
    final displayFutureDists = futureDists.take(safeFutureLength).toList();
    final displayFutureAlts = futureAlts.take(safeFutureLength).toList();

    final bool isRecording =
        ref.watch(trackRecordingProvider).recordingState ==
        RecordingState.recording;
    final bool recordingAndFollowing =
        isRecording && displayFutureDists.isNotEmpty;

    final globalDists = <double>[...displayPastDists, ...displayFutureDists];
    final globalAlts = <double>[...displayPastAlts, ...displayFutureAlts];

    if (globalDists.isEmpty || globalAlts.isEmpty) {
      return const SizedBox.shrink();
    }

    final minAlt = globalAlts.reduce((a, b) => a < b ? a : b);
    final maxAlt = globalAlts.reduce((a, b) => a > b ? a : b);
    final double elevationDiff = (maxAlt - minAlt).abs();

    final double elevationRange = math.max(
      elevationDiff,
      AppDimensions.minElevationChartWindow,
    );
    final double elevationPaddingBottom = elevationRange * 0.10;
    final double elevationPaddingTop = elevationRange * 0.15;

    double forcedMinY = minAlt - elevationPaddingBottom;
    double forcedMaxY = maxAlt + elevationPaddingTop;

    final double currentYAxisRange = forcedMaxY - forcedMinY;
    if (currentYAxisRange < AppDimensions.minElevationChartYAxisRange) {
      final double missingRange =
          AppDimensions.minElevationChartYAxisRange - currentYAxisRange;
      forcedMinY -= missingRange / 2;
      forcedMaxY += missingRange / 2;
    }

    const double globalTopReserved = 0.0;
    const double globalBottomReserved = 16.0;

    final maxDist = globalDists.last > 0 ? globalDists.last : 1.0;
    final selectableMaxIndex = globalDists.length - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double mapX(double dist) {
          if (maxDist == 0) return 0;
          return (dist / maxDist) * width;
        }

        int clampIndex(int? idx) {
          if (idx == null || idx < 0 || idx >= globalDists.length) return -1;
          return idx > selectableMaxIndex ? -1 : idx;
        }

        final int? effectiveGraphIdx = (_draggingNeedle == -1)
            ? (_localGraphIdx ?? widget.autoGraphIndex)
            : _localGraphIdx;
        final graphIdx = clampIndex(effectiveGraphIdx);
        final startIdx = clampIndex(_localStartIdx);
        final endIdx = clampIndex(_localEndIdx);

        final graphX = graphIdx >= 0 ? mapX(globalDists[graphIdx]) : null;
        final startX = startIdx >= 0 ? mapX(globalDists[startIdx]) : null;
        final endX = endIdx >= 0 ? mapX(globalDists[endIdx]) : null;

        final currentMode = ref.watch(elevationSelectionProvider).mode;
        final bool showRangeArea =
            currentMode == SelectionMode.range && startIdx >= 0 && endIdx >= 0;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (_) {
            final int totalPoints = selectableMaxIndex + 1;
            if (totalPoints <= 0) return;
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
            // ref
            //     .read(elevationSelectionProvider.notifier)
            //     .activateMapSelectionTool();
            setState(() {
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
              int idx = ChartLogic.calculateIndexFromX(x, width, globalDists);
              idx = idx.clamp(0, selectableMaxIndex);
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
                int idx = ChartLogic.calculateIndexFromX(x, width, globalDists);
                idx = idx.clamp(0, selectableMaxIndex);
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
            int idx = ChartLogic.calculateIndexFromX(x, width, globalDists);
            idx = idx.clamp(0, selectableMaxIndex);

            final now = DateTime.now();
            if (now.difference(_lastThrottleTime).inMilliseconds >=
                _throttleDurationMs) {
              _lastThrottleTime = now;
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
                  _localGraphIdx =
                      null; // 🔒 Netegem el blau local de seguretat
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
                  _localGraphIdx =
                      null; // 🔒 Netegem el blau local de seguretat
                });
              } else if (_draggingNeedle == 3) {
                setState(() {
                  _localGraphIdx = idx;
                });
              }
            }

            if (now.difference(_lastStatsThrottleTime).inMilliseconds >=
                _statsThrottleDurationMs) {
              _lastStatsThrottleTime = now;

              // 🛡️ REGLA DE NEGOCI: Si arrosseguem agulles de tram (1 o 2), prohibim actualitzar el punt blau
              if (_localStartIdx != null &&
                  _localEndIdx != null &&
                  (_draggingNeedle == 1 || _draggingNeedle == 2)) {
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
            // 🛡️ REGLA DE NEGOCI FINALIZACIÓ: Només guardem el punt blau si veníem de moure el blau
            if (_localStartIdx != null &&
                _localEndIdx != null &&
                (_draggingNeedle == 1 || _draggingNeedle == 2)) {
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
          // lib/screens/elevations/widgets/elevation_chart_widget.dart (BLOC 3 DE 3)
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: globalBottomReserved,
                child: Container(color: Colors.white),
              ),
              Positioned.fill(
                child: LineChart(
                  _buildChartData(
                    context: context,
                    pastAlts: displayPastAlts,
                    pastDists: displayPastDists,
                    futureAlts: displayFutureAlts,
                    futureDists: displayFutureDists,
                    trackColor: widget.realColor,
                    importedTrackColor: widget.importedColor,
                    forcedMinY: forcedMinY,
                    forcedMaxY: forcedMaxY,
                    maxDist: maxDist,
                    topReservedSize: globalTopReserved,
                    bottomReservedSize: globalBottomReserved,
                    futureDashed: recordingAndFollowing,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: SelectionPainter(
                    graphX: showRangeArea ? null : graphX,
                    graphIndex: showRangeArea ? null : graphIdx,
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
                    minY: forcedMinY,
                    maxY: forcedMaxY,
                  ),
                ),
              ),

              // TOOLTIPS NATIVOS FLUTTER: Elevados a -18px para que salgan por arriba del gráfico
              if (showRangeArea) ...[
                Positioned(
                  top: -18,
                  left: 4,
                  child: _buildFlutterTooltip(
                    "${(globalDists[startIdx] / 1000.0).toStringAsFixed(2)} km | ${globalAlts[startIdx].toStringAsFixed(0)} m",
                    widget.sliderStartNeedleColor,
                  ),
                ),
                Positioned(
                  top: -18,
                  right: 4,
                  child: _buildFlutterTooltip(
                    "${(globalDists[endIdx] / 1000.0).toStringAsFixed(2)} km | ${globalAlts[endIdx].toStringAsFixed(0)} m",
                    widget.sliderEndNeedleColor,
                  ),
                ),
              ],

              // TOOLTIP AZUL MÓVIL: Flota dinámicamente a 12px exactos por encima de la montaña
              if (!showRangeArea && graphIdx >= 0 && graphX != null)
                Positioned(
                  left: (graphX - 65).clamp(4.0, width - 130.0),
                  top: -18,
                  child: _buildFlutterTooltip(
                    "${(globalDists[graphIdx] / 1000.0).toStringAsFixed(2)} km | ${globalAlts[graphIdx].toStringAsFixed(0)} m",
                    widget.graphNeedleColor,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

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
    required bool futureDashed,
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
    final bool showRangeArea =
        currentSelection.mode == SelectionMode.range &&
        currentSelection.startTrackIndex != null &&
        currentSelection.endTrackIndex != null;

    final List<FlSpot> rangeSelectedSpots = [];
    if (showRangeArea && allSpots.isNotEmpty) {
      final int startClamp = currentSelection.startTrackIndex!.clamp(
        0,
        allSpots.length - 1,
      );
      final int endClamp = currentSelection.endTrackIndex!.clamp(
        0,
        allSpots.length - 1,
      );
      final double minDist = math.min(
        allSpots[startClamp].x,
        allSpots[endClamp].x,
      );
      final double maxDistBound = math.max(
        allSpots[startClamp].x,
        allSpots[endClamp].x,
      );

      for (final spot in allSpots) {
        if (spot.x >= minDist && spot.x <= maxDistBound) {
          rangeSelectedSpots.add(spot);
        }
      }
    }

    LineChartBarData buildBar(
      List<FlSpot> spots,
      Color color, {
      bool dashed = false,
    }) {
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.4,
        preventCurveOverShooting: false,
        isStrokeCapRound: true,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        color: color,
        dashArray: dashed ? [5, 5] : null,
        belowBarData: BarAreaData(show: false),
      );
    }

    return LineChartData(
      minY: forcedMinY,
      maxY: forcedMaxY,
      minX: 0,
      maxX: maxDist,
      backgroundColor: Colors.grey.shade100.withValues(alpha: 0.5),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      clipData: const FlClipData.all(),
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

              final String fullText = formatDistance(value);
              final List<String> parts = fullText.split(' ');

              // Tipado estricto String para evitar el error de asignación Object
              final String numberPart = parts.isNotEmpty ? parts[0] : fullText;
              final String unitPart = parts.length > 1 ? parts[1] : '';

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
        if (!showRangeArea && allSpots.isNotEmpty)
          LineChartBarData(
            spots: allSpots,
            isCurved: true,
            curveSmoothness: 0.4,
            preventCurveOverShooting: false,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: trackColor.withValues(alpha: 0.1),
              cutOffY: forcedMinY,
              applyCutOffY: true,
            ),
          ),
        if (showRangeArea && rangeSelectedSpots.isNotEmpty)
          LineChartBarData(
            spots: rangeSelectedSpots,
            isCurved: true,
            curveSmoothness: 0.4,
            preventCurveOverShooting: false,
            barWidth: 0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  trackColor.withValues(alpha: 0.7),
                  trackColor.withValues(alpha: 0.15),
                ],
              ),
              cutOffY: forcedMinY,
              applyCutOffY: true,
            ),
          ),
        if (pastSpots.isNotEmpty) buildBar(pastSpots, trackColor),
        if (futureSpots.isNotEmpty)
          buildBar(futureSpots, importedTrackColor, dashed: futureDashed),
      ],
    );
  }
}
