import 'package:flutter/material.dart';
import 'package:senda/models/track.dart';
import 'package:senda/theme/app_colors.dart';

class SpeedChart extends StatefulWidget {
  final Track? real;
  final Track? imported;

  const SpeedChart({super.key, this.real, this.imported});

  @override
  State<SpeedChart> createState() => _SpeedChartState();
}

class _SpeedChartState extends State<SpeedChart> {
  final ValueNotifier<double?> needleXNotifier = ValueNotifier<double?>(null);
  late List<double> realSpeeds;
  late List<double> importedSpeeds;

  @override
  void initState() {
    super.initState();
    _precompute();
  }

  void _precompute() {
    realSpeeds = widget.real != null ? _calcSpeeds(widget.real!) : [];
    importedSpeeds = widget.imported != null
        ? _calcSpeeds(widget.imported!)
        : [];
  }

  List<double> _calcSpeeds(Track t) {
    if (t.distances.isEmpty) return [];
    final s = <double>[0.0];
    for (int i = 1; i < t.distances.length; i++) {
      final dDist = t.distances[i] - t.distances[i - 1];
      final dTime = t.timestamps[i].difference(t.timestamps[i - 1]).inSeconds;
      s.add(dTime > 0 ? (dDist / dTime) * 3.6 : 0.0);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
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
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  height: chartH,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(width, chartH),
                      painter: _SpeedBackgroundPainter(
                        real: widget.real,
                        imported: widget.imported,
                        realSpeeds: realSpeeds,
                        importedSpeeds: importedSpeeds,
                      ),
                    ),
                  ),
                ),
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
                        painter: _SpeedInteractivePainter(
                          needleX: val,
                          real: widget.real,
                          imported: widget.imported,
                          realSpeeds: realSpeeds,
                          importedSpeeds: importedSpeeds,
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

class _SpeedBackgroundPainter extends CustomPainter {
  final Track? real;
  final Track? imported;
  final List<double> realSpeeds;
  final List<double> importedSpeeds;

  _SpeedBackgroundPainter({
    this.real,
    this.imported,
    required this.realSpeeds,
    required this.importedSpeeds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allS = [...realSpeeds, ...importedSpeeds];
    if (allS.isEmpty) return;

    final maxD = _getMaxDist();
    final minS = allS.reduce((a, b) => a < b ? a : b);
    final maxS = allS.reduce((a, b) => a > b ? a : b);
    final rangeS = (maxS - minS).abs() == 0 ? 1.0 : (maxS - minS).abs();

    double x(double d) => (d / maxD) * size.width;
    double y(double s) => size.height - ((s - minS) / rangeS) * size.height;

    final pGrid = Paint()
      ..color = Colors.grey.withAlpha(40)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y(maxS)), Offset(size.width, y(maxS)), pGrid);
    canvas.drawLine(Offset(0, y(minS)), Offset(size.width, y(minS)), pGrid);

    void draw(Track t, List<double> s, Color c) {
      if (s.isEmpty) return;
      final path = Path()..moveTo(x(t.distances.first), y(s.first));
      for (int i = 1; i < s.length; i++)
        path.lineTo(x(t.distances[i]), y(s[i]));
      canvas.drawPath(
        path,
        Paint()
          ..color = c
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    if (imported != null)
      draw(imported!, importedSpeeds, AppColors.trackGreen.withAlpha(100));
    if (real != null) draw(real!, realSpeeds, AppColors.redAlert);
  }

  double _getMaxDist() {
    double d = 0;
    if (real != null && real!.distances.isNotEmpty) d = real!.distances.last;
    if (imported != null && imported!.distances.isNotEmpty)
      d = imported!.distances.last > d ? imported!.distances.last : d;
    return d == 0 ? 1 : d;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SpeedInteractivePainter extends CustomPainter {
  final double? needleX;
  final Track? real;
  final Track? imported;
  final List<double> realSpeeds;
  final List<double> importedSpeeds;

  _SpeedInteractivePainter({
    this.needleX,
    this.real,
    this.imported,
    required this.realSpeeds,
    required this.importedSpeeds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allS = [...realSpeeds, ...importedSpeeds];
    if (allS.isEmpty) return;

    final minS = allS.reduce((a, b) => a < b ? a : b);
    final maxS = allS.reduce((a, b) => a > b ? a : b);
    final rangeS = (maxS - minS).abs() == 0 ? 1.0 : (maxS - minS).abs();
    double getY(double s) => size.height - ((s - minS) / rangeS) * size.height;

    _drawL(canvas, "${maxS.toStringAsFixed(1)} km/h", -15, size.width);
    _drawL(
      canvas,
      "${minS.toStringAsFixed(1)} km/h",
      size.height + 5,
      size.width,
    );

    if (needleX == null) return;
    final xPos = needleX!.clamp(0.0, size.width);
    final currentDist = (xPos / size.width) * _getMaxDist();

    canvas.drawLine(
      Offset(xPos, -25),
      Offset(xPos, size.height + 15),
      Paint()..color = Colors.black12,
    );

    double? rVal, iVal;
    // Solo dibujamos círculo si el track existe
    if (real != null && realSpeeds.isNotEmpty) {
      rVal = _findValue(real!, realSpeeds, currentDist);
      _drawPoint(canvas, xPos, getY(rVal), AppColors.redAlert);
    }
    if (imported != null && importedSpeeds.isNotEmpty) {
      iVal = _findValue(imported!, importedSpeeds, currentDist);
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
          text: "REAL: ${r.toStringAsFixed(1)}km/h",
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
          text: "IMP: ${i.toStringAsFixed(1)}km/h",
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

    // Dibujamos el tooltip con el color AppColors.primary
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
    if (imported?.distances.isNotEmpty == true && imported!.distances.last > d)
      d = imported!.distances.last;
    return d == 0 ? 1 : d;
  }

  double _findValue(Track t, List<double> s, double d) {
    for (int i = 0; i < t.distances.length; i++)
      if (t.distances[i] >= d) return s[i];
    return s.isNotEmpty ? s.last : 0.0;
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
  bool shouldRepaint(_SpeedInteractivePainter old) => old.needleX != needleX;
}
