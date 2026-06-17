// lib/screens/main_screen/helpers/map_geometry_helper.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/remaining_track_notifier.dart';

class MapGeometryHelper {
  final WidgetRef ref;
  final MapLibreMapController? mapController;

  MapGeometryHelper({required this.ref, required this.mapController});

  /// Tradueix un índex unificat del gràfic en coordenades [lon, lat] reals
  List<double>? getCoordsFromGlobalIndex(int? index) {
    if (index == null || index < 0) return null;

    final realTrack = ref.read(trackRecordingProvider);
    final importedTrack = ref.read(importedTrackProvider);
    final remainingTrack = ref.read(remainingTrackProvider);
    final int pastCount = realTrack.points.length;

    if (index < pastCount) {
      final pos = realTrack.points[index].position;
      return [pos.longitude, pos.latitude];
    }

    final int futureIndex = index - pastCount;
    final bool showingSimulationFuture =
        ref.read(navigationProvider).isFollowing && remainingTrack != null;

    if (showingSimulationFuture && importedTrack != null) {
      final int realRouteIndex = remainingTrack.anchorIndex + futureIndex;
      if (realRouteIndex < importedTrack.coordinates.length) {
        return importedTrack.coordinates[realRouteIndex];
      }
    } else if (importedTrack != null) {
      if (futureIndex < importedTrack.coordinates.length) {
        return importedTrack.coordinates[futureIndex];
      }
    }
    return null;
  }

  /// Calcula de forma automàtica l'enquadrament de càmera (Bounding Box)
  void fitToBounds(List<List<double>> coords, {bool instant = false}) {
    if (coords.isEmpty || mapController == null) return;

    final lats = coords.map((c) => c[1]).toList();
    final lons = coords.map((c) => c[0]).toList();

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

    final update = CameraUpdate.newLatLngBounds(
      bounds,
      left: 50,
      right: 50,
      top: 50,
      bottom: 50,
    );
    instant
        ? mapController!.moveCamera(update)
        : mapController!.animateCamera(update);
  }
}
