// lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';
import 'package:senda/notifiers/track_settings_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/notifiers/waypoints_recorded_notifier.dart';
import 'package:senda/screens/elevations/widgets/elevation_chart_widget.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/utils/distance_utils.dart';

class EmbeddedElevationProfile extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  // Parámetros de sincronización finales del mapa
  final int? selectedIndexStart;
  final int? selectedIndexEnd;
  final int? selectedIndexGraph;

  final void Function(int index) onNeedleMove;
  final void Function(int start, int end) onRangeSelected;
  final VoidCallback onClearSelection;

  const EmbeddedElevationProfile({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.selectedIndexStart,
    required this.selectedIndexEnd,
    required this.selectedIndexGraph,
    required this.onNeedleMove,
    required this.onRangeSelected,
    required this.onClearSelection,
  });

  @override
  ConsumerState<EmbeddedElevationProfile> createState() =>
      _EmbeddedElevationProfileState();
}

class _EmbeddedElevationProfileState
    extends ConsumerState<EmbeddedElevationProfile> {
  // 🛡️ MOTOR DE GESTOS ULTRA-FLUIDO DE BAJA LATENCIA (Consumo cero de GPU en arrastre)
  final ValueNotifier<int?> _localHoverIndex = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _localRangeStart = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _localRangeEnd = ValueNotifier<int?>(null);

  // Memoria caché de distancias trigonométricas
  List<double> _cachedImportedDists = [];
  int _lastCoordinatesLength = 0;

  @override
  void dispose() {
    _localHoverIndex.dispose();
    _localRangeStart.dispose();
    _localRangeEnd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;

    // Escuchadores de dades de tu ecosistema Riverpod
    final real = ref.watch(trackRecordingProvider);
    final imported = ref.watch(importedTrackProvider);
    final remaining = ref.watch(remainingTrackProvider);
    final follow = ref.watch(navigationProvider);

    final realAlts = real.altitudes;
    final realDists = real.distances;
    final double pastLastDist = realDists.isNotEmpty ? realDists.last : 0.0;
    final bool shouldShowFuture =
        follow.isFollowing && !follow.isOffTrack && remaining != null;

    if (realAlts.isEmpty && (imported == null || imported.altitudes.isEmpty)) {
      return const SizedBox.shrink();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 🧮 TU LÓGICA DE VENTANA ASIMÉTRICA DE SENDA (Mantenida intacta)
    // ─────────────────────────────────────────────────────────────────────────
    late List<double> futureAlts;
    late List<double> futureDistsGlobal;

    if (shouldShowFuture) {
      final double maxFutureDistanceVisible = pastLastDist / 3.0;
      final remainingAlts = remaining!.altitudes;
      final remainingDists = remaining.distances;

      double elevationOffset = 0.0;
      if (realAlts.isNotEmpty && remainingAlts.isNotEmpty) {
        elevationOffset = realAlts.last - remainingAlts.first;
      }

      final List<double> tempFutureAlts = [];
      final List<double> tempFutureDists = [];

      for (int i = 0; i < remainingDists.length; i++) {
        if (remainingDists[i] <= maxFutureDistanceVisible) {
          tempFutureAlts.add(remainingAlts[i] + elevationOffset);
          tempFutureDists.add(pastLastDist + remainingDists[i]);
        } else {
          break;
        }
      }
      futureAlts = tempFutureAlts;
      futureDistsGlobal = tempFutureDists;
    } else {
      if (imported != null && imported.coordinates.isNotEmpty) {
        if (_lastCoordinatesLength != imported.coordinates.length) {
          _lastCoordinatesLength = imported.coordinates.length;
          _cachedImportedDists = calculateDistances(imported.coordinates);
        }
        futureDistsGlobal = _cachedImportedDists;
      } else {
        _lastCoordinatesLength = 0;
        _cachedImportedDists = [];
        futureDistsGlobal = [];
      }
      futureAlts = imported?.altitudes ?? [];
    }

    final globalDists = <double>[...realDists, ...futureDistsGlobal];
    // lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 2 DE 2)
    // ─────────────────────────────────────────────
    // WAYPOINTS Y AJUSTES DE COLOR DE SENDA
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
      for (final wp in importedWps) {
        if (wp.trackIndex < futureDistsGlobal.length) {
          importedWaypointGlobalDists.add(futureDistsGlobal[wp.trackIndex]);
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: widget.isCollapsed
          ? (38.0 + systemBottomPadding)
          : (220.0 + systemBottomPadding),
      padding: EdgeInsets.only(bottom: systemBottomPadding),
      decoration: BoxDecoration(
        color: AppColors.skyBlueDark.withOpacity(0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // ─── 1. LA NANSA DE CONTROL SUPERIOR (Estable de fàbrica) ───
            GestureDetector(
              onTap: widget.onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                height: 36,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(90),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),

            // ─── 2. RENDERIZACIÓN EXCLUSIVA DE TU GRÁFICO ORIGINAL DE SENDA ───
            if (!widget.isCollapsed)
              SizedBox(
                height: 160,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _localHoverIndex,
                    _localRangeStart,
                    _localRangeEnd,
                  ]),
                  builder: (context, _) {
                    // Combinamos los Notifiers de arrastre rápido local con el estado guardado final
                    final currentHover =
                        _localHoverIndex.value ?? widget.selectedIndexGraph;
                    final currentStart =
                        _localRangeStart.value ?? widget.selectedIndexStart;
                    final currentEnd =
                        _localRangeEnd.value ?? widget.selectedIndexEnd;

                    return ElevationChartWidget(
                      pastAlts: realAlts,
                      pastDists: realDists,
                      futureAlts: futureAlts,
                      futureDistsGlobal: futureDistsGlobal,

                      // Inyectamos las referencias fluidas de memoria RAM
                      selectedIndexStart: currentStart,
                      selectedIndexEnd: currentEnd,
                      selectedIndexGraph: currentHover,

                      recordedWaypointGlobalDists: recordedWaypointGlobalDists,
                      importedWaypointGlobalDists: importedWaypointGlobalDists,
                      realColor: trackColor,
                      importedColor: importedTrackColor,
                      graphNeedleColor: AppColors.skyBlue,
                      sliderStartNeedleColor: Colors.green,
                      sliderEndNeedleColor: Colors.red,

                      // 🔥 CAPTURA DE CALLBACKS: Sincronización atómica optimizada para Vulkan
                      onNeedleMove: (idx) {
                        if (_localHoverIndex.value == idx) return;
                        _localHoverIndex.value = idx;
                        _localRangeStart.value = null;
                        _localRangeEnd.value = null;
                      },
                      onRangeSelected: (start, end) {
                        if (_localRangeStart.value == start &&
                            _localRangeEnd.value == end)
                          return;
                        _localRangeStart.value = start;
                        _localRangeEnd.value = end;
                        _localHoverIndex.value = null;

                        // Los rangos fijados (LongPress) sí notifican arriba directo porque no son ráfagas
                        widget.onRangeSelected(start, end);
                      },
                      onClearSelection: () {
                        _localHoverIndex.value = null;
                        _localRangeStart.value = null;
                        _localRangeEnd.value = null;
                        widget.onClearSelection();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
