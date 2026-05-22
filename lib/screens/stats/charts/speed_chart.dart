import 'package:flutter/material.dart';
import 'package:senda/models/track.dart';
import 'package:senda/theme/app_colors.dart';

class SpeedChart extends StatelessWidget {
  final Track? real;
  final Track? imported;

  const SpeedChart({super.key, this.real, this.imported});

  @override
  Widget build(BuildContext context) {
    final hasReal = real != null && real!.distances.length > 1;
    final hasImported = imported != null && imported!.distances.length > 1;

    if (!hasReal && !hasImported) {
      return const Center(
        child: Text(
          "Sense dades de velocitat",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return CustomPaint(
      painter: _SpeedPainter(real: real, imported: imported),
      size: const Size(double.infinity, 160),
    );
  }
}

class _SpeedPainter extends CustomPainter {
  final Track? real;
  final Track? imported;

  _SpeedPainter({this.real, this.imported});

  List<double> computeSpeeds(Track t) {
    final speeds = <double>[];

    for (int i = 1; i < t.distances.length; i++) {
      final dDist = t.distances[i] - t.distances[i - 1];
      final dTime = t.timestamps[i].difference(t.timestamps[i - 1]).inSeconds;

      if (dTime > 0 && dDist >= 0) {
        speeds.add((dDist / dTime) * 3.6);
      } else {
        speeds.add(0.0);
      }
    }

    return [0.0, ...speeds];
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

    final tracks = <(Track, List<double>)>[];

    if (real != null && real!.distances.length > 1) {
      tracks.add((real!, computeSpeeds(real!)));
    }

    if (imported != null && imported!.distances.length > 1) {
      tracks.add((imported!, computeSpeeds(imported!)));
    }

    if (tracks.isEmpty) return;

    final maxDist = tracks
        .map((t) => t.$1.distances.last)
        .fold(0.0, (a, b) => a > b ? a : b);

    if (maxDist == 0) return;

    final allSpeeds = tracks.expand((t) => t.$2).toList();
    final minSpeed = allSpeeds.reduce((a, b) => a < b ? a : b);
    final maxSpeed = allSpeeds.reduce((a, b) => a > b ? a : b);
    final speedRange = (maxSpeed - minSpeed).abs();

    double x(double dist) => (dist / maxDist) * size.width;

    double y(double speed) {
      if (speedRange == 0) return size.height * 0.5;
      return size.height - ((speed - minSpeed) / speedRange) * size.height;
    }

    // --- GRID LINES ---
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    // línia superior
    canvas.drawLine(
      Offset(0, y(maxSpeed)),
      Offset(size.width, y(maxSpeed)),
      gridPaint,
    );

    // línia inferior
    canvas.drawLine(
      Offset(0, y(minSpeed)),
      Offset(size.width, y(minSpeed)),
      gridPaint,
    );

    // text max
    textPainter.text = TextSpan(
      text: "${maxSpeed.toStringAsFixed(1)} km/h",
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, y(maxSpeed) - 12));

    // text min
    textPainter.text = TextSpan(
      text: "${minSpeed.toStringAsFixed(1)} km/h",
      style: const TextStyle(fontSize: 10, color: Colors.grey),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(0, y(minSpeed) - 12));

    // --- DRAW TRACKS ---
    void drawTrack(Track t, List<double> speeds, Paint p) {
      final path = Path()..moveTo(x(t.distances.first), y(speeds.first));

      for (int i = 1; i < speeds.length; i++) {
        path.lineTo(x(t.distances[i]), y(speeds[i]));
      }

      canvas.drawPath(path, p);
    }

    for (final (track, speeds) in tracks) {
      drawTrack(track, speeds, track == real ? paintReal : paintImported);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
