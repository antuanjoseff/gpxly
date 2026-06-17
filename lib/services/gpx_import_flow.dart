// lib/services/gpx_import_flow.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/l10n/app_localizations.dart';
// ✅ ADAPTAT: Importem el proveïdor de la ruta importada de la branca
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/services/gpx_import_service.dart';

/// Flux complet d'importació GPX + zoom al mapa.
/// Aquesta funció és cridada tant des de la bottom bar com des de l'AppBar.
Future<void> pickGpxAndImport({
  required BuildContext context,
  required WidgetRef ref,
  required MapLibreMapController? mapController,
}) async {
  final t = AppLocalizations.of(context)!;

  // 📝 MANTINGUT: La teva crida original exacta al FilePicker
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['gpx'],
  );

  if (result == null) return;

  final path = result.files.single.path;
  if (path == null) return;

  // 1) Validar extensió
  if (!path.toLowerCase().endsWith(".gpx")) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.gpxErrorInvalidExtension)));
    return;
  }

  // 2) Llegir contingut
  String xml;
  try {
    xml = await File(path).readAsString();
  } catch (_) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.gpxErrorRead)));
    return;
  }

  // 3) Validar XML
  if (!xml.trim().startsWith("<")) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.gpxErrorInvalidXml)));
    return;
  }

  // 4) Validar etiqueta GPX
  if (!xml.contains("<gpx")) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.gpxErrorNoGpxTag)));
    return;
  }

  // Importar el contingut del GPX al magatzem de dades
  await GpxImportService.importGpx(ref, xml);

  // ─── CENTRAR MAPA EN EL RECUADRE DE LA RUTA IMPORTADA ───
  // ✅ OPTIMITZAT: Llegim les coordenades i els valors del Bounding Box
  // que el model unificat ja ens dona precalculats, estalviant els bucles 'reduce'.
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

  // Reconstruïm els límits de MapLibre usant els valors que el servei ja ha processat
  final bounds = LatLngBounds(
    southwest: LatLng(stats.minLat!, stats.minLon!),
    northeast: LatLng(stats.maxLat!, stats.maxLon!),
  );

  await mapController.animateCamera(
    CameraUpdate.newLatLngBounds(
      bounds,
      left: 40,
      right: 40,
      top: 40,
      bottom: 40,
    ),
  );
}
