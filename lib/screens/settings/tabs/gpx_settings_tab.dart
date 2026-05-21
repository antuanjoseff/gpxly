import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/gpx_settings_notifier.dart';
import 'package:senda/theme/app_colors.dart';
// Assegura't que el path sigui el correcte on tinguis el SectionTitle i SettingsCard
import 'package:senda/widgets/custom_settings_card.dart';

class GpxSettingsTab extends ConsumerWidget {
  const GpxSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gpxSettingsProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false, // Consistència amb Baròmetre
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.gpxTab,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- TÍTOL DE SECCIÓ UNIFICAT ---
          // Utilitzem el widget que ja té el format 12, bold, grey i majúscules
          SectionTitle(t.gpxIncludeExtraData),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.accuracies,
            field: "accuracies",
            title: t.gpxAccuracyPerPoint,
            icon: Icons.gps_fixed,
            t: t,
          ),
          const SizedBox(height: 12),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.speeds,
            field: "speeds",
            title: t.gpxSpeed,
            icon: Icons.speed,
            t: t,
          ),
          const SizedBox(height: 12),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.headings,
            field: "headings",
            title: t.gpxHeading,
            icon: Icons.explore_outlined,
            t: t,
          ),
          const SizedBox(height: 12),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.satellites,
            field: "satellites",
            title: t.gpxSatellites,
            icon: Icons.satellite_alt,
            t: t,
          ),
          const SizedBox(height: 12),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.vAccuracies,
            field: "vAccuracies",
            title: t.gpxVerticalAccuracy,
            icon: Icons.height,
            t: t,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGpxSwitchCard({
    required WidgetRef ref,
    required bool value,
    required String field,
    required String title,
    required IconData icon,
    required AppLocalizations t,
  }) {
    final Color currentColor = value ? AppColors.primary : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.primary.withAlpha(80) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            ref.read(gpxSettingsProvider.notifier).toggle(field, !value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: currentColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: value ? AppColors.primary : Colors.grey,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value ? t.switchOn : t.switchOff,
                  style: const TextStyle(
                    fontSize: 11, // Mantenim l'estil dels badges petits
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
