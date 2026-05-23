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
import 'package:senda/screens/stats/widgets/stat_header.dart';
import 'package:senda/theme/app_colors.dart';

class TrackStatsScreen extends ConsumerWidget {
  const TrackStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);
    final liveDuration = ref.watch(timerProvider);

    final hasImported = imported != null && imported.coordinates.isNotEmpty;

    bool isValidElev(double elevation) => elevation.abs() < 9000;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.trackStatsTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(t, hasImported),

          // --- TEMPS ---
          StatTile(
            icon: Icons.timer_outlined,
            label: t.statTime,
            valueReal: _timeFor(real, liveDuration),
            valueImported: hasImported && imported!.hasTimeData
                ? imported.formattedDuration
                : null,
            chartType: StatChartType.speed, // velocitat vs distància
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.timer_outlined,
              label: t.statTime,
              valueReal: _timeFor(real, liveDuration),
              valueImported: hasImported ? imported!.formattedDuration : null,
              chartType: StatChartType.speed,
              real: real,
              imported: imported,
            ),
          ),

          // --- DISTÀNCIA ---
          StatTile(
            icon: Icons.straighten_rounded,
            label: t.statDistance,
            valueReal: real.coordinates.isNotEmpty
                ? "${(real.distance / 1000).toStringAsFixed(2)} km"
                : "---",
            valueImported: hasImported
                ? "${(imported!.distance / 1000).toStringAsFixed(2)} km"
                : null,
            chartType: StatChartType.slope,
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.straighten_rounded,
              label: t.statDistance,
              valueReal: "${(real.distance / 1000).toStringAsFixed(2)} km",
              valueImported: hasImported
                  ? "${(imported!.distance / 1000).toStringAsFixed(2)} km"
                  : null,
              chartType: StatChartType.slope,
              real: real,
              imported: imported,
            ),
          ),

          // --- VELOCITAT ---
          StatTile(
            icon: Icons.speed_rounded,
            label: t.statSpeed,
            valueReal: _hasTimeDataFromTimestamps(real)
                ? "${_averageSpeedFromTimestamps(real).toStringAsFixed(1)} km/h"
                : "---",
            valueImported: hasImported && _hasTimeDataFromTimestamps(imported!)
                ? "${_averageSpeedFromTimestamps(imported!).toStringAsFixed(1)} km/h"
                : null,
            chartType: StatChartType.speed,
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.speed_rounded,
              label: t.statSpeed,
              valueReal: _hasTimeDataFromTimestamps(real)
                  ? "${_averageSpeedFromTimestamps(real).toStringAsFixed(1)} km/h"
                  : "---",
              valueImported:
                  hasImported && _hasTimeDataFromTimestamps(imported!)
                  ? "${_averageSpeedFromTimestamps(imported!).toStringAsFixed(1)} km/h"
                  : null,
              chartType: StatChartType.speed,
              real: real,
              imported: imported,
            ),
          ),

          const Divider(height: 32, thickness: 0.7),

          // --- ALTIMETRIA ---
          StatTile(
            icon: Icons.terrain_rounded,
            label: t.statMaxElevation,
            valueReal: real.hasElevationData && isValidElev(real.maxElevation)
                ? "${real.maxElevation.toStringAsFixed(0)} m"
                : "---",
            valueImported:
                hasImported &&
                    imported!.hasElevationData &&
                    isValidElev(imported.maxElevation)
                ? "${imported.maxElevation.toStringAsFixed(0)} m"
                : null,
            chartType: StatChartType.elevation,
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.terrain_rounded,
              label: t.statMaxElevation,
              valueReal: "${real.maxElevation.toStringAsFixed(0)} m",
              valueImported: hasImported
                  ? "${imported!.maxElevation.toStringAsFixed(0)} m"
                  : null,
              chartType: StatChartType.elevation,
              real: real,
              imported: imported,
            ),
          ),

          StatTile(
            icon: Icons.south_east_rounded,
            label: t.statMinElevation,
            valueReal: real.hasElevationData && isValidElev(real.minElevation)
                ? "${real.minElevation.toStringAsFixed(0)} m"
                : "---",
            valueImported:
                hasImported &&
                    imported!.hasElevationData &&
                    isValidElev(imported.minElevation)
                ? "${imported.minElevation.toStringAsFixed(0)} m"
                : null,
            chartType: StatChartType.elevation,
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.south_east_rounded,
              label: t.statMinElevation,
              valueReal: "${real.minElevation.toStringAsFixed(0)} m",
              valueImported: hasImported
                  ? "${imported!.minElevation.toStringAsFixed(0)} m"
                  : null,
              chartType: StatChartType.elevation,
              real: real,
              imported: imported,
            ),
          ),

          StatTile(
            icon: Icons.unfold_less_rounded,
            label: t.statAscent,
            valueReal: real.hasAscentDescent
                ? "${real.ascent.toStringAsFixed(0)} m"
                : "---",
            valueImported: hasImported && imported!.hasAscentDescent
                ? "${imported.ascent.toStringAsFixed(0)} m"
                : null,
            chartType: StatChartType.elevation,
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.unfold_less_rounded,
              label: t.statAscent,
              valueReal: "${real.ascent.toStringAsFixed(0)} m",
              valueImported: hasImported
                  ? "${imported!.ascent.toStringAsFixed(0)} m"
                  : null,
              chartType: StatChartType.elevation,
              real: real,
              imported: imported,
            ),
          ),

          StatTile(
            icon: Icons.unfold_more_rounded,
            label: t.statDescent,
            valueReal: real.hasAscentDescent
                ? "${real.descent.toStringAsFixed(0)} m"
                : "---",
            valueImported: hasImported && imported!.hasAscentDescent
                ? "${imported.descent.toStringAsFixed(0)} m"
                : null,
            chartType: StatChartType.elevation,
            onTap: () => _navigateToDetail(
              context,
              icon: Icons.unfold_more_rounded,
              label: t.statDescent,
              valueReal: "${real.descent.toStringAsFixed(0)} m",
              valueImported: hasImported
                  ? "${imported!.descent.toStringAsFixed(0)} m"
                  : null,
              chartType: StatChartType.elevation,
              real: real,
              imported: imported,
            ),
          ),
        ],
      ),
    );
  }

  // --- CAPÇALERA ---
  Widget _buildHeader(AppLocalizations t, bool hasImported) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 54),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.redAlert.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  t.recordingTrack.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.redAlert,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          if (hasImported) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.trackGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    t.importedTrack.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.trackGreen,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- NEW SCREEN ---
  // --- NAVEGACIÓ AMB EFECTE SWAP ---
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

  // --- TEMPS ---
  String _timeFor(Track t, Duration live) {
    switch (t.recordingState) {
      case RecordingState.recording:
        return _formatDuration(live);
      case RecordingState.paused:
        return t.formattedDuration;
      default:
        return "---";
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  double _averageSpeedFromTimestamps(Track t) {
    if (t.timestamps.length < 2) return 0;

    final seconds = t.timestamps.last.difference(t.timestamps.first).inSeconds;

    if (seconds <= 0) return 0;

    final hours = seconds / 3600.0;
    final km = t.distance / 1000.0;

    return km / hours;
  }

  bool _hasTimeDataFromTimestamps(Track t) {
    return t.timestamps.length >= 2;
  }
}
