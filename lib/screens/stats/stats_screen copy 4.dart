import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/theme/app_colors.dart';

class TrackStatsScreen extends ConsumerWidget {
  const TrackStatsScreen({super.key});

  String _formatDuration(Duration? d) {
    if (d == null || d == Duration.zero) return "--:--:--";
    return d.toString().split('.').first.padLeft(8, "0");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);
    final liveDuration = ref.watch(timerProvider);

    Track? track;
    if (real.coordinates.isNotEmpty) {
      track = real;
    } else if (imported != null && imported.coordinates.isNotEmpty) {
      track = imported;
    }

    if (track == null) return _buildEmptyState(context, t);

    final isReal = track == real;
    final currentDuration = isReal ? liveDuration : track.duration;
    final speedKmH = isReal ? (real.currentSpeed * 3.6) : null;
    final currentAlt = (isReal && real.altitudes.isNotEmpty)
        ? real.altitudes.last
        : (track.altitudes.isNotEmpty ? track.altitudes.last : null);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
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
            // Ajustem l'alçada per evitar qualsevol overflow
            final cardHeight = (constraints.maxHeight - 64) / 4;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // 1. DISTÀNCIA
                  _StatCard(
                    height: cardHeight,
                    pages: [
                      _StatPage(
                        Icons.straighten,
                        track!.distance > 0 ? (track.distance / 1000) : null,
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
                  ),
                  const SizedBox(height: 8),
                  // 2. TEMPS
                  _StatCard(
                    height: cardHeight,
                    pages: [
                      _StatPage(
                        Icons.timer,
                        null,
                        "",
                        t.statTimeTotal,
                        customValue: _formatDuration(currentDuration),
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
                          currentDuration - track.stoppedDuration,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 3. VELOCITAT
                  _StatCard(
                    height: cardHeight,
                    pages: [
                      _StatPage(
                        Icons.bolt,
                        speedKmH,
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
                  ),
                  const SizedBox(height: 8),
                  // 4. ALTIMETRIA (5 PÀGINES)
                  _StatCard(
                    height: cardHeight,
                    pages: [
                      _StatPage(
                        Icons.terrain,
                        currentAlt,
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
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations t) {
    return Scaffold(
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
}

class _StatCard extends StatelessWidget {
  final double height;
  final List<Widget> pages;

  const _StatCard({required this.height, required this.pages});

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
        child: PageView(scrollDirection: Axis.horizontal, children: pages),
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
    String displayValue =
        customValue ??
        (value == null
            ? "--"
            : (isInt ? value!.toStringAsFixed(0) : value!.toStringAsFixed(2)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Capçalera: Icona i Títol més grans
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
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
          const SizedBox(height: 6),
          // Valor principal lleugerament més petit per equilibri
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayValue,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 34, // Reduït de 38 a 34
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (unit.isNotEmpty && displayValue != "--") ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
