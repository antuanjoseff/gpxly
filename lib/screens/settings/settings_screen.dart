import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/alarm_settings_notifier.dart';
import 'package:senda/notifiers/track_follow_notifier.dart';
import 'package:senda/screens/settings/tabs/alarm_settings_tab.dart';
import 'package:senda/screens/settings/tabs/barometer_settings_tab.dart';
import 'package:senda/screens/settings/tabs/gps_settings_tab.dart';
import 'package:senda/screens/settings/tabs/gpx_settings_tab.dart';
import 'package:senda/screens/settings/tabs/imported_track_settings_tab.dart';
import 'package:senda/screens/settings/tabs/track_settings_tab.dart';
import 'package:senda/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    // Escoltant els estats per bloquejar el GPS si cal
    final alarms = ref.watch(alarmSettingsProvider);
    final followingTrack = ref.watch(trackFollowNotifierProvider);

    final isAlarmActive =
        alarms.distanceEnabled || alarms.altitudeEnabled || alarms.timeEnabled;
    final isTrackActive = followingTrack.isFollowing;
    final gpsLocked = isAlarmActive || isTrackActive;

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
              icon: Icons
                  .device_thermostat_rounded, // Icona que suggereix relleu/alçada
              label: t.barometerTitle,
              t: t,
              onTap: () {
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
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool isAlarmActive;
  final bool isTrackActive;
  final AppLocalizations t;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.t,
    this.enabled = true,
    this.isAlarmActive = false,
    this.isTrackActive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Definim el color dels elements (icona i text) segons l'estat
    final colorElements = enabled ? AppColors.primary : Colors.grey.shade400;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Blanc pur
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled ? Colors.transparent : Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.white, // Forçat blanc també al Material
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 40, color: colorElements),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorElements,
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
