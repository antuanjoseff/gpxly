import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strack_rec/l10n/app_localizations.dart';
import 'package:strack_rec/notifiers/imported_track_settings_notifier.dart';
import 'package:strack_rec/theme/app_colors.dart';
import 'package:strack_rec/widgets/colors/track_color_picker_dialog.dart';
import 'package:strack_rec/widgets/custom_settings_card.dart';
import 'package:strack_rec/screens/settings/tabs/track_settings_tab.dart';

class ImportedTrackSettingsTab extends ConsumerWidget {
  const ImportedTrackSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(importedTrackSettingsProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          t.importedTrack,
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
          SectionTitle(t.trackColor),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: settings.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.trackColor,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                CustomPaint(
                  size: const Size(double.infinity, 20),
                  painter: TrackPathPainter(
                    color: settings.color,
                    strokeWidth: 6,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.palette_outlined, size: 20),
                    label: Text(t.changeTrackColor),
                    onPressed: () async {
                      final color = await showTrackColorPickerDialog(
                        context: context,
                        initialColor: settings.color,
                      );

                      if (color != null) {
                        ref
                            .read(importedTrackSettingsProvider.notifier)
                            .setColor(color);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          SectionTitle(t.trackWidth),

          SettingsCard(
            title: t.trackWidth,
            valueText: "${settings.width.toStringAsFixed(1)} px",
            value: settings.width,
            min: 1,
            max: 10,
            divisions: 18,
            onChanged: (v) =>
                ref.read(importedTrackSettingsProvider.notifier).setWidth(v),
            extraChild: Column(
              children: [
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: TrackPathPainter(
                      color: settings.color,
                      strokeWidth: settings.width,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
