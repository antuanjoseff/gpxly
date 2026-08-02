// lib/notifiers/elevation_selection_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/notifiers/nearest_track_point_notifier.dart';

enum SelectionMode { none, single, range }

enum MapSelectionMode { none, reticle, waypoint }

enum MapSelectionToolState { off, selectingStart, selectingEnd, selected }

enum SelectionSource { none, chart, map }

class ElevationSelectionState {
  final SelectionMode mode;
  final int? singlePointIndex;
  final int? startTrackIndex;
  final int? endTrackIndex;
  final int? provisionalEndIndex;
  final MapSelectionToolState mapToolState;
  final SelectionSource source;
  final bool forceHideChart;
  final bool showCenterButton;
  final MapSelectionMode selectionMode;

  const ElevationSelectionState({
    required this.mode,
    this.singlePointIndex,
    this.startTrackIndex,
    this.endTrackIndex,
    this.provisionalEndIndex,
    this.mapToolState = MapSelectionToolState.off,
    this.source = SelectionSource.none,
    this.forceHideChart = false,
    this.showCenterButton = false,
    this.selectionMode = MapSelectionMode.none,
  });

  factory ElevationSelectionState.initial() {
    return const ElevationSelectionState(
      mode: SelectionMode.none,
      mapToolState: MapSelectionToolState.off,
      source: SelectionSource.none,
      forceHideChart: false,
      showCenterButton: false,
      selectionMode: MapSelectionMode.none,
    );
  }

  ElevationSelectionState copyWith({
    SelectionMode? mode,
    int? singlePointIndex,
    int? startTrackIndex,
    int? endTrackIndex,
    int? provisionalEndIndex,
    MapSelectionToolState? mapToolState,
    SelectionSource? source,
    bool? forceHideChart,
    bool? showCenterButton,
    bool clearSinglePoint = false,
    bool clearStartTrack = false,
    bool clearEndTrack = false,
    bool clearProvisional = false,
    MapSelectionMode? selectionMode,
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
      provisionalEndIndex: clearProvisional
          ? null
          : (provisionalEndIndex ?? this.provisionalEndIndex),
      mapToolState: mapToolState ?? this.mapToolState,
      source: source ?? this.source,
      forceHideChart: forceHideChart ?? this.forceHideChart,
      showCenterButton: showCenterButton ?? this.showCenterButton,
      // 🟢 FIX CRÍTIC: Ara el copyWith manté i propaga correctament el mode actiu
      selectionMode: selectionMode ?? this.selectionMode,
    );
  }
}

class ElevationSelectionNotifier extends Notifier<ElevationSelectionState> {
  int? _prevWpIndex;
  int? _lastWpIndex;
  int? _darrerWpClicat;
  bool _isJustSelectedFromMap = false;

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

  void clearSelection() {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;
    _isJustSelectedFromMap = false;
    state = ElevationSelectionState.initial();
  }

  // 1. Modifica la funció setSinglePoint per poder passar-li el mapToolState
  void setSinglePoint(int index, {MapSelectionToolState? toolState}) {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;

    state = ElevationSelectionState(
      mode: SelectionMode.single,
      singlePointIndex: index,
      startTrackIndex: null,
      endTrackIndex: null,
      selectionMode: state.selectionMode, // Conservem el submode actiu de la UI
      // 🚀 UNITAT DE FLUX: Si li passem un estat d'eina el guardem, si no usem l'actual
      mapToolState: toolState ?? state.mapToolState,
    );
  }

  // 2. Substitueix completament el mètode toggleWaypoint
  void toggleWaypoint(int idx, Set<int> allWpIndexes) {
    if (state.selectionMode != MapSelectionMode.waypoint) {
      return;
    }

    // 🚀 MODIFICACIÓ CLAU (Primer Waypoint Clicat):
    // Si encara no hi ha un tram (mode no és range), fixem el primer punt com a singlePointIndex,
    // però mantenim l'eina encesa avançant l'estat cap a 'selectingEnd' (esperant el segon punt).
    if (state.mode != SelectionMode.range) {
      setSinglePoint(idx, toolState: MapSelectionToolState.selectingEnd);
      return;
    }

    // A partir d'aquí és el segon clic (ja estem avaluant un rang de dades):
    final start =
        state.startTrackIndex ??
        state.singlePointIndex; // Considerem el primer clic com a inici
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
        final int distToStart = (start - idx).abs();
        final int distToEnd = (end - idx).abs();
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
        selectionMode: MapSelectionMode.waypoint,
        // 🚀 Segon Waypoint Clicat: El tram s'ha tancat del tot, passem a 'selected'
        // i això activarà l'Oient 2 de la UI per aixecar el gràfic.
        mapToolState: MapSelectionToolState.selected,
      );
    }
  }

  void setPointFromMapSelectionTool(int indexMesProper) {
    if (state.mode == SelectionMode.range) {
      final int? inici = state.startTrackIndex;
      final int? finalTram = state.endTrackIndex;

      if (inici != null && finalTram != null) {
        _prevWpIndex = null;
        _lastWpIndex = null;
        _darrerWpClicat = null;
        state = state.copyWith(
          mode: SelectionMode.single,
          singlePointIndex: indexMesProper,
          clearStartTrack: true,
          clearEndTrack: true,
        );
      } else if (inici != null && finalTram == null) {
        final int menor = indexMesProper <= inici ? indexMesProper : inici;
        final int major = indexMesProper > inici ? indexMesProper : inici;
        _prevWpIndex = menor;
        _lastWpIndex = major;
        state = state.copyWith(
          mode: SelectionMode.range,
          startTrackIndex: menor,
          endTrackIndex: major,
          clearSinglePoint: true,
        );
      } else {
        setSinglePoint(indexMesProper);
      }
    } else {
      final int? puntUnic = state.singlePointIndex;
      if (puntUnic != null) {
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
          clearSinglePoint: true,
        );
      } else {
        setSinglePoint(indexMesProper);
      }
    }
  }

  void activateMapSelectionTool() {
    _isJustSelectedFromMap = false;
    final int? immediateNearest = ref.read(nearestTrackPointProvider);
    state = state.copyWith(
      mode: SelectionMode.single,
      mapToolState: MapSelectionToolState.selectingStart,
      forceHideChart: true,
      source: SelectionSource.map,
      showCenterButton: false,
      provisionalEndIndex: immediateNearest,
    );
  }

  void deactivateMapSelectionTool() {
    _isJustSelectedFromMap = false;
    state = ElevationSelectionState.initial();
  }

  void fixStartFromMap(int index) {
    _isJustSelectedFromMap = false;
    state = state.copyWith(
      startTrackIndex: index,
      endTrackIndex: null,
      provisionalEndIndex: index,
      mode: SelectionMode.range,
      mapToolState: MapSelectionToolState.selectingEnd,
      source: SelectionSource.map,
      showCenterButton: false,
    );
  }

  void fixEndFromMap(int index) {
    final start = state.startTrackIndex;
    if (start == null) return;
    final menor = index < start ? index : start;
    final major = index > start ? index : start;
    _isJustSelectedFromMap = true;

    state = state.copyWith(
      startTrackIndex: menor,
      endTrackIndex: major,
      clearProvisional: true,
      mode: SelectionMode.range,
      mapToolState: MapSelectionToolState.selected,
      source: SelectionSource.map,
      showCenterButton: false,
    );
  }

  void handleMapMovementOnSelected() {
    if (state.mapToolState == MapSelectionToolState.selected) {
      state = state.copyWith(showCenterButton: true);
    }
  }

  void iniciarNouTramDesDeSelected(int indexNouInici) {
    _isJustSelectedFromMap = false;
    state = state.copyWith(
      mode: SelectionMode.range,
      startTrackIndex: indexNouInici,
      provisionalEndIndex: indexNouInici,
      mapToolState: MapSelectionToolState.selectingEnd,
      clearEndTrack: true,
      clearSinglePoint: true,
      source: SelectionSource.map,
      showCenterButton: false,
    );
  }

  void resetMapSelection() {
    _isJustSelectedFromMap = false;
    final int? currentNearest = ref.read(nearestTrackPointProvider);
    state = state.copyWith(
      mapToolState: MapSelectionToolState.selectingStart,
      mode: SelectionMode.single,
      startTrackIndex: null,
      endTrackIndex: null,
      singlePointIndex: null,
      clearSinglePoint: true,
      clearStartTrack: true,
      clearEndTrack: true,
      provisionalEndIndex: currentNearest,
      source: SelectionSource.map,
      showCenterButton: false,
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
    // 🟢 FIX: Permetem el pas del punt tant si s'usa retícula com waypoint
    if (state.selectionMode == MapSelectionMode.none) return;
    if (state.mapToolState == MapSelectionToolState.selected) return;
    if (state.mapToolState == MapSelectionToolState.selectingStart ||
        state.mapToolState == MapSelectionToolState.selectingEnd) {
      state = state.copyWith(provisionalEndIndex: index);
    }
  }

  void showSelectionButton() {
    if (state.mapToolState == MapSelectionToolState.selectingStart ||
        state.mapToolState == MapSelectionToolState.selectingEnd ||
        state.mapToolState == MapSelectionToolState.selected) {
      state = state.copyWith(showCenterButton: true);
    }
  }

  void hideSelectionButton() {
    if (state.showCenterButton) {
      state = state.copyWith(showCenterButton: false);
    }
  }

  void updateTemporaryRange({int? startIndex, int? endIndex}) {
    if (state.selectionMode == MapSelectionMode.none) return;
    if (state.mapToolState == MapSelectionToolState.selected) return;
    state = state.copyWith(
      startTrackIndex: startIndex,
      endTrackIndex: endIndex,
      mode: SelectionMode.range,
    );
  }

  // 🟢 FIX: Atòmiques nets que assignen correctament el mode inicial sense trencar estats residuals
  void activateReticleMode() {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;
    _isJustSelectedFromMap = false;
    state = const ElevationSelectionState(
      mode: SelectionMode.single,
      mapToolState: MapSelectionToolState.selectingStart,
      source: SelectionSource.map,
      forceHideChart: true,
      showCenterButton: false,
      selectionMode: MapSelectionMode.reticle,
    );
  }

  void activateWaypointMode() {
    _prevWpIndex = null;
    _lastWpIndex = null;
    _darrerWpClicat = null;
    _isJustSelectedFromMap = false;
    state = const ElevationSelectionState(
      mode: SelectionMode.single,
      mapToolState: MapSelectionToolState.selectingStart,
      source: SelectionSource.chart,
      forceHideChart: false,
      showCenterButton: false,
      selectionMode: MapSelectionMode.waypoint,
    );
  }
}

final elevationSelectionProvider =
    NotifierProvider<ElevationSelectionNotifier, ElevationSelectionState>(
      ElevationSelectionNotifier.new,
    );
