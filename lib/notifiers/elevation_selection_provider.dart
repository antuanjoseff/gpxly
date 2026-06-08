import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ElevationSelectionNotifier extends Notifier<List<int?>> {
  // Memòria cronològica dels teus dos últims clics manuals a waypoints
  int? _prevWpIndex;
  int? _lastWpIndex;

  // Guardem de forma fixa quin ha estat el darrer ID real clicat pel dit
  int? _darrerWpClicat;

  @override
  List<int?> build() => [null, null]; // [0] = selectedIndexStart, [1] = selectedIndexEnd

  /// 📊 ACCIÓ DEL DRAG MANUAL / LONG PRESS AL GRÀFIC
  void setManualRange(int start, int end) {
    // Mantinguem els índexs que arrossega l'usuari, però conservem la memòria
    // del darrer waypoint clicat per si després torna a interactuar amb el mapa
    state = [start, end];
  }

  /// 🧹 NETEJA TOTAL DE LA SELECCIÓ
  void clearSelection() {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;
    state = [null, null];
  }

  /// 📍 ACCIÓ DEL MAPA / LLISTA (Clic net a un Waypoint)
  void toggleWaypoint(int idx, Set<int> allWpIndexes) {
    final start = state[0];
    final end = state[1];

    // 1. Analitzem si les barres actuals de la pantalla coincideixen amb un WP real
    final bool startIsOnWaypoint =
        start != null && allWpIndexes.contains(start);
    final bool endIsOnWaypoint = end != null && allWpIndexes.contains(end);

    int? nouPrev;
    int? nouLast;

    // ─────────────────────────────────────────────────────────────────────────
    // MÀQUINA D'ESTATS (Les 3 Regles de Negoci Exactes)
    // ─────────────────────────────────────────────────────────────────────────

    // 🟢 CAS 3: Les dues barres del gràfic ja estan sobre Waypoints -> Dos últims clics
    if (startIsOnWaypoint && endIsOnWaypoint) {
      if (_darrerWpClicat == start) {
        nouPrev = start;
        nouLast = idx;
      } else if (_darrerWpClicat == end) {
        nouPrev = end;
        nouLast = idx;
      } else {
        final int distToStart = (start! - idx).abs();
        final int distToEnd = (end! - idx).abs();
        nouPrev = (distToStart > distToEnd) ? start : end;
        nouLast = idx;
      }
    }
    // 🟡 CAS 2: Només una de les dues barres coincideix amb un Waypoint
    else if (startIsOnWaypoint || endIsOnWaypoint) {
      if (startIsOnWaypoint) {
        nouPrev = start;
        nouLast = idx;
      } else {
        nouPrev = end;
        nouLast = idx;
      }
    }
    // 🔴 CAS 1: Cap de les dues barres coincideix amb un Waypoint (Venim d'un Drag lliure)
    else {
      if (start != null && end != null) {
        final int distToStart = (start - idx).abs();
        final int distToEnd = (end - idx).abs();

        if (distToStart <= distToEnd) {
          nouPrev = end; // L'altre extrem fa de base quieta
          nouLast = idx; // L'inici viatja cap al waypoint
        } else {
          nouPrev = start; // L'altre extrem fa de base quieta
          nouLast = idx; // El final viatja cap al waypoint
        }
      } else {
        nouPrev = idx;
        nouLast = idx;
      }
    }

    // Actualitzem les variables de l'historial intern
    _prevWpIndex = nouPrev;
    _lastWpIndex = nouLast;
    _darrerWpClicat = idx;

    // 2. ORDENACIÓ NUMÈRICA STRICTA PER AL GRÀFIC (Menor a l'esquerra, Major a la dreta)
    if (_prevWpIndex != null && _lastWpIndex != null) {
      if (_prevWpIndex! <= _lastWpIndex!) {
        state = [_prevWpIndex, _lastWpIndex];
      } else {
        state = [_lastWpIndex, _prevWpIndex];
      }
    }

    debugPrint(
      "🎯 [Riverpod Custom] Rang aplicat -> Start: \${state[0]} | End: \${state[1]}",
    );
  }
}

// DEFINICIÓ DEL PROVIDER EXACTAMENT COM EL TEU TIMER
final elevationSelectionProvider =
    NotifierProvider<ElevationSelectionNotifier, List<int?>>(
      ElevationSelectionNotifier.new,
    );
