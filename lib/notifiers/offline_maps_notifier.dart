import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strack_rec/services/offline_maps_service.dart';

/// Estat dels mapes offline.
///
/// [enabled] → toggle OFFLINE de l'usuari (persistit a SharedPreferences).
/// [catalunyaDownloaded] → si el fitxer catalunya.mbtiles ja és al dispositiu.
/// [downloading] → si hi ha una descàrrega en curs.
/// [progress] → bytes rebuts de la descàrrega en curs (null si no n'hi ha).
/// [progressTotal] → bytes totals esperats (null si el servidor no els informa).
class OfflineMapsState {
  final bool enabled;
  final bool catalunyaDownloaded;
  final bool downloading;
  final int? progress;
  final int? progressTotal;

  const OfflineMapsState({
    required this.enabled,
    required this.catalunyaDownloaded,
    required this.downloading,
    this.progress,
    this.progressTotal,
  });

  OfflineMapsState copyWith({
    bool? enabled,
    bool? catalunyaDownloaded,
    bool? downloading,
    int? Function()? progress,
    int? Function()? progressTotal,
  }) {
    return OfflineMapsState(
      enabled: enabled ?? this.enabled,
      catalunyaDownloaded: catalunyaDownloaded ?? this.catalunyaDownloaded,
      downloading: downloading ?? this.downloading,
      progress: progress != null ? progress() : this.progress,
      progressTotal: progressTotal != null
          ? progressTotal()
          : this.progressTotal,
    );
  }
}

class OfflineMapsNotifier extends Notifier<OfflineMapsState> {
  static const String _prefsKeyEnabled = 'offline_maps_enabled';
  static const String regioCatalunya = 'catalunya';

  @override
  OfflineMapsState build() {
    _init();
    return const OfflineMapsState(
      enabled: false,
      catalunyaDownloaded: false,
      downloading: false,
    );
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsKeyEnabled) ?? false;
    final downloaded = await OfflineMapsService.instance.isRegionDownloaded(
      regioCatalunya,
    );
    state = state.copyWith(enabled: enabled, catalunyaDownloaded: downloaded);
  }

  /// Activa/desactiva el mode offline (només té efecte visual al mapa
  /// principal si la regió està descarregada).
  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyEnabled, value);
  }

  /// Descarrega la regió de Catalunya (+ glyphs si cal).
  Future<void> downloadCatalunya() async {
    debugPrint('⬇️ [OFFLINE] downloadCatalunya() iniciat');
    if (state.downloading) {
      debugPrint(
        '⚠️ [OFFLINE] downloadCatalunya abortat: ja està descarregant',
      );
      return;
    }
    state = state.copyWith(
      downloading: true,
      progress: () => 0,
      progressTotal: () => null,
    );

    try {
      debugPrint('⬇️ [OFFLINE] ensureGlyphs()...');
      await OfflineMapsService.instance.ensureGlyphs();
      debugPrint('⬇️ [OFFLINE] ensureGlyphs() OK - iniciant downloadRegion...');
      await OfflineMapsService.instance.downloadRegion(
        regioCatalunya,
        onProgress: (received, total) {
          state = state.copyWith(
            progress: () => received,
            progressTotal: () => total,
          );
        },
      );
      debugPrint('✅ [OFFLINE] downloadRegion completat');
      state = state.copyWith(
        downloading: false,
        catalunyaDownloaded: true,
        progress: () => null,
        progressTotal: () => null,
      );
    } catch (e) {
      debugPrint('💥 [OFFLINE] Error en la descàrrega: $e');
      state = state.copyWith(
        downloading: false,
        progress: () => null,
        progressTotal: () => null,
      );
      rethrow;
    }
  }

  /// Esborra el mapa descarregat i desactiva el mode offline.
  Future<void> deleteCatalunya() async {
    await OfflineMapsService.instance.deleteRegion(regioCatalunya);
    await setEnabled(false);
    state = state.copyWith(catalunyaDownloaded: false);
  }
}

final offlineMapsProvider =
    NotifierProvider<OfflineMapsNotifier, OfflineMapsState>(
      OfflineMapsNotifier.new,
    );
