// lib/screens/main_screen/helpers/navigation_flow_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/waypoints_imported_notifier.dart';
import 'package:senda/services/gpx_import_flow.dart';
import 'package:senda/ui/app_messages.dart';

class NavigationFlowHandler {
  final WidgetRef ref;
  final BuildContext context;

  NavigationFlowHandler({required this.ref, required this.context});

  Future<void> openNavigationControl({
    required MapLibreMapController? mapController,
    required bool hasImportedTrack,
    required void Function(List<List<double>>, {bool instant}) fitToBounds,
  }) async {
    final navigationState = ref.read(navigationProvider);
    String? action;

    if (!hasImportedTrack) {
      action = "import";
    } else if (hasImportedTrack && !navigationState.isFollowing) {
      action = "follow";
    } else if (navigationState.isFollowing) {
      final confirmStop = await AppMessages.showStopFollowingDialog(context);

      if (confirmStop == true) {
        action =
            "stop_follow"; // Si confirma, l'autòmat de sota esborrarà el track i netejarà el mapa
      } else {
        return; // Si prem cancel·lar, aturem el flux i no fem res
      }
    }

    if (action == null) return;

    switch (action) {
      case "import":
        try {
          await pickGpxAndImport(
            context: context,
            ref: ref,
            mapController: mapController,
          );
          final importedData = ref.read(importedTrackProvider);
          if (importedData != null && importedData.points.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 50), () {
              fitToBounds(importedData.coordinates, instant: true);
            });
          }
        } catch (e) {
          debugPrint("⚠️ Errada en la importació del fitxer: $e");
        }
        break;

      case "follow":
        await ref
            .read(navigationProvider.notifier)
            .startFollowing(context, mapController);
        break;

      case "clear_imported":
        final confirm = await AppMessages.showDeleteImportedTrackDialog(
          context,
        );
        if (confirm == true) {
          ref.read(importedTrackProvider.notifier).clear();
          ref.read(importedWaypointsProvider.notifier).clear();
        }
        break;

      case "toggle_pause":
        final currentNavState = ref.read(navigationProvider);
        ref.read(navigationProvider.notifier).state = currentNavState.copyWith(
          isPaused: !currentNavState.isPaused,
        );
        break;

      case "stop_follow":
        ref.read(navigationProvider.notifier).stopFollowing();
        ref.read(importedTrackProvider.notifier).clear();
        ref.read(importedWaypointsProvider.notifier).clear();
        break;
    }
  }
}
