import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/services/gpx_import_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class ImportGpxButton extends ConsumerWidget {
  final MapLibreMapController? mapController;
  final bool enabled;

  const ImportGpxButton({
    super.key,
    required this.mapController,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      // height: 56, // 👈 mateixa alçada que els altres botons
      child: IconButton(
        icon: const Icon(Icons.file_upload_outlined, size: 26),
        onPressed: !enabled
            ? null
            : () async {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['gpx'],
                );

                if (result == null) return;

                final path = result.files.single.path;
                if (path == null) return;

                final xml = await File(path).readAsString();

                await GpxImportService.importGpx(ref, xml);

                final track = ref.read(trackProvider);
                if (track.coordinates.isNotEmpty && mapController != null) {
                  final lats = track.coordinates.map((c) => c[1]);
                  final lons = track.coordinates.map((c) => c[0]);

                  final bounds = LatLngBounds(
                    southwest: LatLng(
                      lats.reduce((a, b) => a < b ? a : b),
                      lons.reduce((a, b) => a < b ? a : b),
                    ),
                    northeast: LatLng(
                      lats.reduce((a, b) => a > b ? a : b),
                      lons.reduce((a, b) => a > b ? a : b),
                    ),
                  );

                  mapController!.animateCamera(
                    CameraUpdate.newLatLngBounds(
                      bounds,
                      left: 40,
                      right: 40,
                      top: 40,
                      bottom: 40,
                    ),
                  );
                }
              },
      ),
    );
  }
}
