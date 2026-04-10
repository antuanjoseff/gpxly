import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/providers/active_track_provider.dart';
import 'package:gpxly/theme/app_colors.dart';

class TrackStatsScreen extends ConsumerWidget {
  const TrackStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(activeTrackProvider);
    final hasCoords = track.coordinates.isNotEmpty;
    final hasElev = track.hasElevationData;
    final hasTime = track.hasTimeData;
    final hasAscDesc = track.hasAscentDescent;

    return Scaffold(
      appBar: AppBar(title: const Text("Dades de la ruta")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            context,
            "Temps total",
            hasTime ? track.formattedDuration : "---",
            Icons.timer,
            AppColors.dark,
          ),

          _buildStatCard(
            context,
            "Distància",
            hasCoords
                ? "${(track.distance / 1000).toStringAsFixed(2)} km"
                : "---",
            Icons.straighten,
            AppColors.dark,
          ),

          _buildStatCard(
            context,
            "Velocitat Mitjana",
            hasTime ? "${track.averageSpeed.toStringAsFixed(1)} km/h" : "---",
            Icons.speed,
            AppColors.dark,
          ),

          const Divider(height: 30),

          _buildStatCard(
            context,
            "Elevació Màxima",
            hasElev ? "${track.maxElevation.toStringAsFixed(0)} m" : "---",
            Icons.terrain,
            AppColors.dark,
          ),

          _buildStatCard(
            context,
            "Elevació Mínima",
            hasElev ? "${track.minElevation.toStringAsFixed(0)} m" : "---",
            Icons.south_east,
            AppColors.dark,
          ),

          _buildStatCard(
            context,
            "Desnivell Positiu (+)",
            hasAscDesc ? "${track.ascent.toStringAsFixed(0)} m" : "---",
            Icons.unfold_less,
            AppColors.dark,
          ),

          _buildStatCard(
            context,
            "Desnivell Negatiu (-)",
            hasAscDesc ? "${track.descent.toStringAsFixed(0)} m" : "---",
            Icons.unfold_more,
            AppColors.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }
}
