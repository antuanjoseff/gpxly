// lib/screens/elevations/elevation_profile_screen.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/screens/elevations/widgets/elevation_chart_widget.dart';
import 'package:senda/screens/elevations/widgets/header_legend_widget.dart';
import 'package:senda/screens/elevations/widgets/waypoints_list_widget.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/utils/distance_utils.dart';

class ElevationProfileScreen extends ConsumerStatefulWidget {
  const ElevationProfileScreen({super.key});

  @override
  ConsumerState<ElevationProfileScreen> createState() =>
      _ElevationProfileScreenState();
}

class _ElevationProfileScreenState
    extends ConsumerState<ElevationProfileScreen> {
  int? selectedIndexStart;
  int? selectedIndexEnd;
  int? selectedIndexGraph;
  // 1. Afegeix aquestes dues variables a dalt de tot de la classe de l'Estat, a vora de selectedIndexStart:
  int? _prevWpIndex; // Guarda l'índex del Waypoint (N - 1)
  int? _lastWpIndex; // Guarda l'índex del Waypoint (N)

  void _onToggleWaypoint(Waypoint wp) {
    final int idx = wp.trackIndex;

    setState(() {
      selectedIndexGraph = null; // Neteja el pin vertical flotant del gràfic

      // 🔄 GESTIÓ CONTINUA DE L'HISTORIAL: L'antic N passa a ser el nou N-1, i el toc actual és el nou N
      _prevWpIndex = _lastWpIndex;
      _lastWpIndex = idx;

      if (_prevWpIndex == null) {
        // 🟢 CAS 1: PRIMER CLIC DE WAYPOINT (N-1 encara és null)
        // Busquem quin dels dos extrems del Long Press inicial està més a prop del Waypoint actual (N)
        if (selectedIndexStart != null && selectedIndexEnd != null) {
          final int distToStart = (selectedIndexStart! - idx).abs();
          final int distToEnd = (selectedIndexEnd! - idx).abs();

          if (distToStart <= distToEnd) {
            // El Waypoint N està més a vora de l'inici. Per tant, l'inici del Long Press és el nostre (N-1)
            _prevWpIndex = selectedIndexStart;
          } else {
            // El Waypoint N està más a vora del final. El final del Long Press esdevé el nostre (N-1)
            _prevWpIndex = selectedIndexEnd;
          }
        } else {
          // Salvaguarda per si l'usuari no hagués fet cap Long Press abans
          _prevWpIndex = idx;
        }
      }

      // 🟢 CAS 2: SEGON CLIC I POSTERIORS (N i N-1 ja estan perfectament definits)
      // Ara el tram seleccionat queda definit estrictament entre _lastWpIndex (N) i _prevWpIndex (N-1).
      // Com que N pot ser l'inici o el final (i el mateix amb N-1), fem una comprovació purament numèrica
      // per col·locar el més petit a l'esquerra del gràfic i el més gran a la dreta, salvant la GPU.
      if (_prevWpIndex != null && _lastWpIndex != null) {
        if (_prevWpIndex! <= _lastWpIndex!) {
          selectedIndexStart = _prevWpIndex;
          selectedIndexEnd = _lastWpIndex;
        } else {
          selectedIndexStart = _lastWpIndex;
          selectedIndexEnd = _prevWpIndex;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Escuchadores de datos de Riverpod
    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);
    final remaining = ref.watch(remainingTrackProvider);
    final follow = ref.watch(navigationProvider);

    final realAlts = real.altitudes;
    final realDists = real.distances;

    final double pastLastDist = realDists.isNotEmpty ? realDists.last : 0.0;
    final bool shouldShowFuture =
        follow.isFollowing && !follow.isOffTrack && remaining != null;

    // ─────────────────────────────────────────────────────────────────────────
    // 🆕 LÒGICA DE FINESTRA ASIMÈTRICA: MODIFICADES NOMÉS LES ALÇADES FUTURES
    // ─────────────────────────────────────────────────────────────────────────
    late List<double> futureAlts;
    late List<double> futureDistsGlobal;

    if (shouldShowFuture) {
      // Proporción exacta para que el futuro ocupe siempre el 25% de la gráfica visible
      final double maxFutureDistanceVisible = pastLastDist / 3.0;

      final remainingAlts = remaining!.altitudes;
      final remainingDists = remaining.distances;

      // 🧮 CALCULEM L'OFFSET ENTRE L'ÚLTIM PUNT REAL I EL PRIMER FUTUR
      double elevationOffset = 0.0;
      if (realAlts.isNotEmpty && remainingAlts.isNotEmpty) {
        elevationOffset = realAlts.last - remainingAlts.first;
      }

      final List<double> tempFutureAlts = [];
      final List<double> tempFutureDists = [];

      for (int i = 0; i < remainingDists.length; i++) {
        // Solo añadimos los puntos del futuro que entran dentro de este 25% espacial
        if (remainingDists[i] <= maxFutureDistanceVisible) {
          // Apliquem l'offset sumant la diferència a cada punt futur per evitar el graó
          tempFutureAlts.add(remainingAlts[i] + elevationOffset);
          tempFutureDists.add(pastLastDist + remainingDists[i]);
        } else {
          break; // Ventana llena, detenemos el bucle
        }
      }

      futureAlts = tempFutureAlts;
      futureDistsGlobal = tempFutureDists;
    } else {
      // Si no hay navegación activa, mostramos la ruta de referencia completa
      final importedDists = calculateDistances(imported?.coordinates ?? []);
      futureAlts = imported?.altitudes ?? [];
      futureDistsGlobal = importedDists;
    }

    // Unificamos las listas filtradas para el eje global de coordenadas
    final globalDists = <double>[...realDists, ...futureDistsGlobal];
    final globalAlts = <double>[...realAlts, ...futureAlts];

    // ─────────────────────────────────────────────
    // 3) WAYPOINTS
    // ─────────────────────────────────────────────
    final recordedWps = ref.watch(waypointsProvider);
    final importedWps = ref.watch(importedWaypointsProvider);

    final trackColor = ref.watch(trackSettingsProvider).color;
    final importedTrackColor = ref.watch(importedTrackSettingsProvider).color;

    final recordedWaypointGlobalDists = recordedWps
        .where((wp) => wp.trackIndex >= 0 && wp.trackIndex < realDists.length)
        .map((wp) => realDists[wp.trackIndex])
        .toList(growable: false);

    final importedWaypointGlobalDists = <double>[];

    if (!shouldShowFuture) {
      final importedDists = calculateDistances(imported?.coordinates ?? []);
      for (final wp in importedWps) {
        if (wp.trackIndex < importedDists.length) {
          importedWaypointGlobalDists.add(importedDists[wp.trackIndex]);
        }
      }
    } else {
      for (final wp in importedWps) {
        final idx = wp.trackIndex;
        if (idx < remaining!.anchorIndex) continue;

        final futureIdx = idx - remaining.anchorIndex;
        if (futureIdx < remaining.distances.length) {
          importedWaypointGlobalDists.add(
            pastLastDist + remaining.distances[futureIdx],
          );
        }
      }
    }

    final hasReal = realAlts.isNotEmpty;
    final hasFuture = futureAlts.isNotEmpty;

    // ─────────────────────────────────────────────
    // 5) ESTADÍSTIQUES DEL TRAM SELECCIONAT
    // ─────────────────────────────────────────────
    double? rangeDistance;
    double? rangeAscent;
    double? rangeDescent;
    Duration? rangeTime;

    if (selectedIndexStart != null && selectedIndexEnd != null) {
      final start = selectedIndexStart!;
      final end = selectedIndexEnd!;

      rangeDistance = (globalDists[end] - globalDists[start]).abs();

      double ascent = 0;
      double descent = 0;

      for (int i = start + 1; i <= end; i++) {
        final diff = globalAlts[i] - globalAlts[i - 1];
        if (diff > 0) ascent += diff;
        if (diff < 0) descent += diff.abs();
      }

      rangeAscent = ascent;
      rangeDescent = descent;

      if (real.timestamps.length > end && real.timestamps.length > start) {
        final t0 = real.timestamps[start];
        final t1 = real.timestamps[end];
        rangeTime = t1.difference(t0);
      }
    }

    // lib/screens/elevations/elevation_profile_screen.dart (BLOC 2 DE 2)
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          t.elevationProfile,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          HeaderLegendWidget(
            hasReal: hasReal,
            hasImported: hasFuture,
            primaryIsReal: true,
            rangeStartIndex: selectedIndexStart,
            rangeEndIndex: selectedIndexEnd,
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            height: MediaQuery.of(context).size.height * 0.32,
            child: ElevationChartWidget(
              pastAlts: realAlts,
              pastDists: realDists,
              futureAlts: futureAlts,
              futureDistsGlobal: futureDistsGlobal,
              selectedIndexStart: selectedIndexStart,
              selectedIndexEnd: selectedIndexEnd,
              selectedIndexGraph: selectedIndexGraph,
              recordedWaypointGlobalDists: recordedWaypointGlobalDists,
              importedWaypointGlobalDists: importedWaypointGlobalDists,
              realColor: trackColor,
              importedColor: importedTrackColor,
              graphNeedleColor: AppColors.primary,
              sliderStartNeedleColor: Colors.green,
              sliderEndNeedleColor: Colors.red,
              onNeedleMove: (idx) => setState(() {
                selectedIndexGraph = idx;
              }),
              onRangeSelected: (start, end) => setState(() {
                selectedIndexStart = start;
                selectedIndexEnd = end;
                selectedIndexGraph = null;
                // 🎯 CRÍTIC: Un nou Long Press esborra l'historial de Waypoints per arrencar net el cicle N i N-1
                _prevWpIndex = null;
                _lastWpIndex = null;
              }),
              onClearSelection: () => setState(() {
                selectedIndexStart = null;
                selectedIndexEnd = null;
                selectedIndexGraph = null;
                _prevWpIndex = null;
                _lastWpIndex = null;
              }),
              // onRangeSelected: (start, end) => setState(() {
              //   selectedIndexStart = start;
              //   selectedIndexEnd = end;
              //   selectedIndexGraph = null;
              // }),
              // onClearSelection: () => setState(() {
              //   selectedIndexStart = null;
              //   selectedIndexEnd = null;
              //   selectedIndexGraph = null;
              // }),
            ),
          ),

          // ───────────────────────────────────────────────────────────────────
          // ✅ NUEVO PANEL DE SELECCIÓN MANTENIDO TOTALMENTE INTACTO
          // ───────────────────────────────────────────────────────────────────
          if (rangeDistance != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la sección del tramo
                    Text(
                      t.statRangeSelectedTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Distancia del tramo
                    Text(
                      "${t.statRangeDistance}: ${(rangeDistance! / 1000).toStringAsFixed(2)} km",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Desnivel positivo acumulado del tramo
                    Text(
                      "${t.statRangeAscent}: ${rangeAscent!.toStringAsFixed(0)} m",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Desnivel negativo acumulado del tramo
                    Text(
                      "${t.statRangeDescent}: ${rangeDescent!.toStringAsFixed(0)} m",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Tiempo invertido en el tramo
                    if (rangeTime != null)
                      Text(
                        "${t.statRangeTime}: ${rangeTime!.inMinutes} min",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          WaypointsListWidget(
            recorded: recordedWps,
            imported: importedWps,
            selectedStartIndex: selectedIndexStart,
            selectedEndIndex: selectedIndexEnd,
            onToggleWaypoint: _onToggleWaypoint,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
