import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/remaining_track_data.dart';
import 'package:senda/notifiers/imported_track_notifier.dart'; // Tu provider de track importado
import 'package:senda/notifiers/track_notifier.dart'; // Tu provider de grabación real
import 'package:senda/utils/geo_utils.dart'; // Para haversineDistance

class RemainingTrackNotifier extends Notifier<RemainingTrackData?> {
  @override
  RemainingTrackData? build() {
    // 1. Escuchamos activamente los dos tracks
    final realTrack = ref.watch(trackProvider);
    final importedTrack = ref.watch(importedTrackProvider);

    // Si no hay grabación o no hay guía, el futuro es nulo
    if (realTrack.coordinates.isEmpty || importedTrack == null) {
      return null;
    }

    // 2. Punto de anclaje (Última posición GPS grabada)
    final currentGPS = realTrack.coordinates.last; // [lon, lat]
    final currentAlt = realTrack.altitudes.last;

    // Buscamos el índice más cercano en la guía
    final anchorIdx = _findClosestIndex(
      currentGPS[1], // lat
      currentGPS[0], // lon
      importedTrack.coordinates,
    );

    // 3. Recorte de listas (desde el anclaje hasta el final)
    List<double> futureAlts = importedTrack.altitudes.sublist(anchorIdx);
    List<DateTime> futureTimes = importedTrack.timestamps.sublist(anchorIdx);

    // Normalizamos distancias: que el punto actual sea el km 0.0 de la guía
    final double startDistOffset = importedTrack.distances[anchorIdx];
    final List<double> futureDists = importedTrack.distances
        .sublist(anchorIdx)
        .map((d) => d - startDistOffset)
        .toList();

    // 4. Ajuste de altitud (Umbral de 10m)
    final double guideAltAtAnchor = futureAlts.first;
    final double diff = currentAlt - guideAltAtAnchor;

    if (diff.abs() <= 10.0) {
      // Desplazamos toda la curva para que nazca de nuestra altura actual
      futureAlts = futureAlts.map((a) => a + diff).toList();
    }

    return RemainingTrackData(
      altitudes: futureAlts,
      distances: futureDists,
      timestamps: futureTimes,
      anchorIndex: anchorIdx,
    );
  }

  int _findClosestIndex(double lat, double lon, List<List<double>> coords) {
    double minDist = double.infinity;
    int minIndex = 0;
    for (int i = 0; i < coords.length; i++) {
      // Usamos tu función haversineDistance (asegúrate de que los parámetros coincidan)
      final d = haversineDistance(lat, lon, coords[i][1], coords[i][0]);
      if (d < minDist) {
        minDist = d;
        minIndex = i;
      }
    }
    return minIndex;
  }
}

// DEFINICIÓN DEL PROVIDER
final remainingTrackProvider =
    NotifierProvider<RemainingTrackNotifier, RemainingTrackData?>(
      RemainingTrackNotifier.new,
    );
