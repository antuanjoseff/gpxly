import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/track_notifier.dart';

class TrackStatsScreen extends ConsumerWidget {
  const TrackStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(trackProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final hasData = track.coordinates.isNotEmpty;
    final maxElev = hasData
        ? "${track.maxElevation.toStringAsFixed(0)} m"
        : "---";
    final minElev = hasData
        ? "${track.minElevation.toStringAsFixed(0)} m"
        : "---";

    return Scaffold(
      appBar: AppBar(title: const Text("Dades de la ruta")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            context,
            "Temps total",
            track.formattedDuration,
            Icons.timer,
            colors.primary, // blau cel
          ),

          _buildStatCard(
            context,
            "Distància",
            "${(track.distance / 1000).toStringAsFixed(2)} km",
            Icons.straighten,
            colors.secondary, // ocre
          ),

          _buildStatCard(
            context,
            "Velocitat Mitjana",
            "${track.averageSpeed.toStringAsFixed(1)} km/h",
            Icons.speed,
            colors.primary,
          ),

          const Divider(height: 30),

          _buildStatCard(
            context,
            "Elevació Màxima",
            maxElev,
            Icons.terrain,
            colors.secondary,
          ),

          _buildStatCard(
            context,
            "Elevació Mínima",
            minElev,
            Icons.south_east,
            colors.secondary,
          ),

          _buildStatCard(
            context,
            "Desnivell Positiu (+)",
            "${track.ascent.toStringAsFixed(0)} m",
            Icons.unfold_less,
            colors.primary,
          ),

          _buildStatCard(
            context,
            "Desnivell Negatiu (-)",
            "${track.descent.toStringAsFixed(0)} m",
            Icons.unfold_more,
            colors.primary,
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
            color: colors.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }
}
