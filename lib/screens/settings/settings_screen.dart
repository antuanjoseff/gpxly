import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/screens/settings/tabs/alarm_settings_tab.dart';
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GpsSettingsTab()),
              ),
            ),
            _SettingsTile(
              icon: Icons.map,
              label: t.gpxTab,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GpxSettingsTab()),
              ),
            ),
            _SettingsTile(
              icon: Icons.timeline,
              label: t.trackTab,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrackSettingsTab()),
              ),
            ),
            _SettingsTile(
              icon: Icons.route,
              label: t.importedTrack,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImportedTrackSettingsTab(),
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.alarm,
              label: t.alarms, // afegeix-ho al teu l10n
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlarmSettingsTab()),
              ),
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

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
