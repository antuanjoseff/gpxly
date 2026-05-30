// lib/notifiers/remaining_track_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/remaining_track_data.dart';
import 'package:senda/notifiers/imported_track_notifier.dart'; // El teu provider de track importat
// ✅ ADAPTAT: Importem el nou gravador i el model de track unificat
import 'package:senda/notifiers/recording_notifier.dart'; // Bloc 2: Gravació neta
import 'package:senda/utils/geo_utils.dart'; // Per a haversineDistance

class RemainingTrackNotifier extends Notifier<RemainingTrackData?> {
  @override
  RemainingTrackData? build() {
    // 1. 🔗 DATA PIPELINING: Escuchamos activamente los dos tracks (El gravat nou i l'importat)
    final realTrack = ref.watch(
      trackRecordingProvider,
    ); // ✅ ADAPTAT: Substitueix trackProvider
    final importedTrack = ref.watch(importedTrackProvider);

    // Si no hay grabación con puntos o no hay guía, el futuro es nulo
    if (realTrack.points.isEmpty || importedTrack == null) {
      return null;
    }

    // 2. Punto de anclaje (Última posición GPS gravada)
    // Llegim de forma ultra neta l'últim punt a través del nou model UserPosition
    final lastPoint = realTrack.points.last;
    final currentGPS = lastPoint.position; // LatLng objecte
    final currentAlt = lastPoint.altitude;

    // Buscamos el índice más cercano en la guía
    final anchorIdx = _findClosestIndex(
      currentGPS.latitude, // ✅ ADAPTAT: Ara és .latitude de MapLibre
      currentGPS.longitude, // ✅ ADAPTAT: Ara és .longitude de MapLibre
      importedTrack.coordinates,
    );

    // 3. Recorte de listas (desde el anclaje hasta el final)
    // Nota: Aquests getters fan servir la simulació de llistes del model Track sense trencar el codi!
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
      final d = haversineDistance(lat, lon, coords[i][1], coords[i][0]);
      if (d < minDist) {
        minDist = d;
        minIndex = i;
      }
    }
    return minIndex;
  }
}

// ─────────────────────────────────────────────────────────────
// 🔗 DEFINICIÓ DEL PROVIDER GLOBAL REFACTORITZAT
// ─────────────────────────────────────────────────────────────
final remainingTrackProvider =
    NotifierProvider<RemainingTrackNotifier, RemainingTrackData?>(
      RemainingTrackNotifier.new,
    );
