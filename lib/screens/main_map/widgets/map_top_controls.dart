// lib/screens/main_map/widgets/map_top_controls.dart (Bloc 1 de 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/screens/main_map/widgets/map_square_button.dart';
import 'package:senda/screens/stats/stats_screen.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/compass_widget.dart';

class MapTopControls extends ConsumerWidget {
  final MapLibreMapController? mapController;
  final bool smartCenterEnabled;
  final VoidCallback onCenterOnUser;
  final VoidCallback onAddWaypoint;

  const MapTopControls({
    super.key,
    required this.mapController,
    required this.smartCenterEnabled,
    required this.onCenterOnUser,
    required this.onAddWaypoint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned(
          top: 10,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // El panell de la brúixola ara amida 48px concrets i té vora vermella elèctrica
              CompassScalePanel(
                onTapCompass: () =>
                    mapController?.animateCamera(CameraUpdate.bearingTo(0)),
              ),
              const SizedBox(height: 8),

              // Botó d'Estadístiques (Tipus 2: Control Tècnic Vermell)
              MapSquareButton(
                icon: Icons.bar_chart,
                style: MapButtonStyle
                    .control, // 🔥 Força l'estat elèctric de vora vermella
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrackStatsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Botó d'afegir fita (Només visible si es grava, Tipus 2 Control Vermell)
              if (ref.watch(trackRecordingProvider).recordingState ==
                  RecordingState.recording) ...[
                MapSquareButton(
                  icon: Icons.add_location_alt_outlined,
                  style: MapButtonStyle
                      .control, // 🔥 Força l'estat elèctric de vora vermella
                  onTap: onAddWaypoint,
                ),
                const SizedBox(height: 8),
              ],

              // Botó de recentrat GPS (Tipus 2 Control Vermell)
              if (!smartCenterEnabled)
                MapSquareButton(
                  icon: Icons.gps_fixed,
                  style: MapButtonStyle
                      .control, // 🔥 Força l'estat elèctric de vora vermella
                  onTap: onCenterOnUser,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // (Continuació del fitxer map_top_controls.dart)
  // (Substitueix aquest mètode dins de map_top_controls.dart)
  Widget _buildAltitudeCapsule(BuildContext context, WidgetRef ref) {
    final userPos = ref.watch(locationProvider);
    final double? altitude = userPos?.altitude;
    final bool isFixed = userPos?.isHgtFixed ?? false;

    return Container(
      height:
          48, // 🎯 Manté exactament la mateixa alçada simètrica de la graella de botons (48px)
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ), // Marge lateral perquè el text respiri [INDEX]
      decoration: BoxDecoration(
        color: AppColors
            .primary, // 🟢 Fons sòlid corporatiu exactament igual que els botons de dalt [INDEX]
        borderRadius: BorderRadius.circular(
          12,
        ), // Mateix arrodoniment dels botons superiors [INDEX]
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize
            .min, // 🚀 CRÍTIC: Fa que el contenidor s'estiri horitzontalment de forma elàstica
        children: [
          Icon(
            Icons.filter_hdr_rounded,
            // Si la cota encara no és fixa o és estimada, usem el vermell d'alerta per contrastar sobre el blau
            color: isFixed ? Colors.white : AppColors.redAlert,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            altitude != null ? "${altitude.toStringAsFixed(0)} m" : "--- m",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
