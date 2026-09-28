import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/notifiers/offline_maps_notifier.dart';
import 'package:strack_rec/services/offline_maps_service.dart';

class MapBaseLayer extends ConsumerStatefulWidget {
  final LatLng initialCameraTarget;
  final double initialZoom;
  final bool smartCenterEnabled;
  final bool isProgrammaticMove;
  final bool isFullScreen;
  final void Function(bool) onSmartCenterChanged;
  final void Function(bool) onFullScreenChanged;
  final void Function(MapLibreMapController) onMapCreated;
  final VoidCallback onStyleLoading;
  final VoidCallback onStyleLoaded;
  final void Function(CameraPosition)? onCameraMove;
  final VoidCallback? onCameraIdle;

  const MapBaseLayer({
    super.key,
    required this.initialCameraTarget,
    required this.initialZoom,
    required this.smartCenterEnabled,
    required this.isProgrammaticMove,
    required this.isFullScreen,
    required this.onSmartCenterChanged,
    required this.onFullScreenChanged,
    required this.onMapCreated,
    required this.onStyleLoading,
    required this.onStyleLoaded,
    this.onCameraMove,
    this.onCameraIdle,
  });

  @override
  ConsumerState<MapBaseLayer> createState() => _MapBaseLayerState();
}

class _MapBaseLayerState extends ConsumerState<MapBaseLayer> {
  String? _styleString;
  MapLibreMapController? _controller;

  /// Estil offline pendent d'aplicar un cop el mapa s'ha inicialitzat amb
  /// l'estil online. Evita que el renderer natiu peti processant mbtiles
  /// mentre s'inicialitza (SIGABRT a libmaplibre.so).
  String? _pendingOfflineStyle;
  bool _hasInitialStyleLoaded = false;

  // 🛡️ Evita que dues crides a `_loadStyle` (p.ex. `enabled` i
  // `downloadedRegionIds` canviant gairebé alhora en carregar l'app) es
  // solapin i disparin dos `setStyle` concurrents sobre el mateix controlador.
  bool _isLoadingStyle = false;
  bool _reloadRequestedWhileLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  /// Decideix l'estil (online/offline) i l'aplica.
  ///
  /// 🛡️ ESTRATÈGIA PER EVITAR EL CRASH JNI:
  /// En mode offline, NO carreguem l'estil offline com a `styleString` inicial
  /// del MapLibreMap. El renderer natiu peta (SIGABRT) si processa tiles del
  /// mbtiles mentre s'inicialitza. En lloc d'això:
  ///   1. Creem el mapa amb l'estil ONLINE (estable, ràpid).
  ///   2. Un cop l'estil online està carregat i el mapa és estable,
  ///      fem `setStyle` a l'offline en calent.
  ///
  /// Si el mapa ja existeix (canvi offline↔online amb l'app en marxa),
  /// simplement fem `setStyle` en calent — això funciona bé perquè el
  /// renderer ja està inicialitzat.
  Future<void> _loadStyle() async {
    if (_isLoadingStyle) {
      // Ja hi ha una càrrega en curs: la reprogramem per quan acabi en lloc
      // de disparar un segon `setStyle` concurrent.
      _reloadRequestedWhileLoading = true;
      return;
    }
    _isLoadingStyle = true;
    try {
      await _doLoadStyle();
    } finally {
      _isLoadingStyle = false;
      if (_reloadRequestedWhileLoading) {
        _reloadRequestedWhileLoading = false;
        _loadStyle();
      }
    }
  }

  Future<void> _setStyle(String style) async {
    final controller = _controller;
    if (controller == null) return;
    widget.onStyleLoading();
    await controller.setStyle(style);
  }

  Future<void> _doLoadStyle() async {
    final offline = ref.read(offlineMapsProvider);
    debugPrint(
      '🗺️ [BASE LAYER] _loadStyle: enabled=${offline.enabled} '
      'hasDownloaded=${offline.hasDownloadedRegions}',
    );
    if (offline.enabled && offline.hasDownloadedRegions) {
      final style = await OfflineMapsService.instance.buildOfflineStyle(
        offline.downloadedRegionIds,
      );
      debugPrint(
        '🗺️ [BASE LAYER] buildOfflineStyle retornat: '
        '${style == null ? "NULL (fallback online)" : "OK (${style.length} chars)"}',
      );
      if (style != null && mounted) {
        if (_controller != null && _hasInitialStyleLoaded) {
          // Mapa ja existeix: canvi en calent (funciona bé)
          await _setStyle(style);
        } else {
          // El controller es crea abans que el primer Style. Esperem el
          // primer onStyleLoaded abans de substituir-lo per l'estil offline.
          _pendingOfflineStyle = style;
          if (_styleString != 'assets/osm_style.json') {
            setState(() => _styleString = 'assets/osm_style.json');
          }
        }
        debugPrint('🗺️ [OFFLINE] Estil offline preparat');
        return;
      }
    }
    if (mounted) {
      _pendingOfflineStyle = null;
      if (_controller != null && _hasInitialStyleLoaded) {
        await _setStyle('assets/osm_style.json');
      } else {
        if (_styleString != 'assets/osm_style.json') {
          setState(() => _styleString = 'assets/osm_style.json');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reacciona quan l'usuari activa/desactiva el mode offline o acaba
    // una descàrrega: recarrega l'estil del mapa en calent.
    ref.listen(offlineMapsProvider, (previous, next) {
      if (previous?.enabled != next.enabled ||
          previous?.downloadedRegionIds.join(',') !=
              next.downloadedRegionIds.join(',')) {
        debugPrint(
          '🗺️ [BASE LAYER] Estat offline canviat → recarregant estil',
        );
        _loadStyle();
        _hasInitialStyleLoaded = true;
      }
    });

    if (_styleString == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RepaintBoundary(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (PointerDownEvent event) {
          if (widget.isProgrammaticMove) return;
          if (widget.smartCenterEnabled) {
            widget.onSmartCenterChanged(false);
          }
        },
        child: MapLibreMap(
          tiltGesturesEnabled: false,
          trackCameraPosition: true,
          compassEnabled: false,
          styleString: _styleString!,
          initialCameraPosition: CameraPosition(
            target: widget.initialCameraTarget,
            zoom: widget.initialZoom,
          ),
          onMapLongClick: (point, latlng) => widget.onFullScreenChanged(true),
          onMapClick: (point, latlng) => widget.onFullScreenChanged(false),
          onCameraMove: widget.onCameraMove,
          onCameraIdle: widget.onCameraIdle,
          onMapCreated: (controller) {
            _controller = controller;
            widget.onMapCreated(controller);
          },
          onStyleLoadedCallback: () async {
            // 🛡️ Si hi havia un estil offline pendent (arrencada offline),
            // l'apliquem ARA que el renderer ja és estable, ABANS de dir
            // al pare que l'estil està llest (que activa els listeners).
            if (_pendingOfflineStyle != null && _controller != null) {
              debugPrint('🗺️ [OFFLINE] Aplicant estil offline pendent...');
              await _setStyle(_pendingOfflineStyle!);
              _pendingOfflineStyle = null;
              // No cridem widget.onStyleLoaded encara: esperem el proper
              // onStyleLoaded que dispararà el setStyle en calent.
              return;
            }
            widget.onStyleLoaded();
          },
        ),
      ),
    );
  }
}
