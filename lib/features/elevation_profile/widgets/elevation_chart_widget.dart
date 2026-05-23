import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:senda/features/elevation_profile/painters/range_highlight_painter.dart'
    show RangeAreaPainter;
import 'package:senda/features/elevation_profile/painters/selection_painter.dart';
import 'package:senda/features/elevation_profile/utils/chart_utils.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/utils/distance_utils.dart';

class ElevationChartWidget extends StatefulWidget {
  final List<double> realAlts;
  final List<double> realDists;

  final List<double> importedAlts;
  final List<double> importedDists;

  final bool primaryIsReal;

  final int? selectedIndexStart;
  final int? selectedIndexEnd;
  final int? selectedIndexGraph;

  final List<int>? recordedWaypointIndices;
  final List<int>? importedWaypointIndices;

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
    required this.realAlts,
    required this.realDists,
    required this.importedAlts,
    required this.importedDists,
    required this.primaryIsReal,
    required this.selectedIndexStart,
    required this.selectedIndexEnd,
    required this.selectedIndexGraph,
    required this.recordedWaypointIndices,
    required this.importedWaypointIndices,
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
  int _draggingNeedle = 0; // 0=cap, 1=inici, 2=final, 3=agulla principal

  @override
  Widget build(BuildContext context) {
    final primaryDists = widget.primaryIsReal
        ? widget.realDists
        : widget.importedDists;
    final primaryAlts = widget.primaryIsReal
        ? widget.realAlts
        : widget.importedAlts;

    final secondaryDists = widget.primaryIsReal
        ? widget.importedDists
        : widget.realDists;
    final secondaryAlts = widget.primaryIsReal
        ? widget.importedAlts
        : widget.realAlts;

    if (primaryDists.isEmpty || primaryAlts.isEmpty) {
      return const SizedBox.shrink();
    }

    // ─────────────────────────────────────────────
    // RANG VERTICAL EXACTE (com l’original)
    // ─────────────────────────────────────────────
    final allAlts = [
      ...primaryAlts,
      if (secondaryAlts.isNotEmpty) ...secondaryAlts,
    ];

    final minAlt = allAlts.reduce((a, b) => a < b ? a : b);
    final maxAlt = allAlts.reduce((a, b) => a > b ? a : b);
    final diff = maxAlt - minAlt;

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

    final maxDist = [
      if (widget.realDists.isNotEmpty) widget.realDists.last,
      if (widget.importedDists.isNotEmpty) widget.importedDists.last,
    ].fold<double>(0, (a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Map X original
        double mapX(double dist) {
          final maxD = primaryDists.last;
          if (maxD == 0) return 24;
          return (dist / maxD) * (width - 48) + 24;
        }

        final graphX = widget.selectedIndexGraph != null
            ? mapX(primaryDists[widget.selectedIndexGraph!])
            : null;

        final startX = widget.selectedIndexStart != null
            ? mapX(primaryDists[widget.selectedIndexStart!])
            : null;

        final endX = widget.selectedIndexEnd != null
            ? mapX(primaryDists[widget.selectedIndexEnd!])
            : null;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          // ─────────────────────────────────────────────
          // LONG PRESS → crear rang automàtic
          // ─────────────────────────────────────────────
          onLongPressStart: (_) {
            final start = ChartLogic.calculateIndexFromX(
              width * 0.25,
              width,
              primaryDists,
            );
            final end = ChartLogic.calculateIndexFromX(
              width * 0.75,
              width,
              primaryDists,
            );

            widget.onRangeSelected(start, end);
            setState(() => _draggingNeedle = 0);
          },

          // ─────────────────────────────────────────────
          // TAPUP → si no toques cap agulla → netejar selecció
          onTapUp: (details) {
            final x = details.localPosition.dx;

            final touchedStart = startX != null && (x - startX).abs() < 30;
            final touchedEnd = endX != null && (x - endX).abs() < 30;

            // Si no s’ha tocat cap agulla → netejar TOT
            if (!touchedStart && !touchedEnd) {
              widget.onClearSelection();
              setState(() {
                _draggingNeedle = 0;
              });
            }
          },

          // ─────────────────────────────────────────────
          // ─────────────────────────────────────────────
          // PAN DOWN → detectar quina agulla s’agafa
          // ─────────────────────────────────────────────
          onPanDown: (details) {
            final x = details.localPosition.dx;

            final touchedStart = startX != null && (x - startX).abs() < 30;
            final touchedEnd = endX != null && (x - endX).abs() < 30;

            setState(() {
              if (touchedStart) {
                _draggingNeedle = 1; // mou inici
              } else if (touchedEnd) {
                _draggingNeedle = 2; // mou final
              } else {
                // NO s’ha tocat cap agulla → netejar selecció
                widget.onClearSelection();

                _draggingNeedle = 3; // mou agulla principal
                final idx = ChartLogic.calculateIndexFromX(
                  x,
                  width,
                  primaryDists,
                );
                widget.onNeedleMove(idx);
              }
            });
          },

          // ─────────────────────────────────────────────
          // PAN UPDATE → mou la que toqui
          // ─────────────────────────────────────────────
          onPanUpdate: (details) {
            if (_draggingNeedle == 0) return;

            final x = details.localPosition.dx;
            final idx = ChartLogic.calculateIndexFromX(x, width, primaryDists);

            if (_draggingNeedle == 1) {
              widget.onRangeSelected(idx, widget.selectedIndexEnd ?? idx);
            } else if (_draggingNeedle == 2) {
              widget.onRangeSelected(widget.selectedIndexStart ?? idx, idx);
            } else if (_draggingNeedle == 3) {
              widget.onNeedleMove(idx);
            }
          },

          onPanEnd: (_) => setState(() => _draggingNeedle = 0),
          onPanCancel: () => setState(() => _draggingNeedle = 0),

          child: Stack(
            children: [
              // ─────────────────────────────────────────────
              // 1) BASE: FLCHART (perfil d’elevació)
              // ─────────────────────────────────────────────
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: SelectionPainter.topReserved,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LineChart(
                      _buildChartData(
                        context: context,
                        primaryAlts: primaryAlts,
                        primaryDists: primaryDists,
                        secondaryAlts: secondaryAlts,
                        secondaryDists: secondaryDists,
                        trackColor: widget.primaryIsReal
                            ? AppColors.recordingTrackColor
                            : AppColors.routeTrackColor,
                        importedTrackColor: widget.primaryIsReal
                            ? widget.importedColor
                            : widget.realColor,
                        forcedMinY: forcedMinY,
                        forcedMaxY: forcedMaxY,
                        maxDist: maxDist,
                      ),
                    ),
                  ),
                ),
              ),

              // ─────────────────────────────────────────────
              // 2) ÀREA DEL RANG (RangeAreaPainter)
              // ─────────────────────────────────────────────
              if (widget.selectedIndexStart != null &&
                  widget.selectedIndexEnd != null)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: SelectionPainter.topReserved,
                    ),
                    child: CustomPaint(
                      painter: RangeAreaPainter(
                        startIndex: widget.selectedIndexStart!,
                        endIndex: widget.selectedIndexEnd!,
                        distances: primaryDists,
                        altitudes: primaryAlts,
                        minY: forcedMinY,
                        maxY: forcedMaxY,
                        color: Colors.orange.withAlpha(50),
                      ),
                    ),
                  ),
                ),

              // ─────────────────────────────────────────────
              // 3) SELECTIONPAINTER (agulles + waypoints + línies min/max + tooltip)
              // ─────────────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: SelectionPainter(
                    graphX: graphX,
                    graphIndex: widget.selectedIndexGraph,
                    startX: startX,
                    startIndex: widget.selectedIndexStart,
                    endX: endX,
                    endIndex: widget.selectedIndexEnd,
                    distances: primaryDists,
                    altitudes: primaryAlts,
                    secondaryDistances: secondaryDists.isEmpty
                        ? null
                        : secondaryDists,
                    secondaryAltitudes: secondaryAlts.isEmpty
                        ? null
                        : secondaryAlts,
                    graphNeedleColor: widget.graphNeedleColor,
                    sliderStartNeedleColor: widget.sliderStartNeedleColor,
                    sliderEndNeedleColor: widget.sliderEndNeedleColor,
                    secondaryGraphNeedleColor: widget.importedColor,
                    recordedWaypointIndices: widget.recordedWaypointIndices,
                    importedWaypointIndices: widget.importedWaypointIndices,
                    recordedWaypointColor: AppColors.recordingTrackColor,
                    importedWaypointColor: AppColors.routeTrackColor,
                    primaryIsReal: widget.primaryIsReal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // FLCHART DATA (eix X + etiquetes + perfil)
  // ─────────────────────────────────────────────
  LineChartData _buildChartData({
    required BuildContext context,
    required List<double> primaryAlts,
    required List<double> primaryDists,
    required List<double> secondaryAlts,
    required List<double> secondaryDists,
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

              final isLast = (maxDist - value).abs() < 0.001;

              final text = formatDistance(value);

              // Mesurem l’amplada del text
              final tp = TextPainter(
                text: TextSpan(
                  text: text,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                textDirection: TextDirection.ltr,
              )..layout();

              double dx = 0;

              if (isLast) {
                // Moure l’etiqueta cap a l’esquerra exactament
                dx = -(tp.width / 2);
              }

              return SideTitleWidget(
                meta: meta,
                space: 10,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),

      lineTouchData: const LineTouchData(enabled: false),

      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            primaryAlts.length,
            (i) => FlSpot(primaryDists[i], primaryAlts[i]),
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

        if (secondaryDists.isNotEmpty)
          LineChartBarData(
            spots: List.generate(
              secondaryAlts.length,
              (i) => FlSpot(secondaryDists[i], secondaryAlts[i]),
            ),
            isCurved: true,
            curveSmoothness: 0.5,
            preventCurveOverShooting: true,
            color: importedTrackColor,
            barWidth: 3,
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
