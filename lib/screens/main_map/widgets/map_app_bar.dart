// lib/widgets/map_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/gps_debug_notifier.dart';
import 'package:senda/notifiers/location_notifier.dart';
import 'package:senda/notifiers/permissions_notifier.dart';
import 'package:senda/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:senda/screens/stats/satellites/screens/satellite_detail_screen.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/gps_accuracy_bars.dart';
import 'package:senda/l10n/app_localizations.dart'; // 🟢 Import de traduccions nates

class MapAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final double? pressure;
  final bool isRunning;
  final bool isPaused;
  final VoidCallback onShareLog;

  const MapAppBar({
    super.key,
    required this.pressure,
    required this.isRunning,
    required this.isPaused,
    required this.onShareLog,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!; // 🟢 Inicialització del diccionari

    // 📡 Escuita reactiva de les alarmes de seguretat actives
    final alarms = ref.watch(alarmSettingsProvider);
    final gpsDebugEnabled = ref.watch(gpsDebugProvider);
    final anyAlarmActive =
        alarms.distanceEnabled ||
        alarms.accEnabled ||
        alarms.cotaEnabled ||
        alarms.timeEnabled;

    return AppBar(
      backgroundColor: AppColors.primary,
      automaticallyImplyLeading: false,
      titleSpacing: 16,

      centerTitle: false,

      title: Consumer(
        builder: (context, ref, child) {
          // 📡 1. Llegim l'estat del GPS i dels permisos/serveis simultàniament
          final userPos = ref.watch(locationProvider);
          final permissions = ref.watch(permissionsProvider);

          // 🛡️ CONTROL REAL: El GPS està desactivat si manquen permisos o l'antena està apagada
          final bool isGpsDisabled =
              !permissions.hasPermission || !permissions.serviceEnabled;

          final bool isSearchingSignal = !isGpsDisabled && userPos == null;
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

              // 🏔️ B) El mòdul d'Altimetria adaptatiu estil comptador
              if (isGpsDisabled)
                // 🎯 CAS ERROR: Càpsula amb fons blanc i text vermell idèntica al teu cronòmetre
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 10.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_off_rounded,
                        color: AppColors.redAlert,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.gpsDisabledTitle.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.redAlert,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // CAS STANDARD / CERCA: Es manté integrat en línia net sobre el fons de l'AppBar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSearchingSignal
                          ? Icons.satellite_alt_rounded
                          : Icons.filter_hdr_rounded,
                      color: isSearchingSignal
                          ? Colors.white54
                          : (isFixed ? Colors.white : AppColors.redAlert),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSearchingSignal
                          ? t.gpsSearching
                          : (altitude != null
                                ? "${altitude.toStringAsFixed(0)} m"
                                : "--- m"),
                      style: TextStyle(
                        color: isSearchingSignal
                            ? Colors.white54
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),

      actions: [
        if (gpsDebugEnabled)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: onShareLog,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

        if (anyAlarmActive)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
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

        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SatelliteDetailScreen(),
                ),
              );
            },
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.satellite_alt_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),

        // GpsAccuracyBars a la dreta del tot
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: GpsAccuracyBars(),
        ),

        const SizedBox(width: 4),
      ],
    );
  }
}
