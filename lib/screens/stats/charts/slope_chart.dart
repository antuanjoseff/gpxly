import 'package:flutter/material.dart';
import 'package:senda/models/track.dart';
import 'package:senda/theme/app_colors.dart';

class SlopeChart extends StatelessWidget {
  final Track? real;
  final Track? imported;

  const SlopeChart({super.key, this.real, this.imported});

  @override
  Widget build(BuildContext context) {
    final hasReal = real != null && real!.distances.length > 1;
    final hasImported = imported != null && imported!.distances.length > 1;

    if (!hasReal && !hasImported) {
      return const Center(
        child: Text(
          "Sense dades de pendent",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return CustomPaint(
      painter: _SlopePainter(real: real, imported: imported),
      size: const Size(double.infinity, 160),
    );
  }
}

class _SlopePainter extends CustomPainter {
  final Track? real;
  final Track? imported;

  _SlopePainter({this.real, this.imported});

  // --- CALCULA PENDENTS AMB ALTITUD + DISTÀNCIA ---
  List<double> computeSlopes(Track t) {
    final slopes = <double>[];

    for (int i = 1; i < t.distances.length; i++) {
      final dDist = t.distances[i] - t.distances[i - 1];
      final dAlt = t.altitudes[i] - t.altitudes[i - 1];

      if (dDist > 0) {
        slopes.add((dAlt / dDist) * 100); // pendent %
      } else {
        slopes.add(0.0);
      }
    }

    return [0.0, ...slopes];
  }

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

    // --- PREPAREM TRACKS ---
    final tracks = <(Track, List<double>)>[];

    if (real != null && real!.distances.length > 1) {
      tracks.add((real!, computeSlopes(real!)));
    }

    if (imported != null && imported!.distances.length > 1) {
      tracks.add((imported!, computeSlopes(imported!)));
    }

    if (tracks.isEmpty) return;

    // --- DISTÀNCIA MÀXIMA ---
    final maxDist = tracks
        .map((t) => t.$1.distances.last)
        .fold(0.0, (a, b) => a > b ? a : b);

    if (maxDist == 0) return;

    // --- PENDENT MIN/MAX ---
    final allSlopes = tracks.expand((t) => t.$2).toList();
    final minSlope = allSlopes.reduce((a, b) => a < b ? a : b);
    final maxSlope = allSlopes.reduce((a, b) => a > b ? a : b);
    final slopeRange = (maxSlope - minSlope).abs();

    double x(double dist) => (dist / maxDist) * size.width;

    double y(double slope) {
      if (slopeRange == 0) return size.height * 0.5;
      return size.height - ((slope - minSlope) / slopeRange) * size.height;
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
      Offset(0, y(maxSlope)),
      Offset(size.width, y(maxSlope)),
      gridPaint,
    );

    // línia inferior
    canvas.drawLine(
      Offset(0, y(minSlope)),
      Offset(size.width, y(minSlope)),
      gridPaint,
    );

    // text max
    textPainter.text = TextSpan(
      text: "${maxSlope.toStringAsFixed(1)} %",
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, y(maxSlope) - 12));

    // text min
    textPainter.text = TextSpan(
      text: "${minSlope.toStringAsFixed(1)} %",
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, y(minSlope) - 12));

    // --- DIBUIXAR TRACK ---
    void drawTrack(Track t, List<double> slopes, Paint p) {
      final path = Path()..moveTo(x(t.distances.first), y(slopes.first));

      for (int i = 1; i < slopes.length; i++) {
        path.lineTo(x(t.distances[i]), y(slopes[i]));
      }

      canvas.drawPath(path, p);
    }

    for (final (track, slopes) in tracks) {
      drawTrack(track, slopes, track == real ? paintReal : paintImported);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
