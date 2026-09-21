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
    final offline = ref.read(offlineMapsProvider);
    debugPrint(
      '🗺️ [BASE LAYER] _loadStyle: enabled=${offline.enabled} '
      'downloaded=${offline.catalunyaDownloaded}',
    );
    if (offline.enabled && offline.catalunyaDownloaded) {
      final style = await OfflineMapsService.instance.buildOfflineStyle(
        OfflineMapsNotifier.regioCatalunya,
      );
      debugPrint(
        '🗺️ [BASE LAYER] buildOfflineStyle retornat: '
        '${style == null ? "NULL (fallback online)" : "OK (${style.length} chars)"}',
      );
      if (style != null && mounted) {
        if (_controller != null) {
          // Mapa ja existeix: canvi en calent (funciona bé)
          await _controller!.setStyle(style);
        } else {
          // 🛡️ ARRENCADA OFFLINE: no posem l'estil offline com a inicial.
          // Creem el mapa amb l'estil online primer; el canvi a offline es
          // farà a onStyleLoaded quan el renderer ja sigui estable.
          setState(() {
            _styleString = 'assets/osm_style.json';
            _pendingOfflineStyle = style;
          });
        }
        debugPrint('🗺️ [OFFLINE] Estil offline preparat');
        return;
      }
    }
    if (mounted) {
      if (_controller != null) {
        await _controller!.setStyle('assets/osm_style.json');
      } else {
        setState(() => _styleString = 'assets/osm_style.json');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reacciona quan l'usuari activa/desactiva el mode offline o acaba
    // una descàrrega: recarrega l'estil del mapa en calent.
    ref.listen(offlineMapsProvider, (previous, next) {
      if (previous?.enabled != next.enabled ||
          previous?.catalunyaDownloaded != next.catalunyaDownloaded) {
        debugPrint(
          '🗺️ [BASE LAYER] Estat offline canviat → recarregant estil',
        );
        _loadStyle();
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
              await _controller!.setStyle(_pendingOfflineStyle!);
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
