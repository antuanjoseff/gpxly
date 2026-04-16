import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gpxly/l10n/app_localizations.dart';
import 'package:gpxly/notifiers/track_settings_notifier.dart';
import 'package:gpxly/theme/app_colors.dart';

class TrackSettingsTab extends ConsumerWidget {
  final VoidCallback onPending;
  final VoidCallback onApplied;

  const TrackSettingsTab({
    super.key,
    required this.onPending,
    required this.onApplied,
  });

  static void apply(WidgetRef ref) {
    ref.read(trackSettingsProvider.notifier).apply();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(trackSettingsProvider);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- BLOC COLOR ---
            _buildSettingsCard(
              title: t.trackColor,
              rightWidget: CustomPaint(
                size: const Size(100, 16),
                painter: TrackPathPainter(
                  color: settings.color,
                  strokeWidth: 6,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.secondary),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.palette_outlined),
                      label: Text(t.changeTrackColor),
                      onPressed: () =>
                          _openColorPicker(context, ref, settings.color),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- BLOC GRUIX ---
            _buildSettingsCard(
              title: t.trackWidth,
              rightWidget: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${settings.width.toStringAsFixed(1)} px",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildSliderRow(
                    context: context,
                    value: settings.width,
                    min: 1,
                    max: 10,
                    divisions: 18,
                    onChanged: (v) {
                      ref.read(trackSettingsProvider.notifier).setWidth(v);
                      onPending();
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t.trackPreview,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required Widget rightWidget,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              rightWidget,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required BuildContext context,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final step = (max - min) / divisions;
    return Row(
      children: [
        IconButton(
          onPressed: value > min
              ? () => onChanged((value - step).clamp(min, max))
              : null,
          icon: const Icon(Icons.remove_circle_outline, size: 28),
          color: AppColors.primary,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.black12,
              trackHeight: 6,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        IconButton(
          onPressed: value < max
              ? () => onChanged((value + step).clamp(min, max))
              : null,
          icon: const Icon(Icons.add_circle_outline, size: 28),
          color: AppColors.primary,
        ),
      ],
    );
  }

  void _openColorPicker(
    BuildContext context,
    WidgetRef ref,
    Color currentColor,
  ) {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.pickColor),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (c) {
              ref.read(trackSettingsProvider.notifier).setColor(c);
              onPending();
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}

// --- PINTORES PERSONALITZATS PER SIMULAR EL CAMÍ ---
class TrackPathPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  TrackPathPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TrackPathPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
