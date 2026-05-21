import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/imported_track_settings_notifier.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/custom_settings_card.dart';

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

          // --- TARJETA DE COLOR PERSONALIZADA (SIN SLIDER) ---
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
                    // Círculo de color actual
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
                // Línea de previsualización
                CustomPaint(
                  size: const Size(double.infinity, 20),
                  painter: _TrackPreviewPainter(
                    color: settings.color,
                    strokeWidth: 6,
                  ),
                ),
                const SizedBox(height: 20),
                // Botón ajustado al ancho de la tarjeta
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
                    onPressed: () =>
                        _openColorPicker(context, ref, settings.color),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          SectionTitle(t.trackWidth),

          // --- SECCIÓN ANCHO (MANTIENE SETTINGSCARD PORQUE AQUÍ SÍ HAY SLIDER) ---
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
                    painter: _TrackPreviewPainter(
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

  void _openColorPicker(
    BuildContext context,
    WidgetRef ref,
    Color currentColor,
  ) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.pickColor),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (c) {
              ref.read(importedTrackSettingsProvider.notifier).setColor(c);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}

// Mantenemos el Painter para dibujar la línea
class _TrackPreviewPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  _TrackPreviewPainter({required this.color, required this.strokeWidth});

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
  bool shouldRepaint(covariant _TrackPreviewPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
