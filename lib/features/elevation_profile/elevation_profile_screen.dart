import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gpxly/features/elevation_profile/painters/selection_painter.dart';

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

  // --- Conversió rang [0–1] → índexs ---
  (int, int) _rangeToIndexes(List<double> distances) {
    if (distances.isEmpty) return (0, 0);
    final maxIndex = distances.length - 1;

    final start = (selectedRange.start * maxIndex).round().clamp(0, maxIndex);
    final end = (selectedRange.end * maxIndex).round().clamp(0, maxIndex);

    return (start <= end) ? (start, end) : (end, start);
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

  // --- Drag sobre el gràfic ---
  void _handleGlobalTouch(
    Offset globalPos,
    List<double> distances,
    List<double> altitudes,
  ) {
    if (chartKey.currentContext == null) return;

    final box = chartKey.currentContext!.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPos);

    const double horizontalPadding = 24.0;
    final double left = horizontalPadding;
    final double right = box.size.width - horizontalPadding;

    if (local.dx < left || local.dx > right) return;

    final maxDist = distances.last;
    final xValue = (local.dx / box.size.width) * maxDist;

    final index = _closestIndexForDistance(distances, xValue);

    setState(() {
      // Mode: agulla del gràfic → esborrem agulles del slider
      activeHandle = ActiveHandle.none;
      selectedIndexStart = null;
      selectedIndexEnd = null;
      selectedIndexGraph = index;
    });
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

    // --- CÀLCUL DEL RANG VERTICAL (Mateixa lògica que al Painter) ---
    final minAlt = alts.reduce((a, b) => a < b ? a : b);
    final maxAlt = alts.reduce((a, b) => a > b ? a : b);
    final range = maxAlt - minAlt;

    // Forcem el 10% de marge dalt i baix per coincidir amb el SelectionPainter
    final forcedMinY = minAlt - (range * 0.1);
    final forcedMaxY = maxAlt + (range * 0.1);

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
              const SizedBox(height: 20),

              // HEADER
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.08,
                child: Center(
                  child: _buildHeader(context, altitudes, distances),
                ),
              ),

              _buildSegmentStatsBar(altitudes, distances, times),

              const SizedBox(height: 20),

              // GRÀFIC + HIGHLIGHT + AGULLES
              SizedBox(
                height: chartHeight,
                child: LayoutBuilder(
                  builder: (context, chartConstraints) {
                    final touchData = _buildTouchData(
                      distances,
                      altitudes,
                      chartConstraints.maxWidth,
                    );

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) {
                        _handleGlobalTouch(
                          d.globalPosition,
                          touchData.distances,
                          touchData.altitudes,
                        );
                      },
                      onPanUpdate: (d) {
                        _handleGlobalTouch(
                          d.globalPosition,
                          touchData.distances,
                          touchData.altitudes,
                        );
                      },
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

              // RANGE SLIDER + TOOLTIP
              LayoutBuilder(
                builder: (context, sliderConstraints) {
                  final sliderWidth = sliderConstraints.maxWidth;
                  final (startIndex, endIndex) = _rangeToIndexes(distances);

                  final startX = selectedRange.start * sliderWidth;
                  final endX = selectedRange.end * sliderWidth;
                  final chartBox =
                      chartKey.currentContext!.findRenderObject() as RenderBox;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: RangeSlider(
                          values: selectedRange,
                          onChanged: (values) {
                            setState(() {
                              // Detectem quin mànec canvia
                              if (values.start != selectedRange.start &&
                                  values.end == selectedRange.end) {
                                activeHandle = ActiveHandle.start;
                              } else if (values.end != selectedRange.end &&
                                  values.start == selectedRange.start) {
                                activeHandle = ActiveHandle.end;
                              }

                              selectedRange = values;

                              // Quan es mou el slider, esborrem agulla del gràfic
                              selectedIndexGraph = null;

                              // Actualitzem índexs d’agulles del slider
                              final maxDist = distances.last;
                              if (activeHandle == ActiveHandle.start) {
                                final distStart = values.start * maxDist;
                                selectedIndexStart = _closestIndexForDistance(
                                  distances,
                                  distStart,
                                );
                              } else if (activeHandle == ActiveHandle.end) {
                                final distEnd = values.end * maxDist;
                                selectedIndexEnd = _closestIndexForDistance(
                                  distances,
                                  distEnd,
                                );
                              }
                            });
                          },
                          onChangeEnd: (_) {
                            setState(() {
                              activeHandle = ActiveHandle.none;
                            });
                          },
                          divisions: distances.length > 1
                              ? distances.length - 1
                              : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
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
    // Si no hi ha rang seleccionat, retornem un espai buit
    if (selectedIndexStart == null || selectedIndexEnd == null) {
      return const SizedBox(height: 70);
    }

    // Ordenem índexs per si l'usuari els mou al revés
    final start = selectedIndexStart! < selectedIndexEnd!
        ? selectedIndexStart!
        : selectedIndexEnd!;
    final end = selectedIndexStart! < selectedIndexEnd!
        ? selectedIndexEnd!
        : selectedIndexStart!;

    final distMetres = dists[end] - dists[start];
    final desnivell = alts[end] - alts[start];

    String durationStr = "00:00";
    String speedStr = "0.0 km/h";

    if (times != null && times.length > end) {
      final duration = times[end].difference(times[start]);

      // Format Temps (mm:ss o h:mm:ss)
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      durationStr = duration.inHours > 0
          ? "${duration.inHours}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}"
          : "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";

      // Velocitat mitjana
      final hores = duration.inSeconds / 3600;
      if (hores > 0) {
        speedStr = "${((distMetres / 1000) / hores).toStringAsFixed(1)} km/h";
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _newStatItem("DISTÀNCIA", formatDistance(distMetres)),
          _newDivider(),
          _newStatItem("TEMPS", durationStr),
          _newDivider(),
          _newStatItem("VELOCITAT", speedStr),
          _newDivider(),
          _newStatItem(
            "DESNIVELL",
            "${desnivell >= 0 ? '+' : ''}${desnivell.toStringAsFixed(0)}m",
          ),
        ],
      ),
    );
  }

  Widget _newStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _newDivider() =>
      Container(width: 1, height: 20, color: Colors.black12);
}
