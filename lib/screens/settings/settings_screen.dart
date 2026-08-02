// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/alarm_settings_notifier.dart';
import 'package:strack_rec/notifiers/barometer_settings_notifier.dart';
import 'package:strack_rec/notifiers/navigation_notifier.dart';
import 'package:strack_rec/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:strack_rec/screens/settings/tabs/barometer_settings_tab.dart';
import 'package:strack_rec/screens/settings/tabs/gps_settings_tab.dart';
import 'package:strack_rec/screens/settings/tabs/gpx_settings_tab.dart';
import 'package:strack_rec/screens/settings/tabs/imported_track_settings_tab.dart';
import 'package:strack_rec/screens/settings/tabs/track_settings_tab.dart';
import 'package:strack_rec/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    // Escoltant els estats per bloquejar el GPS si cal
    final alarms = ref.watch(alarmSettingsProvider);

    // ✅ ADAPTAT: Llegim amb '.select' només la variable que ens interessa per evitar redibuixats inútils
    final isTrackActive = ref.watch(
      navigationProvider.select((n) => n.isFollowing),
    );

    final isAlarmActive =
        alarms.distanceEnabled ||
        alarms.accEnabled ||
        alarms.cotaEnabled ||
        alarms.timeEnabled;

    final gpsLocked = isAlarmActive || isTrackActive;

    final baro = ref.watch(barometerSettingsProvider);
    final hasBarometer = baro.hasBarometer;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(t.settings),
        toolbarHeight: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _SettingsTile(
              icon: Icons.gps_fixed,
              label: t.gpsTab,
              enabled: !gpsLocked,
              isAlarmActive: isAlarmActive,
              isTrackActive: isTrackActive,
              t: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GpsSettingsTab()),
              ),
            ),
            _SettingsTile(
              icon: Icons.map,
              label: t.gpxTab,
              t: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GpxSettingsTab()),
              ),
            ),
            _SettingsTile(
              icon: Icons.timeline,
              label: t.trackTab,
              t: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrackSettingsTab()),
              ),
            ),
            _SettingsTile(
              icon: Icons.route,
              label: t.importedTrack,
              t: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImportedTrackSettingsTab(),
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.alarm,
              label: t.alarms,
              t: t,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlarmSettingsTab()),
              ),
            ),
            _SettingsTile(
              label: t.demManagerTitle,
              t: t,
              enabled: hasBarometer,
              // 🟢 SUPERPOSICIÓ COMPLEMENTÀRIA: Creem un bloc de mapa + graella
              customIcon: SizedBox(
                width: 42,
                height: 42,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Icon(
                        Icons.landscape_outlined,
                        size: 34,
                        color: hasBarometer
                            ? AppColors.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(1.5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.grid_on_rounded,
                          size: 18,
                          color: hasBarometer
                              ? AppColors.skyBlue
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              onTap: () {
                if (!hasBarometer) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BarometerSettingsTab(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon; // 🔄 Modificat: Ara accepta nuls
  final Widget?
  customIcon; // 🟢 Nou paràmetre opcional per a qualsevol Widget (com un Stack)
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool isAlarmActive;
  final bool isTrackActive;
  final AppLocalizations t;

  const _SettingsTile({
    this.icon, // 🔄 Passa a ser opcional (sense required)
    this.customIcon, // 🟢 Nou paràmetre opcional
    required this.label,
    required this.onTap,
    required this.t,
    this.enabled = true,
    this.isAlarmActive = false,
    this.isTrackActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorElements = enabled ? AppColors.primary : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? Colors.transparent : Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: enabled ? 2 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled
              ? onTap
              : () {
                  String message = t.gpsLockedMessage;
                  if (isTrackActive) message = t.reasonTrack;
                  if (isAlarmActive) message = t.reasonAlarm;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.orange.shade800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
          child: Stack(
            children: [
              SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🟢 CONDICIÓ DE DISSENY:
                      // Si passem un widget a customIcon, el dibuixa. Si no, utilitza l'IconData tradicional de tota la vida.
                      if (customIcon != null)
                        customIcon!
                      else
                        Icon(icon, size: 40, color: colorElements),

                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorElements,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!enabled)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTrackActive ? Icons.navigation_rounded : Icons.alarm,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.lock, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
