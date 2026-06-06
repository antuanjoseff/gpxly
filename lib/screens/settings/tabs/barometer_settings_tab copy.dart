// lib/screens/settings/tabs/barometer_settings_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/core/altitude/altitude_processor.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/gps_accuracy_notifier.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:senda/widgets/debug_dem_map.dart';

class BarometerSettingsTab extends ConsumerWidget {
  const BarometerSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final accuracy = ref.watch(gpsAccuracyProvider);
    final bool isAccuracyGood = accuracy > 0.1 && accuracy <= 10.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.barometerTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      // 🌟 SOLUCIÓ: Cambiamos a un Column fijo con el mapa ocupando todo el fondo inferior
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: const _FusedAltitudeStatusCard(),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.manualCalibration.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildActionCard(
              context: context,
              ref: ref,
              icon: Icons.autorenew_rounded,
              title: t.recalibrateGpsDem,
              subtitle:
                  "${t.currentGpsAccuracy}: ${accuracy.toStringAsFixed(1)} m",
              accuracyColor: isAccuracyGood ? Colors.green : Colors.orange,
              onTap: () async {
                if (accuracy > 15.0 || accuracy <= 0.1) {
                  AppMessages.showErrorSnackBar(
                    context,
                    t.insufficientCoverage,
                  );
                  return;
                }
                ref.read(altitudeProcessorProvider.notifier).reset();
                AppMessages.showSuccessSnackBar(
                  context,
                  t.barometerCalibratedSuccess,
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              "VISUALITZACIÓ COBERTURA MIGRADA DEM",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // 🌟 EL MAPA ARA ÉS GEGANT: Ocupa todo el resto de la pantalla de forma nativa
          const Expanded(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: DebugDemMap(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color accuracyColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: accuracyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _FusedAltitudeStatusCard extends ConsumerWidget {
  const _FusedAltitudeStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final altState = ref.watch(altitudeProcessorProvider);
    final altitude = altState.fused ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            t.fusedAltitude,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${altitude.toStringAsFixed(1)} m",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
