import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/dem_bounds_notifier.dart';
import 'package:senda/services/cog_service.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/ui/app_messages.dart';

class BarometerSettingsTab extends ConsumerStatefulWidget {
  const BarometerSettingsTab({super.key});

  @override
  ConsumerState<BarometerSettingsTab> createState() =>
      _BarometerSettingsTabState();
}

class _BarometerSettingsTabState extends ConsumerState<BarometerSettingsTab> {
  MapLibreMapController? _mapController;
  bool _styleLoaded = false;
  double _currentZoom = 5.5;
  bool _isHudCollapsed = false;

  static const int _maxDownloadedCellsLimit = 8;
  static const double _visibleZoomThreshold = 9.5;

  String? _downloadingKey;
  Map<String, dynamic>? _selectedCellProps;

  // 🛡️ RECOLECCIÓ COMPACTADA: Llista neta sense text repetitiu per evitar talls de línia
  final List<String> _tifFiles = [
    "N27W013",
    "N27W014",
    "N27W015",
    "N27W016",
    "N27W017",
    "N27W018",
    "N27W019",
    "N28W013",
    "N28W014",
    "N28W015",
    "N28W016",
    "N28W017",
    "N28W018",
    "N28W019",
    "N29W013",
    "N29W014",
    "N29W015",
    "N29W016",
    "N29W017",
    "N29W018",
    "N29W019",
    "N36W003",
    "N36W004",
    "N36W005",
    "N36W006",
    "N36W007",
    "N36W008",
    "N36W009",
    "N36W010",
    "N36W011",
    "N37W003",
    "N37W004",
    "N37W005",
    "N37W006",
    "N37W007",
    "N37W008",
    "N37W009",
    "N37W010",
    "N37W011",
    "N38E000",
    "N38E001",
    "N38E002",
    "N38E003",
    "N38E004",
    "N38W001",
    "N38W002",
    "N38W003",
    "N38W004",
    "N38W005",
    "N38W006",
    "N38W007",
    "N38W008",
    "N38W009",
    "N38W010",
    "N38W011",
    "N39E000",
    "N39E001",
    "N39E002",
    "N39E003",
    "N39E004",
    "N39W001",
    "N39W002",
    "N39W003",
    "N39W004",
    "N39W005",
    "N39W006",
    "N39W007",
    "N39W008",
    "N39W009",
    "N39W010",
    "N39W011",
    "N40E000",
    "N40E001",
    "N40E002",
    "N40E003",
    "N40E004",
    "N40W001",
    "N40W002",
    "N40W003",
    "N40W004",
    "N40W005",
    "N40W006",
    "N40W007",
    "N40W008",
    "N40W009",
    "N40W010",
    "N40W011",
    "N41E000",
    "N41E001",
    "N41E002",
    "N41E003",
    "N41E004",
    "N41W001",
    "N41W002",
    "N41W003",
    "N41W004",
    "N41W005",
    "N41W006",
    "N41W007",
    "N41W008",
    "N41W009",
    "N41W010",
    "N41W011",
    "N42E000",
    "N42E001",
    "N42E002",
    "N42E003",
    "N42E004",
    "N42W001",
    "N42W002",
    "N42W003",
    "N42W004",
    "N42W005",
    "N42W006",
    "N42W007",
    "N42W008",
    "N42W009",
    "N42W010",
    "N42W011",
    "N43E000",
    "N43E001",
    "N43E002",
    "N43E003",
    "N43E004",
    "N43W001",
    "N43W002",
    "N43W003",
    "N43W004",
    "N43W005",
    "N43W006",
    "N43W007",
    "N43W008",
    "N43W009",
    "N43W010",
    "N43W011",
    "N44E000",
    "N44E001",
    "N44E002",
    "N44E003",
    "N44E004",
    "N44W001",
    "N44W002",
    "N44W003",
    "N44W004",
    "N44W005",
    "N44W006",
    "N44W007",
    "N44W008",
    "N44W009",
    "N44W010",
    "N44W011",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await CogService().initService(ref);
      if (mounted && _styleLoaded) {
        _refreshGridGeometry();
      }
    });
  }

  Map<String, dynamic> _buildGridGeoJson() {
    final List<Map<String, dynamic>> features = [];
    final activeMaps = CogService().activeCacheMaps;

    for (final filename in _tifFiles) {
      final latBase = double.parse(filename.substring(1, 3));
      final lonSign = filename.substring(3, 4) == 'E' ? 1.0 : -1.0;
      final lonBase = double.parse(filename.substring(4, 7)) * lonSign;

      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
          final double minLat = latBase + (i * 0.2);
          final double maxLat = minLat + 0.2;
          final double minLon = lonBase + (j * 0.2);
          final double maxLon = minLon + 0.2;

          bool isDownloaded = false;
          for (final map in activeMaps) {
            if ((map.minLat - minLat).abs() < 0.01 &&
                (map.minLon - minLon).abs() < 0.01) {
              isDownloaded = true;
              break;
            }
          }

          final String key =
              "${minLat.toStringAsFixed(1)}_${minLon.toStringAsFixed(1)}";
          int currentStatus = isDownloaded ? 2 : 0;
          if (_downloadingKey == key) currentStatus = 1;

          features.add({
            "type": "Feature",
            "properties": {
              "status": currentStatus,
              "minLat": minLat,
              "minLon": minLon,
              "maxLat": maxLat,
              "maxLon": maxLon,
            },
            "geometry": {
              "type": "Polygon",
              "coordinates": [
                [
                  [minLon, minLat],
                  [maxLon, minLat],
                  [maxLon, maxLat],
                  [minLon, maxLat],
                  [minLon, minLat],
                ],
              ],
            },
          });
        }
      }
    }
    return {"type": "FeatureCollection", "features": features};
  }

  Future<void> _refreshGridGeometry() async {
    if (_mapController == null || !_styleLoaded) return;
    final geojson = _buildGridGeoJson();

    try {
      await _mapController!.setGeoJsonSource("dem_grid_source", geojson);
    } catch (_) {
      await _mapController!.addSource(
        "dem_grid_source",
        GeojsonSourceProperties(data: geojson),
      );

      await _mapController!.addLayer(
        "dem_grid_source",
        "dem_grid_layer",
        FillLayerProperties(
          fillColor: [
            "match",
            ["get", "status"],
            2,
            "#2ecc71",
            1,
            "#e67e22",
            0,
            "#2980b9",
            "#2980b9",
          ],
          fillOpacity: [
            "match",
            ["get", "status"],
            2,
            0.75,
            1,
            0.70,
            0,
            0.40,
            0.40,
          ],
          fillOutlineColor: "#ffffff",
        ),
      );
    }
  }

  void _onGridFeatureTapped(Map<String, dynamic> feature) {
    setState(() => _selectedCellProps = feature["properties"]);
  }

  Future<void> _deleteCellFisica(double minLat, double minLon) async {
    try {
      final target = CogService().activeCacheMaps.firstWhere(
        (m) =>
            (m.minLat - minLat).abs() < 0.01 &&
            (m.minLon - minLon).abs() < 0.01,
      );
      final file = File(target.path);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    ref.read(demBoundsProvider.notifier).clearAll();
    await CogService().initService(ref);
    await _refreshGridGeometry();
    setState(() => _selectedCellProps = null);
  }

  Future<void> _downloadCellManual(
    double centerLat,
    double centerLon,
    String key,
  ) async {
    setState(() {
      _downloadingKey = key;
      if (_selectedCellProps != null) _selectedCellProps!["status"] = 1;
    });
    await _refreshGridGeometry();

    try {
      await CogService().getCorrectedElevation(centerLat, centerLon, 0.0, ref);
    } catch (e) {
      debugPrint("⚠️ Error: $e");
    }

    setState(() {
      _downloadingKey = null;
      _selectedCellProps = null;
    });
    await _refreshGridGeometry();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final int downloadedCount = CogService().activeCacheMaps.length;
    final bool isLimitReached = downloadedCount >= _maxDownloadedCellsLimit;

    final double? selLat = _selectedCellProps?["minLat"] != null
        ? (_selectedCellProps!["minLat"] as num).toDouble()
        : null;
    final double? selLon = _selectedCellProps?["minLon"] != null
        ? (_selectedCellProps!["minLon"] as num).toDouble()
        : null;
    final int? selStatus = _selectedCellProps?["status"] != null
        ? (_selectedCellProps!["status"] as num).toInt()
        : null;
    final String selKey =
        "${selLat?.toStringAsFixed(1)}_${selLon?.toStringAsFixed(1)}";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.demManagerTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MapLibreMap(
              tiltGesturesEnabled: false,
              compassEnabled: false,
              styleString: "assets/osm_style.json",
              initialCameraPosition: const CameraPosition(
                target: LatLng(40.4167, -3.7037),
                zoom: 5.5,
              ),

              // 🔥 SOLUCIÓ DE CÀRREGA: Forcem el dibuix NOMÉS quan l'estil de la GPU ja s'ha activat del tot
              onStyleLoadedCallback: () async {
                setState(() => _styleLoaded = true);
                await _refreshGridGeometry();
              },

              onMapCreated: (controller) {
                _mapController = controller;
                controller.onFeatureTapped.add((
                  point,
                  latlng,
                  featureId,
                  layerId,
                  annotation,
                ) async {
                  if (!_styleLoaded) return;
                  if (layerId == "dem_grid_layer") {
                    final features = await _mapController
                        ?.queryRenderedFeatures(point, [
                          "dem_grid_layer",
                        ], null);
                    if (features != null && features.isNotEmpty) {
                      _onGridFeatureTapped(
                        Map<String, dynamic>.from(features.first),
                      );
                    }
                  } else {
                    setState(() => _selectedCellProps = null);
                  }
                });
              },
              onCameraIdle: () {
                if (_mapController?.cameraPosition != null) {
                  final newZoom = _mapController!.cameraPosition!.zoom;
                  if ((newZoom - _currentZoom).abs() > 0.1) {
                    setState(() => _currentZoom = newZoom);
                  }
                }
              },
            ),
          ),

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.skyBlueDark.withAlpha(214),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _isHudCollapsed = !_isHudCollapsed),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _isHudCollapsed
                                ? t.demManagerTitle
                                : t.demManagerDesc,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: _isHudCollapsed ? 1 : 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isHudCollapsed
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  if (!_isHudCollapsed) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLimitReached
                                ? Colors.red.withAlpha(76)
                                : Colors.white.withAlpha(38),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Zones: $downloadedCount / $_maxDownloadedCellsLimit",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.zoom_in,
                              color: Colors.orangeAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Zoom: ${_currentZoom.toStringAsFixed(1)}",
                              style: TextStyle(
                                color: Colors.orangeAccent.withAlpha(230),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_selectedCellProps != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(38),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: selStatus == 2
                          ? Colors.green.withAlpha(38)
                          : (selStatus == 1
                                ? Colors.orange.withAlpha(38)
                                : AppColors.primary.withAlpha(38)),
                      child: Icon(
                        selStatus == 2
                            ? Icons.cloud_done_outlined
                            : (selStatus == 1
                                  ? Icons.cloud_download_outlined
                                  : Icons.cloud_outlined),
                        color: selStatus == 2
                            ? Colors.green
                            : (selStatus == 1
                                  ? Colors.orange
                                  : AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lat: ${selLat?.toStringAsFixed(1)}° / Lon: ${selLon?.toStringAsFixed(1)}°",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selStatus == 2
                                ? t.demCellDownloaded
                                : (selStatus == 1
                                      ? "Descarregant d'Azure..."
                                      : t.demCellAvailable),
                            style: TextStyle(
                              fontSize: 12,
                              color: selStatus == 2
                                  ? Colors.green
                                  : (selStatus == 1
                                        ? Colors.orange
                                        : Colors.grey),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selStatus == 1 || _downloadingKey == selKey)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (selStatus == 2)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.redAccent,
                            size: 26,
                          ),
                          onPressed: () => _deleteCellFisica(selLat!, selLon!),
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_circle_down_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          onPressed: () {
                            if (isLimitReached) {
                              AppMessages.showErrorSnackBar(
                                context,
                                t.demLimitReached,
                              );
                              return;
                            }
                            _downloadCellManual(
                              selLat! + 0.1,
                              selLon! + 0.1,
                              selKey,
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                          size: 22,
                        ),
                        onPressed: () =>
                            setState(() => _selectedCellProps = null),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
