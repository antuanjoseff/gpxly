// lib/screens/main_map/widgets/map_selection_top_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';
import 'package:senda/notifiers/helpers/map_selection_helper.dart';
import 'package:senda/notifiers/map_selection_tool_notifier.dart';

class MapSelectionTopButton extends ConsumerWidget {
  final MapLibreMapController? mapController;

  const MapSelectionTopButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isToolActive = ref.watch(mapSelectionToolProvider);
    if (!isToolActive) return const SizedBox.shrink();

    final selectionState = ref.watch(elevationSelectionProvider);

    final bool demanaFinal =
        selectionState.startTrackIndex != null &&
        selectionState.endTrackIndex == null;

    // 🟢 CORREGIT: 'textBoto' completament net i exactament igual a tot el fitxer
    final String textBoto = demanaFinal ? "Selecciona fi" : "Selecciona inici";

    return Positioned(
      top: 80,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final helper = MapSelectionHelper(
              ref: ref,
              mapController: mapController,
            );
            helper.executarSeleccioDesDeMira();
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_location_alt,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  textBoto, // 🟢 Ara sí que coincideix al 100% i compilarà perfectament
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
