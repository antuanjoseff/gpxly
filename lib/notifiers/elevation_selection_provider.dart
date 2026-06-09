import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SelectionMode {
  none, // Cap agulla, cap punt.
  single, // Mode punt únic: Cercle taronja al mapa / 1 agulla al gràfic.
  range, // Mode tram (Requerix Long Press): Cercles verd i vermell / 2 agulles al gràfic.
}

class ElevationSelectionState {
  final SelectionMode mode;
  final int? singlePointIndex; // Cercle taronja (Mode single)
  final int? startTrackIndex; // Cercle verd (Mode range)
  final int? endTrackIndex; // Cercle vermell (Mode range)

  const ElevationSelectionState({
    required this.mode,
    this.singlePointIndex,
    this.startTrackIndex,
    this.endTrackIndex,
  });

  factory ElevationSelectionState.initial() {
    return const ElevationSelectionState(mode: SelectionMode.none);
  }

  // 🟢 AFEGIT: El mètode copyWith indispensable per a les modificacions dels trams
  ElevationSelectionState copyWith({
    SelectionMode? mode,
    int? singlePointIndex,
    int? startTrackIndex,
    int? endTrackIndex,
    bool clearSinglePoint = false, // Permet forçar el buidat del taronja
    bool clearStartTrack = false, // Permet forçar el buidat del verd
    bool clearEndTrack = false, // Permet forçar el buidat del vermell
  }) {
    return ElevationSelectionState(
      mode: mode ?? this.mode,
      singlePointIndex: clearSinglePoint
          ? null
          : (singlePointIndex ?? this.singlePointIndex),
      startTrackIndex: clearStartTrack
          ? null
          : (startTrackIndex ?? this.startTrackIndex),
      endTrackIndex: clearEndTrack
          ? null
          : (endTrackIndex ?? this.endTrackIndex),
    );
  }
}

class ElevationSelectionNotifier extends Notifier<ElevationSelectionState> {
  int? _prevWpIndex;
  int? _lastWpIndex;
  int? _darrerWpClicat;

  @override
  ElevationSelectionState build() => ElevationSelectionState.initial();

  void startSelectionWithLongPress(int startIdx, int endIdx) {
    _prevWpIndex = startIdx;
    _lastWpIndex = endIdx;
    _darrerWpClicat = endIdx;

    state = ElevationSelectionState(
      mode: SelectionMode.range,
      startTrackIndex: startIdx,
      endTrackIndex: endIdx,
      singlePointIndex: null,
    );
  }

  /// 📊 ACCIÓ DEL DRAG MANUAL DENTRE DEL GRÀFIC (Només en mode range)
  void setManualRange(int start, int end) {
    _prevWpIndex = start;
    _lastWpIndex = end;
    _darrerWpClicat =
        null; // Desvinculem el passat del mapa per evitar desplaçaments

    state = ElevationSelectionState(
      mode: SelectionMode.range,
      startTrackIndex: start,
      endTrackIndex: end,
      singlePointIndex: null,
    );
  }

  /// 🟠 ACCIÓ DE SELECCIÓ DE PUNT ÚNIC (Tap ordinari al mapa o gràfic)
  void setSinglePoint(int index) {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;

    state = ElevationSelectionState(
      mode: SelectionMode.single, // Activem el cercle taronja
      singlePointIndex: index,
      startTrackIndex: null,
      endTrackIndex: null,
    );
  }

  /// 🧹 NETEJA TOTAL
  void clearSelection() {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;
    state = ElevationSelectionState.initial();
  }

  /// 📍 ACCIÓ DEL MAPA: Clic net a un Waypoint
  void toggleWaypoint(int idx, Set<int> allWpIndexes) {
    // 📐 REGLA 1: Si no s'ha fet long press previ, ESTÀ PROHIBIT crear un tram.
    // El tap al waypoint es comporta com un punt únic ordinar i mou el cercle taronja.
    if (state.mode != SelectionMode.range) {
      setSinglePoint(idx);
      return;
    }

    // 📐 REGLA 2: Som en mode RANGE (S'havia fet long press). Gestionem la selecció del tram.
    final start = state.startTrackIndex;
    final end = state.endTrackIndex;

    final bool startIsOnWaypoint =
        start != null && allWpIndexes.contains(start);
    final bool endIsOnWaypoint = end != null && allWpIndexes.contains(end);

    int? nouPrev;
    int? nouLast;

    // CAS 3: Les dues barres ja estan sobre Waypoints -> Dos últims clics cronològics
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
    // CAS 2: Només una de les dues barres coincideix amb un Waypoint
    else if (startIsOnWaypoint || endIsOnWaypoint) {
      if (startIsOnWaypoint) {
        nouPrev = start;
        nouLast = idx;
      } else {
        nouPrev = end;
        nouLast = idx;
      }
    }
    // CAS 1: Cap barreja amb Waypoint (Venim d'un Drag manual)
    else {
      if (start != null && end != null) {
        final int distToStart = (start - idx).abs();
        final int distToEnd = (end - idx).abs();

        if (distToStart <= distToEnd) {
          nouPrev = end;
          nouLast = idx;
        } else {
          nouPrev = start;
          nouLast = idx;
        }
      } else {
        nouPrev = start ?? idx;
        nouLast = idx;
      }
    }

    _prevWpIndex = nouPrev;
    _lastWpIndex = nouLast;
    _darrerWpClicat = idx;

    // AVALUEM EL SWAP I L'ORDENACIÓ DELS EXTREMS DEL TRAM
    if (_prevWpIndex != null && _lastWpIndex != null) {
      final int menor = _prevWpIndex! <= _lastWpIndex!
          ? _prevWpIndex!
          : _lastWpIndex!;
      final int major = _prevWpIndex! > _lastWpIndex!
          ? _prevWpIndex!
          : _lastWpIndex!;

      state = ElevationSelectionState(
        mode: SelectionMode.range,
        startTrackIndex: menor,
        endTrackIndex: major,
        singlePointIndex: null,
      );
    }
  }
}

final elevationSelectionProvider =
    NotifierProvider<ElevationSelectionNotifier, ElevationSelectionState>(
      ElevationSelectionNotifier.new,
    );
