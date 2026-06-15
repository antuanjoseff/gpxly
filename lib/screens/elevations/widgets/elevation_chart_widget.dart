import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:senda/screens/elevations/painters/range_highlight_painter.dart';
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
    final forcedMaxY = forcedMinY + (effectiveRange * 1.62 * exaggeration);

    // 🚀 UNIFICACIÓ TOTAL DE LA GRAELLA: Marges únics compartits per a les 3 capes
    const double globalTopReserved = 8.0;
    const double globalBottomReserved = 16.0;

    final maxDist = globalDists.last > 0 ? globalDists.last : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // 🟢 AFACCIÓ CRÍTICA: Llegim l'alçada real del contenidor calculat al 20%
        final height = constraints.maxHeight;

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

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
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
                .startSelectionWithLongPress(sIdx, eIdx);
            setState(() {
              _draggingNeedle = 0;
              _localStartIdx = sIdx;
              _localEndIdx = eIdx;
              _localGraphIdx = null;
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

            // 1. ACTUALITZACIÓ LOCALS DE LES AGULLES (Sempre a màxima taxa de refresc)
            if (_draggingNeedle == 1) {
              final actualEnd = endIdx >= 0 ? endIdx : idx;
              setState(() {
                if (idx > actualEnd) {
                  _localStartIdx = actualEnd;
                  _localEndIdx = idx;
                  _draggingNeedle =
                      2; // Commuta a l'agulla de la dreta (anti-swap)
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
                  _draggingNeedle =
                      1; // Commuta a l'agulla de l'esquerra (anti-swap)
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

            // 2. FILTRE THROTTLE: Notificació controlada a Riverpod cada 32ms
            // Així les agulles van fines com la seda i evitem col·lapsar la CPU amb els desnivells
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

          // 📐 EL NUCLI SÍNCRON: Eliminem el Padding exterior d'un sol component.
          // Totes les 3 capes comparteixen exactament el mateix Positioned.fill horitzontal.
          child: Stack(
            children: [
              // Capa 1: El gràfic de línies de fons de FL Chart
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
                    // 🚀 UNITAT TOTAL: Enviem forcedMinY i forcedMaxY calculats amb exageració
                    forcedMinY: forcedMinY,
                    forcedMaxY: forcedMaxY,
                    maxDist: maxDist,
                    topReservedSize: globalTopReserved,
                    bottomReservedSize: globalBottomReserved,
                  ),
                ),
              ),

              // Capa 2: El polígon de ressaltat degradat (Sincronia perfecta a sobre de la línia)
              if (startIdx >= 0 &&
                  endIdx >= 0 &&
                  currentMode == SelectionMode.range)
                Positioned.fill(
                  child: CustomPaint(
                    painter: RangeAreaPainter(
                      startIndex: startIdx,
                      endIndex: endIdx,
                      distances: globalDists,
                      altitudes: globalAlts,
                      realPointsCount: safePastDists.length,
                      trackColor: widget.realColor,
                      topReserved: globalTopReserved, // 👈 Mateixos píxels
                      bottomReserved:
                          globalBottomReserved, // 👈 Mateixos píxels
                    ),
                  ),
                ),

              // Capa 3: Les agulles verticals, nodes geomètrics i bafarades (Sincronia perfecta)
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
                    topReserved: globalTopReserved, // 👈 Mateixos píxels
                    bottomReserved: globalBottomReserved, // 👈 Mateixos píxels
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
    required double topReservedSize, // 🚀 AFEGIT: Mida del coixí superior
    required double bottomReservedSize, // Rebut síncronament des de la vista
  }) {
    return LineChartData(
      minY: forcedMinY,
      maxY: forcedMaxY,
      minX: 0,
      maxX: maxDist,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      clipData: const FlClipData.all(),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(y: forcedMinY, color: Colors.grey, strokeWidth: 1.5),
        ],
      ),
      titlesData: FlTitlesData(
        // 🚀 RECTIFICACIÓ: Sincronitzem el sostre d'fl_chart amb els teus Painters utilitzant la mida reservada a dalt
        topTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: topReservedSize,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: 0, // 🟢 Forcem a ocupar 0px de marge dret
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: false,
            reservedSize: 0, // 🟢 Forcem a ocupar 0px de marge esquerre
          ),
        ),

        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            // Sincronitzem exactament amb els painters: mateixa mida reservada de baix
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
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              );

              final String fullTextString = unitPart.isNotEmpty
                  ? "$numberPart $unitPart"
                  : numberPart;
              final tp = TextPainter(
                text: TextSpan(text: fullTextString, style: textStyle),
                textDirection: TextDirection.ltr,
              )..layout();

              double dx = 0;
              if (isFirst) {
                dx = (tp.width / 2) + 4.0;
              } else if (isLast) {
                dx = -(tp.width / 2) - 4.0;
              } else {
                dx = -(tp.width / 2);
              }

              // 🟢 Si és el del mig, eliminem el translate i deixem que fl_chart apliqui
              // el centrat absolut alineant el RichText al mig de la seva pròpia caixa.
              if (!isFirst && !isLast) {
                return SideTitleWidget(
                  meta: meta,
                  space: 2,
                  child: RichText(
                    textAlign:
                        TextAlign.center, // 🟢 Clava el text a l'eix central
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
              }

              // Per a l'inici i el final mantenim el translate per evitar que es tallin a les vores
              return SideTitleWidget(
                meta: meta,
                space: 2,
                child: Transform.translate(
                  offset: Offset(dx, 0),
                  child: RichText(
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
            curveSmoothness: 0.5,
            isStrokeCapRound: true,
            preventCurveOverShooting: true,
            color: trackColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: trackColor.withAlpha(64),
              cutOffY: forcedMinY,
              applyCutOffY: false, // Desactivem el retall rígid inferior
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
              applyCutOffY: false, // Desactivem el retall rígid inferior
            ),
          ),
      ],
    );
  }
}
