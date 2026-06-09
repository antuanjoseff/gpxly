// lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // 🟢 NETEJA TOTAL: S'esborren completament tots els paràmetres de selecció i els callbacks residuals d'aquí.
  const EmbeddedElevationProfile({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  ConsumerState<EmbeddedElevationProfile> createState() =>
      _EmbeddedElevationProfileState();
}

class _EmbeddedElevationProfileState
    extends ConsumerState<EmbeddedElevationProfile> {
  // 🛡️ NOTIFIERS LOCALS DE MEMÒRIA RAM CONTRA EL COL·LAPSE DE VIDEO D'ANDROIDE
  final ValueNotifier<int?> _localHoverIndex = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _localRangeStart = ValueNotifier<int?>(null);
  final ValueNotifier<int?> _localRangeEnd = ValueNotifier<int?>(null);
  DateTime _lastTouchMoveTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _touchThrottleDurationMs = 32;
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
    // lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 2 DE 2)
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
        color: AppColors.skyBlueDark.withAlpha(214),
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
            // Nansa superior del panell flotant
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

            // Contenidor del perfil gràfic d'altituds
            if (!widget.isCollapsed)
              SizedBox(
                height: 166,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _localHoverIndex,
                    _localRangeStart,
                    _localRangeEnd,
                  ]),
                  builder: (context, _) {
                    return ElevationChartWidget(
                      pastAlts: realAlts,
                      pastDists: realDists,
                      futureAlts: futureAlts,
                      futureDistsGlobal: futureDistsGlobal,
                      recordedWaypointGlobalDists: recordedWaypointGlobalDists,
                      importedWaypointGlobalDists: importedWaypointGlobalDists,
                      realColor: trackColor,
                      importedColor: importedTrackColor,
                      graphNeedleColor: AppColors.primary,
                      sliderStartNeedleColor: Colors.green,
                      sliderEndNeedleColor: Colors.red,
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
