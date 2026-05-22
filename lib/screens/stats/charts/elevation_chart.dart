import 'package:flutter/material.dart';
import 'package:senda/models/track.dart';
import 'package:senda/theme/app_colors.dart';

class ElevationChart extends StatelessWidget {
  final Track? real;
  final Track? imported;

  const ElevationChart({super.key, this.real, this.imported});

  @override
  Widget build(BuildContext context) {
    final hasReal = real != null && real!.distances.length > 1;
    final hasImported = imported != null && imported!.distances.length > 1;

    if (!hasReal && !hasImported) {
      return const Center(
        child: Text(
          "Sense dades d'elevació",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return CustomPaint(
      painter: _ElevationPainter(real: real, imported: imported),
      size: const Size(double.infinity, 160),
    );
  }
}

class _ElevationPainter extends CustomPainter {
  final Track? real;
  final Track? imported;

  _ElevationPainter({this.real, this.imported});

  @override
  void paint(Canvas canvas, Size size) {
    final paintReal = Paint()
      ..color = AppColors.redAlert
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintImported = Paint()
      ..color = AppColors.trackGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // --- TRACKS ---
    final tracks = [
      if (real != null && real!.distances.length > 1) real!,
      if (imported != null && imported!.distances.length > 1) imported!,
    ];

    if (tracks.isEmpty) return;

    // --- DISTÀNCIA MÀXIMA ---
    final maxDist = tracks
        .map((t) => t.distances.last)
        .fold(0.0, (a, b) => a > b ? a : b);

    if (maxDist == 0) return;

    // --- ALTITUD MIN/MAX ---
    final allAlts = tracks.expand((t) => t.altitudes).toList();
    final minAlt = allAlts.reduce((a, b) => a < b ? a : b);
    final maxAlt = allAlts.reduce((a, b) => a > b ? a : b);
    final altRange = (maxAlt - minAlt).abs();

    double x(double dist) => (dist / maxDist) * size.width;

    double y(double alt) {
      if (altRange == 0) return size.height * 0.5;
      return size.height - ((alt - minAlt) / altRange) * size.height;
    }

    // --- GRID + TEXT ---
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    // línia superior
    canvas.drawLine(
      Offset(0, y(maxAlt)),
      Offset(size.width, y(maxAlt)),
      gridPaint,
    );

    // línia inferior
    canvas.drawLine(
      Offset(0, y(minAlt)),
      Offset(size.width, y(minAlt)),
      gridPaint,
    );

    // text max
    textPainter.text = TextSpan(
      text: "${maxAlt.toStringAsFixed(0)} m",
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, y(maxAlt) - 12));

    // text min
    textPainter.text = TextSpan(
      text: "${minAlt.toStringAsFixed(0)} m",
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, y(minAlt) - 12));

    // --- DIBUIXAR TRACK ---
    void drawTrack(Track t, Paint p) {
      final path = Path()..moveTo(x(t.distances.first), y(t.altitudes.first));

      for (int i = 1; i < t.distances.length; i++) {
        path.lineTo(x(t.distances[i]), y(t.altitudes[i]));
      }

      canvas.drawPath(path, p);
    }

    for (final t in tracks) {
      drawTrack(t, t == real ? paintReal : paintImported);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
