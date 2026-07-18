// lib/notifiers/imported_track_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/utils/geo_utils.dart';

class ImportedTrackNotifier extends Notifier<Track?> {
  // Guardem de forma efímera fins a quin punt hem de dibuixar al mapa
  int _simulationIndex = -1;

  @override
  Track? build() {
    return null;
  }

  void setTrack(Track t) {
    _simulationIndex = -1; // Reset de control
    state = t;
  }

  void clear() {
    _simulationIndex = -1;
    state = null;
  }

  // ─────────────────────────────────────────────────────────────
  // 🎮 CONTROL VISUAL DE LA SIMULACIÓ PROGRESSIVA
  // ─────────────────────────────────────────────────────────────
  void updateSimulationProgress(int index) {
    _simulationIndex = index;
    // Forcem la notificació a Riverpod per reactivar el ref.listen del mapa
    state = state?.copyWith();
  }

  void resetSimulationProgress() {
    _simulationIndex = -1;
    state = state?.copyWith();
  }

  // 📐 GETTER MODIFICAT: Si estem simulant, només exposa la llista tallada al mapa!
  List<List<double>> get visibleCoordinates {
    final t = state;
    if (t == null || t.points.isEmpty) return const [];

    // Si NO estem simulant (_simulationIndex == -1), mostrem la ruta completa estàndard
    if (_simulationIndex == -1) {
      return t.points
          .map((p) => [p.position.longitude, p.position.latitude])
          .toList();
    }

    // 🔥 SI ESTEM SIMULANT: Tallem la llista des del punt 0 fins a l'índex actual del simulador!
    final limit = (_simulationIndex + 1).clamp(0, t.points.length);
    return t.points
        .sublist(0, limit)
        .map((p) => [p.position.longitude, p.position.latitude])
        .toList();
  }

  void reverseTrack() {
    final t = state;
    if (t == null || t.points.isEmpty) return;

    _simulationIndex = -1;
    final reversedPoints = _recomputeCumulativeDistances(
      t.points.reversed.toList(),
    );
    state = t.copyWith(points: reversedPoints);
  }

  List<UserPosition> _recomputeCumulativeDistances(List<UserPosition> points) {
    double acc = 0.0;
    final rebuilt = <UserPosition>[];

    for (int i = 0; i < points.length; i++) {
      if (i > 0) {
        acc += haversineDistance(
          points[i - 1].position.latitude,
          points[i - 1].position.longitude,
          points[i].position.latitude,
          points[i].position.longitude,
        );
      }
      rebuilt.add(points[i].copyWith(distanceAtPoint: acc));
    }

    return rebuilt;
  }
}

final importedTrackProvider = NotifierProvider<ImportedTrackNotifier, Track?>(
  ImportedTrackNotifier.new,
);
