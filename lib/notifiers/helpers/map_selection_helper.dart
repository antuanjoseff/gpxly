// lib/screens/main_map/helpers/map_selection_helper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/user_position.dart';
import 'package:strack_rec/notifiers/elevation_selection_provider.dart';
import 'package:strack_rec/notifiers/imported_track_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';

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

    // 🧪 ------------------------------------------------------------------
    // 🧪 BLOC DE PROVA PER SORTIR DE DUBTES (MAPA VS GRÀFIC)
    // ------------------------------------------------------------------

    // A. El punt que ha trobat el mapa físicament sota la retícula
    final UserPosition puntMapa = trackActiu.points[indexMesProper];
    debugPrint(
      "🗺️ COORDENADA MAPA:  Lat: ${puntMapa.position.latitude}, Lon: ${puntMapa.position.longitude}",
    );

    try {
      // B. El punt que el teu gràfic pintarà utilitzant eixe mateix número d'índex.
      // ⚠️ ATENCIÓ: Si el teu panell d'elevacions llegeix una altra llista reduïda o un altre provider,
      // substitueix 'trackActiu.points' per eixa llista o provider exactament.
      final List<UserPosition> puntsDelGrafic = trackActiu.points;
      final UserPosition puntGrafic = puntsDelGrafic[indexMesProper];

      if (puntMapa.position.latitude == puntGrafic.position.latitude &&
          puntMapa.position.longitude == puntGrafic.position.longitude) {
      } else {
        debugPrint(
          "❌ RESULTAT: DESALINEACIÓ DETECTADA! Les dues llistes tenen coordenades diferents per a l'índex $indexMesProper.",
        );
      }
    } catch (e) {
      debugPrint(
        "🚨 RESULTAT: L'índex $indexMesProper no existeix a la llista del gràfic! (Fora de rang, llista més curta)",
      );
    }
    // ------------------------------------------------------------------

    // 4. Extraiem la UserPosition d'eixe índex segons el teu model d'estructures
    final UserPosition puntSnap = trackActiu.points[indexMesProper];
    final LatLng coordsSnap = LatLng(
      puntSnap.position.latitude,
      puntSnap.position.longitude,
    );

    // 5. EFECTE SNAP: Desplacem el mapa de forma suau per clavar la ruta sota la mira
    mapController!.animateCamera(CameraUpdate.newLatLng(coordsSnap));

    // 6. Sincronitzem l'estat a Riverpod llançant la teva funció
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

      final double latRuta = p.position.latitude;
      final double lonRuta = p.position.longitude;

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
