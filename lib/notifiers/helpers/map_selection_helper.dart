// lib/screens/main_map/helpers/map_selection_helper.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/models/user_position.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';

class MapSelectionHelper {
  final WidgetRef ref;
  final MapLibreMapController? mapController;

  const MapSelectionHelper({required this.ref, required this.mapController});

  /// Captura la posició del visor, fa snap a la ruta i mou les agulles del gràfic
  void executarSeleccioDesDeMira() {
    if (mapController == null) return;

    // 1. Obtenim la coordenada on apunta actualment el reticle fix del centre
    final LatLng centreActual = mapController!.cameraPosition!.target;

    // 2. Determinem quina font de dades està activa (Importada de referència o Gravació en viu)
    final Track? trackImportat = ref.read(importedTrackProvider);
    final Track trackGravacio = ref.read(trackRecordingProvider);

    // Prioritzem el track importat si existeix i té punts, si no passem al de gravació
    final Track trackActiu =
        (trackImportat != null && trackImportat.points.isNotEmpty)
        ? trackImportat
        : trackGravacio;

    if (trackActiu.points.isEmpty) return;

    // 3. Busquem el punt del model exactament més proper al reticle
    final int indexMesProper = _cercarIndexMesProperARuta(
      centreActual,
      trackActiu,
    );

    // 4. Extraiem la UserPosition d'eixe índex segons el teu model d'estructures
    final UserPosition puntSnap = trackActiu.points[indexMesProper];
    final LatLng coordsSnap = LatLng(
      puntSnap.position.latitude,
      puntSnap.position.longitude,
    );

    // 5. 🎯 EFECTE SNAP: Desplacem el mapa de forma suau per clavar la ruta sota la mira
    mapController!.animateCamera(CameraUpdate.newLatLng(coordsSnap));

    // 6. Sincronitzem l'estat a Riverpod llançant la teva funció cíclica continuada
    ref
        .read(elevationSelectionProvider.notifier)
        .setPointFromMapSelectionTool(indexMesProper);
  }

  /// Recorre la llista de punts primitius compactes del teu model per trobar el més proper a la mira
  int _cercarIndexMesProperARuta(LatLng puntCamera, Track track) {
    int indexMesProper = 0;
    double distanciaMinima = double.infinity;

    for (int i = 0; i < track.points.length; i++) {
      final UserPosition p = track.points[i];

      // Accedim correctament a l'estructura geogràfica real tipada del teu model
      final double latRuta = p.position.latitude;
      final double lonRuta = p.position.longitude;

      // Càlcul de distància quadràtica simplificada ultra ràpida ideal per a milers de punts a la GPU
      final double dLat = latRuta - puntCamera.latitude;
      final double dLon = lonRuta - puntCamera.longitude;
      final double dist = (dLat * dLat) + (dLon * dLon);

      if (dist < distanciaMinima) {
        distanciaMinima = dist;
        indexMesProper = i;
      }
    }
    return indexMesProper;
  }
}
