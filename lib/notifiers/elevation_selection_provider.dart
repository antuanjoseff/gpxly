// lib/notifiers/elevation_selection_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/notifiers/nearest_track_point_notifier.dart';

enum SelectionMode { none, single, range }

enum MapSelectionMode { none, reticle }

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
  @override
  ElevationSelectionState build() => ElevationSelectionState.initial();

  void startSelectionWithLongPress(int startIdx, int endIdx) {
    state = ElevationSelectionState(
      mode: SelectionMode.range,
      startTrackIndex: startIdx,
      endTrackIndex: endIdx,
      singlePointIndex: null,
    );
  }

  void setManualRange(int start, int end) {
    state = ElevationSelectionState(
      mode: SelectionMode.range,
      startTrackIndex: start,
      endTrackIndex: end,
      singlePointIndex: null,
    );
  }

  void clearSelection() {
    state = ElevationSelectionState.initial();
  }

  // 1. Modifica la funció setSinglePoint per poder passar-li el mapToolState
  void setSinglePoint(int index, {MapSelectionToolState? toolState}) {
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

  void setPointFromMapSelectionTool(int indexMesProper) {
    if (state.mode == SelectionMode.range) {
      final int? inici = state.startTrackIndex;
      final int? finalTram = state.endTrackIndex;

      if (inici != null && finalTram != null) {
        state = state.copyWith(
          mode: SelectionMode.single,
          singlePointIndex: indexMesProper,
          clearStartTrack: true,
          clearEndTrack: true,
        );
      } else if (inici != null && finalTram == null) {
        final int menor = indexMesProper <= inici ? indexMesProper : inici;
        final int major = indexMesProper > inici ? indexMesProper : inici;
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
    state = ElevationSelectionState.initial();
  }

  void fixStartFromMap(int index) {
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
    } else {
      // Eina apagada: en amagar el gràfic, netegem també cercles i tram del mapa
      clearSelection();
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
    state = const ElevationSelectionState(
      mode: SelectionMode.single,
      mapToolState: MapSelectionToolState.selectingStart,
      source: SelectionSource.map,
      forceHideChart: true,
      showCenterButton: false,
      selectionMode: MapSelectionMode.reticle,
    );
  }
}

final elevationSelectionProvider =
    NotifierProvider<ElevationSelectionNotifier, ElevationSelectionState>(
      ElevationSelectionNotifier.new,
    );
