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

  String _formatDuration(Duration d) =>
      d.toString().split('.').first.padLeft(8, "0");

  String _formatElevation(double v) => "${v.toStringAsFixed(0)} m";

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

    if (track == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          title: Text(
            t.trackStatsTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            t.noRecordedTrack,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    final isReal = track == real;
    final currentDuration = isReal ? liveDuration : track.duration;
    final timeTotal = _formatDuration(currentDuration);
    final timeStopped = _formatDuration(track.stoppedDuration);
    final distanceKm = (track.distance / 1000).toStringAsFixed(2);
    final currentSpeed = (isReal && real.speeds.isNotEmpty)
        ? real.speeds.last.toStringAsFixed(1)
        : "0.0";
    final avgSpeed = track.averageSpeed.isFinite
        ? track.averageSpeed.toStringAsFixed(1)
        : "0.0";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. Distància Hero (Més compacte verticalment) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                ), // Reduït de 32 a 20
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(217),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      distanceKm,
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "KM",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- 2. Segona Fila (Títols més visibles i multilineals) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMicroCard([
                      _StatItem(
                        t.statTimeStopped,
                        timeStopped,
                        Icons.pause_circle_filled,
                      ),
                      _StatItem(t.statTimeTotal, timeTotal, Icons.timer),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMicroCard([
                      _StatItem(
                        t.statSpeedCurrent,
                        "$currentSpeed km/h",
                        Icons.bolt,
                      ),
                      _StatItem(
                        t.statSpeedAverage,
                        "$avgSpeed km/h",
                        Icons.speed,
                      ),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- 3. Tercer Element (Swipe Lineal) ---
            SizedBox(
              height: 240,
              child: PageView(
                controller: PageController(viewportFraction: 1.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSwipeCard(
                      title: t.statElevation,
                      icon: Icons.terrain,
                      children: [
                        _DetailRow(
                          Icons.trending_up,
                          t.statAscent,
                          _formatElevation(track.ascent),
                        ),
                        const Divider(),
                        _DetailRow(
                          Icons.trending_down,
                          t.statDescent,
                          _formatElevation(track.descent),
                        ),
                        const Divider(),
                        _DetailRow(
                          Icons.height,
                          t.statMaxElevation,
                          _formatElevation(track.maxElevation),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSwipeCard(
                      title: isReal ? t.recordingTrack : t.importedTrack,
                      icon: Icons.info_outline,
                      children: [
                        _DetailRow(
                          Icons.directions_run,
                          t.statTimeMoving,
                          _formatDuration(
                            currentDuration - track.stoppedDuration,
                          ),
                        ),
                        const Divider(),
                        _DetailRow(
                          Icons.location_on,
                          t.statMinElevation,
                          _formatElevation(track.minElevation),
                        ),
                        const Divider(),
                        _DetailRow(
                          Icons.straighten,
                          "Punts",
                          "${track.coordinates.length}",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroCard(List<Widget> items) {
    return Container(
      height: 110, // Una mica més alt per encabir el possible multiline
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PageView(
          physics: const BouncingScrollPhysics(),
          children: items,
        ),
      ),
    );
  }

  Widget _buildSwipeCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withAlpha(179),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                // Permet que el text ocupi dues files si cal
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withAlpha(128), size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
