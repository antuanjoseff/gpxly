// lib/screens/stats/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
// Assegura't que aquest import apunti exactament on tens definit el LocationNotifier/locationProvider
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/screens/stats/notifiers/stats_prefs_notifier.dart';
import 'package:senda/theme/app_colors.dart';

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

  // ─── FUNCIONS DE FORMAT PER A LES COORDENADES ───
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

    // 🚀 Connectem directament amb el teu LocationNotifier per tenir posicionament global constant
    final liveLocation = ref.watch(locationProvider);

    // Si estem gravant el track utilitza la posició interna, si està en repòs agafa la del teu GPS
    final LatLng? activePosition =
        track?.currentPosition ?? liveLocation?.position;

    final double? distanceKm = track != null ? (track.distance / 1000.0) : null;
    final double? currentAltitude = track != null && track.altitudes.isNotEmpty
        ? track.altitudes.last
        : null;

    final Map<String, List<Widget>> cardPages = {
      'dist': [
        _StatPage(Icons.straighten, distanceKm, "km", "Distància"),
        const _StatPage(Icons.flag, null, "km", "Restant"),
      ],
      'time': [
        _StatPage(
          Icons.timer,
          null,
          "",
          "Temps Actiu",
          customValue: _formatDuration(duration),
        ),
        const _StatPage(
          Icons.hourglass_bottom,
          null,
          "",
          "Temps Estimat",
          customValue: "--:--:--",
        ),
      ],
      'speed': [
        _StatPage(Icons.speed, track?.currentSpeedKmH, "km/h", "Velocitat"),
        _StatPage(Icons.trending_up, track?.averageSpeed, "km/h", "Mitjana"),
      ],
      'alt': [
        _StatPage(Icons.filter_hdr, currentAltitude, "m", "Altitud"),
        _StatPage(
          Icons.arrow_upward,
          track?.ascent,
          "m",
          "Desnivell",
          isInt: true,
        ),
      ],
      'coords': [
        _StatPage(
          Icons.my_location,
          null,
          "",
          "Posició GD",
          customValue: _formatLatLngToDecimal(activePosition),
        ),
        _StatPage(
          Icons.explore,
          null,
          "",
          "Posició DMS",
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
// (Continuació de lib/screens/stats/stats_screen.dart)

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(102), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.pages.length, (index) {
                    final bool isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 6 : 4,
                      height: isActive ? 6 : 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                val,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              if (unit.isNotEmpty && val != "--") ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
