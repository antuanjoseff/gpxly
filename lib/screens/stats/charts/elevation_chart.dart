import 'package:flutter/material.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/theme/app_colors.dart';

class ElevationChart extends StatefulWidget {
  final Track? real;
  final Track? imported;

  const ElevationChart({super.key, this.real, this.imported});

  @override
  State<ElevationChart> createState() => _ElevationChartState();
}

class _ElevationChartState extends State<ElevationChart> {
  final ValueNotifier<double?> needleXNotifier = ValueNotifier<double?>(null);

  @override
  Widget build(BuildContext context) {
    final hasReal = widget.real != null && widget.real!.distances.length > 1;
    final hasImported =
        widget.imported != null && widget.imported!.distances.length > 1;

    if (!hasReal && !hasImported) {
      return const Center(
        child: Text(
          "Sense dades d'elevació",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const totalH = 240.0;
        const chartH = 150.0;

        return SizedBox(
          width: width,
          height: totalH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) =>
                needleXNotifier.value = d.localPosition.dx,
            onTapDown: (d) => needleXNotifier.value = d.localPosition.dx,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. CAPA ESTÀTICA (Perfil)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  height: chartH,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(width, chartH),
                      painter: _ElevationBackgroundPainter(
                        real: widget.real,
                        imported: widget.imported,
                      ),
                    ),
                  ),
                ),
                // 2. CAPA DINÀMICA (Interacció)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  height: chartH,
                  child: ValueListenableBuilder<double?>(
                    valueListenable: needleXNotifier,
                    builder: (context, val, _) {
                      return CustomPaint(
                        size: Size(width, chartH),
                        painter: _ElevationInteractivePainter(
                          needleX: val,
                          real: widget.real,
                          imported: widget.imported,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ElevationBackgroundPainter extends CustomPainter {
  final Track? real;
  final Track? imported;

  _ElevationBackgroundPainter({this.real, this.imported});

  @override
  void paint(Canvas canvas, Size size) {
    final tracks = [if (real != null) real!, if (imported != null) imported!];
    final allAlts = tracks.expand((t) => t.altitudes).toList();
    if (allAlts.isEmpty) return;

    final maxD = _getMaxDist();
    final minA = allAlts.reduce((a, b) => a < b ? a : b);
    final maxA = allAlts.reduce((a, b) => a > b ? a : b);
    final rangeA = (maxA - minA).abs() == 0 ? 1.0 : (maxA - minA).abs();

    double x(double d) => (d / maxD) * size.width;
    double y(double a) => size.height - ((a - minA) / rangeA) * size.height;

    final pGrid = Paint()
      ..color = Colors.grey.withAlpha(40)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y(maxA)), Offset(size.width, y(maxA)), pGrid);
    canvas.drawLine(Offset(0, y(minA)), Offset(size.width, y(minA)), pGrid);

    void draw(Track t, Color c) {
      if (t.distances.isEmpty) return;
      final path = Path()..moveTo(x(t.distances.first), y(t.altitudes.first));
      for (int i = 1; i < t.distances.length; i++) {
        path.lineTo(x(t.distances[i]), y(t.altitudes[i]));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = c
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    if (imported != null) draw(imported!, AppColors.trackGreen.withAlpha(100));
    if (real != null) draw(real!, AppColors.redAlert);
  }

  double _getMaxDist() {
    double d = real?.distances.isNotEmpty == true ? real!.distances.last : 0;
    if (imported?.distances.isNotEmpty == true &&
        imported!.distances.last > d) {
      d = imported!.distances.last;
    }
    return d == 0 ? 1 : d;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _ElevationInteractivePainter extends CustomPainter {
  final double? needleX;
  final Track? real;
  final Track? imported;

  _ElevationInteractivePainter({this.needleX, this.real, this.imported});

  @override
  void paint(Canvas canvas, Size size) {
    final tracks = [if (real != null) real!, if (imported != null) imported!];
    final allAlts = tracks.expand((t) => t.altitudes).toList();
    if (allAlts.isEmpty) return;

    final minA = allAlts.reduce((a, b) => a < b ? a : b);
    final maxA = allAlts.reduce((a, b) => a > b ? a : b);
    final rangeA = (maxA - minA).abs() == 0 ? 1.0 : (maxA - minA).abs();
    double getY(double a) => size.height - ((a - minA) / rangeA) * size.height;

    _drawL(canvas, "${maxA.toStringAsFixed(0)} m", -15, size.width);
    _drawL(canvas, "${minA.toStringAsFixed(0)} m", size.height + 5, size.width);

    if (needleX == null) return;
    final xPos = needleX!.clamp(0.0, size.width);
    final currentDist = (xPos / size.width) * _getMaxDist();

    canvas.drawLine(
      Offset(xPos, -25),
      Offset(xPos, size.height + 15),
      Paint()..color = Colors.black12,
    );

    double? rVal, iVal;
    if (real != null && real!.altitudes.isNotEmpty) {
      rVal = _findValue(real!, currentDist);
      _drawPoint(canvas, xPos, getY(rVal), AppColors.redAlert);
    }
    if (imported != null && imported!.altitudes.isNotEmpty) {
      iVal = _findValue(imported!, currentDist);
      _drawPoint(canvas, xPos, getY(iVal), AppColors.trackGreen);
    }

    _drawUnifiedTooltip(canvas, size, xPos, rVal, iVal);
  }

  void _drawPoint(Canvas canvas, double x, double y, Color color) {
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
    canvas.drawCircle(
      Offset(x, y),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawUnifiedTooltip(
    Canvas canvas,
    Size size,
    double x,
    double? r,
    double? i,
  ) {
    final spans = <TextSpan>[
      if (r != null)
        TextSpan(
          text: "REAL: ${r.toStringAsFixed(0)}m",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      if (r != null && i != null)
        const TextSpan(
          text: "  |  ",
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      if (i != null)
        TextSpan(
          text: "IMP: ${i.toStringAsFixed(0)}m",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
    ];

    if (spans.isEmpty) return;
    final tp = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    )..layout();
    final rw = tp.width + 16;
    final tx = (x - rw / 2).clamp(0.0, size.width - rw);

    canvas.drawRRect(
      RRect.fromLTRBR(
        tx,
        -52,
        tx + rw,
        -52 + tp.height + 10,
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.primary,
    );
    tp.paint(canvas, Offset(tx + 8, -47));
  }

  double _getMaxDist() {
    double d = real?.distances.isNotEmpty == true ? real!.distances.last : 0;
    if (imported?.distances.isNotEmpty == true &&
        imported!.distances.last > d) {
      d = imported!.distances.last;
    }
    return d == 0 ? 1 : d;
  }

  double _findValue(Track t, double d) {
    for (int i = 0; i < t.distances.length; i++) {
      if (t.distances[i] >= d) return t.altitudes[i];
    }
    return t.altitudes.isNotEmpty ? t.altitudes.last : 0.0;
  }

  void _drawL(Canvas canvas, String txt, double y, double w) {
    final tp = TextPainter(
      text: TextSpan(
        text: txt,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w - tp.width, y));
  }

  @override
  bool shouldRepaint(_ElevationInteractivePainter old) =>
      old.needleX != needleX;
}
