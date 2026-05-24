import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/timer_notifier.dart';
import 'package:senda/notifiers/track_notifier.dart';
import 'package:senda/screens/stats/models/stat_chart_type.dart';
import 'package:senda/screens/stats/stats_detail_screen.dart';
import 'package:senda/theme/app_colors.dart';

class TrackStatsScreen extends ConsumerWidget {
  const TrackStatsScreen({super.key});

  // --- Mètodes de suport (Originals mantinguts) ---
  String _timeFor(Track real, Duration liveDuration) {
    if (real.coordinates.isEmpty) return "00:00:00";
    return liveDuration.toString().split('.').first.padLeft(8, "0");
  }

  bool _trackHasElevation(Track? track) {
    return track != null && track.altitudes.isNotEmpty;
  }

  String _formatElevation({
    required double value,
    required bool hasElevationData,
  }) {
    return hasElevationData ? "${value.toStringAsFixed(0)} m" : "---";
  }

  void _navigateToDetail(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String valueReal,
    required StatChartType chartType,
    Track? real,
    Track? imported,
    String? valueImported,
  }) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        // <--- Això activa el gest de swipe lateral
        builder: (context) => StatDetailScreen(
          icon: icon,
          label: label,
          valueReal: valueReal,
          valueImported: valueImported,
          chartType: chartType,
          realTrack: real,
          importedTrack: imported,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);
    final liveDuration = ref.watch(timerProvider);

    final hasImported = imported != null && imported.coordinates.isNotEmpty;

    final currentRealTime = _timeFor(real, liveDuration);
    final currentRealElev = "${real.maxElevation.toStringAsFixed(0)} m";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          t.trackStatsTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(t, hasImported),
          const SizedBox(height: 8),

          // --- BLOC 1: RENDIMENT ---
          _StatGroupCard(
            title: t.statTime.toUpperCase(),
            icon: Icons.speed_rounded,
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.speed_rounded,
              label: "Rendiment",
              valueReal: currentRealTime,
              chartType: StatChartType.speed,
              real: real,
              imported: imported,
              valueImported: hasImported ? imported!.formattedDuration : null,
            ),
            rows: [
              _StatRow(
                label: t.statTime,
                valueReal: currentRealTime,
                valueImported: hasImported && imported!.hasTimeData
                    ? imported.formattedDuration
                    : null,
              ),
              _StatRow(
                label: t.statDistance,
                valueReal: real.coordinates.isNotEmpty
                    ? "${(real.distance / 1000).toStringAsFixed(2)} km"
                    : "---",
                valueImported: hasImported
                    ? "${(imported!.distance / 1000).toStringAsFixed(2)} km"
                    : null,
              ),
              _StatRow(
                label: t.statSpeed,
                valueReal: real.hasTimeData
                    ? "${real.averageSpeed.toStringAsFixed(1)} km/h"
                    : "---",
                valueImported: hasImported && imported!.hasTimeData
                    ? "${imported.averageSpeed.toStringAsFixed(1)} km/h"
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- BLOC 2: ALTIMETRIA ---
          _StatGroupCard(
            title: t.statMaxElevation.toUpperCase(),
            icon: Icons.terrain_rounded,
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.terrain_rounded,
              label: "Altimetria",
              chartType: StatChartType.elevation,
              real: real,
              imported: imported,
              valueReal: currentRealElev,
              valueImported: hasImported
                  ? "${imported!.maxElevation.toStringAsFixed(0)} m"
                  : null,
            ),
            rows: [
              _StatRow(
                label: t.statMaxElevation,
                valueReal: _formatElevation(
                  value: real.maxElevation,
                  hasElevationData: _trackHasElevation(real),
                ),
                valueImported: hasImported
                    ? _formatElevation(
                        value: imported.maxElevation,
                        hasElevationData: _trackHasElevation(imported),
                      )
                    : null,
              ),
              _StatRow(
                label: t.statMinElevation,
                valueReal: _formatElevation(
                  value: real.minElevation,
                  hasElevationData: _trackHasElevation(real),
                ),
                valueImported: hasImported
                    ? _formatElevation(
                        value: imported.minElevation,
                        hasElevationData: _trackHasElevation(imported),
                      )
                    : null,
              ),
              _StatRow(
                label: t.statAscent,
                valueReal: _formatElevation(
                  value: real.ascent,
                  hasElevationData: _trackHasElevation(real),
                ),
                valueImported: hasImported
                    ? _formatElevation(
                        value: imported.ascent,
                        hasElevationData: _trackHasElevation(imported),
                      )
                    : null,
              ),
              _StatRow(
                label: t.statDescent,
                valueReal: _formatElevation(
                  value: real.descent,
                  hasElevationData: _trackHasElevation(real),
                ),
                valueImported: hasImported
                    ? _formatElevation(
                        value: imported.descent,
                        hasElevationData: _trackHasElevation(imported),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations t, bool hasImported) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Expanded(flex: 3, child: SizedBox.shrink()),
          _HeaderLabel(label: t.recordingTrack, color: AppColors.redAlert),
          const SizedBox(width: 8),
          if (hasImported)
            _HeaderLabel(label: t.importedTrack, color: AppColors.trackGreen)
          else
            const Expanded(flex: 2, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

// --- Components de suport per mantenir el codi net ---

class _HeaderLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _HeaderLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _StatGroupCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  final VoidCallback onTap;
  final IconData icon;

  const _StatGroupCard({
    required this.title,
    required this.rows,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.black12,
                  ),
                ],
              ),
            ),
            ...rows,
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String valueReal;
  final String? valueImported;

  const _StatRow({
    required this.label,
    required this.valueReal,
    this.valueImported,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              valueReal,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          if (valueImported != null)
            Expanded(
              flex: 2,
              child: Text(
                valueImported!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black38),
              ),
            )
          else
            const Expanded(flex: 2, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
