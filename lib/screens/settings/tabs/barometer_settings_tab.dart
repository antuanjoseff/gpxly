import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/dem_bounds_notifier.dart';
import 'package:strack_rec/services/cog_service.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/ui/app_messages.dart';
import 'package:strack_rec/notifiers/location_notifier.dart';
import 'package:strack_rec/utils/map_animator.dart';
import 'package:strack_rec/utils/map_constants.dart';

class BarometerSettingsTab extends ConsumerStatefulWidget {
  const BarometerSettingsTab({super.key});

  @override
  ConsumerState<BarometerSettingsTab> createState() =>
      _BarometerSettingsTabState();
}

class _BarometerSettingsTabState extends ConsumerState<BarometerSettingsTab> {
  MapLibreMapController? _mapController;
  MapAnimator? _mapAnimator;

  bool _styleLoaded = false;
  bool _isHudCollapsed = true;

  // Controls de guàrdia per saber si l'usuari interacciona amb el mapa
  final bool _hasCenteredOnUser = false;
  bool _userMovedMap = false;

  static const int _maxDownloadedCellsLimit = 8;
  String? _downloadingKey;
  String? _selectedKey;
  Map<String, dynamic>? _selectedCellProps;

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

  Map<String, dynamic> _buildGridGeoJson(List<DemBounds> downloadedCells) {
    final List<Map<String, dynamic>> features = [];

    final tiles =
        ref.read(availableTilesProvider).value ?? MapConstants.tifFilesEspanya;
    for (final filename in tiles) {
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
          for (final cell in downloadedCells) {
            if ((cell.minLat - minLat).abs() < 0.01 &&
                (cell.minLon - minLon).abs() < 0.01) {
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
              "isSelected": _selectedKey == key,
              "minLat": minLat,
              "minLon": minLon,
              "maxLat": maxLat,
              "maxLon": maxLon,
              "key": key,
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

  /// 🔲 Construeix el polígon irregular (footprint) unint totes les cel·les
  /// de 0.2º. Les arestes interiors compartides per dues cel·les es cancel·len
  /// i les exteriors es concatenen formant anells tancats (contorns + forats)
  /// que es retornen com un únic MultiPolygon.
  Map<String, dynamic> _buildFootprintGeoJson() {
    final tiles =
        ref.read(availableTilesProvider).value ?? MapConstants.tifFilesEspanya;

    // Arestes dirigides en coordenades enteres (graus x 5) per evitar errors
    // de punt flotant. Cada cel·la s'afegeix en sentit antihorari, de manera
    // que l'interior queda sempre a l'esquerra de l'aresta.
    final Map<String, List<int>> edges = {};

    void addEdge(int x1, int y1, int x2, int y2) {
      final String reverseKey = "$x2,$y2>$x1,$y1";
      if (edges.containsKey(reverseKey)) {
        edges.remove(reverseKey);
      } else {
        edges["$x1,$y1>$x2,$y2"] = [x1, y1, x2, y2];
      }
    }

    for (final filename in tiles) {
      final latBase = double.parse(filename.substring(1, 3));
      final lonSign = filename.substring(3, 4) == 'E' ? 1.0 : -1.0;
      final lonBase = double.parse(filename.substring(4, 7)) * lonSign;

      final int baseX = (lonBase * 5).round();
      final int baseY = (latBase * 5).round();

      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
          final int minX = baseX + j;
          final int maxX = minX + 1;
          final int minY = baseY + i;
          final int maxY = minY + 1;
          addEdge(minX, minY, maxX, minY);
          addEdge(maxX, minY, maxX, maxY);
          addEdge(maxX, maxY, minX, maxY);
          addEdge(minX, maxY, minX, minY);
        }
      }
    }

    // Concatena les arestes restants en anells tancats
    final Set<String> unused = edges.keys.toSet();
    final List<List<List<double>>> rings = [];

    while (unused.isNotEmpty) {
      final first = edges[unused.first]!;
      unused.remove(unused.first);
      final List<List<int>> ring = [
        [first[0], first[1]],
        [first[2], first[3]],
      ];
      int cx = first[2];
      int cy = first[3];
      int dx = first[2] - first[0];
      int dy = first[3] - first[1];

      while (cx != ring.first[0] || cy != ring.first[1]) {
        // Preferència de gir: esquerra > recte > dreta > enrere
        final List<List<int>> prefs = [
          [-dy, dx],
          [dx, dy],
          [dy, -dx],
          [-dx, -dy],
        ];
        bool advanced = false;
        for (final p in prefs) {
          final int tx = cx + p[0];
          final int ty = cy + p[1];
          final String key = "$cx,$cy>$tx,$ty";
          if (unused.contains(key)) {
            unused.remove(key);
            cx = tx;
            cy = ty;
            dx = p[0];
            dy = p[1];
            ring.add([cx, cy]);
            advanced = true;
            break;
          }
        }
        if (!advanced) break;
      }

      if (cx == ring.first[0] && cy == ring.first[1] && ring.length >= 4) {
        rings.add(ring.map((p) => [p[0] / 5.0, p[1] / 5.0]).toList());
      }
    }

    // Classifica els anells: àrea positiva = contorn exterior, negativa = forat
    double signedArea(List<List<double>> ring) {
      double area = 0;
      for (int k = 0; k < ring.length - 1; k++) {
        area += ring[k][0] * ring[k + 1][1] - ring[k + 1][0] * ring[k][1];
      }
      return area / 2;
    }

    final outers = rings.where((r) => signedArea(r) > 0).toList();
    final holes = rings.where((r) => signedArea(r) < 0).toList();

    bool containsPoint(List<List<double>> ring, List<double> p) {
      bool inside = false;
      for (int a = 0, b = ring.length - 1; a < ring.length; b = a++) {
        final double xa = ring[a][0], ya = ring[a][1];
        final double xb = ring[b][0], yb = ring[b][1];
        if ((ya > p[1]) != (yb > p[1]) &&
            p[0] < (xb - xa) * (p[1] - ya) / (yb - ya) + xa) {
          inside = !inside;
        }
      }
      return inside;
    }

    final List<List<List<List<double>>>> polygons = [
      for (final outer in outers) [outer],
    ];
    for (final hole in holes) {
      for (final polygon in polygons) {
        if (containsPoint(polygon.first, hole.first)) {
          polygon.add(hole);
          break;
        }
      }
    }

    return {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {},
          "geometry": {"type": "MultiPolygon", "coordinates": polygons},
        },
      ],
    };
  }

  Future<void> _refreshGridGeometry() async {
    if (_mapController == null || !_styleLoaded) return;
    final demState = ref.read(demBoundsProvider);
    final geojson = _buildGridGeoJson(demState.cells);

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
        minzoom: 5,
        const FillLayerProperties(
          fillColor: [
            "case",
            ["get", "isSelected"],
            "#f1c40f",
            [
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
          ],
          fillOpacity: [
            "case",
            ["get", "isSelected"],
            0.85,
            [
              "match",
              ["get", "status"],
              2,
              0.75,
              1,
              0.70,
              0,
              0.35,
              0.35,
            ],
          ],
          fillOutlineColor: "#ffffff",
        ),
      );
    }

    // 🗺️ Footprint global per a zooms allunyats: un sol polígon irregular.
    // Preferència: footprint calculat pel servidor. Fallback: càlcul local.
    final serverFootprint = ref.read(footprintProvider).value;
    final footprint = serverFootprint ?? _buildFootprintGeoJson();
    try {
      await _mapController!.setGeoJsonSource("dem_footprint_source", footprint);
    } catch (_) {
      await _mapController!.addSource(
        "dem_footprint_source",
        GeojsonSourceProperties(data: footprint),
      );
      await _mapController!.addLayer(
        "dem_footprint_source",
        "dem_footprint_layer",
        maxzoom: 5,
        const FillLayerProperties(fillColor: "#2980b9", fillOpacity: 0.15),
      );
      await _mapController!.addLayer(
        "dem_footprint_source",
        "dem_footprint_outline",
        maxzoom: 5,
        const LineLayerProperties(lineColor: "#e74c3c", lineWidth: 1.5),
      );
    }
  }

  void _onGridFeatureTapped(Map<String, dynamic> feature) {
    final props = feature["properties"];
    setState(() {
      _selectedCellProps = props;
      _selectedKey = props["key"];
    });
    _refreshGridGeometry();
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
    setState(() {
      _selectedCellProps = null;
      _selectedKey = null;
    });
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
      _selectedKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    // Cada cop que hi hagi un canvi al proveïdor, forçarem el refresc automàtic de la quadrícula al mapa
    ref.listen(demBoundsProvider, (previous, next) {
      if (_styleLoaded) {
        _refreshGridGeometry();
      }
    });

    // Quan arribi la llista remota de tessel·les, refresca la graella
    ref.listen(availableTilesProvider, (previous, next) {
      if (_styleLoaded) {
        _refreshGridGeometry();
      }
    });

    // Quan arribi el footprint del servidor, refresca el polígon de contorn
    ref.listen(footprintProvider, (previous, next) {
      if (_styleLoaded) {
        _refreshGridGeometry();
      }
    });

    final demState = ref.watch(demBoundsProvider);
    final downloadedCells = demState.cells;
    final isDownloadingGlobal = demState.isDownloading;

    final int downloadedCount = downloadedCells.length;
    final bool isLimitReached = downloadedCount >= _maxDownloadedCellsLimit;

    final userPositionState = ref.watch(locationProvider);

    final double? selLat = _selectedCellProps?["minLat"] != null
        ? double.tryParse(_selectedCellProps!["minLat"].toString())
        : null;
    final double? selLon = _selectedCellProps?["minLon"] != null
        ? double.tryParse(_selectedCellProps!["minLon"].toString())
        : null;
    final int? selStatus = _selectedCellProps?["status"] != null
        ? int.tryParse(_selectedCellProps!["status"].toString())
        : null;

    final String selKey = (selLat != null && selLon != null)
        ? "${selLat.toStringAsFixed(1)}_${selLon.toStringAsFixed(1)}"
        : "";

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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            // 🟢 SOLUCIÓ COMPLETADA: S'esborra el GestureDetector que segrestava el pan i el zoom de la GPU
            child: MapLibreMap(
              tiltGesturesEnabled: false,
              compassEnabled: false,
              styleString: "assets/osm_style.json",
              myLocationEnabled: true,
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  MapConstants.demViewCenterLatitude,
                  MapConstants.demViewCenterLongitude,
                ),
                zoom: 4.8,
              ),

              // 🔥 CONTROL NATIU DE MOVIMENT (PAN / ZOOM MANUAL):
              // S'executa a l'instant cada cop que els dits de l'usuari desplacen el mapa.
              onCameraMove: (cameraPosition) {
                // Filtrem el semàfor de l'animador del track unificat per evitar falsos positius de fons
                final bool isAnimating = _mapAnimator?.isAnimating ?? false;

                if (_styleLoaded && !_userMovedMap && !isAnimating) {
                  setState(() => _userMovedMap = true);
                }
              },

              onStyleLoadedCallback: () async {
                if (_mapController == null) return;

                // Enquadrament matemàtic forçat per encabir absolutament totes les cel·les a la pantalla
                await _mapController!.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: const LatLng(
                        MapConstants.demViewMinLatitude,
                        MapConstants.demViewMinLongitude,
                      ),
                      northeast: const LatLng(
                        MapConstants.demViewMaxLatitude,
                        MapConstants.demViewMaxLongitude,
                      ),
                    ),
                    left: 20,
                    right: 20,
                    top: 40,
                    bottom: 40,
                  ),
                );

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
                    setState(() {
                      _selectedCellProps = null;
                      _selectedKey = null;
                    });
                    _refreshGridGeometry();
                  }
                });
              },
              onCameraIdle: () {},
            ),
          ),

          if (isDownloadingGlobal)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                minHeight: 4,
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
                        const Row(
                          children: [
                            Icon(
                              Icons.zoom_in,
                              color: Colors.orangeAccent,
                              size: 16,
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

          if (_userMovedMap && userPositionState != null)
            Positioned(
              right: 16,
              bottom: _selectedCellProps != null ? 140 : 32,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                child: const Icon(Icons.my_location_rounded, size: 20),
                onPressed: () {
                  setState(() => _userMovedMap = false);
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(userPositionState.position),
                  );
                },
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
                          onPressed: () => isLimitReached
                              ? AppMessages.showErrorSnackBar(
                                  context,
                                  t.demLimitReached,
                                )
                              : _downloadCellManual(
                                  selLat! + 0.1,
                                  selLon! + 0.1,
                                  selKey,
                                ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                          size: 22,
                        ),
                        onPressed: () => setState(() {
                          _selectedCellProps = null;
                          _selectedKey = null;
                          _refreshGridGeometry();
                        }),
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
