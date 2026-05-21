import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/barometer_settings_notifier.dart';
import 'package:senda/notifiers/gps_accuracy_notifier.dart';
import 'package:senda/notifiers/gps_altitude_notifier.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/ui/app_messages.dart';
import 'package:senda/utils/gps_accuracy.dart';

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
        title: Text(
          t.barometerTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- TARGETA D'ESTAT ACTUAL ---
          _buildStatusCard(t, altitude),

          const SizedBox(height: 24),

          // --- SECCIÓ CALIBRATGE MANUAL ---
          _buildSectionTitle(t.manualCalibration),
          const SizedBox(height: 12),
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

          const SizedBox(height: 24),

          // --- SECCIÓ INTERVAL AUTOMÀTIC (Estil GPS) ---
          _buildSectionTitle(t.autoCalibrationInterval),
          const SizedBox(height: 12),
          _buildSettingsCard(
            title: t.howOften,
            valueText: "${baroSettings.calibrationInterval} min",
            sliderRow: _buildSliderRow(
              context: context,
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
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              t.barometerExplanation,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // UI HELPERS (Basats en GpsSettingsTab)
  // ------------------------------

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

  Widget _buildSettingsCard({
    required String title,
    required String valueText,
    required Widget sliderRow,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          sliderRow,
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final step = (max - min) / divisions;

    return Row(
      children: [
        IconButton(
          onPressed: value > min
              ? () => onChanged((value - step).clamp(min, max))
              : null,
          icon: const Icon(Icons.remove_circle_outline, size: 28),
          color: AppColors.primary,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.black.withAlpha(30),
              trackHeight: 6,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        IconButton(
          onPressed: value < max
              ? () => onChanged((value + step).clamp(min, max))
              : null,
          icon: const Icon(Icons.add_circle_outline, size: 28),
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: accuracyColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
