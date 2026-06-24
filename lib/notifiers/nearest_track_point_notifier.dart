// lib/notifiers/nearest_track_point_notifier.dart (OPTIMITZAT SOTA DEMANDA I ZOOM)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/gps_speed_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
// 🚀 Importa aquí el provider on tinguis el zoom actual del mapa de Senda, exemple:
// import 'package:senda/notifiers/map_zoom_notifier.dart';

class NearestTrackPointNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Estat inicial en repòs absolut
  }

  /// 🚀 CÀLCUL QUIRÚRGIC LLIURE DE BUCLES INUTILS:
  /// Només es dispara quan l'usuari clica un botó de fixar.
  void refreshNearestPoint({required double currentZoom}) {
    final track = ref.read(importedTrackProvider);
    if (track == null || track.coordinates.isEmpty) {
      state = 0;
      return;
    }

    // Llegim la posició del mapa sota demanda (Sense watch reactius continus)
    final centerLat = ref.read(mapCenterLatProvider);
    final centerLon = ref.read(mapCenterLonProvider);

    int bestIndex = 0;
    double bestDist = double.infinity;
    final int totalPoints = track.coordinates.length;

    // 🎯 REGLA 1: CONTROL DE VISUALITZACIÓ SEGONS ZOOM
    // Si el zoom és alt (> 15, l'usuari està a prop de la línia), mirem el 100% dels punts pel detall.
    // Si el zoom és baix, saltem punts per protegir la memòria del telèfon.
    int step = 1;
    if (currentZoom < 11) {
      step = 12; // Molt lluny: saltem de 12 en 12
    } else if (currentZoom < 14) {
      step = 4; // Distància mitjana: saltem de 4 en 4
    }

    // 🎯 REGLA 2: FILTRE DE CAPSA VISUAL (REDUIR PUNTS DINS LA VISTA DEL MÒBIL)
    // Creem un marge de tolerància estimat en graus segons el zoom actual
    // per descartar de cop tot el track de 50km que queda fora de la pantalla.
    final double degreeTolerance = currentZoom > 13 ? 0.015 : 0.08;

    final double minLat = centerLat - degreeTolerance;
    final double maxLat = centerLat + degreeTolerance;
    final double minLon = centerLon - degreeTolerance;
    final double maxLon = centerLon + degreeTolerance;

    // Bucle de cerca intel·ligent
    for (int i = 0; i < totalPoints; i += step) {
      final p = track.coordinates[i];
      final double lon = p[0];
      final double lat = p[1];

      // Filtre de tall: Si el punt està fora del rectangle visible del mòbil, l'ignorem directament!
      if (lat < minLat || lat > maxLat || lon < minLon || lon > maxLon) {
        continue;
      }

      // Distància Manhattan super ràpida pels punts que Sí que estan en pantalla
      final double d = (lat - centerLat).abs() + (lon - centerLon).abs();

      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }

    // 🎯 REFINAMENT FINAL EXTRA:
    // Si hem saltat punts (step > 1), mirem de prop al voltant del guanyador per clavar el píxel
    if (step > 1 && bestDist != double.infinity) {
      int refineStart = (bestIndex - step).clamp(0, totalPoints - 1);
      int refineEnd = (bestIndex + step).clamp(0, totalPoints - 1);
      for (int i = refineStart; i <= refineEnd; i++) {
        final p = track.coordinates[i];
        final double d = (p[1] - centerLat).abs() + (p[0] - centerLon).abs();
        if (d < bestDist) {
          bestDist = d;
          bestIndex = i;
        }
      }
    }

    // Si cap punt del track fos visible a la pantalla pel zoom, fem un fallback al punt 0 o el més proper global
    if (bestDist == double.infinity) {
      // Cerca bàsica ràpida de seguretat saltant punts per tot el track
      for (int i = 0; i < totalPoints; i += 20) {
        final p = track.coordinates[i];
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
