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

  bool _isInsideRegion(LatLng p) {
    return p.longitude >= _minLon &&
        p.longitude <= _maxLon &&
        p.latitude >= _minLat &&
        p.latitude <= _maxLat;
  }

  Future<void> _onStyleLoaded(MapLibreMapController controller) async {
    // Polígon del bounding box com a GeoJSON
    final geojson = {
      "type": "Feature",
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
    };

    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: geojson),
    );
    await controller.addLayer(
      _sourceId,
      _fillLayerId,
      const FillLayerProperties(fillColor: '#1E88E5', fillOpacity: 0.15),
    );
    await controller.addLineLayer(
      _sourceId,
      _lineLayerId,
      const LineLayerProperties(lineColor: '#1E88E5', lineWidth: 3.0),
    );
  }

  Future<void> _onMapClick(LatLng latLng) async {
    final offline = ref.read(offlineMapsProvider);
    if (offline.downloading) return;
    if (!_isInsideRegion(latLng)) return;

    final t = AppLocalizations.of(context)!;
    final notifier = ref.read(offlineMapsProvider.notifier);

    if (offline.catalunyaDownloaded) return; // ja descarregat: no cal res

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

    if (confirm == true && mounted) {
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
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.offlineTab),
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: "assets/osm_style.json",
            tiltGesturesEnabled: false,
            rotateGesturesEnabled: false,
            compassEnabled: false,
            initialCameraPosition: const CameraPosition(
              target: LatLng(41.7, 1.7), // centre de Catalunya
              zoom: 6.2,
            ),
            onMapCreated: (c) => _controller = c,
            onStyleLoadedCallback: () {
              if (_controller != null) _onStyleLoaded(_controller!);
            },
            onMapClick: (point, latLng) => _onMapClick(latLng),
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
    );
  }
}
