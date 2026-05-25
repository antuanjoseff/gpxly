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
            // --- 1. Distància Hero ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildMainHero(distanceKm, "km"),
            ),

            // --- 2. Segona Fila (Micro-swipes Centrats) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMicroSwipeCard([
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
                    child: _buildMicroSwipeCard([
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

            const SizedBox(height: 20),

            // --- 3. Tercer Element (PageView sense peek) ---
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

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_outlined, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    "Llisca per veure més detalls",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicroSwipeCard(List<Widget> items) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PageView(children: items),
      ),
    );
  }

  Widget _buildMainHero(String value, String unit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            unit.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
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
          Icon(icon, color: AppColors.primary.withOpacity(0.5), size: 18),
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
