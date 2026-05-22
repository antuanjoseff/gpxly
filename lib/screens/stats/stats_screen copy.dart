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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);
    final liveDuration = ref.watch(timerProvider);

    final hasImported = imported != null && imported.coordinates.isNotEmpty;

    bool isValidElev(double elevation) => elevation.abs() < 9000;

    const headerStyleRec = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.redAlert,
      letterSpacing: 0.8,
    );

    const headerStyleImp = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.trackGreen,
      letterSpacing: 0.8,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.trackStatsTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- CAPÇALERA DE COLUMNES ---
          Padding(
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
                        style: headerStyleRec,
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
                          style: headerStyleImp,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // --- TEMPS ---
          _buildStatTile(
            context: context,
            icon: Icons.timer_outlined,
            label: t.statTime,
            value1: _timeFor(real, liveDuration),
            value2: hasImported && imported!.hasTimeData
                ? imported.formattedDuration
                : null,
          ),

          // --- DISTÀNCIA ---
          _buildStatTile(
            context: context,
            icon: Icons.straighten_rounded,
            label: t.statDistance,
            value1: real.coordinates.isNotEmpty
                ? "${(real.distance / 1000).toStringAsFixed(2)} km"
                : "---",
            value2: hasImported
                ? "${(imported!.distance / 1000).toStringAsFixed(2)} km"
                : null,
          ),

          // --- VELOCITAT ---
          _buildStatTile(
            context: context,
            icon: Icons.speed_rounded,
            label: t.statSpeed,
            value1: real.hasTimeData
                ? "${real.averageSpeed.toStringAsFixed(1)} km/h"
                : "---",
            value2: hasImported && imported!.hasTimeData
                ? "${imported.averageSpeed.toStringAsFixed(1)} km/h"
                : null,
          ),

          const Divider(height: 32, thickness: 0.7),

          // --- ALTIMETRIA ---
          _buildStatTile(
            context: context,
            icon: Icons.terrain_rounded,
            label: t.statMaxElevation,
            value1: real.hasElevationData && isValidElev(real.maxElevation)
                ? "${real.maxElevation.toStringAsFixed(0)} m"
                : "---",
            value2:
                hasImported &&
                    imported!.hasElevationData &&
                    isValidElev(imported.maxElevation)
                ? "${imported.maxElevation.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            context: context,
            icon: Icons.south_east_rounded,
            label: t.statMinElevation,
            value1: real.hasElevationData && isValidElev(real.minElevation)
                ? "${real.minElevation.toStringAsFixed(0)} m"
                : "---",
            value2:
                hasImported &&
                    imported!.hasElevationData &&
                    isValidElev(imported.minElevation)
                ? "${imported.minElevation.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            context: context,
            icon: Icons.unfold_less_rounded,
            label: t.statAscent,
            value1: real.hasAscentDescent
                ? "${real.ascent.toStringAsFixed(0)} m"
                : "---",
            value2: hasImported && imported!.hasAscentDescent
                ? "${imported.ascent.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            context: context,
            icon: Icons.unfold_more_rounded,
            label: t.statDescent,
            value1: real.hasAscentDescent
                ? "${real.descent.toStringAsFixed(0)} m"
                : "---",
            value2: hasImported && imported!.hasAscentDescent
                ? "${imported.descent.toStringAsFixed(0)} m"
                : null,
          ),
        ],
      ),
    );
  }

  // --- TILE TAPPABLE ---
  Widget _buildStatTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value1,
    String? value2,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showStatDetails(context, icon, label, value1, value2),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.grey.shade600, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _valueBox(value: value1, color: AppColors.redAlert),
            ),

            if (value2 != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _valueBox(value: value2, color: AppColors.trackGreen),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- BOTTOMSHEET ---
  void _showStatDetails(
    BuildContext context,
    IconData icon,
    String label,
    String value1,
    String? value2,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 26, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _detailRow("Track gravat", value1),
                if (value2 != null) _detailRow("Track importat", value2),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _valueBox({required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40), width: 1),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 0.3,
            color: color,
          ),
        ),
      ),
    );
  }

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
}
