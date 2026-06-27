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
  final int? provisionalEndIndex;
  final MapSelectionToolState mapToolState;
  final SelectionSource source;
  final bool forceHideChart;
  final bool showCenterButton; // 🚀 Para el botón flotante central

  const ElevationSelectionState({
    required this.mode,
    this.singlePointIndex,
    this.startTrackIndex,
    this.endTrackIndex,
    this.provisionalEndIndex,
    this.mapToolState = MapSelectionToolState.off,
    this.source = SelectionSource.none,
    this.forceHideChart = false,
    this.showCenterButton = false, // Por defecto apagado
  });

  factory ElevationSelectionState.initial() {
    return const ElevationSelectionState(
      mode: SelectionMode.none,
      mapToolState: MapSelectionToolState.off,
      source: SelectionSource.none,
      forceHideChart: false,
      showCenterButton: false,
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
    bool clearProvisional = false, // 🚀 Novedad para limpiezas estrictas
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
    );
  }
}

class ElevationSelectionNotifier extends Notifier<ElevationSelectionState> {
  int? _prevWpIndex;
  int? _lastWpIndex;
  int? _darrerWpClicat;

  // 🛡️ Pany de seguretat contra actualitzacions residuals
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
    _isJustSelectedFromMap = false;
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

  // -------------------------------------------------------------
  // 🚀 NOVA LÒGICA MESTRA DE SELECCIÓ DES DEL MAPA (SENSE CRIMERES)
  // -------------------------------------------------------------

  void activateMapSelectionTool() {
    _isJustSelectedFromMap = false;

    // 🎯 REGLA REQUERIDA: Llegim el punt inicial més proper immediatament al obrir
    final int? immediateNearest = ref.read(nearestTrackPointProvider);

    state = state.copyWith(
      mode: SelectionMode.single,
      singlePointIndex: null,
      startTrackIndex: null,
      endTrackIndex: null,
      provisionalEndIndex:
          immediateNearest, // 🟢 FIXEM EL VERD DES DEL SEGON ZERO!
      mapToolState: MapSelectionToolState.selectingStart,
      forceHideChart: true,
      source: SelectionSource.map,
      showCenterButton: false,
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
      mapToolState:
          MapSelectionToolState.selectingEnd, // 🔴 Transició a vermell
      source: SelectionSource.map,
      showCenterButton: false,
    );
  }

  void fixEndFromMap(int index) {
    final start = state.startTrackIndex;
    if (start == null) return;

    final menor = index < start ? index : start;
    final major = index > start ? index : start;

    // 🔒 Bloquegem qualsevol actualització residual asíncrona immediata
    _isJustSelectedFromMap = true;

    state = state.copyWith(
      startTrackIndex: menor,
      endTrackIndex: major,
      clearProvisional: true, // Esborrem la línia elàstica efímera de moviment
      mode: SelectionMode.range,
      mapToolState: MapSelectionToolState.selected, // 🏁 TRAM PERMANENT FIXAT!
      source: SelectionSource.map,
      showCenterButton: false,
    );
  }

  void handleMapMovementOnSelected() {
    // 🚫 NO fem res. El tram selected és persistent.
    if (state.mapToolState == MapSelectionToolState.selected) {
      return;
    }
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

  // 📈 ACTUALITZACIÓ DELS KM: Escriu el provisional pur sense trepitjar els punts reals
  void updateProvisionalEnd(int index) {
    // 🚫 NOVETAT: En estat selected NO actualitzem el provisional
    if (state.mapToolState == MapSelectionToolState.selected) {
      return;
    }

    if (state.mapToolState == MapSelectionToolState.selectingStart) {
      state = state.copyWith(provisionalEndIndex: index);
    } else if (state.mapToolState == MapSelectionToolState.selectingEnd) {
      state = state.copyWith(provisionalEndIndex: index);
    }
  }

  void showSelectionButton() {
    if (state.mapToolState == MapSelectionToolState.selectingStart ||
        state.mapToolState == MapSelectionToolState.selectingEnd) {
      state = state.copyWith(showCenterButton: true);
    }
  }

  void hideSelectionButton() {
    if (state.showCenterButton) {
      state = state.copyWith(showCenterButton: false);
    }
  }

  void updateTemporaryRange({int? startIndex, int? endIndex}) {
    // 🚫 NOVETAT: En estat selected NO actualitzem el tram efímer
    if (state.mapToolState == MapSelectionToolState.selected) {
      return;
    }

    state = state.copyWith(
      startTrackIndex: startIndex,
      endTrackIndex: endIndex,
      mode: SelectionMode.range,
    );
  }
}

final elevationSelectionProvider =
    NotifierProvider<ElevationSelectionNotifier, ElevationSelectionState>(
      ElevationSelectionNotifier.new,
    );
