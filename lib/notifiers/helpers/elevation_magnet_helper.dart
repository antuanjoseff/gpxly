// lib/notifiers/helpers/elevation_magnet_helper.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/gps_speed_notifier.dart';
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

      // 1. Recuperem les coordenades actuals del centre del mapa
      final double centerLat = ref.read(mapCenterLatProvider);
      final double centerLon = ref.read(mapCenterLonProvider);

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

      // 3. El bucle geomètric de precisió
      for (int i = 0; i < coordsAEvaluar.length; i++) {
        final double ptLon = coordsAEvaluar[i][0]; // [0] és la Longitud
        final double ptLat = coordsAEvaluar[i][1]; // [1] és la Latitud

        final double dLat = ptLat - centerLat;
        final double dLon = ptLon - centerLon;
        final double distSq = (dLat * dLat) + (dLon * dLon);

        if (distSq < minDistance) {
          minDistance = distSq;
          nearestIndex = i;
        }
      }

      // 4. Sincronització de l'estat a Riverpod
      notifier.updateProvisionalEnd(nearestIndex);

      final liveState = ref.read(elevationSelectionProvider);
      notifier.updateTemporaryRange(
        startIndex: liveState.startTrackIndex,
        endIndex: nearestIndex,
      );

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
      );

      // 5. Pintem a la GPU esperando a que la operación nativa finalice
      // Nota: Asegúrate de añadir el 'await' aquí. Si 'updateSelectedSegmentGeometry'
      // no es un Future, edítala para que use la lógica de comprobar con getSourceIds()
      await updateSelectedSegmentGeometry(
        mapController,
        geometryState,
        coordsAEvaluar,
      );
    } catch (e) {
      debugPrint("⚠️ Errada en el helper de magnetisme: $e");
    } finally {
      // Liberamos el candado pase lo que pase
      _isRecalculating = false;
    }
  }
}
