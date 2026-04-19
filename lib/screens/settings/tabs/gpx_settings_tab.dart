import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/notifiers/gpx_settings_notifier.dart';
import 'package:gpxly/notifiers/settings_pending_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';

class GpxSettingsTab extends ConsumerWidget {
  const GpxSettingsTab({super.key});

  static void apply(WidgetRef ref) {
    ref.read(gpxSettingsProvider.notifier).apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gpxSettingsProvider);
    final t = AppLocalizations.of(context)!;

    void markPending() {
      ref.read(settingsPendingProvider.notifier).mark();
      ref.read(gpxPendingProvider.notifier).mark();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(backgroundColor: AppColors.primary, title: Text(t.gpxTab)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
            child: Text(
              t.gpxIncludeExtraData,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),

          _buildCustomSwitch(
            context,
            ref,
            settings.accuracies,
            "accuracies",
            t.gpxAccuracyPerPoint,
            Icons.gps_fixed,
            markPending,
          ),
          const SizedBox(height: 12),

          _buildCustomSwitch(
            context,
            ref,
            settings.speeds,
            "speeds",
            t.gpxSpeed,
            Icons.speed,
            markPending,
          ),
          const SizedBox(height: 12),

          _buildCustomSwitch(
            context,
            ref,
            settings.headings,
            "headings",
            t.gpxHeading,
            Icons.explore_outlined,
            markPending,
          ),
          const SizedBox(height: 12),

          _buildCustomSwitch(
            context,
            ref,
            settings.satellites,
            "satellites",
            t.gpxSatellites,
            Icons.satellite_alt,
            markPending,
          ),
          const SizedBox(height: 12),

          _buildCustomSwitch(
            context,
            ref,
            settings.vAccuracies,
            "vAccuracies",
            t.gpxVerticalAccuracy,
            Icons.height,
            markPending,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCustomSwitch(
    BuildContext context,
    WidgetRef ref,
    bool value,
    String field,
    String title,
    IconData icon,
    VoidCallback markPending,
  ) {
    final t = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
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
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(gpxSettingsProvider.notifier).toggle(field, !value);
          markPending();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Icon(
                icon,
                color: value ? AppColors.primary : Colors.grey,
                size: 24,
              ),
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
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value ? t.switchOn : t.switchOff,
                  style: const TextStyle(
                    fontSize: 12,
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
