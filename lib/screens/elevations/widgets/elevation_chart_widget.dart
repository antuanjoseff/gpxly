// lib/screens/elevations/widgets/elevation_chart_widget.dart (BLOC 1 DE 2)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:senda/screens/elevations/painters/selection_painter.dart';
import 'package:senda/screens/elevations/painters/range_highlight_painter.dart';
import 'package:senda/screens/elevations/utils/chart_utils.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/utils/distance_utils.dart';

class ElevationChartWidget extends StatefulWidget {
  final List<double> pastAlts;
  final List<double> pastDists;

  final List<double> futureAlts;
  final List<double> futureDistsGlobal;

  final int? selectedIndexStart;
  final int? selectedIndexEnd;
  final int? selectedIndexGraph;

  final List<double>? recordedWaypointGlobalDists;
  final List<double>? importedWaypointGlobalDists;

  final Color realColor;
  final Color importedColor;

  final Color graphNeedleColor;
  final Color sliderStartNeedleColor;
  final Color sliderEndNeedleColor;

  final void Function(int index) onNeedleMove;
  final void Function(int start, int end) onRangeSelected;
  final VoidCallback onClearSelection;

  const ElevationChartWidget({
    super.key,
    required this.pastAlts,
    required this.pastDists,
    required this.futureAlts,
    required this.futureDistsGlobal,
    required this.selectedIndexStart,
    required this.selectedIndexEnd,
    required this.selectedIndexGraph,
    required this.recordedWaypointGlobalDists,
    required this.importedWaypointGlobalDists,
    required this.realColor,
    required this.importedColor,
    required this.graphNeedleColor,
    required this.sliderStartNeedleColor,
    required this.sliderEndNeedleColor,
    required this.onNeedleMove,
    required this.onRangeSelected,
    required this.onClearSelection,
  });

  @override
  State<ElevationChartWidget> createState() => _ElevationChartWidgetState();
}

class _ElevationChartWidgetState extends State<ElevationChartWidget> {
  int _draggingNeedle = 0;

  @override
  Widget build(BuildContext context) {
    final pastDists = widget.pastDists;
    final pastAlts = widget.pastAlts;
    final futureDists = widget.futureDistsGlobal;
    final futureAlts = widget.futureAlts;

    // Si no hay datos, evitamos pintar un lienzo vacío
    if (pastDists.isEmpty && futureDists.isEmpty) {
      return const SizedBox.shrink();
    }

    // Aseguramos de forma robusta la misma longitud en las listas [INDEX]
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

    // Estructuramos los ejes globales [INDEX]
    final globalDists = <double>[...safePastDists, ...safeFutureDists];
    final globalAlts = <double>[...safePastAlts, ...safeFutureAlts];

    if (globalDists.isEmpty || globalAlts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Rango vertical automático robusto [INDEX]
    final minAlt = globalAlts.reduce((a, b) => a < b ? a : b);
    final maxAlt = globalAlts.reduce((a, b) => a > b ? a : b);
    final diff = (maxAlt - minAlt).abs();

    double exaggeration = 1.0;
    if (diff < 30) {
      exaggeration = 1.8;
    } else if (diff < 60) {
      exaggeration = 1.4;
    } else if (diff < 100) {
      exaggeration = 1.2;
    }

    final effectiveRange = diff < 50 ? 50 : diff;
    final forcedMinY = minAlt - (effectiveRange * 0.3 * exaggeration);
    final forcedMaxY = forcedMinY + (effectiveRange * 1.3 * exaggeration);

    final maxDist = globalDists.last > 0 ? globalDists.last : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double mapX(double dist) {
          if (maxDist == 0) return 0;
          return (dist / maxDist) * width;
        }

        int clampIndex(int? idx) {
          if (idx == null) return -1;
          if (idx < 0) return -1;
          if (idx >= globalDists.length) return -1;
          return idx;
        }

        final graphIdx = clampIndex(widget.selectedIndexGraph);
        final startIdx = clampIndex(widget.selectedIndexStart);
        final endIdx = clampIndex(widget.selectedIndexEnd);

        final graphX = graphIdx >= 0 ? mapX(globalDists[graphIdx]) : null;
        final startX = startIdx >= 0 ? mapX(globalDists[startIdx]) : null;
        final endX = endIdx >= 0 ? mapX(globalDists[endIdx]) : null;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (_) {
            final start = ChartLogic.calculateIndexFromX(
              width * 0.25,
              width,
              globalDists,
            );
            final end = ChartLogic.calculateIndexFromX(
              width * 0.75,
              width,
              globalDists,
            );
            widget.onRangeSelected(start, end);
            setState(() => _draggingNeedle = 0);
          },
          onTapUp: (details) {
            final x = details.localPosition.dx;
            final touchedStart = startX != null && (x - startX).abs() < 30;
            final touchedEnd = endX != null && (x - endX).abs() < 30;

            if (!touchedStart && !touchedEnd) {
              widget.onClearSelection();
              setState(() => _draggingNeedle = 0);
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
                widget.onClearSelection();
                _draggingNeedle = 3;
                final idx = ChartLogic.calculateIndexFromX(
                  x,
                  width,
                  globalDists,
                );
                widget.onNeedleMove(idx);
              }
            });
          },
          onPanUpdate: (details) {
            if (_draggingNeedle == 0) return;

            final x = details.localPosition.dx;
            final idx = ChartLogic.calculateIndexFromX(x, width, globalDists);

            if (_draggingNeedle == 1) {
              widget.onRangeSelected(idx, endIdx >= 0 ? endIdx : idx);
            } else if (_draggingNeedle == 2) {
              widget.onRangeSelected(startIdx >= 0 ? startIdx : idx, idx);
            } else if (_draggingNeedle == 3) {
              widget.onNeedleMove(idx);
            }
          },
          onPanEnd: (_) => setState(() => _draggingNeedle = 0),
          onPanCancel: () => setState(() => _draggingNeedle = 0),
          child: Stack(
            children: [
              // Capa 1: El gráfico de líneas de fondo de FL Chart
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: SelectionPainter.topReserved,
                  ),
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
                    ),
                  ),
                ),
              ),

              // Capa 2: El polígono de resaltado degradado (Tu nuevo RangeAreaPainter) [INDEX]
              if (startIdx >= 0 && endIdx >= 0)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: SelectionPainter.topReserved,
                    ),
                    child: CustomPaint(
                      painter: RangeAreaPainter(
                        startIndex: startIdx,
                        endIndex: endIdx,
                        distances: globalDists,
                        altitudes: globalAlts,
                        realPointsCount: safePastDists.length,
                        trackColor: widget.realColor,
                      ),
                    ),
                  ),
                ),

              // Capa 3: Las agujas, nodos y bocadillos flotantes de información
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
                  ),
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
  }) {
    final colors = Theme.of(context).colorScheme;

    return LineChartData(
      minY: forcedMinY,
      maxY: forcedMaxY,
      minX: 0,
      maxX: maxDist,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(y: forcedMinY, color: Colors.grey, strokeWidth: 1.5),
        ],
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: maxDist > 0 ? maxDist / 2 : 1.0,
            getTitlesWidget: (value, meta) {
              if (value > maxDist + 0.1) return const SizedBox();

              final isFirst = value == 0;
              final isLast = (maxDist - value).abs() < 0.001;

              final fullText = formatDistance(value);
              final parts = fullText.split(' ');
              final numberPart = parts.isNotEmpty ? parts[0] : fullText;
              final unitPart = parts.length > 1 ? parts[1] : '';

              final textStyle = TextStyle(
                color: colors.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              );

              final tp = TextPainter(
                text: TextSpan(text: numberPart, style: textStyle),
                textDirection: TextDirection.ltr,
              )..layout();

              double dx = 0;
              if (isFirst) {
                dx = tp.width / 2;
              } else if (isLast) {
                dx = -(tp.width / 2);
              }

              return SideTitleWidget(
                meta: meta,
                space: 6,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        numberPart,
                        style: textStyle.copyWith(color: Colors.white),
                      ),
                      if (unitPart.isNotEmpty)
                        Text(
                          unitPart,
                          style: textStyle.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.normal,
                            height: 0.8,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        if (pastDists.isNotEmpty)
          LineChartBarData(
            spots: List.generate(
              pastAlts.length,
              (i) => FlSpot(pastDists[i], pastAlts[i]),
            ),
            isCurved: true,
            curveSmoothness: 0.12,
            isStrokeCapRound: true,
            preventCurveOverShooting: true,
            color: trackColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: trackColor.withAlpha(64),
              cutOffY: forcedMinY,
              applyCutOffY: true,
            ),
          ),
        if (futureDists.isNotEmpty)
          LineChartBarData(
            spots: List.generate(
              futureAlts.length,
              (i) => FlSpot(futureDists[i], futureAlts[i]),
            ),
            isCurved: true,
            curveSmoothness: 0.5,
            preventCurveOverShooting: true,
            color: importedTrackColor,
            barWidth: 3,
            dashArray: const [8, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: importedTrackColor.withAlpha(48),
              cutOffY: forcedMinY,
              applyCutOffY: true,
            ),
          ),
      ],
    );
  }
}
