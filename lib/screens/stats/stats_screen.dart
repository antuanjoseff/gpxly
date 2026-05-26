import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
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
    if (!prefsState.isInitialized)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);
    Track? track = real.coordinates.isNotEmpty
        ? real
        : (imported?.coordinates.isNotEmpty == true ? imported : null);

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
            final cardHeight = (constraints.maxHeight - 64) / 4;

            return ReorderableListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onReorder: (oldIdx, newIdx) =>
                  ref.read(statsPrefsProvider.notifier).reorder(oldIdx, newIdx),
              children: prefsState.order.map((key) {
                return Padding(
                  key: ValueKey(key),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCardByKey(key, track, cardHeight, t, ref),
                );
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
    final real = ref.read(trackProvider);
    final liveDuration = ref.watch(timerProvider);
    final isReal = track == real;

    switch (key) {
      case 'dist':
        return _StatCard(
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
              track.coordinates.length.toDouble(),
              "PTS",
              "PUNTS GPS",
              isInt: true,
            ),
          ],
        );
      case 'time':
        return _StatCard(
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
              track.averageSpeed > 0 ? track.averageSpeed : null,
              "km/h",
              t.statSpeedAverage,
            ),
          ],
        );
      case 'alt':
        return _StatCard(
          height: height,
          controller: _controllers['alt']!,
          onPageChanged: (i) =>
              ref.read(statsPrefsProvider.notifier).setCarouselIdx('alt', i),
          pages: [
            _StatPage(
              Icons.terrain,
              (isReal && real.altitudes.isNotEmpty)
                  ? real.altitudes.last
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
              track.maxElevation,
              "m",
              t.statMaxElevation,
              isInt: true,
            ),
            _StatPage(
              Icons.vertical_align_bottom,
              track.minElevation,
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

class _StatCard extends StatelessWidget {
  final double height;
  final List<Widget> pages;
  final PageController controller;
  final Function(int) onPageChanged;

  const _StatCard({
    required this.height,
    required this.pages,
    required this.controller,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
        child: PageView(
          controller: controller,
          onPageChanged: onPageChanged,
          children: pages,
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
            : (isInt ? value!.toStringAsFixed(0) : value!.toStringAsFixed(2)));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 26,
            ), // 🔥 Pujat de 22 a 26
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
                  fontSize: 30, // 📉 Baixat de 34 a 30 per compensar
                  fontWeight: FontWeight.w900,
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
