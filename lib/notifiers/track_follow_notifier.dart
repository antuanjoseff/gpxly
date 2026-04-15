import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/models/track_follow_state.dart';
import 'package:gpxly/notifiers/permissions_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/utils/geo_utils.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class TrackFollowNotifier extends Notifier<TrackFollowState> {
  List<LatLng> _importedTrack = [];
  StreamSubscription? _locationSub;

  @override
  TrackFollowState build() {
    ref.onDispose(() {
      _locationSub?.cancel();
    });

    return const TrackFollowState(
      isFollowing: false,
      isOffTrack: false,
      distanceToTrack: 0,
    );
  }

  // ------------------------------------------------------------
  // Assignar track importat
  // ------------------------------------------------------------
  void setImportedTrack(List<LatLng> coords) {
    _importedTrack = coords;
  }

  // ------------------------------------------------------------
  // Iniciar seguiment (amb gravació automàtica si cal)
  // ------------------------------------------------------------
  void startFollowingWithRecording(BuildContext context) async {
    // 1. Comprovar permisos
    final permNotifier = ref.read(permissionsProvider.notifier);
    await permNotifier.checkPermissions();

    final hasPerm = ref.read(permissionsProvider).hasPermission;

    if (!hasPerm) {
      // Demanar permisos
      await permNotifier.requestPermissions();

      final granted = ref.read(permissionsProvider).hasPermission;
      if (!granted) {
        // No podem seguir sense permisos
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cal donar permisos de localització')),
        );
        return;
      }
    }

    // 2. Iniciar gravació si no n’hi ha
    final realTrack = ref.read(trackProvider);
    final hasReal = realTrack.coordinates.isNotEmpty;

    if (!hasReal) {
      ref.read(trackProvider.notifier).startRecording(context);
    }

    // 3. Activar mode seguiment
    state = state.copyWith(isFollowing: true);
  }

  void stopFollowing() {
    state = state.copyWith(
      isFollowing: false,
      isOffTrack: false,
      distanceToTrack: 0,
    );
  }

  // ------------------------------------------------------------
  // Actualitzar posició de l’usuari
  // ------------------------------------------------------------
  void updateUserPosition(LatLng userPos) {
    if (!state.isFollowing || _importedTrack.isEmpty) return;

    final dist = _distanceToClosestPoint(userPos, _importedTrack);

    state = state.copyWith(
      distanceToTrack: dist,
      isOffTrack: dist > 30, // llindar configurable
    );
  }

  // ------------------------------------------------------------
  // Distància mínima punt → track
  // ------------------------------------------------------------
  double _distanceToClosestPoint(LatLng p, List<LatLng> track) {
    double minDist = double.infinity;

    for (final t in track) {
      final d = distanceBetween(
        p.latitude,
        p.longitude,
        t.latitude,
        t.longitude,
      );

      if (d < minDist) minDist = d;
    }

    return minDist;
  }
}

final trackFollowNotifierProvider =
    NotifierProvider<TrackFollowNotifier, TrackFollowState>(
      TrackFollowNotifier.new,
    );
