import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/gpx_settings_provider.dart';
import 'package:gpxly/theme/app_colors.dart';

class GpxSettingsTab extends ConsumerWidget {
  final VoidCallback onPending;
  final VoidCallback onApplied;

  const GpxSettingsTab({
    super.key,
    required this.onPending,
    required this.onApplied,
  });

  static void apply(WidgetRef ref) {
    ref.read(gpxSettingsProvider.notifier).apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gpxSettingsProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F7,
      ), // Mateix fons gris de les altres tabs
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Títol de secció opcional per donar context
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12, top: 8),
            child: Text(
              "Incloure dades extres al fitxer GPX",
              style: TextStyle(
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
            "Accuracy per punt",
            Icons.gps_fixed,
          ),
          const SizedBox(height: 12),

          _buildCustomSwitch(
            context,
            ref,
            settings.speeds,
            "speeds",
            "Velocitat",
            Icons.speed,
          ),
          const SizedBox(height: 12),

          _buildCustomSwitch(
            context,
            ref,
            settings.headings,
            "headings",
            "Heading (Rumb)",
            Icons.explore_outlined,
          ),
          const SizedBox(height: 12),

          _buildCustomSwitch(
            context,
            ref,
            settings.satellites,
            "satellites",
            "Satèl·lits",
            Icons.satellite_alt,
          ),
          const SizedBox(height: 12),

          _buildCustomSwitch(
            context,
            ref,
            settings.vAccuracies,
            "vAccuracies",
            "Vertical accuracy",
            Icons.height,
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
  ) {
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
          onPending();
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
              // --- CÀPSULA BLAVA SÒLIDA AMB TEXT BLANC ---
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
                  value ? "ON" : "OFF",
                  style: TextStyle(
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
