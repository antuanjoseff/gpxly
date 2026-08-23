// lib/services/gpx_exporter.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
// Proveïdors existents de la teva aplicació
import 'package:strack_rec/notifiers/gpx_settings_notifier.dart'
    show gpxSettingsProvider;
import 'package:strack_rec/notifiers/recording_notifier.dart'; // El nou gravador Bloc 2
import 'package:strack_rec/notifiers/waypoints_recorded_notifier.dart';
import 'package:share_plus/share_plus.dart';

String buildGpxFilename() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return "STrack Rec-$y-$m-$d.gpx";
}

Future<void> exportGpx(
  String filename,
  WidgetRef ref,
  BuildContext context,
) async {
  // ✅ ADAPTAT: Llegim el nou trackRecordingProvider que conté la llista unificada de punts
  final track = ref.read(trackRecordingProvider);
  final settings = ref.read(gpxSettingsProvider);

  if (track.points.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hi ha cap track per exportar")),
      );
    }
    return;
  }

  final buffer = StringBuffer();

  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln(
    '<gpx version="1.1" creator="STrack Rec" xmlns="http://www.topografix.com/GPX/1/1">',
  );

  // ─────────────────────────────────────────────────
  // 1. AFEGIR WAYPOINTS ENREGISTRATS
  // ─────────────────────────────────────────────────
  final waypoints = ref.read(waypointsProvider);
  for (final wp in waypoints) {
    buffer.writeln('<wpt lat="${wp.lat}" lon="${wp.lon}">');
    buffer.writeln('<name>${wp.name}</name>');
    buffer.writeln('</wpt>');
  }

  // ─────────────────────────────────────────────────
  // 2. MANTENIR ELS BOUNDS (Llegits directament de TrackStats)
  // ─────────────────────────────────────────────────
  // Usamos un fallback a 0.0 si per algun motiu el bounding box fos null
  final minLat = track.stats.minLat ?? 0.0;
  final minLon = track.stats.minLon ?? 0.0;
  final maxLat = track.stats.maxLat ?? 0.0;
  final maxLon = track.stats.maxLon ?? 0.0;

  buffer.writeln(
    '<bounds minlat="$minLat" minlon="$minLon" maxlat="$maxLat" maxlon="$maxLon" />',
  );

  buffer.writeln('<trk><name>$filename</name><trkseg>');

  // ─────────────────────────────────────────────────
  // 3. RECÓRRER LA LLISTA DE PUNTS SENSE RISC D'ÍNDEXS
  // ─────────────────────────────────────────────────
  for (final currentPoint in track.points) {
    final lat = currentPoint.position.latitude;
    final lon = currentPoint.position.longitude;
    final ele = currentPoint.altitude;
    final timeStr = currentPoint.timestamp.toUtc().toIso8601String();

    // Atributs GPS llegits directament del mateix objecte
    final acc = currentPoint.accuracy;
    final heading = currentPoint.heading;
    final sat = currentPoint.satellites;
    final vAcc = currentPoint.vAccuracy;

    // La velocitat del punt ja és la mitjana suavitzada en km/h.
    final speed = currentPoint.speed / 3.6;

    buffer.writeln('<trkpt lat="$lat" lon="$lon">');

    // Altitud i temps estructurats
    buffer.writeln('<ele>$ele</ele>');
    buffer.writeln('<time>$timeStr</time>');

    // Speed si l'usuari la demana
    if (settings.speeds) {
      buffer.writeln('<speed>$speed</speed>');
    }

    // ─────────────────────────────────────────────────
    // 4. EXTENSIONS GPS PERSONALITZADES (Neteja absoluta)
    // ─────────────────────────────────────────────────
    final hasExtensions =
        settings.accuracies ||
        settings.headings ||
        settings.satellites ||
        settings.vAccuracies;

    if (hasExtensions) {
      buffer.writeln('<extensions>');

      if (settings.accuracies) {
        buffer.writeln('<accuracy>$acc</accuracy>');
      }

      if (settings.headings) {
        buffer.writeln('<heading>$heading</heading>');
      }

      if (settings.satellites) {
        buffer.writeln('<satellites>$sat</satellites>');
      }

      if (settings.vAccuracies) {
        buffer.writeln('<vAccuracy>$vAcc</vAccuracy>');
      }

      buffer.writeln('</extensions>');
    }

    buffer.writeln('</trkpt>');
  }

  buffer.writeln('</trkseg></trk></gpx>');

  // ─────────────────────────────────────────────────
  // 5. GUARDAR TEMPORALMENT I COMPARTIR L'ARXIU
  // ─────────────────────────────────────────────────
  final dir = await getTemporaryDirectory();
  final safeName = filename.endsWith(".gpx") ? filename : "$filename.gpx";
  final file = File("${dir.path}/$safeName");

  await file.writeAsString(buffer.toString());

  // ignore: deprecated_member_use
  await Share.shareXFiles([XFile(file.path)], text: "GPX exportat");
}
