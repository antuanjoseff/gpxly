import 'package:flutter/material.dart';
import 'package:senda/models/track.dart';
import 'package:senda/theme/app_colors.dart';

class SlopeChart extends StatefulWidget {
  final Track? real;
  final Track? imported;

  const SlopeChart({super.key, this.real, this.imported});

  @override
  State<SlopeChart> createState() => _SlopeChartState();
}

class _SlopeChartState extends State<SlopeChart> {
  final ValueNotifier<double?> needleXNotifier = ValueNotifier<double?>(null);
  late List<double> realSlopes;
  late List<double> importedSlopes;

  @override
  void initState() {
    super.initState();
    _precompute();
  }

  void _precompute() {
    realSlopes = widget.real != null ? _calc(widget.real!) : [];
    importedSlopes = widget.imported != null ? _calc(widget.imported!) : [];
  }

  List<double> _calc(Track t) {
    if (t.distances.isEmpty) return [];
    final s = <double>[0.0];
    for (int i = 1; i < t.distances.length; i++) {
      final dDist = t.distances[i] - t.distances[i - 1];
      final dAlt = t.altitudes[i] - t.altitudes[i - 1];
      s.add(dDist > 0 ? (dAlt / dDist) * 100 : 0.0);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 220.0; // Augmentem una mica l'alçada total

        return SizedBox(
          width: width,
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) =>
                needleXNotifier.value = d.localPosition.dx,
            onTapDown: (d) => needleXNotifier.value = d.localPosition.dx,
            child: Stack(
              clipBehavior:
                  Clip.none, // <--- IMPORTANT: Permet dibuixar fora dels marges
              children: [
                // 1. EL GRÀFIC (Fons) - Baixem el top a 45
                Positioned(
                  top: 45,
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(width, height - 75),
                      painter: _SlopeMiddlePainter(
                        real: widget.real,
                        imported: widget.imported,
                        realSlopes: realSlopes,
                        importedSlopes: importedSlopes,
                      ),
                    ),
                  ),
                ),

                // 2. L'INTERACCIÓ (Agulla i Cercles) - Baixem el top a 45
                Positioned(
                  top: 45,
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<double?>(
                    valueListenable: needleXNotifier,
                    builder: (context, val, _) {
                      return CustomPaint(
                        size: Size(width, height - 75),
                        painter: _SlopeInteractivePainter(
                          needleX: val,
                          real: widget.real,
                          imported: widget.imported,
                          realSlopes: realSlopes,
                          importedSlopes: importedSlopes,
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

class _SlopeMiddlePainter extends CustomPainter {
  final Track? real;
  final Track? imported;
  final List<double> realSlopes;
  final List<double> importedSlopes;

  _SlopeMiddlePainter({
    this.real,
    this.imported,
    required this.realSlopes,
    required this.importedSlopes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || (realSlopes.isEmpty && importedSlopes.isEmpty)) {
      return;
    }

    final maxD = _getMaxDist();
    final allS = [...realSlopes, ...importedSlopes];
    final minS = allS.reduce((a, b) => a < b ? a : b);
    final maxS = allS.reduce((a, b) => a > b ? a : b);
    final rangeS = (maxS - minS).abs() == 0 ? 1.0 : (maxS - minS).abs();

    double x(double d) => (d / maxD) * size.width;
    double y(double s) => size.height - ((s - minS) / rangeS) * size.height;

    // Línia del 0%
    canvas.drawLine(
      Offset(0, y(0)),
      Offset(size.width, y(0)),
      Paint()..color = Colors.grey.withAlpha(40),
    );

    if (imported != null) {
      _drawTrack(
        canvas,
        imported!,
        importedSlopes,
        AppColors.trackGreen.withAlpha(100),
        x,
        y,
      );
    }
    if (real != null) {
      _drawTrack(canvas, real!, realSlopes, AppColors.redAlert, x, y);
    }
  }

  double _getMaxDist() {
    double d = 0;
    if (real != null && real!.distances.isNotEmpty) d = real!.distances.last;
    if (imported != null && imported!.distances.isNotEmpty) {
      if (imported!.distances.last > d) d = imported!.distances.last;
    }
    return d == 0 ? 1 : d;
  }

  void _drawTrack(
    Canvas canvas,
    Track t,
    List<double> s,
    Color c,
    Function x,
    Function y,
  ) {
    if (t.distances.isEmpty) return;
    final path = Path()..moveTo(x(t.distances.first), y(s.first));
    for (int i = 1; i < s.length; i++) {
      path.lineTo(x(t.distances[i]), y(s[i]));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = c
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// --- PINTA L'AGULLA, CERCLES DINÀMICS I TOOLTIP UNIFICAT ---
class _SlopeInteractivePainter extends CustomPainter {
  final double? needleX;
  final Track? real;
  final Track? imported;
  final List<double> realSlopes;
  final List<double> importedSlopes;

  _SlopeInteractivePainter({
    this.needleX,
    this.real,
    this.imported,
    required this.realSlopes,
    required this.importedSlopes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;

    final allS = [...realSlopes, ...importedSlopes];
    if (allS.isEmpty) return;

    final minS = allS.reduce((a, b) => a < b ? a : b);
    final maxS = allS.reduce((a, b) => a > b ? a : b);
    final rangeS = (maxS - minS).abs() == 0 ? 1.0 : (maxS - minS).abs();

    double getY(double s) => size.height - ((s - minS) / rangeS) * size.height;

    // Etiquetes eix Y (mínim i màxim)
    _drawLabel(canvas, "${maxS.toStringAsFixed(0)}%", -15, size.width);
    _drawLabel(
      canvas,
      "${minS.toStringAsFixed(0)}%",
      size.height + 5,
      size.width,
    );

    if (needleX == null) return;

    final xPos = needleX!.clamp(0.0, size.width);
    final maxD = _getMaxDist();
    final currentDist = (xPos / size.width) * maxD;

    // Línia vertical (Agulla)
    canvas.drawLine(
      Offset(xPos, -20),
      Offset(xPos, size.height + 20),
      Paint()
        ..color = Colors.black12
        ..strokeWidth = 1,
    );

    double? rVal, iVal;

    // NOMÉS dibuixem cercle si el track existeix i té dades
    if (real != null && realSlopes.isNotEmpty) {
      rVal = _findValue(real!, realSlopes, currentDist);
      _drawPoint(canvas, xPos, getY(rVal), AppColors.redAlert);
    }

    if (imported != null && importedSlopes.isNotEmpty) {
      iVal = _findValue(imported!, importedSlopes, currentDist);
      _drawPoint(canvas, xPos, getY(iVal), AppColors.trackGreen);
    }

    // Tooltip unificat i condicionat
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
    final spans = <TextSpan>[];

    // Afegim el valor Real si existeix
    if (r != null) {
      spans.add(
        TextSpan(
          text: "REAL: ${r.toStringAsFixed(1)}%",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    }

    // Separador només si hi ha els DOS tracks
    if (r != null && i != null) {
      spans.add(
        const TextSpan(
          text: "  |  ",
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      );
    }

    // Afegim el valor Importat si existeix
    if (i != null) {
      spans.add(
        TextSpan(
          text: "IMP: ${i.toStringAsFixed(1)}%",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    }

    if (spans.isEmpty) return;

    final tp = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    )..layout();

    final rectW = tp.width + 16;
    final rectH = tp.height + 10;
    final tx = (x - rectW / 2).clamp(0.0, size.width - rectW);

    // Dibuixem el rectangle amb AppColors.primary
    final rect = RRect.fromLTRBR(
      tx,
      -38,
      tx + rectW,
      -38 + rectH,
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = AppColors.primary);

    tp.paint(canvas, Offset(tx + 8, -33));
  }

  double _getMaxDist() {
    double d = 0;
    if (real != null && real!.distances.isNotEmpty) d = real!.distances.last;
    if (imported != null && imported!.distances.isNotEmpty) {
      if (imported!.distances.last > d) d = imported!.distances.last;
    }
    return d == 0 ? 1 : d;
  }

  double _findValue(Track t, List<double> s, double d) {
    if (s.isEmpty) return 0.0;
    for (int i = 0; i < t.distances.length; i++) {
      if (t.distances[i] >= d) return s[i];
    }
    return s.last;
  }

  void _drawLabel(Canvas canvas, String txt, double y, double w) {
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
  bool shouldRepaint(_SlopeInteractivePainter old) => old.needleX != needleX;
}
