import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpxly/notifiers/gpx_settings_notifier.dart'
    show gpxSettingsProvider;
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/waypoints_notifier.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

String buildGpxFilename() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return "Track-gpxly-$y-$m-$d.gpx";
}

double computeSpeed(
  double lat1,
  double lon1,
  DateTime t1,
  double lat2,
  double lon2,
  DateTime t2,
) {
  final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  final dt = t2.difference(t1).inMilliseconds / 1000.0;
  if (dt <= 0) return 0;
  return distance / dt;
}

Map<String, double> computeBounds(List<List<double>> coords) {
  double minLat = 90, maxLat = -90;
  double minLon = 180, maxLon = -180;

  for (final c in coords) {
    final lon = c[0];
    final lat = c[1];

    if (lat < minLat) minLat = lat;
    if (lat > maxLat) maxLat = lat;
    if (lon < minLon) minLon = lon;
    if (lon > maxLon) maxLon = lon;
  }

  return {
    "minlat": minLat,
    "minlon": minLon,
    "maxlat": maxLat,
    "maxlon": maxLon,
  };
}

// Future<void> exportGpx(
//   String filename,
//   WidgetRef ref,
//   BuildContext context,
// ) async {
//   final track = ref.read(trackProvider);

//   if (track.coordinates.isEmpty) {
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("No hi ha cap track per exportar")),
//       );
//     }
//     return;
//   }

//   final coords = track.coordinates;
//   final alts = track.altitudes;
//   final times = track.timestamps;

//   final bounds = computeBounds(coords);

//   final buffer = StringBuffer();

//   buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
//   buffer.writeln('<gpx version="1.1" creator="Gpxly">');

//   buffer.writeln(
//     '<bounds minlat="${bounds["minlat"]}" minlon="${bounds["minlon"]}" '
//     'maxlat="${bounds["maxlat"]}" maxlon="${bounds["maxlon"]}" />',
//   );

//   buffer.writeln('<trk><name>$filename</name><trkseg>');

//   for (int i = 0; i < coords.length; i++) {
//     final lon = coords[i][0];
//     final lat = coords[i][1];

//     final ele = (i < alts.length) ? alts[i] : 0.0;
//     final time = (i < times.length) ? times[i].toUtc().toIso8601String() : null;

//     double speed = 0;
//     if (i > 0 && i < times.length) {
//       speed = computeSpeed(
//         coords[i - 1][1],
//         coords[i - 1][0],
//         times[i - 1],
//         lat,
//         lon,
//         times[i],
//       );
//     }

//     buffer.writeln('<trkpt lat="$lat" lon="$lon">');
//     buffer.writeln('<ele>$ele</ele>');
//     if (time != null) buffer.writeln('<time>$time</time>');
//     buffer.writeln('<speed>$speed</speed>');
//     buffer.writeln('</trkpt>');
//   }

//   buffer.writeln('</trkseg></trk></gpx>');

//   // 🔥 Guardar temporalment
//   final dir = await getTemporaryDirectory();
//   final safeName = filename.endsWith(".gpx") ? filename : "$filename.gpx";
//   final file = File("${dir.path}/$safeName");

//   await file.writeAsString(buffer.toString());

//   // 🔥 Compartir (API funcional encara que deprecated)
//   // ignore: deprecated_member_use
//   await Share.shareXFiles([XFile(file.path)], text: "GPX exportat");
// }

Future<void> exportGpx(
  String filename,
  WidgetRef ref,
  BuildContext context,
) async {
  final track = ref.read(trackProvider);
  final settings = ref.read(gpxSettingsProvider);

  if (track.coordinates.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hi ha cap track per exportar")),
      );
    }
    return;
  }

  final coords = track.coordinates;
  final alts = track.altitudes;
  final times = track.timestamps;
  final accs = track.accuracies;
  final headings = track.headings;
  final sats = track.satellites;
  final vAccs = track.vAccuracies;

  final bounds = computeBounds(coords);

  final buffer = StringBuffer();

  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<gpx version="1.1" creator="Gpxly">');

  // 🔥 Afegim waypoints
  final waypoints = ref.read(waypointsProvider);
  for (final wp in waypoints) {
    buffer.writeln('<wpt lat="${wp.lat}" lon="${wp.lon}">');
    buffer.writeln('<name>${wp.name}</name>');
    buffer.writeln('</wpt>');
  }

  // 🔥 Mantenim els bounds
  buffer.writeln(
    '<bounds minlat="${bounds["minlat"]}" minlon="${bounds["minlon"]}" '
    'maxlat="${bounds["maxlat"]}" maxlon="${bounds["maxlon"]}" />',
  );

  buffer.writeln('<trk><name>$filename</name><trkseg>');

  for (int i = 0; i < coords.length; i++) {
    final lon = coords[i][0];
    final lat = coords[i][1];

    final ele = (i < alts.length) ? alts[i] : 0.0;
    final time = (i < times.length) ? times[i].toUtc().toIso8601String() : null;

    // Atributs GPS opcionals
    final acc = (i < accs.length) ? accs[i] : null;
    final heading = (i < headings.length) ? headings[i] : null;
    final sat = (i < sats.length) ? sats[i] : null;
    final vAcc = (i < vAccs.length) ? vAccs[i] : null;

    // Speed només si activat
    double speed = 0;
    if (settings.speeds && i > 0 && i < times.length) {
      speed = computeSpeed(
        coords[i - 1][1],
        coords[i - 1][0],
        times[i - 1],
        lat,
        lon,
        times[i],
      );
    }

    buffer.writeln('<trkpt lat="$lat" lon="$lon">');

    // 🔥 Altitud sempre present
    buffer.writeln('<ele>$ele</ele>');

    // 🔥 Temps sempre present si existeix
    if (time != null) buffer.writeln('<time>$time</time>');

    // 🔥 Speed només si activat
    if (settings.speeds) {
      buffer.writeln('<speed>$speed</speed>');
    }

    // 🔥 Extensions GPS (només si algun camp està activat)
    final hasExtensions =
        (settings.accuracies && acc != null) ||
        (settings.headings && heading != null) ||
        (settings.satellites && sat != null) ||
        (settings.vAccuracies && vAcc != null);

    if (hasExtensions) {
      buffer.writeln('<extensions>');

      if (settings.accuracies && acc != null) {
        buffer.writeln('<accuracy>$acc</accuracy>');
      }

      if (settings.headings && heading != null) {
        buffer.writeln('<heading>$heading</heading>');
      }

      if (settings.satellites && sat != null) {
        buffer.writeln('<satellites>$sat</satellites>');
      }

      if (settings.vAccuracies && vAcc != null) {
        buffer.writeln('<vAccuracy>$vAcc</vAccuracy>');
      }

      buffer.writeln('</extensions>');
    }

    buffer.writeln('</trkpt>');
  }

  buffer.writeln('</trkseg></trk></gpx>');

  // 🔥 Guardar temporalment
  final dir = await getTemporaryDirectory();
  final safeName = filename.endsWith(".gpx") ? filename : "$filename.gpx";
  final file = File("${dir.path}/$safeName");

  await file.writeAsString(buffer.toString());

  // 🔥 Compartir
  // ignore: deprecated_member_use
  await Share.shareXFiles([XFile(file.path)], text: "GPX exportat");
}
