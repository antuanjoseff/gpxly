// lib/screens/stats/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
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
      'dist': PageController(initialPage: prefs.indices['dist']!),
      'time': PageController(initialPage: prefs.indices['time']!),
      'speed': PageController(initialPage: prefs.indices['speed']!),
      'alt': PageController(initialPage: prefs.indices['alt']!),
    };
  }

  @override
  void dispose() {
    _controllers.forEach((_, ctrl) => ctrl.dispose());
    super.dispose();
  }

  String _formatDuration(Duration d) =>
      d.toString().split('.').first.padLeft(8, "0");

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

    if (track == null) return _buildEmptyState(t);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        title: Text(
          t.trackStatsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = (constraints.maxHeight - 32) / 4;

            return ReorderableListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onReorder: (oldIdx, newIdx) =>
                  ref.read(statsPrefsProvider.notifier).reorder(oldIdx, newIdx),

              // 🚀 SOLUCIÓ LÍMITS BLANCS: Evitem fons blancs de control en moure targetes
              proxyDecorator:
                  (Widget child, int index, Animation<double> animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (BuildContext context, Widget? child) {
                        return Material(
                          elevation: 4,
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },

              children: prefsState.order.map((key) {
                return _buildCardByKey(key, track, cardHeight, t, ref);
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardByKey(
    String key,
    Track track,
    double height,
    AppLocalizations t,
    WidgetRef ref,
  ) {
    final real = ref.read(trackRecordingProvider);
    final liveDuration = ref.watch(timerProvider);
    final isReal = track == real;

    switch (key) {
      case 'dist':
        return _StatCard(
          key: ValueKey(key),
          height: height,
          controller: _controllers['dist']!,
          onPageChanged: (i) =>
              ref.read(statsPrefsProvider.notifier).setCarouselIdx('dist', i),
          pages: [
            _StatPage(
              Icons.straighten,
              track.distance > 0 ? (track.distance / 1000) : null,
              "KM",
              t.statDistance,
            ),
            _StatPage(
              Icons.tag,
              track.points.length.toDouble(),
              "PTS",
              "PUNTS GPS",
              isInt: true,
            ),
          ],
        );
      case 'time':
        return _StatCard(
          key: ValueKey(key),
          height: height,
          controller: _controllers['time']!,
          onPageChanged: (i) =>
              ref.read(statsPrefsProvider.notifier).setCarouselIdx('time', i),
          pages: [
            _StatPage(
              Icons.timer,
              null,
              "",
              t.statTimeTotal,
              customValue: _formatDuration(
                isReal ? liveDuration : track.duration,
              ),
            ),
            _StatPage(
              Icons.pause_circle_filled,
              null,
              "",
              t.statTimeStopped,
              customValue: _formatDuration(track.stoppedDuration),
            ),
            _StatPage(
              Icons.directions_run,
              null,
              "",
              t.statTimeMoving,
              customValue: _formatDuration(
                isReal
                    ? (liveDuration - track.stoppedDuration)
                    : (track.duration - track.stoppedDuration),
              ),
            ),
          ],
        );
      case 'speed':
        return _StatCard(
          key: ValueKey(key),
          height: height,
          controller: _controllers['speed']!,
          onPageChanged: (i) =>
              ref.read(statsPrefsProvider.notifier).setCarouselIdx('speed', i),
          pages: [
            _StatPage(
              Icons.bolt,
              isReal ? (real.currentSpeed * 3.6) : null,
              "km/h",
              t.statSpeedCurrent,
            ),
            _StatPage(
              Icons.speed,
              track.averageSpeed > 0 ? track.averageSpeed * 3.6 : null,
              "km/h",
              t.statSpeedAverage,
            ),
            _StatPage(
              Icons.trending_up,
              track.maxSpeed > 0 ? track.maxSpeed * 3.6 : null,
              "km/h",
              t.statSpeedMax,
            ),
            _StatPage(
              Icons.directions_walk_rounded,
              null,
              "",
              t.statPaceAverage,
              customValue: track.formattedAveragePace,
            ),
          ],
        );
      case 'alt':
        return _StatCard(
          key: ValueKey(key),
          height: height,
          controller: _controllers['alt']!,
          onPageChanged: (i) =>
              ref.read(statsPrefsProvider.notifier).setCarouselIdx('alt', i),
          pages: [
            _StatPage(
              Icons.terrain,
              (isReal && real.points.isNotEmpty)
                  ? real.points.last.altitude
                  : null,
              "m",
              t.statElevationCurrent,
              isInt: true,
            ),
            _StatPage(
              Icons.trending_up,
              track.ascent,
              "m",
              t.statAscent,
              isInt: true,
            ),
            _StatPage(
              Icons.trending_down,
              track.descent,
              "m",
              t.statDescent,
              isInt: true,
            ),
            _StatPage(
              Icons.vertical_align_top,
              track.maxElevation != -9999.0 ? track.maxElevation : null,
              "m",
              t.statMaxElevation,
              isInt: true,
            ),
            _StatPage(
              Icons.vertical_align_bottom,
              track.minElevation != 9999.0 ? track.minElevation : null,
              "m",
              t.statMinElevation,
              isInt: true,
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildEmptyState(AppLocalizations t) => Scaffold(
    backgroundColor: const Color(0xFFF5F5F7),
    appBar: AppBar(
      backgroundColor: AppColors.primary,
      title: Text(t.trackStatsTitle),
    ),
    body: Center(
      child: Text(
        t.noRecordedTrack,
        style: const TextStyle(color: Colors.black54),
      ),
    ),
  );
}

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: widget.height - 8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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

              // 🚀 CERCLES INDICADORS DISCRETS DE PÀGINA (PUNTETS)
              if (widget.pages.length > 1)
                Positioned(
                  bottom: 6,
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
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
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
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
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
      ],
    );
  }
}
