// lib/screens/main_map/widgets/map_selection_reticle.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/map_selection_tool_notifier.dart';

class MapSelectionReticle extends ConsumerWidget {
  const MapSelectionReticle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuitem si l'eina està activada de forma explícita per l'usuari
    final bool isToolActive = ref.watch(mapSelectionToolProvider);

    // Si està apagada, el giny esdevé totalment invisible i no ocupa espai
    if (!isToolActive) return const SizedBox.shrink();

    return const IgnorePointer(
      // Evita interceptar els gestos del dit perquè el mapa de sota es pugui moure
      child: Center(
        child: Icon(
          Icons.center_focus_strong, // Reticle de precisió clàssic estil Senda
          size: 44,
          color: Color(0xFF4CAF50), // El teu verd corporatiu sòlid
        ),
      ),
    );
  }
}
