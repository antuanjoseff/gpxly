// lib/notifiers/helpers/elevation_magnet_helper.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/utils/map_layers.dart';

class ElevationMagnetHelper {
  // 🛡️ Candado estático: evita colisiones en la GPU si Riverpod o los movimientos
  // del mapa disparan este método múltiples veces por milisegundo.
  static bool _isRecalculating = false;

  /// 🧲 Força el càlcul de l'imant i pinta immediatament a la GPU del mapa
  static Future<void> recalcularIActualitzar({
    required WidgetRef ref,
    required MapLibreMapController mapController,
  }) async {
    // Si ya se está procesando un cálculo y pintando en el mapa, ignoramos esta llamada
    if (_isRecalculating) return;
    _isRecalculating = true;

    try {
      final notifier = ref.read(elevationSelectionProvider.notifier);

      // 🚀 CIRURGIA PAS 1: LLEGIM EL CENTRE DIRECTE DE LA CÀMERA DE LA GPU
      // Evitem el retard o arrofoniment de text del provider i obtenim els decimals pures de precisió
      final CameraPosition? currentCamera = mapController.cameraPosition;
      if (currentCamera == null) return;

      final double centerLat = currentCamera.target.latitude;
      final double centerLon = currentCamera.target.longitude;

      // 2. Esbrinem si estem gravant o usant una ruta importada
      final bool isRecording =
          ref.read(trackRecordingProvider).recordingState ==
          RecordingState.recording;

      final List<List<double>> coordsAEvaluar = isRecording
          ? ref.read(trackRecordingProvider).coordinates
          : ref.read(importedTrackProvider.notifier).visibleCoordinates;

      if (coordsAEvaluar.isEmpty) return;

      int nearestIndex = 0;
      double minDistance = double.maxFinite;

      // 🚀 CIRURGIA PAS 3: EL BUCLE GEOMÈTRIC CORREGIT PER LA CURVATURA (COSINUS DE LA LATITUD)
      // Multipliquem la diferència de longitud pel cosinus de la latitud per corregir l'ovalat geomètric de la Terra
      final double radiAnemometre = math.cos(centerLat * math.pi / 180.0);

      for (int i = 0; i < coordsAEvaluar.length; i++) {
        final double ptLon = coordsAEvaluar[i][0]; // [0] és la Longitud
        final double ptLat = coordsAEvaluar[i][1]; // [1] és la Latitud

        final double dLat = ptLat - centerLat;
        // 🧲 Apliquem la correcció de projecció a la longitud per tener una distància real en metres a la pantalla
        final double dLon = (ptLon - centerLon) * radiAnemometre;
        final double distSq = (dLat * dLat) + (dLon * dLon);

        if (distSq < minDistance) {
          minDistance = distSq;
          nearestIndex = i;
        }
      }

      // 4. Sincronització de l'estat a Riverpod (Es manté intacte)
      notifier.updateProvisionalEnd(nearestIndex);

      final liveState = ref.read(elevationSelectionProvider);
      notifier.updateTemporaryRange(
        startIndex: liveState.startTrackIndex,
        endIndex: nearestIndex,
      );

      // 🟢 MODIFICACIÓ DE SEGURETAT: Li passem explícitament el selectionMode actual
      // perquè en fer el copyWith cap a la línia de la GPU no es destrueixi en ple moviment.
      final geometryState = liveState.copyWith(
        startTrackIndex: liveState.startTrackIndex,
        endTrackIndex:
            liveState.mapToolState == MapSelectionToolState.selectingEnd
            ? nearestIndex
            : null,
        provisionalEndIndex: nearestIndex,
        mode: liveState.mapToolState == MapSelectionToolState.selectingEnd
            ? SelectionMode.range
            : SelectionMode.single,
        selectionMode: liveState.selectionMode, // 👈 PROTECCIÓ EN MOVIMENT
      );

      // 5. Pintem a la GPU esperando a que la operación nativa finalice
      await updateSelectedSegmentGeometry(
        mapController,
        geometryState,
        coordsAEvaluar,
      );
    } catch (e) {
      debugPrint("⚠️ Errada en el helper de magnetisme: $e");
    } finally {
      _isRecalculating = false;
    }
  }
}
