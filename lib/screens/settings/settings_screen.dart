import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/notifiers/settings_pending_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';

import 'tabs/gps_settings_tab.dart';
import 'tabs/gpx_settings_tab.dart';
import 'tabs/track_settings_tab.dart';
import 'tabs/imported_track_settings_tab.dart';

import 'package:gpxly/notifiers/gps_settings_notifier.dart';
import 'package:gpxly/notifiers/gpx_settings_provider.dart';
import 'package:gpxly/notifiers/track_settings_notifier.dart';
import 'package:gpxly/notifiers/imported_track_settings_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final hasPending = ref.watch(settingsPendingProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (!hasPending) {
          Navigator.of(context).pop();
          return;
        }

        final apply = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t.pendingChangesTitle),
            content: Text(t.pendingChangesMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.discard),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(t.apply),
              ),
            ],
          ),
        );

        if (apply == true) {
          await _applyAll(ref);
          Navigator.of(context).pop();
        } else if (apply == false) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
              AspectRatio(
                aspectRatio: 1,
                child: _SettingsTile(
                  icon: Icons.gps_fixed,
                  label: t.gpsTab,
                  hasPending: ref.watch(gpsPendingProvider),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GpsSettingsTab()),
                    );
                  },
                ),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: _SettingsTile(
                  icon: Icons.map,
                  label: t.gpxTab,
                  hasPending: ref.watch(gpxPendingProvider),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GpxSettingsTab()),
                    );
                  },
                ),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: _SettingsTile(
                  icon: Icons.timeline,
                  label: t.trackTab,
                  hasPending: ref.watch(trackPendingProvider),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrackSettingsTab(),
                      ),
                    );
                  },
                ),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: _SettingsTile(
                  icon: Icons.route,
                  label: t.importedTrack,
                  hasPending: ref.watch(importedTrackPendingProvider),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ImportedTrackSettingsTab(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 16, 16, 70),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: hasPending
                  ? () async {
                      await _applyAll(ref);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.settingsApplied)),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPending
                    ? AppColors.primary
                    : AppColors.primary.withAlpha(90),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                disabledBackgroundColor: AppColors.primary.withAlpha(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                t.apply,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyAll(WidgetRef ref) async {
    await ref.read(gpsSettingsProvider.notifier).apply();
    ref.read(gpxSettingsProvider.notifier).apply();
    ref.read(trackSettingsProvider.notifier).apply();
    ref.read(importedTrackSettingsProvider.notifier).apply();

    ref.read(settingsPendingProvider.notifier).clear();
    ref.read(gpsPendingProvider.notifier).clear();
    ref.read(gpxPendingProvider.notifier).clear();
    ref.read(trackPendingProvider.notifier).clear();
    ref.read(importedTrackPendingProvider.notifier).clear();
  }
}

class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasPending;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.hasPending,
    required this.onTap,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => scale = 0.96),
        onTapUp: (_) => setState(() => scale = 1.0),
        onTapCancel: () => setState(() => scale = 1.0),
        onTap: widget.onTap,
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 2,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 40, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        widget.label,
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

              if (widget.hasPending)
                Positioned(
                  top: 12,
                  right: 12,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    onEnd: () => setState(() {}),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
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
