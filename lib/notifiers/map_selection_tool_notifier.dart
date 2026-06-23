// lib/notifiers/map_selection_tool_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapSelectionToolNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Al néixer el mapa o el gràfic, l'eina de selecció arrenca apagada (false)
    return false;
  }

  /// Encén la mira central i el mode selecció al mapa
  void activate() {
    state = true;
  }

  /// Apaga la mira central i el mode selecció al mapa
  void deactivate() {
    state = false;
  }

  /// Commuta l'estat (encén/apaga) al prémer el botó de disponibilitat
  void toggle() {
    state = !state;
  }
}

// El provider global que podrem consultar des dels ginys i la pantalla de Senda
final mapSelectionToolProvider =
    NotifierProvider<MapSelectionToolNotifier, bool>(
      MapSelectionToolNotifier.new,
    );
