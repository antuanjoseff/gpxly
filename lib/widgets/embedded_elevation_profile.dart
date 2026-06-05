// lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/utils/distance_utils.dart';

class EmbeddedElevationProfile extends ConsumerStatefulWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  // Mantenemos los parámetros para reflejar el estado final, pero la animación viva será interna
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
  // 🛡️ RELLOTGES LOCALS ULTRA-FLUIDS SINS SETSTATE GLOBAL
  final ValueNotifier<int?> _localHoverIndex = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _localRangeStart = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _localRangeEnd = ValueNotifier<int?>(null);

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
    final int totalPointsCount = globalDists.isNotEmpty
        ? globalDists.length
        : 1;
    // lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 2 DE 2)
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
            // Nansa superior del panell
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

            if (!widget.isCollapsed)
              SizedBox(
                height: 160,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,

                      onLongPressStart: (details) {
                        final double x = details.localPosition.dx;
                        int realStart = ((x / width) * totalPointsCount)
                            .round()
                            .clamp(0, totalPointsCount - 1);
                        int step = (totalPointsCount * 0.15).round().clamp(
                          1,
                          totalPointsCount,
                        );
                        int realEnd = (realStart + step).clamp(
                          0,
                          totalPointsCount - 1,
                        );

                        // Actualizamos los Notifiers locales al instante (render ultra rápido de RAM)
                        _localRangeStart.value = realStart;
                        _localRangeEnd.value = realEnd;
                        _localHoverIndex.value = null;

                        // Notificamos arriba SOLO el valor del rango final
                        widget.onRangeSelected(realStart, realEnd);
                      },

                      onTapUp: (_) {
                        _localRangeStart.value = null;
                        _localRangeEnd.value = null;
                        _localHoverIndex.value = null;
                        widget.onClearSelection();
                      },

                      onPanDown: (details) {
                        final double x = details.localPosition.dx;
                        int realIdx = ((x / width) * totalPointsCount)
                            .round()
                            .clamp(0, totalPointsCount - 1);

                        _localHoverIndex.value = realIdx;
                        _localRangeStart.value = null;
                        _localRangeEnd.value = null;

                        // Solo notificamos al mapa en el primer contacto táctil
                        widget.onNeedleMove(realIdx);
                      },

                      onPanUpdate: (details) {
                        final double x = details.localPosition.dx;
                        int realIdx = ((x / width) * totalPointsCount)
                            .round()
                            .clamp(0, totalPointsCount - 1);

                        if (_localHoverIndex.value == realIdx) return;

                        // 🔥 LA CLAVE DEL ÉXITO: Cambiamos el valor local del Notifier.
                        // Esto muta el texto de la pantalla en microsegundos SIN llamar a widget.onNeedleMove(realIdx).
                        // El mapa se queda 100% quieto de fondo, eliminando por completo el ImageReader_JNI Warning.
                        _localHoverIndex.value = realIdx;
                      },

                      onPanEnd: (_) {
                        // 🏁 FI DEL DRAG: Cuando el usuario levanta el dedo, enviamos la posición final al mapa.
                        // MapLibre solo se redibujará UNA vez, yendo a 120 FPS limpios.
                        if (_localHoverIndex.value != null) {
                          widget.onNeedleMove(_localHoverIndex.value!);
                        }
                      },

                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Center(
                          // Usemos un AnimatedBuilder acoplado únicamente a los Notifiers locales
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _localHoverIndex,
                              _localRangeStart,
                              _localRangeEnd,
                            ]),
                            builder: (context, _) {
                              final currentHover =
                                  _localHoverIndex.value ??
                                  widget.selectedIndexGraph;
                              final currentStart =
                                  _localRangeStart.value ??
                                  widget.selectedIndexStart;
                              final currentEnd =
                                  _localRangeEnd.value ??
                                  widget.selectedIndexEnd;

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "HUD SÈNDA (VISTA LOCAL REFORZADA)",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Eix unificat: $totalPointsCount punts reals",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Mira: ${currentHover ?? '-'}  |  Rang: [${currentStart ?? '-'} , ${currentEnd ?? '-'}]",
                                    style: const TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
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
