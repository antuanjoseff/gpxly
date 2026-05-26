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

  String _formatElevation(double v) => "${v.toStringAsFixed(0)}m";

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
      return _buildEmptyState(context, t);
    }

    final isReal = track == real;
    final currentDuration = isReal ? liveDuration : track.duration;
    final distanceKm = (track.distance / 1000).toStringAsFixed(2);
    final currentSpeed = isReal
        ? (real.currentSpeed * 3.6).toStringAsFixed(1)
        : "0.0";
    final currentAlt = isReal
        ? (real.altitudes.isNotEmpty ? real.altitudes.last : 0.0)
        : 0.0;

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
            // --- 1. DISTÀNCIA HERO ---
            _buildHeroDistance(distanceKm),

            // --- 2. SEGONA FILA: 3 COLUMNES AMB CARRUSEL VERTICAL ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 120,
                child: Row(
                  children: [
                    // Columna TEMPS (Total / Aturat)
                    Expanded(
                      child: _buildVerticalCarousel([
                        _StatMini(
                          Icons.timer,
                          _formatDuration(currentDuration),
                          t.statTimeTotal,
                          Colors.blueGrey,
                        ),
                        _StatMini(
                          Icons.pause_circle_filled,
                          _formatDuration(track.stoppedDuration),
                          t.statTimeStopped,
                          Colors.blueGrey,
                        ),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    // Columna VELOCITAT (Actual / Mitjana)
                    Expanded(
                      child: _buildVerticalCarousel([
                        _StatMini(
                          Icons.bolt,
                          currentSpeed,
                          "km/h",
                          Colors.orange.shade800,
                        ),
                        _StatMini(
                          Icons.speed,
                          track.averageSpeed.toStringAsFixed(1),
                          "avg km/h",
                          Colors.orange.shade800,
                        ),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    // Columna ALTITUD (Actual / Mínima)
                    Expanded(
                      child: _buildVerticalCarousel([
                        _StatMini(
                          Icons.terrain,
                          _formatElevation(currentAlt),
                          t.statElevation,
                          Colors.green.shade700,
                        ),
                        _StatMini(
                          Icons.vertical_align_bottom,
                          _formatElevation(track.minElevation),
                          t.statMinElevation,
                          Colors.green.shade700,
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- 3. TERCER ELEMENT (Swipe de detalls horitzontal) ---
            SizedBox(
              height: 240,
              child: PageView(
                children: [
                  _buildDetailCard(
                    title: t.statElevation,
                    icon: Icons.show_chart,
                    rows: [
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
                  _buildDetailCard(
                    title: isReal ? t.recordingTrack : t.importedTrack,
                    icon: Icons.info_outline,
                    rows: [
                      _DetailRow(
                        Icons.directions_run,
                        t.statTimeMoving,
                        _formatDuration(
                          currentDuration - track.stoppedDuration,
                        ),
                      ),
                      const Divider(),
                      _DetailRow(
                        Icons.straighten,
                        "Punts GPS",
                        "${track.coordinates.length}",
                      ),
                      const Divider(),
                      _DetailRow(
                        Icons.satellite_alt,
                        "Satèl·lits",
                        "${isReal ? real.currentSatellites : 0}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILDERS DE WIDGETS ---

  Widget _buildEmptyState(BuildContext context, AppLocalizations t) {
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

  Widget _buildHeroDistance(String distance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              distance,
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: Colors.white,
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
    );
  }

  Widget _buildVerticalCarousel(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PageView(scrollDirection: Axis.vertical, children: items),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatMini(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.black87)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
