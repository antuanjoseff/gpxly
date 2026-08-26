// lib/notifiers/waypoint_eta_notifier.dart
//
// Provider que exposa l'ETA al següent waypoint seguint el track guia.
//
// RIGOR ARQUITECTÒNIC:
//  - SEMPRE s'alimenta del track guia (importedTrackProvider), mai del track
//    gravat. Gravar o no gravar és irrellevant per a l'ETA.
//  - Només calcula quan s'està seguint un track (navigationProvider.isFollowing).
//  - La lògica de càlcul viu a TrackNavigationEngine (lib/services/); aquest
//    notifier només hi connecta els providers i conserva l'últim resultat.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/live_follow_stats_notifier.dart';
import 'package:strack_rec/notifiers/location_notifier.dart';
import 'package:strack_rec/notifiers/navigation_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/notifiers/waypoints_imported_notifier.dart';
import 'package:strack_rec/services/track_navigation_engine.dart';

class WaypointEtaNotifier extends Notifier<TrackNavigationResult> {
  final TrackNavigationEngine _engine = TrackNavigationEngine();
  int _lastFingerprint = 0;

  @override
  TrackNavigationResult build() {
    final imported = ref.watch(importedTrackProvider);
    final waypoints = ref.watch(importedWaypointsProvider);
    final isFollowing = ref.watch(navigationProvider).isFollowing;
    final position = ref.watch(locationProvider);

    if (!isFollowing || imported == null || imported.points.isEmpty) {
      _lastFingerprint = 0;
      return TrackNavigationResult.empty;
    }

    // (Re)configurem el motor NOMÉS si la guia o els waypoints han canviat
    // (nova importació, reverse, etc.). Això conserva la velocitat filtrada
    // i el progrés entre rebuilds causats pel GPS.
    // La fingerprint es calcula sobre les DADES NOVES dels providers, no
    // sobre l'estat intern de l'engine.
    final fingerprint = TrackNavigationEngine.fingerprintOf(
      imported,
      waypoints,
    );
    if (fingerprint != _lastFingerprint) {
      _engine.configure(track: imported, waypoints: waypoints);
      _lastFingerprint = fingerprint;
    }

    // Si encara no hi ha GPS, no hi ha ETA.
    if (position == null) {
      return TrackNavigationResult.empty;
    }

    final isRecording = ref.watch(
      trackRecordingProvider.select(
        (t) => t.recordingState == RecordingState.recording,
      ),
    );

    final double avgSpeedKmh = isRecording
        ? ref.watch(trackRecordingProvider.select((t) => t.stats.averageSpeed))
        : ref.watch(liveFollowStatsProvider.select((s) => s.averageSpeedKmh));

    final double averageSpeedMps = avgSpeedKmh / 3.6;

    // Cada rebuild causat per una nova posició GPS recalcula l'estat.
    return _engine.updatePosition(
      position.position,
      time: position.timestamp,
      averageSpeedMps: averageSpeedMps,
    );
  }

  /// Inverteix el sentit de la navegació a nivell d'ETA (cridat quan
  /// NavigationNotifier reverteix el track). El reverse reindexa els
  /// waypoints → la fingerprint canvia → el proper build reconfigura
  /// l'engine automàticament. Aquí només reiniciem el filtre de velocitat.
  void reverse() {
    _engine.resetProgress();
  }
}

final waypointEtaProvider =
    NotifierProvider<WaypointEtaNotifier, TrackNavigationResult>(
      WaypointEtaNotifier.new,
    );
