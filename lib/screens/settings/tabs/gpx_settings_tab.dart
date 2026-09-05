// lib/screens/settings/tabs/gpx_settings_tab.dart (Bloc 1 de 2)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/gpx_settings_notifier.dart';
import 'package:strack_rec/notifiers/recording_notifier.dart';
import 'package:strack_rec/theme/app_colors.dart';

class GpxSettingsTab extends ConsumerWidget {
  const GpxSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gpxSettingsProvider);
    final hasTrackPoints = ref.watch(
      trackRecordingProvider.select((track) => track.points.isNotEmpty),
    );
    final t = AppLocalizations.of(context)!;

    // Lògica de comprovació per saber si estan tots seleccionats
    final bool isAllSelected =
        settings.accuracies &&
        settings.speeds &&
        settings.headings &&
        settings.satellites &&
        settings.vAccuracies;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
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
          _buildInfoBanner(t.gpxIncludeExtraData),
          const SizedBox(height: 20),

          // --- 🎯 CAPÇALERA INTEGRADA DE BAIXA VISIBILITAT ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // El botó minimalista de selecció global
              _buildMinimalAllSelector(
                context: context,
                ref: ref,
                isAllSelected: isAllSelected,
              ),
            ],
          ),
          const SizedBox(height: 10),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.accuracies,
            field: "accuracies",
            title: t.gpxAccuracyPerPoint,
            icon: Icons.gps_fixed_rounded,
          ),
          const SizedBox(height: 12),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.speeds,
            field: "speeds",
            title: t.gpxSpeed,
            icon: Icons.speed_rounded,
          ),
          const SizedBox(height: 12),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.headings,
            field: "headings",
            title: t.gpxHeading,
            icon: Icons.explore_rounded,
          ),
          const SizedBox(height: 12),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.satellites,
            field: "satellites",
            title: t.gpxSatellites,
            icon: Icons.satellite_alt_rounded,
          ),
          const SizedBox(height: 12),

          _buildGpxSwitchCard(
            ref: ref,
            value: settings.vAccuracies,
            field: "vAccuracies",
            title: t.gpxVerticalAccuracy,
            icon: Icons.height_rounded,
          ),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: hasTrackPoints
                ? () async {
                    await ref
                        .read(trackRecordingProvider.notifier)
                        .saveToCache();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(t.gpxTrackSaved)));
                  }
                : null,
            icon: const Icon(Icons.save_outlined),
            label: Text(t.gpxSaveTrack),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
  // lib/screens/settings/tabs/gpx_settings_tab.dart (Bloc 2 de 2)

  // 🎯 SELECTOR MINIMALISTA: Integrat amb un TextButton net i discret al costat de la secció
  Widget _buildMinimalAllSelector({
    required BuildContext context,
    required WidgetRef ref,
    required bool isAllSelected,
  }) {
    final t = AppLocalizations.of(context)!;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        HapticFeedback.lightImpact();
        // Canvi massiu de tots els estats al contrari actual
        final bool targetValue = !isAllSelected;
        final notifier = ref.read(gpxSettingsProvider.notifier);
        notifier.toggle("accuracies", targetValue);
        notifier.toggle("speeds", targetValue);
        notifier.toggle("headings", targetValue);
        notifier.toggle("satellites", targetValue);
        notifier.toggle("vAccuracies", targetValue);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAllSelected ? t.gpxDeselectAll : t.gpxSelectAll,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isAllSelected ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isAllSelected
                  ? Icons.check_circle_outline_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isAllSelected ? AppColors.primary : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  // Targeta amb disseny unificat i Switch mecànic ON/OFF de fons interactiu
  Widget _buildGpxSwitchCard({
    required WidgetRef ref,
    required bool value,
    required String field,
    required String title,
    required IconData icon,
  }) {
    final Color currentColor = value ? AppColors.primary : Colors.grey.shade600;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppColors.primary.withAlpha(50) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(gpxSettingsProvider.notifier).toggle(field, !value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: currentColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: value ? AppColors.primary : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 🎛️ Switcher mecànic ON/OFF clonat de les alarmes
              IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 58,
                  height: 28,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: value
                        ? AppColors.primary.withAlpha(40)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: value ? AppColors.primary : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 6,
                        child: Text(
                          "ON",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: value
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        child: Text(
                          "OFF",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: !value
                                ? Colors.grey.shade600
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: value
                                ? AppColors.primary
                                : Colors.grey.shade500,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
