import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gpxly/features/elevation_profile/painters/selection_painter.dart';
import 'package:gpxly/features/elevation_profile/utils/chart_utils.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/utils/distance_utils.dart';
import 'package:gpxly/utils/decimation_utils.dart';
import 'models/touch_data.dart';
import 'painters/range_highlight_painter.dart';

enum ActiveHandle { none, start, end }

class ElevationProfileScreen extends ConsumerStatefulWidget {
  const ElevationProfileScreen({super.key});

  @override
  ConsumerState<ElevationProfileScreen> createState() =>
      _ElevationProfileScreenState();
}

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  // --- Estat d’agulles ---
  int? selectedIndexGraph; // agulla del gràfic
  int? selectedIndexStart; // agulla mànec esquerre
  int? selectedIndexEnd; // agulla mànec dret

  ActiveHandle activeHandle = ActiveHandle.none;

  // --- Estat del rang ---
  RangeValues selectedRange = const RangeValues(0, 1);

  // --- Clau del gràfic ---
  final chartKey = GlobalKey();
  int _draggingNeedle = 0;

  // --- Colors configurables ---
  final Color sliderStartNeedleColor = const Color(0xFF007BFF); // blau
  final Color sliderEndNeedleColor = const Color(0xFFFF3B30); // vermell
  final Color graphNeedleColor = const Color(0xFF4CAF50); // verd

  final Color highlightFillColor = const Color(
    0xFFFFA500,
  ).withAlpha(60); // taronja suau
  final Color highlightStrokeColor = const Color(
    0xFFFFA500,
  ).withAlpha(180); // taronja intens

  // --- Decimació per a interacció tàctil ---
  TouchData _buildTouchData(
    List<double> distances,
    List<double> altitudes,
    double chartWidth,
  ) {
    final maxTouchPoints = (chartWidth * 2).round().clamp(200, 2000);
    final d2 = decimateList(distances, maxTouchPoints);
    final a2 = decimateList(altitudes, maxTouchPoints);
    return TouchData(d2, a2);
  }

  // --- Trobar índex més proper a una distància ---
  int _closestIndexForDistance(List<double> distances, double target) {
    if (distances.isEmpty) return 0;
    int index = 0;
    double minDiff = double.infinity;
    for (int i = 0; i < distances.length; i++) {
      final diff = (distances[i] - target).abs();
      if (diff < minDiff) {
        minDiff = diff;
        index = i;
      }
    }
    return index;
  }

  // --- Construcció del gràfic ---
  LineChartData _buildChartData(
    BuildContext context,
    List<double> alts,
    List<double> dists,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (alts.isEmpty || dists.isEmpty) {
      return LineChartData(lineBarsData: []);
    }

    final spots = List.generate(alts.length, (i) => FlSpot(dists[i], alts[i]));
    final maxDist = dists.last;

    // --- CÀLCUL DEL RANG VERTICAL AMB SEGURETAT PER A RUTES PLANES ---
    final minAlt = alts.reduce((a, b) => a < b ? a : b);
    final maxAlt = alts.reduce((a, b) => a > b ? a : b);

    double diff = maxAlt - minAlt;

    // 🔥 Establim el rang mínim de 50m (com als Painters)
    double effectiveRange = diff < 50 ? 50 : diff;

    // Apliquem el 10% de marge (mateixa lògica per tot el projecte)
    final forcedMinY = minAlt - (effectiveRange * 0.1);
    final forcedMaxY = forcedMinY + (effectiveRange * 1.2);
    return LineChartData(
      minY: forcedMinY, // 🔥 Crucial per eliminar el "gap"
      maxY: forcedMaxY, // 🔥 Crucial per eliminar el "gap"
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40, // Espai per als km/m
            interval: maxDist > 0 ? maxDist / 2 : 1.0,
            getTitlesWidget: (value, meta) {
              if (value > maxDist + 0.1) return const SizedBox();
              return SideTitleWidget(
                meta: meta,
                space: 10,
                child: Text(
                  formatDistance(value),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        // NOMÉS LA LÍNIA PRINCIPAL
        LineChartBarData(
          spots: spots,
          isCurved:
              false, // 🔥 Precisió absoluta: la corba sempre enganya l'agulla
          color: colors.secondary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.secondary.withAlpha(120),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(trackProvider);
    final colors = Theme.of(context).colorScheme;

    final altitudes = track.altitudes;
    final coordinates = track.coordinates;
    final times = track.timestamps;
    final distances = calculateDistances(coordinates);

    if (altitudes.isEmpty || distances.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Perfil d'elevació")),
        body: Center(
          child: Text(
            "Sense dades",
            style: TextStyle(color: colors.onSurface.withAlpha(100)),
          ),
        ),
      );
    }

    final chartHeight = MediaQuery.of(context).size.height * 0.3;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text("Perfil d'elevació")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSegmentStatsBar(altitudes, distances, times),
              const SizedBox(height: 20),

              // HEADER
              // SizedBox(
              //   height: MediaQuery.of(context).size.height * 0.08,
              //   child: Center(
              //     child: _buildHeader(context, altitudes, distances),
              //   ),
              // ),
              const SizedBox(height: 20),

              // GRÀFIC + HIGHLIGHT + AGULLES
              SizedBox(
                height: chartHeight,
                child: LayoutBuilder(
                  builder: (context, chartConstraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: (details) {
                        final double width = chartConstraints.maxWidth;
                        setState(() {
                          _draggingNeedle = 0;
                          selectedIndexGraph = null;

                          // Situem els punts al 25% i 75% com volies
                          selectedIndexStart = ChartLogic.calculateIndexFromX(
                            width * 0.25,
                            width,
                            distances,
                          );
                          selectedIndexEnd = ChartLogic.calculateIndexFromX(
                            width * 0.75,
                            width,
                            distances,
                          );
                        });
                      },

                      // 2. DETECCIÓ INICIAL DEL DIT (Calar quina agulla movem)
                      onPanDown: (details) {
                        final double x = details.localPosition.dx;
                        final double width = chartConstraints.maxWidth;

                        final double? xStart = selectedIndexStart != null
                            ? ChartLogic.indexToX(
                                selectedIndexStart!,
                                width,
                                distances,
                              )
                            : null;
                        final double? xEnd = selectedIndexEnd != null
                            ? ChartLogic.indexToX(
                                selectedIndexEnd!,
                                width,
                                distances,
                              )
                            : null;

                        setState(() {
                          if (xStart != null && (x - xStart).abs() < 30) {
                            _draggingNeedle = 1; // Inici
                          } else if (xEnd != null && (x - xEnd).abs() < 30) {
                            _draggingNeedle = 2; // Final
                          } else {
                            _draggingNeedle =
                                3; // Puntual (esborra rang anterior)
                            selectedIndexStart = null;
                            selectedIndexEnd = null;
                            selectedIndexGraph = ChartLogic.calculateIndexFromX(
                              x,
                              width,
                              distances,
                            );
                          }
                        });
                      },

                      // 3. MOVIMENT (onScaleUpdate es converteix en onPanUpdate)
                      onPanUpdate: (details) {
                        if (_draggingNeedle != 0) {
                          final double width = chartConstraints.maxWidth;
                          final double x = details.localPosition.dx;

                          setState(() {
                            if (_draggingNeedle == 1) {
                              selectedIndexStart =
                                  ChartLogic.calculateIndexFromX(
                                    x,
                                    width,
                                    distances,
                                  );
                            } else if (_draggingNeedle == 2) {
                              selectedIndexEnd = ChartLogic.calculateIndexFromX(
                                x,
                                width,
                                distances,
                              );
                            } else if (_draggingNeedle == 3) {
                              selectedIndexGraph =
                                  ChartLogic.calculateIndexFromX(
                                    x,
                                    width,
                                    distances,
                                  );
                            }
                          });
                        }
                      },

                      onPanEnd: (_) => _draggingNeedle = 0,
                      onPanCancel: () => _draggingNeedle = 0,
                      child: Stack(
                        children: [
                          // 1. ÀREA RESSALTADA (Resseguint el perfil de la muntanya)
                          if (selectedIndexStart != null &&
                              selectedIndexEnd != null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: RangeAreaPainter(
                                  startIndex: selectedIndexStart!,
                                  endIndex: selectedIndexEnd!,
                                  distances: distances,
                                  altitudes: altitudes,
                                  minY:
                                      altitudes.reduce(
                                        (a, b) => a < b ? a : b,
                                      ) -
                                      (altitudes.reduce(
                                                (a, b) => a > b ? a : b,
                                              ) -
                                              altitudes.reduce(
                                                (a, b) => a < b ? a : b,
                                              )) *
                                          0.1,
                                  maxY:
                                      altitudes.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) +
                                      (altitudes.reduce(
                                                (a, b) => a > b ? a : b,
                                              ) -
                                              altitudes.reduce(
                                                (a, b) => a < b ? a : b,
                                              )) *
                                          0.1,
                                  color: Colors.orange.withOpacity(0.2),
                                ),
                              ),
                            ),

                          // 2. EL GRÀFIC (Línia del perfil)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            key: chartKey,
                            child: LineChart(
                              _buildChartData(context, altitudes, distances),
                            ),
                          ),

                          // 3. AGULLES DE SELECCIÓ (RECUPERADES 🔥)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SelectionPainter(
                                // Posició agulla de drag (gràfic)
                                graphX: selectedIndexGraph != null
                                    ? (distances[selectedIndexGraph!] /
                                                  distances.last) *
                                              (chartConstraints.maxWidth - 48) +
                                          24
                                    : null,
                                graphIndex: selectedIndexGraph,

                                // Posició agulla inici (slider)
                                startX: selectedIndexStart != null
                                    ? (distances[selectedIndexStart!] /
                                                  distances.last) *
                                              (chartConstraints.maxWidth - 48) +
                                          24
                                    : null,
                                startIndex: selectedIndexStart,

                                // Posició agulla final (slider)
                                endX: selectedIndexEnd != null
                                    ? (distances[selectedIndexEnd!] /
                                                  distances.last) *
                                              (chartConstraints.maxWidth - 48) +
                                          24
                                    : null,
                                endIndex: selectedIndexEnd,

                                distances: distances,
                                altitudes: altitudes,
                                graphNeedleColor: graphNeedleColor,
                                sliderStartNeedleColor: sliderStartNeedleColor,
                                sliderEndNeedleColor: sliderEndNeedleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // HEADER
  Widget _buildHeader(
    BuildContext context,
    List<double> alts,
    List<double> dists,
  ) {
    final colors = Theme.of(context).colorScheme;

    // Prioritat: slider → agulla del gràfic → text neutre
    if (selectedIndexStart != null || selectedIndexEnd != null) {
      final startIdx = selectedIndexStart ?? 0;
      final endIdx = selectedIndexEnd ?? (dists.length - 1);

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (selectedIndexStart != null)
            _buildHeaderBox(
              color: sliderStartNeedleColor,
              altitude: alts[startIdx],
              distance: dists[startIdx],
            ),
          if (selectedIndexEnd != null)
            _buildHeaderBox(
              color: sliderEndNeedleColor,
              altitude: alts[endIdx],
              distance: dists[endIdx],
            ),
        ],
      );
    }

    if (selectedIndexGraph != null) {
      final idx = selectedIndexGraph!;
      return Column(
        children: [
          Text(
            "${alts[idx].toStringAsFixed(1)} m",
            style: TextStyle(
              color: graphNeedleColor,
              fontSize: 22, // abans 36
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            formatDistance(dists[idx]),
            style: TextStyle(
              color: graphNeedleColor.withAlpha(200),
              fontSize: 16, // abans 26
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Text(
      "Llisca sobre el gràfic o ajusta el rang",
      style: TextStyle(color: colors.onSurface.withAlpha(100)),
    );
  }

  Widget _buildHeaderBox({
    required Color color,
    required double altitude,
    required double distance,
  }) {
    return Column(
      children: [
        Text(
          "${altitude.toStringAsFixed(1)} m",
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          formatDistance(distance),
          style: TextStyle(
            color: color.withAlpha(200),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentStatsBar(
    List<double> alts,
    List<double> dists,
    List<DateTime>? times,
  ) {
    if (selectedIndexStart == null || selectedIndexEnd == null) {
      return const SizedBox(height: 50); // Més compacte, estil panell flotant
    }

    final start = selectedIndexStart! < selectedIndexEnd!
        ? selectedIndexStart!
        : selectedIndexEnd!;
    final end = selectedIndexStart! < selectedIndexEnd!
        ? selectedIndexEnd!
        : selectedIndexStart!;

    final distMetres = dists[end] - dists[start];
    double gain = 0;
    for (int i = start; i < end; i++) {
      double diff = alts[i + 1] - alts[i];
      if (diff > 0) gain += diff;
    }

    String durationStr = "00:00:00";
    String speedStr = "0.0 km/h";

    if (times != null && times.length > end) {
      final duration = times[end].difference(times[start]);
      durationStr = duration.toString().split('.').first.padLeft(8, "0");
      final hores = duration.inSeconds / 3600;
      if (hores > 0) {
        speedStr = "${((distMetres / 1000) / hores).toStringAsFixed(1)} km/h";
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tertiary, // Deep Green professional
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribució neta
        children: [
          // DISTÀNCIA
          _buildDarkStat(Icons.straighten, formatDistance(distMetres)),
          _buildVerticalDivider(),

          // TEMPS
          _buildDarkStat(Icons.timer, durationStr),
          _buildVerticalDivider(),

          // VELOCITAT
          _buildDarkStat(Icons.speed, speedStr),
          _buildVerticalDivider(),

          // DESNIVELL ACUMULAT (Gain)
          _buildDarkStat(Icons.terrain, "+${gain.toStringAsFixed(0)}m"),
        ],
      ),
    );
  }

  // Widget auxiliar per a cada dada estil "Panel"
  Widget _buildDarkStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Separador vertical subtil estil GPS
  Widget _buildVerticalDivider() {
    return Container(height: 14, width: 1, color: Colors.white12);
  }

  // Mètodes auxiliars actualitzats amb colors
  Widget _newStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.dark.withAlpha(120), // Etiqueta discreta
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: color, // Valor amb el color temàtic passat
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _newDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.dark.withAlpha(30), // Divisor molt subtil
    );
  }
}
