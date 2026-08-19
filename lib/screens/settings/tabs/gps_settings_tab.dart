import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/gps_debug_notifier.dart';
import 'package:strack_rec/notifiers/gps_settings_notifier.dart';
import 'package:strack_rec/services/altitude_logger.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/widgets/custom_settings_card.dart';

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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // ✅ Asegura icono volver blanco
        title: Text(
          t.gpsTab,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🎯 TEXT EXPLICATIU REFACTORITZAT A L'ESTIL CORPORATIU DE STrack Rec
          _buildInfoBanner(t.gpsAutoConfigInfo),
          const SizedBox(
            height: 16,
          ), // ✅ Incrementado a 16 para mejor aireado visual
          const SectionTitle("Mètode de registre"),

          // --- BLOC TEMPS ---
          SettingsCard(
            isActive: !isFollowing,
            isStyleActive: !isFollowing && gps.useTime,
            title: t.gpsRecordByTime,
            valueText: "${gps.seconds} s",
            value: gps.seconds.toDouble(),
            min: 2,
            max: 60,
            divisions: 58,
            onChanged: (val) {
              // 🔴 Mentres arrossega el dit: canvia el text a la UI a cada mil·lisegon suau
              ref.read(gpsSettingsProvider.notifier).setSeconds(val.toInt());
              ref.read(gpsSettingsProvider.notifier).setUseTime(true);
            },
            onChangeEnd: (val) {
              // 🎯 En aixecar el dit: Aplica la configuració a Kotlin d'un sol cop
              ref.read(gpsSettingsProvider.notifier).apply();
            },
          ),

          const SizedBox(height: 16),

          // --- BLOC DISTÀNCIA ---
          SettingsCard(
            isActive: !isFollowing,
            isStyleActive: !isFollowing && !gps.useTime,
            title: t.gpsRecordByDistance,
            valueText: "${gps.meters.toInt()} m",
            value: gps.meters.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (val) {
              // 🔴 Mentres arrossega el dit: canvia el text a la UI a cada mil·lisegon suau
              ref.read(gpsSettingsProvider.notifier).setMeters(val);
              ref.read(gpsSettingsProvider.notifier).setUseTime(false);
            },
            onChangeEnd: (val) {
              // 🎯 En aixecar el dit: Aplica la configuració a Kotlin d'un sol cop
              ref.read(gpsSettingsProvider.notifier).apply();
            },
          ),

          const SizedBox(height: 12),
          const SectionTitle("Qualitat del senyal"),

          SettingsCard(
            isActive: !isFollowing,
            isStyleActive: !isFollowing,
            title: t.gpsMaxAccuracy,
            valueText: "${gps.accuracy.toInt()} m",
            value: gps.accuracy,
            min: 5,
            max: 100,
            divisions: 19,
            onChanged: (val) {
              // 🔴 Mentres arrossega el dit: canvia el text a la UI a cada mil·lisegon suau
              ref.read(gpsSettingsProvider.notifier).setAccuracy(val);
            },
            onChangeEnd: (val) {
              // 🎯 En aixecar el dit: Aplica la configuració a Kotlin d'un sol cop
              ref.read(gpsSettingsProvider.notifier).apply();
            },
          ),
          const SizedBox(height: 12),

          if (kDebugMode)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: SwitchListTile.adaptive(
                title: const Text(
                  "Mode diagnòstic GPS",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  "Registra telemetria detallada. Pot augmentar consum de bateria.",
                ),
                value: ref.watch(gpsDebugProvider),
                onChanged: (value) async {
                  await ref.read(gpsDebugProvider.notifier).setEnabled(value);
                  await AltitudeLoggerService().setDebugEnabled(value);
                  await ref.read(gpsSettingsProvider.notifier).apply();
                },
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 🎨 DISSENY UNIFICAT: Banner adaptat de forma estricta a l'estètica del mapa
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
