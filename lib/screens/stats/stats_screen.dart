import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/barometer_settings_notifier.dart'; // 🆕 El teu notifier de pressió
import 'package:senda/screens/stats/notifiers/stats_prefs_notifier.dart';
import 'package:senda/screens/stats/satellites/screens/satellite_detail_screen.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/providers/barometer_provider.dart';

class TrackStatsScreen extends ConsumerStatefulWidget {
  const TrackStatsScreen({super.key});

  @override
  ConsumerState<TrackStatsScreen> createState() => _TrackStatsScreenState();
}

class _TrackStatsScreenState extends ConsumerState<TrackStatsScreen> {
  // Mapa de controladors nullable per a inicialització reactiva segura
  Map<String, PageController>? _controllers;

  void _initControllersOnce(dynamic prefs) {
    if (_controllers != null) return;
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
    _controllers?.forEach((_, ctrl) => ctrl.dispose());
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

  // 🔥 CORREGIT: Ja no inclou "min/km" en el text per poder posar-ho a baix separat
  String _formatCurrentPace(double speedKmh) {
    if (speedKmh <= 0.3) return "--:--";
    final double totalMinutes = 60.0 / speedKmh;
    final int minutes = totalMinutes.floor();
    final int seconds = ((totalMinutes - minutes) * 60).round();
    final int displaySeconds = seconds == 60 ? 59 : seconds;
    return "${minutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')}";
  }

  String _formatLatLngToDMS(dynamic position) {
    if (position == null) return "--";
    return "${_convertToDMS(position.latitude, true)}\n${_convertToDMS(position.longitude, false)}";
  }

  String _formatLatLngToDecimal(dynamic position) {
    if (position == null) return "--";
    return "${position.latitude.toStringAsFixed(5)}°\n${position.longitude.toStringAsFixed(5)}°";
  }

  String formatDistanceKm(double? km) {
    if (km == null) return "--";
    final totalMeters = (km * 1000).round();
    final kmPart = totalMeters ~/ 1000;
    final mPart = totalMeters % 1000;

    if (mPart == 0) return "${kmPart} km";
    return "${kmPart}km ${mPart}m";
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final prefsState = ref.watch(statsPrefsProvider);

    if (!prefsState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _initControllersOnce(prefsState);

    final realTrack = ref.watch(trackRecordingProvider);
    final importedTrack = ref.watch(importedTrackProvider);
    final track = realTrack.points.isNotEmpty
        ? realTrack
        : (importedTrack != null && importedTrack.points.isNotEmpty
              ? importedTrack
              : null);

    final duration = track?.stats.duration ?? Duration.zero;
    final liveLocation = ref.watch(locationProvider);
    final activePosition = track?.currentPosition ?? liveLocation?.position;

    final double? distanceKm = track != null ? (track.distance / 1000.0) : null;
    final stoppedDuration = track?.stats.stoppedDuration ?? Duration.zero;
    final movingDuration = duration - stoppedDuration;

    final double? currentAltitude = track != null && track.altitudes.isNotEmpty
        ? track.altitudes.last
        : null;

    final pressure = ref.watch(barometerProvider).value;
    final hasBarometer = ref.watch(barometerSettingsProvider).hasBarometer;

    final Map<String, List<Widget>> cardPages = {
      'dist': [
        _StatPage(
          Icons.straighten,
          null,
          "",
          t.statDistance,
          customValue: formatDistanceKm(distanceKm),
        ),
        const _StatPage(Icons.flag, null, "km", "RESTANT"),
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

      // ... (resta de cardPages: dist i time es mantenen igual)
      'speed': [
        _StatPage(
          Icons.speed,
          track != null
              ? (track.currentSpeedKmH > 0
                    ? track.currentSpeedKmH
                    : (track.stats.averageSpeed * 3.6))
              : null,
          "km/h",
          t.statSpeed,
          unitBelow: true, // Centratives verticals
        ),
        _StatPage(
          Icons.trending_up,
          track != null
              ? (track.stats.averageSpeed > 0
                    ? track.stats.averageSpeed * 3.6
                    : track.averageSpeed)
              : null,
          "km/h",
          t.statSpeedAverage,
          unitBelow: true,
        ),
        _StatPage(
          Icons.bolt,
          track != null
              ? (track.stats.maxSpeed > 0
                    ? track.stats.maxSpeed * 3.6
                    : track.maxSpeed)
              : null,
          "km/h",
          t.statSpeedMax,
          unitBelow: true,
        ),
        _StatPage(
          Icons.av_timer,
          null,
          "min/km",
          t.statPace,
          customValue: _formatCurrentPace(
            track != null
                ? (track.currentSpeedKmH > 0
                      ? track.currentSpeedKmH
                      : (track.stats.averageSpeed * 3.6))
                : 0.0,
          ),
          unitBelow: true,
        ),
        _StatPage(
          Icons.directions_run,
          null,
          "min/km",
          t.statPaceAverage,
          customValue: track != null
              ? (track.formattedAveragePace.isNotEmpty
                    ? track.formattedAveragePace.replaceAll(" min/km", "")
                    : _formatCurrentPace(track.stats.averageSpeed * 3.6))
              : "--:--",
          unitBelow: true,
        ),
      ],

      'alt': [
        _StatPage(
          Icons.filter_hdr,
          currentAltitude,
          "m",
          t.statElevation,
          unitBelow: true,
        ),
        _StatPage(
          Icons.arrow_upward,
          track?.ascent,
          "m",
          t.statAscent,
          isInt: true,
          unitBelow: true,
        ),
        if (hasBarometer)
          _StatPage(
            Icons.compress,
            pressure,
            "hPa",
            t.statBarometerPressure,
            unitBelow: true,
          ),
      ],

      'coords': [
        _StatPage(
          Icons.my_location,
          null,
          "",
          t.statPositionDecimal,
          customValue: _formatLatLngToDecimal(activePosition),
          unitBelow: true, //
        ),
        _StatPage(
          Icons.explore,
          null,
          "",
          t.statPositionDMS,
          customValue: _formatLatLngToDMS(activePosition),
          unitBelow: true, //
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
                controller: _controllers![key]!,
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

/// 🛰️ Targeta estàtica per al diagnòstic del GPS estil llista
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
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.satellite_alt_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "$satellitesUsed/$satellitesInView",
                        textAlign: TextAlign.center,
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
                  textAlign: TextAlign.center,
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

/// 🗂️ Targeta carrusel multianidada reactiva (Evita pèrdues de state)
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
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.controller.hasClients
        ? widget.controller.page?.round() ?? widget.controller.initialPage
        : widget.controller.initialPage;
  }

  @override
  void didUpdateWidget(covariant _StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      setState(() {
        _currentPage = widget.controller.hasClients
            ? widget.controller.page?.round() ?? widget.controller.initialPage
            : widget.controller.initialPage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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

/// 📊 Pàgina de dades d'una mètrica individual (Alineació central global de la graella)
class _StatPage extends StatelessWidget {
  final IconData icon;
  final double? value;
  final String unit;
  final String label;
  final bool isInt;
  final String? customValue;
  final bool unitBelow;

  const _StatPage(
    this.icon,
    this.value,
    this.unit,
    this.label, {
    this.isInt = false,
    this.customValue,
    this.unitBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    final String val =
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
          // 1. CAPÇALERA (Títol + Icona es manté estilitzat a sobre)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
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

          // 2. COS CENTRAL DINÀMIC (Sempre centrat en horitzontal i vertical)
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: unitBelow
                    ? Column(
                        // LAYOUT VERTICAL CENTRAT (Velocitats, Ritmes, Alçades i Coordenades)
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            val,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              height:
                                  1.1, // Un pèl de marge per a la doble línia de coordenades
                            ),
                          ),
                          if (unit.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              unit,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Row(
                        // LAYOUT HORITZONTAL CENTRAT (Distància i Temps)
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

          // 3. ESPAI DE SEGURETAT INFERIOR
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
