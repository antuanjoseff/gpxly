// import_gpx_button.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
// ✅ ADAPTAT: Importem el proveïdor de la ruta importada de la branca
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/services/gpx_import_service.dart';

/// 🔁 Funció reutilitzable per importar GPX i centrar el mapa
Future<void> importGpxAndZoom({
  required BuildContext context,
  required WidgetRef ref,
  required MapLibreMapController? mapController,
}) async {
  // MANTINGUT: La teva crida original exacta al FilePicker
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['gpx'],
  );

  if (result == null) return;

  final path = result.files.single.path;
  if (path == null) return;

  final xml = await File(path).readAsString();

  // Executem el servei d'importació adaptat a la nova arquitectura
  await GpxImportService.importGpx(ref, xml);

  // ─── CENTRAR MAPA EN EL RECUADRE DE LA RUTA IMPORTADA ───
  // ✅ OPTIMITZAT: Llegim de forma instantània les coordenades i els valors del Bounding Box
  // que el model unificat ja ens dona precalculats, estalviant els bucles de reducció temporals.
  final importedTrack = ref.read(importedTrackProvider);
  if (importedTrack == null ||
      importedTrack.points.isEmpty ||
      mapController == null) {
    return;
  }

  final stats = importedTrack.stats;
  if (stats.minLat == null ||
      stats.maxLat == null ||
      stats.minLon == null ||
      stats.maxLon == null) {
    return;
  }

  // Reconstruïm els límits de MapLibre de forma directa i síncrona
  final bounds = LatLngBounds(
    southwest: LatLng(stats.minLat!, stats.minLon!),
    northeast: LatLng(stats.maxLat!, stats.maxLon!),
  );

  mapController.animateCamera(
    CameraUpdate.newLatLngBounds(
      bounds,
      left: 40,
      right: 40,
      top: 40,
      bottom: 40,
    ),
  );
}
