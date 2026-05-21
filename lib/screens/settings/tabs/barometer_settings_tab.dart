import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/barometer_settings_notifier.dart';
import 'package:senda/notifiers/gps_accuracy_notifier.dart';
import 'package:senda/notifiers/gps_altitude_notifier.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:senda/utils/gps_accuracy.dart';
import 'package:senda/widgets/custom_settings_card.dart';

class BarometerSettingsTab extends ConsumerWidget {
  const BarometerSettingsTab({super.key});

  Color _getAccuracyColor(GpsAccuracyLevel level) {
    switch (level) {
      case GpsAccuracyLevel.high:
        return Colors.green;
      case GpsAccuracyLevel.medium:
        return Colors.orange;
      case GpsAccuracyLevel.poor:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final altitude = ref.watch(gpsAltitudeProvider);
    final accuracy = ref.watch(gpsAccuracyProvider);
    final accuracyLevel = ref.watch(gpsAccuracyLevelProvider);
    final baroSettings = ref.watch(barometerSettingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        // AppBar unificada: blanco, semibold y tamaño 18
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- TARGETA D'ESTAT ACTUAL ---
          _buildStatusCard(t, altitude),

          const SizedBox(height: 8),

          // --- SECCIÓ CALIBRATGE MANUAL ---
          // SectionTitle usa el tamaño 12 unificado
          SectionTitle(t.manualCalibration),
          _buildActionCard(
            icon: Icons.refresh,
            title: t.recalibrateGpsDem,
            accuracyColor: _getAccuracyColor(accuracyLevel),
            subtitle:
                "${t.currentGpsAccuracy}: ${accuracy.toStringAsFixed(1)} m",
            onTap: () async {
              if (accuracy > 15.0) {
                AppMessages.showErrorSnackBar(context, t.insufficientCoverage);
                return;
              }
              final lastAltitude = ref.read(gpsAltitudeProvider);
              ref
                  .read(gpsAltitudeProvider.notifier)
                  .forceCalibration(lastAltitude);
              AppMessages.showSuccessSnackBar(
                context,
                t.barometerCalibratedSuccess,
              );
            },
          ),

          // --- SECCIÓ INTERVAL AUTOMÀTIC ---
          SectionTitle(t.autoCalibrationInterval),
          SettingsCard(
            title: t.howOften,
            valueText: "${baroSettings.calibrationInterval} min",
            value: baroSettings.calibrationInterval.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (val) {
              ref
                  .read(barometerSettingsProvider.notifier)
                  .setInterval(val.toInt());
            },
          ),

          // --- TEXT DEL PEU (FOOTER) CORREGIT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Text(
              t.barometerExplanation,
              style: const TextStyle(
                fontSize: 13, // Subido de 12 a 13 para legibilidad
                color: Colors.grey,
                height: 1.4, // Interlineado para mejor lectura
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AppLocalizations t, double altitude) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(180)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            t.fusedAltitude,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "${altitude.toStringAsFixed(1)} m",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color accuracyColor = Colors.grey,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(30),
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
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: accuracyColor),
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
