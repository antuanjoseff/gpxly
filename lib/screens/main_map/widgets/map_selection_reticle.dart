import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/elevation_selection_provider.dart';

class MapSelectionReticle extends ConsumerWidget {
  const MapSelectionReticle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(elevationSelectionProvider);

    // Només mostrem el reticle quan l’eina està activa
    if (sel.mapToolState != MapSelectionToolState.selectingStart &&
        sel.mapToolState != MapSelectionToolState.selectingEnd) {
      return const SizedBox.shrink();
    }

    return const IgnorePointer(
      ignoring: true,
      child: Center(
        child: Icon(
          Icons.center_focus_strong,
          size: 44,
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }
}
