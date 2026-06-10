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
  // -1 = Repòs absolut (El dit NO toca el gràfic)
  int _draggingNeedle = -1;

  // Variables de control local per al dibuix fluid contra CustomPaint
  int? _localStartIdx;
  int? _localEndIdx;
  int? _localGraphIdx;

  // Control de Throttle de temps per no saturar el canal de Riverpod al fer Drag
  DateTime _lastThrottleTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _throttleDurationMs = 32;

  @override
  void didUpdateWidget(covariant ElevationChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentSelection = ref.read(elevationSelectionProvider);

    // 🟢 CLAU DEL MOVIMENT: Només si estem en repòs (-1), el mapa té permís per trepitjar
    // els índexs locals (per exemple, en fer tap a un waypoint del mapa).
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

    // Si no hi ha dades, evitem pintar un llenç buit
    if (pastDists.isEmpty && futureDists.isEmpty) {
      return const SizedBox.shrink();
    }

    // Assegurem la mateixa longitud de forma robusta
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

    // Estructurem l'eix global unint passat i futur de la ruta
    final globalDists = <double>[...safePastDists, ...safeFutureDists];
    final globalAlts = <double>[...safePastAlts, ...safeFutureAlts];

    if (globalDists.isEmpty || globalAlts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Rango vertical de cotes automàtic
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
          if (idx == null || idx < 0 || idx >= globalDists.length) return -1;
          return idx;
        }

        // Recuperem els índexs locals per pintar les agulles de forma independent durant el drag
        final graphIdx = clampIndex(_localGraphIdx);
        final startIdx = clampIndex(_localStartIdx);
        final endIdx = clampIndex(_localEndIdx);

        final graphX = graphIdx >= 0 ? mapX(globalDists[graphIdx]) : null;
        final startX = startIdx >= 0 ? mapX(globalDists[startIdx]) : null;
        final endX = endIdx >= 0 ? mapX(globalDists[endIdx]) : null;

        // Mode del provider per regular tap i gestos
        final currentMode = ref.watch(elevationSelectionProvider).mode;

        void _updateSelectionThrottled(VoidCallback updateStateAction) {
          // 1. Executem el setState de Dart a l'acte per moure l'agulla local als ulls de l'usuari a 60 FPS
          updateStateAction();

          // 2. Regulem l'enviament massiu de dades cap al mapa per no saturar la GPU
          final ara = DateTime.now();
          if (ara.difference(_lastThrottleTime).inMilliseconds >=
              _throttleDurationMs) {
            _lastThrottleTime = ara;

            if (_draggingNeedle == 1 || _draggingNeedle == 2) {
              if (_localStartIdx != null && _localEndIdx != null) {
                ref
                    .read(elevationSelectionProvider.notifier)
                    .setManualRange(_localStartIdx!, _localEndIdx!);
              }
            } else if (_draggingNeedle == 3) {
              if (_localGraphIdx != null) {
                ref
                    .read(elevationSelectionProvider.notifier)
                    .setSinglePoint(_localGraphIdx!);
              }
            }
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          // 🔓 EL LONG PRESS: És l'únic que activa el mode "Selecció de tram" (range)
          // 🔓 EL LONG PRESS: Obre el mode tram obrint el ventall al 25% i 75% del perfil
          onLongPressStart: (_) {
            // 1. Calculem quina posició de la llista unificada correspon a cada percentatge
            final int totalPoints = globalDists.length;

            // Garantim de forma robusta que l'índex estigui dins del rang de la llista
            final int startIdx = (totalPoints * 0.25).floor().clamp(
              0,
              totalPoints - 1,
            );
            final int endIdx = (totalPoints * 0.75).floor().clamp(
              0,
              totalPoints - 1,
            );

            // 2. Avisem a Riverpod pasant-li els dos extrems reals calculats
            ref
                .read(elevationSelectionProvider.notifier)
                .startSelectionWithLongPress(startIdx, endIdx);

            // 3. Forcem les agulles locals a pintar-se separades al 25% i 75% a l'acte
            setState(() {
              _draggingNeedle = 0; // Mode actiu post-longpress
              _localStartIdx = startIdx;
              _localEndIdx = endIdx;
              _localGraphIdx =
                  null; // Desactivem completament el mode single (taronja)
            });
          },

          onTapUp: (details) {
            final x = details.localPosition.dx;
            final touchedStart = startX != null && (x - startX).abs() < 30;
            final touchedEnd = endX != null && (x - endX).abs() < 30;

            if (!touchedStart && !touchedEnd) {
              final idx = ChartLogic.calculateIndexFromX(x, width, globalDists);

              if (currentMode == SelectionMode.range) {
                // Si fem un tap net fora, netegem el tram complet
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

          // 🎛️ INICI DE L'ARROSSEGAMENT: Determina quina agulla o mode s'activa
          onPanDown: (details) {
            final x = details.localPosition.dx;
            final touchedStart = startX != null && (x - startX).abs() < 30;
            final touchedEnd = endX != null && (x - endX).abs() < 30;

            setState(() {
              if (touchedStart) {
                _draggingNeedle = 1; // Dit sobre agulla d'Inici (Verd)
              } else if (touchedEnd) {
                _draggingNeedle = 2; // Dit sobre agulla de Final (Vermell)
              } else {
                // 🔥 RECUPERAT: Si es fa drag sobre el gràfic sense tocar cap agulla,
                // destruïm la selecció de tram a l'acte i activem el "drag-simple-point" (taronja)
                _draggingNeedle = 3;
                final idx = ChartLogic.calculateIndexFromX(
                  x,
                  width,
                  globalDists,
                );
                _localStartIdx = null;
                _localEndIdx = null;
                _localGraphIdx = idx;

                // Actualitzem Riverpod a l'acte perquè el mapa rebi el cercle taronja immediatament
                ref
                    .read(elevationSelectionProvider.notifier)
                    .setSinglePoint(idx);
              }
            });
          },

          // 🔄 MOVIMENT EN TEMPS REAL: Gestiona el throttle i l'intercanvi dinàmic d'agulles (Swap)
          onPanUpdate: (details) {
            if (_draggingNeedle == -1 || _draggingNeedle == 0) return;

            final x = details.localPosition.dx;
            final idx = ChartLogic.calculateIndexFromX(x, width, globalDists);

            // 🟢 CAS A: ARROSSEGUEM L'EXTREM D'INICI (Verd)
            if (_draggingNeedle == 1) {
              final actualEnd = endIdx >= 0 ? endIdx : idx;

              _updateSelectionThrottled(() {
                setState(() {
                  if (idx > actualEnd) {
                    // 🔥 INTERCANVI TOTAL (Swap): Si passem de llarg del final,
                    // l'inici vell es queda clavat com a nou final, el nou inici és on està el dit,
                    // i canviem dinàmicament el rol del dit a l'agulla de final (_draggingNeedle = 2)
                    _localStartIdx = actualEnd;
                    _localEndIdx = idx;
                    _draggingNeedle = 2;
                  } else {
                    _localStartIdx = idx;
                    _localEndIdx = actualEnd;
                  }
                });
              });
            }
            // 🟢 CAS B: ARROSSEGUEM L'EXTREM DE FINAL (Vermell)
            else if (_draggingNeedle == 2) {
              final actualStart = startIdx >= 0 ? startIdx : idx;

              _updateSelectionThrottled(() {
                setState(() {
                  if (idx < actualStart) {
                    // 🔥 INTERCANVI TOTAL (Swap): Si anem per darrere de l'inici,
                    // el final vell es queda clavat com a nou inici, el nou final és on està el dit,
                    // i canviem dinàmicament el rol del dit a l'agulla d'inici (_draggingNeedle = 1)
                    _localStartIdx = idx;
                    _localEndIdx = actualStart;
                    _draggingNeedle = 1;
                  } else {
                    _localStartIdx = actualStart;
                    _localEndIdx = idx;
                  }
                });
              });
            }
            // 🟢 CAS C: MODE DRAG-SIMPLE-POINT ACTIVE (Taronja)
            else if (_draggingNeedle == 3) {
              _updateSelectionThrottled(() {
                setState(() {
                  _localGraphIdx = idx;
                });
              });
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
              // Capa 1: El gràfic de línies de fons de FL Chart
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

              // Capa 2: El polígon de ressaltat degradat (Mode range seleccionat)
              if (startIdx >= 0 &&
                  endIdx >= 0 &&
                  currentMode == SelectionMode.range)
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

              // Capa 3: Les agulles verticals, nodes geomètrics i bafarades
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
    required double forcedMaxY, // El valor que et ve calculat de Riverpod/State
    required double maxDist,
  }) {
    final colors = Theme.of(context).colorScheme;

    // 🛡️ REBAIXA DE LA LÍNIA DEL GRÀFIC (LA CLAU DE L'ÈXIT):
    // Calculem la diferència real d'altitud (diff) per saber el rang d'ajust
    final double diffAlt = forcedMaxY - forcedMinY;

    // Augmentem el sostre virtual un 25% extra sobre el forcedMaxY original.
    // Això fa que la línia real del track d'fl_chart es comprimeixi cap avall,
    // sincronitzant-se de forma simètrica amb les agulles que hem mogut abans!
    final double adjustedMaxY =
        forcedMaxY + (diffAlt > 0 ? diffAlt * 0.25 : 50.0);

    return LineChartData(
      // 🛡️ MODIFICACIÓ: Passem el nou adjustedMaxY en lloc del vell forcedMaxY
      minY: forcedMinY,
      maxY: adjustedMaxY,
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
            // REBAIXA AL BOTTOM mantinguda a 14 píxels
            reservedSize: 14,
            interval: maxDist > 0 ? maxDist / 2 : 1.0,
            getTitlesWidget: (value, meta) {
              if (value > maxDist + 0.1) return const SizedBox();

              final isFirst = value == 0;
              final isLast = (maxDist - value).abs() < 0.001;

              final fullText = formatDistance(value);
              final parts = fullText.split(' ');
              final numberPart = parts.isNotEmpty ? parts[0] : fullText;
              final unitPart = parts.length > 1 ? parts[1] : '';

              // Mantenim l'estil compacte en blanc que teníem d'or
              const textStyle = TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              );

              // Creem el pintor per calcular l'amplada real del text unificat COMPLET
              // (número + espai + unitat) per fer el desplaçament horitzontal mil·limètric
              final String fullTextString = unitPart.isNotEmpty
                  ? "$numberPart $unitPart"
                  : numberPart;
              final tp = TextPainter(
                text: TextSpan(text: fullTextString, style: textStyle),
                textDirection: TextDirection.ltr,
              )..layout();

              // 🛡️ REAJUSTE D'ALINEACIÓ DE BORDES ANTI-TALLS:
              // - El primer text es mou la meitat de la seva amplada cap a la dreta, més un coixí de 4px per separar-se del marge [INDEX].
              // - L'últim text s'aparta la meitat de la seva amplada cap a l'esquerra, menys un coixí de 4px perquè s'arrimi de forma precisa [INDEX].
              double dx = 0;
              if (isFirst) {
                dx = (tp.width / 2) + 4.0;
              } else if (isLast) {
                dx = -(tp.width / 2) - 4.0;
              } else {
                dx =
                    -(tp.width /
                        2); // Els del mig es queden centrats com sempre
              }

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
