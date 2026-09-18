import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/services/cog_service.dart';
import 'package:strack_rec/utils/map_constants.dart';

/// 🌐 Llista global de tessel·les disponibles al servidor (es carrega UN COP a l'arrencada)
/// Fallback: llista hardcoded si la crida falla.
final availableTilesProvider = FutureProvider<List<String>>((ref) async {
  try {
    return await CogService().fetchAvailableTiles();
  } catch (_) {
    return MapConstants.tifFilesEspanya;
  }
});

class DemBounds {
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;

  const DemBounds({
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
  });
}

// 📦 L'estat unificat: la llista de cel·les + l'estat del ProgressIndicator
class DemBoundsState {
  final List<DemBounds> cells;
  final bool isDownloading;

  const DemBoundsState({required this.cells, required this.isDownloading});

  DemBoundsState copyWith({List<DemBounds>? cells, bool? isDownloading}) {
    return DemBoundsState(
      cells: cells ?? this.cells,
      isDownloading: isDownloading ?? this.isDownloading,
    );
  }
}

class DemBoundsNotifier extends Notifier<DemBoundsState> {
  @override
  DemBoundsState build() {
    return const DemBoundsState(cells: [], isDownloading: false);
  }

  void setDownloading(bool value) {
    state = state.copyWith(isDownloading: value);
  }

  void addCell(double minLon, double minLat, double maxLon, double maxLat) {
    final exists = state.cells.any(
      (b) =>
          b.minLon == minLon &&
          b.minLat == minLat &&
          b.maxLon == maxLon &&
          b.maxLat == maxLat,
    );

    if (!exists) {
      state = state.copyWith(
        cells: [
          ...state.cells,
          DemBounds(
            minLon: minLon,
            minLat: minLat,
            maxLon: maxLon,
            maxLat: maxLat,
          ),
        ],
      );
    }
  }

  void clearAll() {
    state = const DemBoundsState(cells: [], isDownloading: false);
  }
}

final demBoundsProvider = NotifierProvider<DemBoundsNotifier, DemBoundsState>(
  () {
    return DemBoundsNotifier();
  },
);
