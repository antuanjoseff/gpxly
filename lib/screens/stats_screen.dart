import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'package:gpxly/models/track.dart';

class TrackStatsScreen extends ConsumerWidget {
  const TrackStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    final real = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);

    final hasReal = real.coordinates.isNotEmpty;
    final hasImported = imported?.coordinates.isNotEmpty == true;

    final hasTimeReal = real.hasTimeData;
    final hasTimeImported = imported?.hasTimeData == true;

    final hasCoordsReal = real.coordinates.isNotEmpty;
    final hasCoordsImported = imported?.coordinates.isNotEmpty == true;

    final hasElevReal = real.hasElevationData;
    final hasElevImported = imported?.hasElevationData == true;

    final hasAscReal = real.hasAscentDescent;
    final hasAscImported = imported?.hasAscentDescent == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.trackStatsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatTile(
            icon: Icons.timer,
            label: t.statTime,
            value1: hasTimeReal ? real.formattedDuration : "---",
            value2: hasImported && hasTimeImported
                ? imported!.formattedDuration
                : null,
          ),

          _buildStatTile(
            icon: Icons.straighten,
            label: t.statDistance,
            value1: hasCoordsReal
                ? "${(real.distance / 1000).toStringAsFixed(2)} km"
                : "---",
            value2: hasImported && hasCoordsImported
                ? "${(imported!.distance / 1000).toStringAsFixed(2)} km"
                : null,
          ),

          _buildStatTile(
            icon: Icons.speed,
            label: t.statSpeed,
            value1: hasTimeReal
                ? "${real.averageSpeed.toStringAsFixed(1)} km/h"
                : "---",
            value2: hasImported && hasTimeImported
                ? "${imported!.averageSpeed.toStringAsFixed(1)} km/h"
                : null,
          ),

          const Divider(height: 30),

          _buildStatTile(
            icon: Icons.terrain,
            label: t.statMaxElevation,
            value1: hasElevReal
                ? "${real.maxElevation.toStringAsFixed(0)} m"
                : "---",
            value2: hasImported && hasElevImported
                ? "${imported!.maxElevation.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            icon: Icons.south_east,
            label: t.statMinElevation,
            value1: hasElevReal
                ? "${real.minElevation.toStringAsFixed(0)} m"
                : "---",
            value2: hasImported && hasElevImported
                ? "${imported!.minElevation.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            icon: Icons.unfold_less,
            label: t.statAscent,
            value1: hasAscReal ? "${real.ascent.toStringAsFixed(0)} m" : "---",
            value2: hasImported && hasAscImported
                ? "${imported!.ascent.toStringAsFixed(0)} m"
                : null,
          ),

          _buildStatTile(
            icon: Icons.unfold_more,
            label: t.statDescent,
            value1: hasAscReal ? "${real.descent.toStringAsFixed(0)} m" : "---",
            value2: hasImported && hasAscImported
                ? "${imported!.descent.toStringAsFixed(0)} m"
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value1,
    String? value2,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconLabelColumn(icon, label),

            const SizedBox(width: 16),

            Expanded(
              flex: 2,
              child: _trackValueBox(
                color: AppColors.mustardYellow.withOpacity(0.25),
                value: value1,
              ),
            ),

            if (value2 != null) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _trackValueBox(
                  color: Colors.lightBlueAccent.withOpacity(0.25),
                  value: value2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconLabelColumn(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.dark, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }

  Widget _trackValueBox({required Color color, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }
}
