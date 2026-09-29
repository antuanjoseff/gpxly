import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strack_rec/models/offline_map_region.dart';
import 'package:strack_rec/services/offline_maps_service.dart';

/// Estat d'una regió de mapa offline concreta.
class OfflineRegionInfo {
  final String id;
  final String name;
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;
  final Map<String, dynamic> geometry;
  final bool downloaded;
  final bool downloading;
  final int? progress;
  final int? progressTotal;
  final int? fileSizeBytes;
  final DateTime? downloadedAt;

  const OfflineRegionInfo({
    required this.id,
    required this.name,
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
    required this.geometry,
    required this.downloaded,
    required this.downloading,
    this.progress,
    this.progressTotal,
    this.fileSizeBytes,
    this.downloadedAt,
  });

  factory OfflineRegionInfo.fromRegion(
    OfflineMapRegion region, {
    required bool downloaded,
    DateTime? downloadedAt,
  }) {
    return OfflineRegionInfo(
      id: region.id,
      name: region.name,
      minLon: region.minLon,
      minLat: region.minLat,
      maxLon: region.maxLon,
      maxLat: region.maxLat,
      geometry: region.geometry,
      downloaded: downloaded,
      downloading: false,
      fileSizeBytes: region.fileSizeBytes,
      downloadedAt: downloadedAt,
    );
  }

  OfflineRegionInfo copyWith({
    bool? downloaded,
    bool? downloading,
    int? Function()? progress,
    int? Function()? progressTotal,
    DateTime? downloadedAt,
  }) {
    return OfflineRegionInfo(
      id: id,
      name: name,
      minLon: minLon,
      minLat: minLat,
      maxLon: maxLon,
      maxLat: maxLat,
      geometry: geometry,
      downloaded: downloaded ?? this.downloaded,
      downloading: downloading ?? this.downloading,
      progress: progress != null ? progress() : this.progress,
      progressTotal: progressTotal != null
          ? progressTotal()
          : this.progressTotal,
      fileSizeBytes: fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }
}

/// Estat global dels mapes offline.
///
/// [enabled] → toggle OFFLINE de l'usuari (persistit a SharedPreferences).
/// Quan és `true`, TOTS els mbtiles descarregats formen part de la
/// cartografia base del mapa principal (no hi ha una única regió "activa").
/// [loadingRegions] → si s'estan carregant les regions disponibles del servidor.
/// [regions] → llista de regions disponibles al servidor amb el seu estat local.
class OfflineMapsState {
  final bool enabled;
  final bool loadingRegions;
  final List<OfflineRegionInfo> regions;

  const OfflineMapsState({
    required this.enabled,
    required this.loadingRegions,
    required this.regions,
  });

  List<String> get downloadedRegionIds =>
      regions.where((r) => r.downloaded).map((r) => r.id).toList();

  bool get hasDownloadedRegions => regions.any((r) => r.downloaded);

  OfflineMapsState copyWith({
    bool? enabled,
    bool? loadingRegions,
    List<OfflineRegionInfo>? regions,
  }) {
    return OfflineMapsState(
      enabled: enabled ?? this.enabled,
      loadingRegions: loadingRegions ?? this.loadingRegions,
      regions: regions ?? this.regions,
    );
  }
}

class OfflineMapsNotifier extends Notifier<OfflineMapsState> {
  static const String _prefsKeyEnabled = 'offline_maps_enabled';
  String? _activeDownloadId;
  bool _cancelRequested = false;

  @override
  OfflineMapsState build() {
    _init();
    return const OfflineMapsState(
      enabled: false,
      loadingRegions: true,
      regions: [],
    );
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsKeyEnabled) ?? false;
    await reloadRegions();
    state = state.copyWith(enabled: enabled);
  }

  /// Recarrega la llista de regions disponibles al servidor i el seu estat
  /// de descàrrega local.
  Future<void> reloadRegions() async {
    state = state.copyWith(loadingRegions: true);
    try {
      final fetched = await OfflineMapsService.instance.fetchAvailableRegions();
      final infos = <OfflineRegionInfo>[];
      for (final region in fetched) {
        final downloaded = await OfflineMapsService.instance.isRegionDownloaded(
          region.id,
        );
        final downloadedAt = downloaded
            ? await OfflineMapsService.instance.regionLastModified(region.id)
            : null;
        infos.add(
          OfflineRegionInfo.fromRegion(
            region,
            downloaded: downloaded,
            downloadedAt: downloadedAt,
          ),
        );
      }
      state = state.copyWith(regions: infos, loadingRegions: false);
    } catch (e) {
      debugPrint('💥 [OFFLINE] Error carregant regions disponibles: $e');
      state = state.copyWith(loadingRegions: false);
    }
  }

  /// Activa/desactiva el mode offline (només té efecte visual al mapa
  /// principal si hi ha almenys una regió descarregada).
  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyEnabled, value);
  }

  /// Descarrega la regió [regionId] (+ glyphs si cal).
  Future<bool> downloadRegion(String regionId) async {
    debugPrint('⬇️ [OFFLINE] downloadRegion($regionId) iniciat');
    if (_activeDownloadId != null ||
        state.regions.firstWhere((r) => r.id == regionId).downloading) {
      debugPrint(
        '⚠️ [OFFLINE] downloadRegion abortat: ja hi ha una descàrrega',
      );
      return false;
    }
    _activeDownloadId = regionId;
    _cancelRequested = false;
    _updateRegion(
      regionId,
      (r) => r.copyWith(
        downloading: true,
        progress: () => 0,
        progressTotal: () => null,
      ),
    );

    try {
      await OfflineMapsService.instance.ensureGlyphs();
      if (_cancelRequested) return false;
      final file = await OfflineMapsService.instance.downloadRegion(
        regionId,
        onProgress: (received, total) {
          _updateRegion(
            regionId,
            (r) => r.copyWith(
              progress: () => received,
              progressTotal: () => total,
            ),
          );
        },
      );
      if (file == null) return false;
      debugPrint('✅ [OFFLINE] downloadRegion($regionId) completat');
      _updateRegion(
        regionId,
        (r) => r.copyWith(
          downloading: false,
          downloaded: true,
          progress: () => null,
          progressTotal: () => null,
          downloadedAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      if (_cancelRequested) return false;
      debugPrint('💥 [OFFLINE] Error descarregant "$regionId": $e');
      rethrow;
    } finally {
      _activeDownloadId = null;
      _cancelRequested = false;
      _updateRegion(
        regionId,
        (r) => r.copyWith(
          downloading: false,
          progress: () => null,
          progressTotal: () => null,
        ),
      );
    }
  }

  void cancelDownload() {
    final regionId = _activeDownloadId;
    if (regionId == null) return;
    _cancelRequested = true;
    OfflineMapsService.instance.cancelRegionDownload(regionId);
  }

  /// Esborra la regió descarregada [regionId]. Si no queda cap regió
  /// descarregada, desactiva el mode offline.
  Future<void> deleteRegion(String regionId) async {
    await OfflineMapsService.instance.deleteRegion(regionId);
    _updateRegion(regionId, (r) => r.copyWith(downloaded: false));
    if (!state.hasDownloadedRegions) {
      await setEnabled(false);
    }
  }

  void _updateRegion(
    String regionId,
    OfflineRegionInfo Function(OfflineRegionInfo) update,
  ) {
    state = state.copyWith(
      regions: [
        for (final r in state.regions)
          if (r.id == regionId) update(r) else r,
      ],
    );
  }
}

final offlineMapsProvider =
    NotifierProvider<OfflineMapsNotifier, OfflineMapsState>(
      OfflineMapsNotifier.new,
    );
