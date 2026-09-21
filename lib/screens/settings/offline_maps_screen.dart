// lib/screens/settings/offline_maps_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/offline_maps_notifier.dart';
import 'package:strack_rec/theme/app_colors.dart';

/// Pantalla de gestió del mapa offline.
///
/// Mostra un mapa amb el rectangle del bounding box de la regió disponible.
/// Si l'usuari toca dins del rectangle, se li proposa descarregar el mapa.
class OfflineMapsScreen extends ConsumerStatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  ConsumerState<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends ConsumerState<OfflineMapsScreen> {
  // Bounding box aproximat de Catalunya: SW → NE
  static const double _minLon = 0.15;
  static const double _minLat = 40.52;
  static const double _maxLon = 3.33;
  static const double _maxLat = 42.87;

  static const String _sourceId = 'offline-region-src';
  static const String _fillLayerId = 'offline-region-fill';
  static const String _lineLayerId = 'offline-region-line';

  MapLibreMapController? _controller;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [OFFLINE SCREEN] initState');
  }

  @override
  void dispose() {
    debugPrint('🔴 [OFFLINE SCREEN] dispose - netejant controller');
    _disposed = true;
    _controller = null;
    super.dispose();
  }

  bool _isInsideRegion(LatLng p) {
    final inside =
        p.longitude >= _minLon &&
        p.longitude <= _maxLon &&
        p.latitude >= _minLat &&
        p.latitude <= _maxLat;
    debugPrint(
      '🔍 [OFFLINE SCREEN] _isInsideRegion($p) = $inside '
      '(bbox: $_minLon,$_minLat → $_maxLon,$_maxLat)',
    );
    return inside;
  }

  Future<void> _addRegionLayers() async {
    if (_disposed) {
      debugPrint('⚠️ [OFFLINE SCREEN] _addRegionLayers: widget ja disposed');
      return;
    }
    if (_controller == null) {
      debugPrint('⚠️ [OFFLINE SCREEN] _addRegionLayers: controller és null');
      return;
    }

    debugPrint('🗺️ [OFFLINE SCREEN] Afegint capes del rectangle...');

    final geojson = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {},
          "geometry": {
            "type": "Polygon",
            "coordinates": [
              [
                [_minLon, _minLat],
                [_maxLon, _minLat],
                [_maxLon, _maxLat],
                [_minLon, _maxLat],
                [_minLon, _minLat],
              ],
            ],
          },
        },
      ],
    };

    try {
      debugPrint('🗺️ [OFFLINE SCREEN] Afegint source...');
      await _controller!.addSource(
        _sourceId,
        GeojsonSourceProperties(data: geojson),
      );
      debugPrint('✅ [OFFLINE SCREEN] Source afegida');

      debugPrint('🗺️ [OFFLINE SCREEN] Afegint fill layer...');
      await _controller!.addLayer(
        _sourceId,
        _fillLayerId,
        const FillLayerProperties(fillColor: '#1E88E5', fillOpacity: 0.15),
      );
      debugPrint('✅ [OFFLINE SCREEN] Fill layer afegida');

      debugPrint('🗺️ [OFFLINE SCREEN] Afegint line layer...');
      await _controller!.addLineLayer(
        _sourceId,
        _lineLayerId,
        const LineLayerProperties(lineColor: '#1E88E5', lineWidth: 3.0),
      );
      debugPrint('✅ [OFFLINE SCREEN] Line layer afegida - TOTES LES CAPES OK');
    } catch (e, stack) {
      debugPrint('💥 [OFFLINE SCREEN] Error afegint capes: $e');
      debugPrint('💥 [OFFLINE SCREEN] Stack: $stack');
    }
  }

  Future<void> _onMapClick(LatLng latLng) async {
    debugPrint('👆 [OFFLINE SCREEN] Click al mapa: $latLng');

    if (_disposed) {
      debugPrint('⚠️ [OFFLINE SCREEN] Click ignorat: widget disposed');
      return;
    }

    final offline = ref.read(offlineMapsProvider);
    if (offline.downloading) {
      debugPrint('⚠️ [OFFLINE SCREEN] Click ignorat: ja està descarregant');
      return;
    }
    if (!_isInsideRegion(latLng)) {
      debugPrint('⚠️ [OFFLINE SCREEN] Click fora del rectangle');
      return;
    }

    debugPrint('✅ [OFFLINE SCREEN] Click DINS del rectangle');

    final t = AppLocalizations.of(context)!;
    final notifier = ref.read(offlineMapsProvider.notifier);

    if (offline.catalunyaDownloaded) {
      debugPrint('⚠️ [OFFLINE SCREEN] Click ignorat: catalunya ja descarregat');
      return; // ja descarregat: no cal res
    }

    debugPrint('💬 [OFFLINE SCREEN] Obrint diàleg de confirmació...');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.offlineDownloadTitle),
        content: Text(t.offlineDownloadConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.download),
          ),
        ],
      ),
    );

    debugPrint('💬 [OFFLINE SCREEN] Diàleg tancat amb confirm=$confirm');

    if (confirm == true && mounted) {
      debugPrint('⬇️ [OFFLINE SCREEN] Cridant notifier.downloadCatalunya()...');
      try {
        await notifier.downloadCatalunya();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.offlineDownloadDone)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.offlineDownloadError),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final offline = ref.watch(offlineMapsProvider);
    final notifier = ref.read(offlineMapsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.offlineTab,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      // 🛡️ SafeArea: la card inferior no queda tapada pels botons del SO
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MapLibreMap(
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                compassEnabled: false,
                styleString: "assets/osm_style.json",
                initialCameraPosition: const CameraPosition(
                  target: LatLng(41.7, 1.7), // centre de Catalunya
                  zoom: 6.2,
                ),
                onMapCreated: (controller) {
                  debugPrint(
                    '🗺️ [OFFLINE SCREEN] onMapCreated - controller assignat',
                  );
                  _controller = controller;

                  // Igual que a barometer_settings_tab.dart: els taps sobre les
                  // capes del rectangle NO arriben a onMapClick — s'han de
                  // capturar aquí via onFeatureTapped.
                  controller.onFeatureTapped.add((
                    point,
                    latLng,
                    featureId,
                    layerId,
                    annotation,
                  ) async {
                    debugPrint(
                      '🎯 [OFFLINE SCREEN] onFeatureTapped: layerId=$layerId featureId=$featureId a $latLng',
                    );
                    if (layerId == _fillLayerId || layerId == _lineLayerId) {
                      await _onMapClick(latLng);
                    }
                  });
                },
                onStyleLoadedCallback: () async {
                  debugPrint(
                    '🎨 [OFFLINE SCREEN] onStyleLoadedCallback iniciat',
                  );
                  if (_disposed) {
                    debugPrint(
                      '⚠️ [OFFLINE SCREEN] Style loaded però widget ja disposed',
                    );
                    return;
                  }
                  if (_controller == null) {
                    debugPrint(
                      '⚠️ [OFFLINE SCREEN] Style loaded però controller és null',
                    );
                    return;
                  }
                  debugPrint('🎨 [OFFLINE SCREEN] Cridant _addRegionLayers...');
                  await _addRegionLayers();
                  debugPrint(
                    '🎨 [OFFLINE SCREEN] onStyleLoadedCallback completat',
                  );
                },
                onMapClick: (point, latLng) => _onMapClick(latLng),
              ),
            ),

            // Targeta inferior amb l'estat
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (offline.downloading) ...[
                        LinearProgressIndicator(
                          value:
                              (offline.progress != null &&
                                  offline.progressTotal != null &&
                                  offline.progressTotal! > 0)
                              ? offline.progress! / offline.progressTotal!
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          offline.progress != null
                              ? '${t.downloading}  ${_formatBytes(offline.progress!)}'
                                    '${offline.progressTotal != null ? ' / ${_formatBytes(offline.progressTotal!)}' : ''}'
                              : t.downloading,
                          textAlign: TextAlign.center,
                        ),
                      ] else if (offline.catalunyaDownloaded) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t.offlineDownloaded)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(t.offlineUseOffline),
                          value: offline.enabled,
                          onChanged: (v) => notifier.setEnabled(v),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            await notifier.deleteCatalunya();
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: Text(t.offlineDelete),
                        ),
                      ] else ...[
                        Text(
                          t.offlineTapRegion,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
