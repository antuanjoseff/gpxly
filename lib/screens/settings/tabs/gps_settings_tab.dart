import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/gps_settings_notifier.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/custom_settings_card.dart';

class GpsSettingsTab extends ConsumerWidget {
  const GpsSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gps = ref.watch(gpsSettingsProvider);
    final isFollowing = gps.isFollowing;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.gpsTab, style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoBanner(t.gpsAutoConfigInfo),
          const SizedBox(height: 8),
          const SectionTitle("Mètode de registre"),

          // --- BLOC TEMPS ---
          SettingsCard(
            // Es pot moure si no seguim un track
            isActive: !isFollowing,
            // Es veu blau si no seguim i és el mètode seleccionat
            isStyleActive: !isFollowing && gps.useTime,
            title: t.gpsRecordByTime,
            valueText: "${gps.seconds} s",
            value: gps.seconds.toDouble(),
            min: 2,
            max: 60,
            divisions: 58,
            onChanged: (val) {
              ref.read(gpsSettingsProvider.notifier).setSeconds(val.toInt());
              ref.read(gpsSettingsProvider.notifier).setUseTime(true);
            },
          ),

          const SizedBox(height: 16),

          // --- BLOC DISTÀNCIA ---
          SettingsCard(
            // Es pot moure si no seguim un track
            isActive: !isFollowing,
            // Es veu blau si no seguim i NO és mode temps
            isStyleActive: !isFollowing && !gps.useTime,
            title: t.gpsRecordByDistance,
            valueText: "${gps.meters.toInt()} m",
            value: gps.meters.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (val) {
              ref.read(gpsSettingsProvider.notifier).setMeters(val);
              ref.read(gpsSettingsProvider.notifier).setUseTime(false);
            },
          ),

          const SizedBox(height: 8),
          const SectionTitle("Qualitat del senyal"),

          SettingsCard(
            isActive: !isFollowing,
            isStyleActive: !isFollowing, // Sempre blau si no seguim
            title: t.gpsMaxAccuracy,
            valueText: "${gps.accuracy.toInt()} m",
            value: gps.accuracy,
            min: 5,
            max: 100,
            divisions: 19,
            onChanged: (val) {
              ref.read(gpsSettingsProvider.notifier).setAccuracy(val);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16), // Unificat a 16 com les cards
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
