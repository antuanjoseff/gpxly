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

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  /// Decideix l'estil (online/offline) i l'aplica: si el mapa ja existeix,
  /// en calent via setStyleString; si no, via setState per la construcció.
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
          await _controller!.setStyle(style);
        } else {
          setState(() => _styleString = style);
        }
        debugPrint('🗺️ [OFFLINE] Estil offline carregat');
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
          onStyleLoadedCallback: widget.onStyleLoaded,
        ),
      ),
    );
  }
}
