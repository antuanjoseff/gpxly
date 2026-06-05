import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/barometer_settings_notifier.dart'; // 🆕 El teu notifier de pressió
import 'package:senda/screens/stats/notifiers/stats_prefs_notifier.dart';
import 'package:senda/screens/stats/satellites/screens/satellite_detail_screen.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/providers/barometer_provider.dart';

// Importem els components del bloc 2 (si els separes en fitxers diferents)
// import 'widgets/stat_cards.dart';

class TrackStatsScreen extends ConsumerStatefulWidget {
  const TrackStatsScreen({super.key});

  @override
  ConsumerState<TrackStatsScreen> createState() => _TrackStatsScreenState();
}

class _TrackStatsScreenState extends ConsumerState<TrackStatsScreen> {
  late Map<String, PageController> _controllers;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(statsPrefsProvider);
    _controllers = {
      'dist': PageController(initialPage: prefs.indices['dist'] ?? 0),
      'time': PageController(initialPage: prefs.indices['time'] ?? 0),
      'speed': PageController(initialPage: prefs.indices['speed'] ?? 0),
      'alt': PageController(initialPage: prefs.indices['alt'] ?? 0),
      'coords': PageController(initialPage: prefs.indices['coords'] ?? 0),
    };
  }

  @override
  void dispose() {
    _controllers.forEach((_, ctrl) => ctrl.dispose());
    super.dispose();
  }

  String _formatDuration(Duration d) =>
      d.toString().split('.').first.padLeft(8, "0");

  String _convertToDMS(double degree, bool isLat) {
    String direction = isLat
        ? (degree >= 0 ? 'N' : 'S')
        : (degree >= 0 ? 'E' : 'O');
    double absDegree = degree.abs();
    int d = absDegree.floor();
    double minutesNotTruncated = (absDegree - d) * 60;
    int m = minutesNotTruncated.floor();
    int s = ((minutesNotTruncated - m) * 60).round();
    return "$d°$m'$s\"$direction";
  }

  String _formatCurrentPace(double speedKmh) {
    if (speedKmh <= 0.3) return "--:-- min/km";
    final double totalMinutes = 60.0 / speedKmh;
    final int minutes = totalMinutes.floor();
    final int seconds = ((totalMinutes - minutes) * 60).round();
    final int displaySeconds = seconds == 60 ? 59 : seconds;
    return "${minutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')} min/km";
  }

  String _formatLatLngToDMS(LatLng? position) {
    if (position == null) return "--";
    return "${_convertToDMS(position.latitude, true)}\n${_convertToDMS(position.longitude, false)}";
  }

  String _formatLatLngToDecimal(LatLng? position) {
    if (position == null) return "--";
    return "${position.latitude.toStringAsFixed(5)}°\n${position.longitude.toStringAsFixed(5)}°";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final prefsState = ref.watch(statsPrefsProvider);

    if (!prefsState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final realTrack = ref.watch(trackRecordingProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    Track? track = realTrack.points.isNotEmpty
        ? realTrack
        : (importedTrack != null && importedTrack.points.isNotEmpty
              ? importedTrack
              : null);

    final duration = ref.watch(timerProvider);
    final liveLocation = ref.watch(locationProvider);
    final LatLng? activePosition =
        track?.currentPosition ?? liveLocation?.position;

    final double? distanceKm = track != null ? (track.distance / 1000.0) : null;
    final Duration stoppedDuration =
        track?.stats.stoppedDuration ?? Duration.zero;
    final Duration movingDuration =
        duration - stoppedDuration; // Temps en moviment

    final double? currentAltitude = track != null && track.altitudes.isNotEmpty
        ? track.altitudes.last
        : null;

    // 🆕 LECTURA DELS TEUS PROVIDERS NATIUS DE BARÒMETRE
    final pressure = ref.watch(barometerProvider).value;
    final hasBarometer = ref.watch(barometerSettingsProvider).hasBarometer;
    final Map<String, List<Widget>> cardPages = {
      'dist': [
        // Usen: "statDistance" (DIST) i "statDistance" repetit o una de nova
        _StatPage(Icons.straighten, distanceKm, "km", t.statDistance),
        const _StatPage(Icons.flag, null, "km", "RESTANT"), // Text auxiliar fix
      ],
      'time': [
        _StatPage(
          Icons.timer,
          null,
          "",
          t.statTime,
          customValue: _formatDuration(duration),
        ),
        _StatPage(
          Icons.directions_walk,
          null,
          "",
          t.statTimeMoving,
          customValue: _formatDuration(movingDuration),
        ),
        _StatPage(
          Icons.hotel,
          null,
          "",
          t.statTimeStopped,
          customValue: _formatDuration(stoppedDuration),
        ),
      ],

      'speed': [
        _StatPage(
          Icons.speed,
          track?.currentSpeedKmH, // Usa el teu getter que ja ve en km/h
          "km/h",
          t.statSpeed, // Velocitat actual
        ),
        _StatPage(
          Icons.trending_up,
          track?.averageSpeed,
          "km/h",
          t.statSpeedAverage,
        ),
        _StatPage(Icons.bolt, track?.maxSpeed, "km/h", t.statSpeedMax),
        _StatPage(
          Icons.av_timer,
          null,
          "",
          t.statPace,
          customValue: _formatCurrentPace(track?.currentSpeedKmH ?? 0.0),
        ),
        _StatPage(
          Icons.directions_run,
          null,
          "",
          t.statPaceAverage,
          customValue: track?.formattedAveragePace ?? "--:-- min/km",
        ),
      ],

      'alt': [
        _StatPage(
          Icons.filter_hdr,
          currentAltitude,
          "m",
          t.statElevation,
        ), // ✅ CORREGIT: Usava "Altitud", la teva clau real és "statElevation"
        _StatPage(
          Icons.arrow_upward,
          track?.ascent,
          "m",
          t.statAscent, // Usa "statAscent" (+ASC)
          isInt: true,
        ),
        if (hasBarometer)
          _StatPage(
            Icons.compress,
            pressure,
            "hPa",
            t.statBarometerPressure, // 🆕 Utilitza la nova clau afegida
          ),
      ],
      // 🔍 Busca i REEMPLAÇA el teu bloc 'coords' actual per aquest:
      'coords': [
        _StatPage(
          Icons.my_location,
          null,
          "",
          t.statPositionDecimal,
          customValue: _formatLatLngToDecimal(
            activePosition,
          ), // 🔥 Connectat a la teva funció!
        ),
        _StatPage(
          Icons.explore,
          null,
          "",
          t.statPositionDMS,
          customValue: _formatLatLngToDMS(activePosition),
        ),
      ],
    };

    final List<String> currentOrder = prefsState.order;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.trackStatsTitle),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ReorderableGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            onReorder: (oldIndex, newIndex) {
              ref.read(statsPrefsProvider.notifier).reorder(oldIndex, newIndex);
            },
            children: currentOrder.map((key) {
              if (key == 'gps') {
                return _GpsStaticCard(
                  key: ValueKey(key),
                  satellitesUsed: liveLocation?.satellitesUsed ?? 0,
                  satellitesInView: liveLocation?.satellitesInView ?? 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SatelliteDetailScreen(),
                      ),
                    );
                  },
                );
              }
              return _StatCard(
                key: ValueKey(key),
                controller: _controllers[key]!,
                height: double.infinity,
                onPageChanged: (index) => ref
                    .read(statsPrefsProvider.notifier)
                    .setCarouselIdx(key, index),
                pages: cardPages[key]!,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// 🛰️ Tarjeta estática para el diagnóstico del GPS
/// 🛰️ Tarjeta estática para el diagnóstico del GPS
class _GpsStaticCard extends StatelessWidget {
  final int satellitesUsed;
  final int satellitesInView;
  final VoidCallback onTap;

  const _GpsStaticCard({
    super.key,
    required this.satellitesUsed,
    required this.satellitesInView,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.12,
            ), // Sombra más densa y marcada
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6), // Desplazamiento vertical pronunciado
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ESTAT GPS",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Icon(
                      Icons.satellite_alt_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$satellitesUsed/$satellitesInView",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Actius / En vista",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con control de carrusel de una o más páginas
class _StatCard extends StatefulWidget {
  final double height;
  final List<Widget> pages;
  final PageController controller;
  final Function(int) onPageChanged;

  const _StatCard({
    super.key,
    required this.height,
    required this.pages,
    required this.controller,
    required this.onPageChanged,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.controller.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.12,
            ), // Sombra más densa y marcada
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            PageView(
              controller: widget.controller,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                widget.onPageChanged(index);
              },
              children: widget.pages,
            ),
            if (widget.pages.length > 1)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.pages.length, (index) {
                    final bool isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: isActive ? 12 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isActive
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Página de datos de una métrica individual
class _StatPage extends StatelessWidget {
  final IconData icon;
  final double? value;
  final String unit;
  final String label;
  final bool isInt;
  final String? customValue;

  const _StatPage(
    this.icon,
    this.value,
    this.unit,
    this.label, {
    this.isInt = false,
    this.customValue,
  });

  @override
  Widget build(BuildContext context) {
    String val =
        customValue ??
        (value == null
            ? "--"
            : (isInt ? value!.toStringAsFixed(0) : value!.toStringAsFixed(1)));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors
                        .grey
                        .shade600, // Ajustado a juego con la elevación
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: AppColors.primary, size: 20),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      val,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (unit.isNotEmpty && val != "--") ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
