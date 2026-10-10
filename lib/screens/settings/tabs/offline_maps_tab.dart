import 'dart:async';
// lib/screens/settings/offline_maps_screen.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/map_bearing_provider.dart';
import 'package:strack_rec/notifiers/offline_maps_notifier.dart';
import 'package:strack_rec/services/offline_maps_service.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/widgets/compass_widget.dart';

/// Pantalla de gestió del mapa offline.
///
/// Mostra les regions disponibles i permet sol·licitar-ne de noves.
class OfflineMapsScreen extends ConsumerStatefulWidget {
  const OfflineMapsScreen({super.key});

  @override
  ConsumerState<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends ConsumerState<OfflineMapsScreen> {
  static const String _emailPreferenceKey = 'offline_maps_request_email';
  static const String _sourceId = 'offline-regions-src';
  static const String _fillLayerId = 'offline-regions-fill';
  static const String _lineLayerId = 'offline-regions-line';
  static const String _proposalSourceId = 'geofabrik-proposal-src';
  static const String _proposalFillLayerId = 'geofabrik-proposal-fill';
  static const String _proposalLineLayerId = 'geofabrik-proposal-line';

  MapLibreMapController? _controller;
  bool _disposed = false;
  bool _layersReady = false;
  bool _cameraFitted = false;
  bool _loadingGeofabrikRegions = true;
  List<GeofabrikRegion> _geofabrikRegions = [];
  GeofabrikRegion? _proposedRegion;
  bool _showAvailable = true;
  bool _showDownloaded = true;
  bool _handlingTap = false;

  @override
  void initState() {
    super.initState();
    _loadGeofabrikRegions();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller = null;
    super.dispose();
  }

  Map<String, dynamic> _buildFeatureCollection(
    List<OfflineRegionInfo> regions,
  ) {
    // Els més grans primer (a sota) i els més petits al final (a sobre).
    double area(OfflineRegionInfo r) =>
        (r.maxLon - r.minLon) * (r.maxLat - r.minLat);
    final sorted = regions.where(_isRegionVisible).toList()
      ..sort((a, b) => area(b).compareTo(area(a)));
    return {
      "type": "FeatureCollection",
      "features": [
        for (final r in sorted)
          {
            "type": "Feature",
            "id": r.id,
            "properties": {
              "id": r.id,
              "name": r.name,
              "downloaded": r.downloaded,
            },
            "geometry": r.geometry,
          },
      ],
    };
  }

  bool _isRegionVisible(OfflineRegionInfo r) =>
      r.downloaded ? _showDownloaded : _showAvailable;

  Map<String, dynamic> _buildProposalFeatureCollection() {
    final region = _proposedRegion;
    if (region == null) return {'type': 'FeatureCollection', 'features': []};
    return {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {"name": region.name},
          "geometry": {
            "type": "Polygon",
            "coordinates": [
              [
                [region.minLon, region.minLat],
                [region.maxLon, region.minLat],
                [region.maxLon, region.maxLat],
                [region.minLon, region.maxLat],
                [region.minLon, region.minLat],
              ],
            ],
          },
        },
      ],
    };
  }

  Future<void> _addOrUpdateRegionLayers(List<OfflineRegionInfo> regions) async {
    if (_disposed || _controller == null) return;
    final geojson = _buildFeatureCollection(regions);
    final proposalGeojson = _buildProposalFeatureCollection();

    if (!_layersReady) {
      await _controller!.addSource(
        _sourceId,
        GeojsonSourceProperties(data: geojson),
      );
      await _controller!.addFillLayer(
        _sourceId,
        _fillLayerId,
        const FillLayerProperties(
          fillColor: [
            Expressions.caseExpression,
            ['get', 'downloaded'],
            '#2E7D32',
            '#1E88E5',
          ],
          fillOpacity: 0.2,
        ),
      );
      await _controller!.addLineLayer(
        _sourceId,
        _lineLayerId,
        const LineLayerProperties(
          lineColor: [
            Expressions.caseExpression,
            ['get', 'downloaded'],
            '#2E7D32',
            '#1E88E5',
          ],
          lineWidth: 3.0,
        ),
      );
      await _controller!.addSource(
        _proposalSourceId,
        GeojsonSourceProperties(data: proposalGeojson),
      );
      await _controller!.addFillLayer(
        _proposalSourceId,
        _proposalFillLayerId,
        const FillLayerProperties(fillColor: '#F9A825', fillOpacity: 0.22),
      );
      await _controller!.addLineLayer(
        _proposalSourceId,
        _proposalLineLayerId,
        const LineLayerProperties(lineColor: '#F9A825', lineWidth: 3),
      );
      _layersReady = true;
    } else {
      await _controller!.setGeoJsonSource(_sourceId, geojson);
      await _controller!.setGeoJsonSource(_proposalSourceId, proposalGeojson);
    }
  }

  Future<void> _loadGeofabrikRegions() async {
    try {
      final regions = await OfflineMapsService.instance.fetchGeofabrikRegions();
      if (mounted) setState(() => _geofabrikRegions = regions);
    } catch (error) {
      debugPrint('Error carregant regions Geofabrik: $error');
    } finally {
      if (mounted) setState(() => _loadingGeofabrikRegions = false);
    }
  }

  Future<void> _onRegionTap(String regionId) async {
    if (_disposed) return;
    final offline = ref.read(offlineMapsProvider);
    if (offline.regions.any((region) => region.downloading)) return;
    final region = _findRegion(offline.regions, regionId);
    if (region == null) return;

    final t = AppLocalizations.of(context)!;
    final notifier = ref.read(offlineMapsProvider.notifier);
    if (region.downloaded) {
      final confirmDelete = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.offlineDelete),
          content: Text(region.name),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.offlineDelete),
            ),
          ],
        ),
      );
      if (confirmDelete == true && mounted) {
        await notifier.deleteRegion(regionId);
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.offlineDownloadTitle),
        content: Text(
          region.fileSizeBytes != null
              ? t.offlineTapRegionInfo(
                  region.name,
                  _formatBytes(region.fileSizeBytes!),
                )
              : region.name,
        ),
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
        final downloaded = await notifier.downloadRegion(regionId);
        if (downloaded && mounted && !ref.read(offlineMapsProvider).enabled) {
          final activateOffline = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(t.offlineDownloadDone),
              content: Text(t.offlineEnableAfterDownload),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(t.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(t.offlineActivate),
                ),
              ],
            ),
          );
          if (activateOffline == true && mounted) {
            await notifier.setEnabled(true);
          }
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

  OfflineRegionInfo? _findRegion(List<OfflineRegionInfo> regions, String id) {
    for (final r in regions) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool _isInsideRegion(OfflineRegionInfo r, LatLng p) {
    return p.longitude >= r.minLon &&
        p.longitude <= r.maxLon &&
        p.latitude >= r.minLat &&
        p.latitude <= r.maxLat;
  }

  /// Un sol toc sobre un rectangle visible obre el diàleg de descàrrega
  /// (blau) o d'eliminació (verd).
  Future<void> _onMapClick(LatLng latLng) async {
    if (_disposed || _requestPanel != null || _handlingTap) return;
    final regions = ref.read(offlineMapsProvider).regions;
    final region = _smallestRegionAt(regions, latLng, onlyVisible: true);
    if (region == null) return;
    _handlingTap = true;
    try {
      await _onRegionTap(region.id);
    } finally {
      _handlingTap = false;
    }
  }

  /// Si diverses regions se solapen, la més petita té prioritat.
  OfflineRegionInfo? _smallestRegionAt(
    List<OfflineRegionInfo> regions,
    LatLng p, {
    bool onlyVisible = false,
  }) {
    OfflineRegionInfo? best;
    var bestArea = double.infinity;
    for (final r in regions) {
      if (!_isInsideRegion(r, p)) continue;
      if (onlyVisible && !_isRegionVisible(r)) continue;
      final area = (r.maxLon - r.minLon) * (r.maxLat - r.minLat);
      if (area < bestArea) {
        best = r;
        bestArea = area;
      }
    }
    return best;
  }

  void _showMessage(String text, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: success
              ? Colors.green.shade700
              : Colors.red.shade700,
        ),
      );
  }

  Future<void> _focusCameraOnRegion(GeofabrikRegion region) async {
    if (_disposed || _controller == null) return;
    final panelBox = _requestPanelKey.currentContext?.findRenderObject();
    final panelHeight = panelBox is RenderBox && panelBox.hasSize
        ? panelBox.size.height
        : 0.0;
    final bottomPadding = panelHeight > 0 ? panelHeight + 8 + 24 : 240.0;
    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(region.minLat, region.minLon),
          northeast: LatLng(region.maxLat, region.maxLon),
        ),
        left: 40,
        top: 40,
        right: 40,
        bottom: bottomPadding,
      ),
    );
  }

  Future<void> _onMapLongClick(LatLng point) async {
    if (_disposed) return;
    final available = ref.read(offlineMapsProvider).regions;
    if (_requestPanel != null) return;
    if (_smallestRegionAt(available, point, onlyVisible: true) != null) {
      _showMessage('Aquesta zona ja està generada');
      return;
    }

    if (_geofabrikRegions.isEmpty) {
      await _loadGeofabrikRegions();
      if (!mounted) return;
      if (_geofabrikRegions.isEmpty) {
        _showMessage('No s’han pogut carregar les zones generables');
        return;
      }
    }

    final matches = _geofabrikRegions.where(
      (region) =>
          point.longitude >= region.minLon &&
          point.longitude <= region.maxLon &&
          point.latitude >= region.minLat &&
          point.latitude <= region.maxLat,
    );
    if (matches.isEmpty) {
      _showMessage('Aquesta zona no es pot generar');
      return;
    }
    final selected = matches.reduce((a, b) {
      final areaA = (a.maxLon - a.minLon) * (a.maxLat - a.minLat);
      final areaB = (b.maxLon - b.minLon) * (b.maxLat - b.minLat);
      return areaA <= areaB ? a : b;
    });

    setState(() => _proposedRegion = selected);
    await _addOrUpdateRegionLayers(available);
    if (!mounted) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      final closed = Completer<void>();
      setState(() {
        _requestPanel = _GeofabrikRequestSheet(
          regionName: selected.name,
          savedEmail: preferences.getString(_emailPreferenceKey) ?? '',
          onClose: () {
            if (!closed.isCompleted) closed.complete();
          },
          onSubmitEmail: (email) =>
              preferences.setString(_emailPreferenceKey, email),
          onRequest: (email) => OfflineMapsService.instance.requestNewRegion(
            name: selected.name,
            url: selected.pbfUrl,
            email: email,
            lang: Localizations.localeOf(context).languageCode,
          ),
        );
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _requestPanel != null) _focusCameraOnRegion(selected);
      });
      await closed.future;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No s’ha pogut enviar la sol·licitud'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error enviant petició de mapa offline: $error');
    } finally {
      if (mounted) setState(() => _requestPanel = null);
      _clearProposal();
    }
  }

  Widget? _requestPanel;
  final GlobalKey _requestPanelKey = GlobalKey();

  void _clearProposal() {
    if (!mounted) return;
    setState(() => _proposedRegion = null);
    _addOrUpdateRegionLayers(ref.read(offlineMapsProvider).regions);
  }

  /// Ajusta la càmera perquè es vegin tots els bboxes disponibles.
  Future<void> _fitCameraToRegions(List<OfflineRegionInfo> regions) async {
    if (_cameraFitted || _disposed || _controller == null || regions.isEmpty) {
      return;
    }
    _cameraFitted = true;
    var minLon = regions.first.minLon;
    var minLat = regions.first.minLat;
    var maxLon = regions.first.maxLon;
    var maxLat = regions.first.maxLat;
    for (final region in regions.skip(1)) {
      if (region.minLon < minLon) minLon = region.minLon;
      if (region.minLat < minLat) minLat = region.minLat;
      if (region.maxLon > maxLon) maxLon = region.maxLon;
      if (region.maxLat > maxLat) maxLat = region.maxLat;
    }
    await _controller!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLon),
          northeast: LatLng(maxLat, maxLon),
        ),
        left: 32,
        top: 32,
        right: 32,
        bottom: 32,
      ),
    );
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
    OfflineRegionInfo? downloadingRegion;
    for (final region in offline.regions) {
      if (region.downloading) {
        downloadingRegion = region;
        break;
      }
    }
    final hasAvailable = offline.regions.any((r) => !r.downloaded);
    final hasDownloaded = offline.hasDownloadedRegions;
    final downloadTotal = downloadingRegion == null
        ? null
        : downloadingRegion.progressTotal ?? downloadingRegion.fileSizeBytes;

    ref.listen(offlineMapsProvider, (previous, next) {
      if (previous?.regions != next.regions) {
        _addOrUpdateRegionLayers(next.regions);
        _fitCameraToRegions(next.regions);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              offline.enabled ? t.offlineTab : t.onlineLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          CompassScalePanel(
            showScale: false,
            onTapCompass: () =>
                _controller?.animateCamera(CameraUpdate.bearingTo(0)),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MapLibreMap(
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: true,
                trackCameraPosition: true,
                compassEnabled: false,
                styleString: "assets/osm_style.json",
                initialCameraPosition: const CameraPosition(
                  target: LatLng(41.7, 1.7), // centre de Catalunya
                  zoom: 6.2,
                ),
                onMapCreated: (controller) {
                  _controller = controller;

                  // Si el toc cau sobre una regió, només es dispara
                  // onFeatureTapped (no onMapClick).
                  controller.onFeatureTapped.add((
                    point,
                    latLng,
                    featureId,
                    layerId,
                    annotation,
                  ) {
                    if (layerId == _fillLayerId || layerId == _lineLayerId) {
                      _onMapClick(latLng);
                    }
                  });
                },
                onCameraMove: (cameraPosition) {
                  ref
                      .read(mapBearingProvider.notifier)
                      .update(cameraPosition.bearing);
                },
                onStyleLoadedCallback: () async {
                  if (_disposed || _controller == null) return;
                  await _addOrUpdateRegionLayers(offline.regions);
                  await _fitCameraToRegions(offline.regions);
                },
                onMapClick: (point, latLng) => _onMapClick(latLng),
                onMapLongClick: (point, latLng) => _onMapLongClick(latLng),
              ),
            ),

            if (offline.loadingRegions || _loadingGeofabrikRegions)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                ),
              ),
            if (_requestPanel == null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.94),
                      elevation: 2,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: _OfflineSwitchRow(
                          value:
                              offline.hasDownloadedRegions && offline.enabled,
                          enabled: offline.hasDownloadedRegions,
                          onChanged: notifier.setEnabled,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white.withValues(alpha: 0.94),
                      elevation: 2,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasAvailable)
                                _LegendCheckRow(
                                  color: const Color(0xFF1E88E5),
                                  icon: Icons.download_outlined,
                                  label: 'Disponible: toca per descarregar',
                                  value: _showAvailable,
                                  onChanged: (v) {
                                    setState(() => _showAvailable = v);
                                    _addOrUpdateRegionLayers(offline.regions);
                                  },
                                ),
                              if (hasDownloaded)
                                _LegendCheckRow(
                                  color: const Color(0xFF2E7D32),
                                  icon: Icons.check_circle_outline,
                                  label: 'Descarregada: toca per eliminar',
                                  value: _showDownloaded,
                                  onChanged: (v) {
                                    setState(() => _showDownloaded = v);
                                    _addOrUpdateRegionLayers(offline.regions);
                                  },
                                ),
                              if (!offline.hasDownloadedRegions) ...[
                                if (hasAvailable) const SizedBox(height: 6),
                                Text(
                                  'Descarrega una zona per activar el mode offline',
                                  style: Theme.of(context).textTheme.bodySmall,
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
            if (_requestPanel == null && downloadingRegion == null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.94),
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: _LegendItem(
                      icon: Icons.touch_app_outlined,
                      label:
                          'Mantén premut en una zona buida per generar-hi mapa',
                    ),
                  ),
                ),
              ),
            if (_requestPanel case final panel?)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: NotificationListener<SizeChangedLayoutNotification>(
                  onNotification: (_) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final region = _proposedRegion;
                      if (mounted && region != null) {
                        _focusCameraOnRegion(region);
                      }
                    });
                    return false;
                  },
                  child: SizeChangedLayoutNotifier(
                    child: Material(
                      key: _requestPanelKey,
                      color: Colors.white.withValues(alpha: 0.97),
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: panel,
                    ),
                  ),
                ),
              ),
            if (downloadingRegion case final region?)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.96),
                  elevation: 3,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${t.downloading} ${region.name}'),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value:
                                    downloadTotal != null && downloadTotal > 0
                                    ? ((region.progress ?? 0) / downloadTotal)
                                          .clamp(0.0, 1.0)
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${_formatBytes(region.progress ?? 0)} / ${downloadTotal == null ? '—' : _formatBytes(downloadTotal)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: t.cancel,
                          onPressed: notifier.cancelDownload,
                          icon: const Icon(Icons.close),
                        ),
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

class _GeofabrikRequestSheet extends StatefulWidget {
  final String regionName;
  final String savedEmail;
  final VoidCallback onClose;
  final Future<bool> Function(String email) onSubmitEmail;
  final Future<String> Function(String email) onRequest;

  const _GeofabrikRequestSheet({
    required this.regionName,
    required this.savedEmail,
    required this.onClose,
    required this.onSubmitEmail,
    required this.onRequest,
  });

  @override
  State<_GeofabrikRequestSheet> createState() => _GeofabrikRequestSheetState();
}

class _GeofabrikRequestSheetState extends State<_GeofabrikRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _enteringEmail = false;
  bool _submitting = false;
  bool _requestFailed = false;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.savedEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final email = _emailController.text.trim();
      await widget.onSubmitEmail(email);
      final message = await widget.onRequest(email);
      if (!mounted) return;
      setState(() {
        _resultMessage = message;
        _submitting = false;
      });
    } catch (error) {
      debugPrint('Error enviant petició de mapa offline: $error');
      if (!mounted) return;
      setState(() {
        _resultMessage = 'No s’ha pogut enviar la sol·licitud.\n\n$error';
        _requestFailed = true;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: _resultMessage != null
            ? _buildResultStep()
            : _enteringEmail
            ? _buildEmailStep(t)
            : _buildConfirmStep(t),
      ),
    );
  }

  Widget _buildConfirmStep(AppLocalizations t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vols iniciar la generació de cartografia offline per a ${widget.regionName}?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => widget.onClose(),
              child: Text(t.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => setState(() => _enteringEmail = true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailStep(AppLocalizations t) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sol·licitud: ${widget.regionName}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text('Introdueix el correu electrònic per rebre l’enllaç.'),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Correu electrònic'),
            validator: (value) {
              final email = value?.trim() ?? '';
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                  ? null
                  : 'Introdueix un correu vàlid';
            },
            onFieldSubmitted: (_) => _submitEmail(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _submitting ? null : () => widget.onClose(),
              child: Text(t.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _submitting ? null : _submitEmail,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _requestFailed ? 'Error' : 'Sol·licitud enviada',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(_resultMessage!),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => widget.onClose(),
            child: const Text('OK'),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color? color;
  final IconData? icon;
  final String label;

  const _LegendItem({this.color, this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color != null)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: icon == null
                ? null
                : Icon(icon, size: 14, color: Colors.white),
          )
        else
          Icon(icon, size: 18),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}

class _LegendCheckRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LegendCheckRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: _LegendItem(color: color, icon: icon, label: label),
          ),
          Checkbox(
            value: value,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (v) => onChanged(v ?? false),
          ),
        ],
      ),
    );
  }
}

class _OfflineSwitchRow extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _OfflineSwitchRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onChanged(!value);
              }
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ? 'Offline activat' : 'Offline desactivat',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: value ? AppColors.primary : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primary.withAlpha(40)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: value ? AppColors.primary : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 6,
                    child: Text(
                      'ON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: value ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    child: Text(
                      'OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: !value
                            ? Colors.grey.shade600
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: value ? AppColors.primary : Colors.grey.shade500,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
