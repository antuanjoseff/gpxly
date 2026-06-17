// lib/widgets/map_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/gps_accuracy_bars.dart';
import 'package:senda/l10n/app_localizations.dart'; // 🟢 Import de traduccions nates

class MapAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final double? pressure;
  final bool isRunning;
  final bool isPaused;

  const MapAppBar({
    super.key,
    required this.pressure,
    required this.isRunning,
    required this.isPaused,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!; // 🟢 Inicialització del diccionari

    // 📡 Escuita reactiva de les alarmes de seguretat actives
    final alarms = ref.watch(alarmSettingsProvider);
    final anyAlarmActive =
        alarms.distanceEnabled ||
        alarms.accEnabled ||
        alarms.cotaEnabled ||
        alarms.timeEnabled;

    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 16,

      leading: const GpsAccuracyBars(),

      centerTitle: true,

      title: Consumer(
        builder: (context, ref, child) {
          // 📡 1. Llegim l'estat del GPS i dels permisos/serveis simultàniament
          final userPos = ref.watch(locationProvider);
          final permissions = ref.watch(permissionsProvider);

          // 🟢 2. LA TEVA LOGICA D'ESTAT REAL UNIFICADA:
          final bool isGpsDisabled =
              !permissions.hasPermission ||
              !permissions.serviceEnabled ||
              userPos == null;

          final double? altitude = userPos?.altitude;
          final bool isFixed = userPos?.isHgtFixed ?? false;

          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🗺️ A) El Nom de l'aplicació
              const Text(
                "SENDA",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),

              // Un petit separador estètic vertical
              Container(
                height: 16,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white24,
              ),

              // 🏔️ B) El mòdul d'Altimetria integrat en línia i unificat
              Icon(
                isGpsDisabled
                    ? Icons.location_off_rounded
                    : Icons.filter_hdr_rounded,
                color: isGpsDisabled
                    ? Colors.redAccent.shade100
                    : (isFixed ? Colors.white : AppColors.redAlert),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isGpsDisabled
                    ? t.gpsDisabledTitle
                    : (altitude != null
                          ? "${altitude.toStringAsFixed(0)} m"
                          : "--- m"),
                style: TextStyle(
                  color: isGpsDisabled
                      ? Colors.redAccent.shade100
                      : Colors.white,
                  fontSize: isGpsDisabled
                      ? 12
                      : 14, // Un puntet més petit en cas de text de bloqueig llarg
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),

      actions: [
        // 🟢 NOU EMPLAÇAMENT: La campana de notificació es mou neta i blanca a la dreta
        if (anyAlarmActive)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlarmSettingsTab()),
                );
              },
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

        // 🛰️ Botó de control del simulador de rutes del track
        if (ref.watch(importedTrackProvider) != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                final notifier = ref.read(locationProvider.notifier);
                if (!isRunning) {
                  final importedData = ref.read(importedTrackProvider);
                  notifier.simulateImportedTrack(importedData);
                } else {
                  notifier.toggleSimulationPause();
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isRunning
                      ? (isPaused ? Colors.blue : Colors.orange)
                      : Colors.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  !isRunning
                      ? Icons.play_arrow
                      : (isPaused ? Icons.play_arrow : Icons.pause),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}
