// lib/notifiers/elevation_selection_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/nearest_track_point_notifier.dart';

enum SelectionMode {
  none, // Cap agulla, cap punt.
  single, // Mode punt único: Cercle taronja al mapa / 1 agulla al gràfic.
  range, // Mode tram (Requerix Long Press): Cercles verd i vermell / 2 agulles al gràfic.
}

enum MapSelectionToolState { off, selectingStart, selectingEnd, selected }

enum SelectionSource { none, chart, map }

class ElevationSelectionState {
  final SelectionMode mode;
  final int? singlePointIndex;
  final int? startTrackIndex;
  final int? endTrackIndex;
  final int? provisionalEndIndex; // 🚀 AÑADIR AQUÍ
  final MapSelectionToolState mapToolState;
  final SelectionSource source;
  final bool forceHideChart;

  const ElevationSelectionState({
    required this.mode,
    this.singlePointIndex,
    this.startTrackIndex,
    this.endTrackIndex,
    this.provisionalEndIndex, // 🚀 AÑADIR AQUÍ
    this.mapToolState = MapSelectionToolState.off,
    this.source = SelectionSource.none,
    this.forceHideChart = false,
  });

  factory ElevationSelectionState.initial() {
    return const ElevationSelectionState(
      mode: SelectionMode.none,
      mapToolState: MapSelectionToolState.off,
      source: SelectionSource.none,
      forceHideChart: false,
    );
  }

  ElevationSelectionState copyWith({
    SelectionMode? mode,
    int? singlePointIndex,
    int? startTrackIndex,
    int? endTrackIndex,
    int? provisionalEndIndex, // 🚀 AÑADIR AQUÍ
    MapSelectionToolState? mapToolState,
    SelectionSource? source,
    bool? forceHideChart,
    bool clearSinglePoint = false,
    bool clearStartTrack = false,
    bool clearEndTrack = false,
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
      provisionalEndIndex:
          provisionalEndIndex ?? this.provisionalEndIndex, // 🚀 AÑADIR AQUÍ
      mapToolState: mapToolState ?? this.mapToolState,
      source: source ?? this.source,
      forceHideChart: forceHideChart ?? this.forceHideChart,
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

  void setManualRange(int start, int end) {
    _prevWpIndex = start;
    _lastWpIndex = end;
    _darrerWpClicat = null;

    state = ElevationSelectionState(
      mode: SelectionMode.range,
      startTrackIndex: start,
      endTrackIndex: end,
      singlePointIndex: null,
    );
  }

  void setSinglePoint(int index) {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;

    state = ElevationSelectionState(
      mode: SelectionMode.single,
      singlePointIndex: index,
      startTrackIndex: null,
      endTrackIndex: null,
    );
  }

  void clearSelection() {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;
    state = ElevationSelectionState.initial();
  }

  void toggleWaypoint(int idx, Set<int> allWpIndexes) {
    if (state.mode != SelectionMode.range) {
      setSinglePoint(idx);
      return;
    }

    final start = state.startTrackIndex;
    final end = state.endTrackIndex;

    final bool startIsOnWaypoint =
        start != null && allWpIndexes.contains(start);
    final bool endIsOnWaypoint = end != null && allWpIndexes.contains(end);

    int? nouPrev;
    int? nouLast;

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
    } else if (startIsOnWaypoint || endIsOnWaypoint) {
      if (startIsOnWaypoint) {
        nouPrev = start;
        nouLast = idx;
      } else {
        nouPrev = end;
        nouLast = idx;
      }
    } else {
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

  // 🟢 IMPLEMENTACIÓ ADAPTADA DE L'EINA DE SELECCIÓ (BUCLE INFINIT)
  void setPointFromMapSelectionTool(int indexMesProper) {
    // CAS A: Ja som en mode RANGE (Dues agulles pintades o el tram sencer en pantalla)
    if (state.mode == SelectionMode.range) {
      final int? inici = state.startTrackIndex;
      final int? finalTram = state.endTrackIndex;

      // 🔄 REGLA DEL TERCER PUNT: Si el tram ja té inici i final posats
      if (inici != null && finalTram != null) {
        _prevWpIndex = null;
        _lastWpIndex = null;
        _darrerWpClicat = null;

        // El tercer clic esborra el tram i passa el gràfic a mode SINGLE (una sola agulla)
        state = state.copyWith(
          mode: SelectionMode.single,
          singlePointIndex: indexMesProper,
          clearStartTrack: true,
          clearEndTrack: true,
        );
      }
      // Segon Clic ordinari: Teníem l'inici guardat i ara fixem el final (Tanca el tram)
      else if (inici != null && finalTram == null) {
        final int menor = indexMesProper <= inici ? indexMesProper : inici;
        final int major = indexMesProper > inici ? indexMesProper : inici;

        _prevWpIndex = menor;
        _lastWpIndex = major;

        state = state.copyWith(
          mode: SelectionMode.range,
          startTrackIndex: menor,
          endTrackIndex: major,
          clearSinglePoint: true, // Apaguem l'agulla taronja
        );
      } else {
        // Seguretat per si els camps fossin nuls estant en mode range
        setSinglePoint(indexMesProper);
      }
    }
    // CAS B: Som en mode SINGLE (Una sola agulla activa des del primer clic)
    else {
      final int? puntUnic = state.singlePointIndex;

      if (puntUnic != null) {
        // L'agulla única es converteix en el Punt d'Inici i el nou clic és el Punt Final
        final int menor = indexMesProper <= puntUnic
            ? indexMesProper
            : puntUnic;
        final int major = indexMesProper > puntUnic ? indexMesProper : puntUnic;

        _prevWpIndex = menor;
        _lastWpIndex = major;

        state = state.copyWith(
          mode: SelectionMode.range,
          startTrackIndex: menor,
          endTrackIndex: major,
          clearSinglePoint:
              true, // El taronja s'apaga i neixen el verd i vermell GeoJSON
        );
      } else {
        // Si no hi hagués cap agulla d'origen, s'inicialitza la primera
        setSinglePoint(indexMesProper);
      }
    }
  }

  // -------------------------------------------------------------
  // NOVA LÒGICA DE L’EINA DE SELECCIÓ DES DEL MAPA
  // -------------------------------------------------------------

  void activateMapSelectionTool() {
    // Obtenim el punt més proper al reticle
    final nearest = ref.read(nearestTrackPointProvider);

    state = state.copyWith(
      mode: SelectionMode.single,
      singlePointIndex: null,
      startTrackIndex: null,
      endTrackIndex: null,
      mapToolState: MapSelectionToolState.selectingStart,
      forceHideChart: true,
      source: SelectionSource.map,
    );
  }

  void deactivateMapSelectionTool() {
    state = ElevationSelectionState.initial();
  }

  void fixStartFromMap(int index) {
    state = state.copyWith(
      startTrackIndex: index,
      endTrackIndex: null,
      mode: SelectionMode.range,
      mapToolState: MapSelectionToolState.selectingEnd,
      source: SelectionSource.map,
    );
  }

  void fixEndFromMap(int index) {
    final start = state.startTrackIndex;
    if (start == null) return;

    final menor = index < start ? index : start;
    final major = index > start ? index : start;

    state = state.copyWith(
      startTrackIndex: menor,
      endTrackIndex: major,
      mode: SelectionMode.range,
      mapToolState: MapSelectionToolState.selected,
      source: SelectionSource.map,
    );
  }

  void resetMapSelection() {
    state = state.copyWith(
      mapToolState: MapSelectionToolState.selectingStart, // Reticle visible
      mode: SelectionMode.none,
      startTrackIndex: null,
      endTrackIndex: null,
      singlePointIndex: null,
      clearSinglePoint: true,
      clearStartTrack: true,
      clearEndTrack: true,
      source: SelectionSource.map,
    );
  }

  void userOpenedChart() {
    state = state.copyWith(forceHideChart: false);
  }

  void userCollapsedChart() {
    if (state.mapToolState != MapSelectionToolState.off) {
      state = state.copyWith(forceHideChart: true);
    }
  }

  void updateProvisionalEnd(int index) {
    if (state.mapToolState == MapSelectionToolState.selectingEnd) {
      state = state.copyWith(provisionalEndIndex: index);
    }
  }
}

final elevationSelectionProvider =
    NotifierProvider<ElevationSelectionNotifier, ElevationSelectionState>(
      ElevationSelectionNotifier.new,
    );
