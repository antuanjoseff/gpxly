// lib/notifiers/nearest_track_point_notifier.dart (OPTIMITZAT SOTA DEMANDA I ZOOM)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/notifiers/gps_speed_notifier.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
// 🚀 Importa aquí el provider on tinguis el zoom actual del mapa de Senda, exemple:
// import 'package:strack_rec/notifiers/map_zoom_notifier.dart';

class NearestTrackPointNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Estat inicial en repòs absolut
  }

  /// 🚀 CÀLCUL QUIRÚRGIC LLIURE DE BUCLES INÚTILS (ACTUALITZAT CONDICIONAL):
  /// Prioritza automàticament el track gravat en viu si l'aplicació està registrant una ruta.
  void refreshNearestPoint({required double currentZoom}) {
    // 1. ESBRINEM SI L'APLICACIÓ ESTÀ GRAVANT O NO
    final recTrack = ref.read(trackRecordingProvider);
    final bool isRecording =
        recTrack.recordingState == RecordingState.recording;

    List<dynamic> coordinatesList = [];

    if (isRecording) {
      // 🟢 CAS A: L'APP ESTÀ GRAVANT. Utilitzem la llista '.points' detectada al teu projecte
      if (recTrack.points.isNotEmpty) {
        coordinatesList = recTrack
            .points; // S'assumeix que conté llistes [lon, lat] o objectes que responen a l'índex [0] i [1]
      }
    } else {
      // 🔵 CAS B: NO ES GRAVA. Fem servir el track importat si existeix tal com tenies abans
      final importedTrack = ref.read(importedTrackProvider);
      if (importedTrack != null && importedTrack.coordinates.isNotEmpty) {
        coordinatesList = importedTrack.coordinates;
      }
    }

    // Si cap dels dos tracks està actiu o ambdues llistes estan buides, aturem l'escàner
    if (coordinatesList.isEmpty) {
      state = 0;
      return;
    }

    // Llegim la posició del mapa sota demanda (Sense watch reactius continus)
    final centerLat = ref.read(mapCenterLatProvider);
    final centerLon = ref.read(mapCenterLonProvider);

    int bestIndex = 0;
    double bestDist = double.infinity;
    final int totalPoints = coordinatesList.length;

    // 🎯 REGLA 1: CONTROL DE VISUALITZACIÓ SEGONS ZOOM
    int step = 1;
    if (currentZoom < 11) {
      step = 12; // Molt lluny: saltem de 12 en 12
    } else if (currentZoom < 14) {
      step = 4; // Distància mitjana: saltem de 4 en 4
    }

    // 🎯 REGLA 2: FILTRE DE CAPSA VISUAL (REDUIR PUNTS DINS LA VISTA DEL MÒBIL)
    final double degreeTolerance = currentZoom > 13 ? 0.015 : 0.08;

    final double minLat = centerLat - degreeTolerance;
    final double maxLat = centerLat + degreeTolerance;
    final double minLon = centerLon - degreeTolerance;
    final double maxLon = centerLon + degreeTolerance;

    // Bucle de cerca intel·ligent sobre la llista escollida condicionalment
    for (int i = 0; i < totalPoints; i += step) {
      final p = coordinatesList[i];
      // Adaptació flexible de lectura: suporta tant estructures GeoJSON [lon, lat] com llistes pures
      final double lon = p[0];
      final double lat = p[1];

      // Filtre de tall espacial
      if (lat < minLat || lat > maxLat || lon < minLon || lon > maxLon) {
        continue;
      }

      // Distància Manhattan super ràpida
      final double d = (lat - centerLat).abs() + (lon - centerLon).abs();

      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }

    // 🎯 REFINAMENT FINAL EXTRA:
    if (step > 1 && bestDist != double.infinity) {
      int refineStart = (bestIndex - step).clamp(0, totalPoints - 1);
      int refineEnd = (bestIndex + step).clamp(0, totalPoints - 1);
      for (int i = refineStart; i <= refineEnd; i++) {
        final p = coordinatesList[i];
        final double d = (p[1] - centerLat).abs() + (p[0] - centerLon).abs();
        if (d < bestDist) {
          bestDist = d;
          bestIndex = i;
        }
      }
    }

    // Fallback de seguretat si l'usuari fa un zoom desplaçat fora de la traça
    if (bestDist == double.infinity) {
      for (int i = 0; i < totalPoints; i += 20) {
        final p = coordinatesList[i];
        final double d = (p[1] - centerLat).abs() + (p[0] - centerLon).abs();
        if (d < bestDist) {
          bestDist = d;
          bestIndex = i;
        }
      }
    }

    state = bestIndex;
  }
}

final nearestTrackPointProvider =
    NotifierProvider<NearestTrackPointNotifier, int>(
      NearestTrackPointNotifier.new,
    );
