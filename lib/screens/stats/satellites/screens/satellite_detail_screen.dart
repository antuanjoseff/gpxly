// lib/stats/satellites/screens/satellite_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/services/native_gps_channel.dart';
import '../painters/skyplot_painter.dart';

class SatelliteDetailScreen extends StatefulWidget {
  const SatelliteDetailScreen({super.key});

  @override
  State<SatelliteDetailScreen> createState() => _SatelliteDetailScreenState();
}

class _SatelliteDetailScreenState extends State<SatelliteDetailScreen> {
  Map<String, String> _parseConstellation(int type, int svid) {
    switch (type) {
      case 1:
        return {'name': 'GPS', 'code': 'G$svid'};
      case 3:
        return {'name': 'GLONASS', 'code': 'R$svid'};
      case 6:
        return {'name': 'GALILEO', 'code': 'E$svid'};
      case 5:
        return {'name': 'BEIDOU', 'code': 'B$svid'};
      default:
        return {'name': 'UNKNOWN', 'code': 'U$svid'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final double radarSize = MediaQuery.of(context).size.width * 0.85;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skyplot'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<dynamic>>(
        stream: NativeGpsChannel.satelliteStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final satellites = snapshot.data ?? [];
          if (satellites.isEmpty) {
            return const Center(
              child: Text(
                'Buscant satèl·lits... Assegura\'t de tenir el GPS actiu exterior.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          // Filtros de conteo para la telemetría superior
          int usedCount = 0;
          for (var sat in satellites) {
            if (Map<String, dynamic>.from(sat)['usedInFix'] as bool) {
              usedCount++;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. FILA SUPERIOR: Telemetría a la izquierda y Leyenda fuera del gráfico a la derecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lado izquierdo: Tu panel de telemetría original
                  _buildTelemetryPanel(satellites.length, usedCount),

                  // Lado derecho: La leyenda de formas geométricas alineada arriba
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(top: 8.0, right: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendRow('GPS', 1),
                        _buildLegendRow('Glonass', 3),
                        _buildLegendRow('Galileo', 6),
                        _buildLegendRow('BeiDou', 5),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. RADAR CIRCULAR LIMPIO (SKYPLOT CENTRADO)
              Center(
                child: SizedBox(
                  width: radarSize,
                  height: radarSize,
                  child: CustomPaint(
                    painter: SkyplotPainter(
                      satellites: satellites,
                      parseFn: _parseConstellation,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 3. GRÁFICO DE BARRAS ESTILO GARMIN INFERIOR
              SizedBox(height: 140, child: _buildGarminBarChart(satellites)),
            ],
          );
        },
      ),
    );
  }

  // Widget auxiliar para pintar cada fila de la leyenda de constelaciones
  Widget _buildLegendRow(String label, int type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size(12, 12),
            painter: _LegendShapePainter(constellationType: type),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryPanel(int totalInView, int totalInUse) {
    final TextStyle labelStyle = TextStyle(
      color: Colors.blue.shade700,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UTC Time: ${DateTime.now().toUtc().toString().split(' ').last.split('.').first}',
            style: labelStyle,
          ),
          Text(
            'Fix Type: ${totalInUse >= 4 ? "3D/RTK Fix" : "No Fix"}',
            style: labelStyle,
          ),
          Text('Satellites in View: $totalInView', style: labelStyle),
          Text('Satellites in Use: $totalInUse', style: labelStyle),
        ],
      ),
    );
  }

  Widget _buildGarminBarChart(List<dynamic> satellites) {
    final sortedSats = List<dynamic>.from(satellites)
      ..sort(
        (a, b) => Map<String, dynamic>.from(a)['constellation'].compareTo(
          Map<String, dynamic>.from(b)['constellation'],
        ),
      );

    return Align(
      alignment: Alignment.bottomCenter,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: sortedSats.length,
        itemBuilder: (context, index) {
          final map = Map<String, dynamic>.from(sortedSats[index]);
          final cn0 = (map['cn0'] as num).toDouble();
          final parsed = _parseConstellation(
            map['constellation'] as int,
            map['svid'] as int,
          );

          final double heightFactor = (cn0 / 50.0).clamp(0.05, 1.0);

          Color barColor = Colors.orange;
          if (cn0 >= 30.0) {
            barColor = Colors.green;
          } else if (cn0 >= 20.0) {
            barColor = Colors.amber;
          }

          return Container(
            width: 26,
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  cn0.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 9,
                    color: barColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 80,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: heightFactor,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parsed['code']!,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 🎨 Pintor miniatura idéntico a las figuras que dibuja tu SkyplotPainter
class _LegendShapePainter extends CustomPainter {
  final int constellationType;

  _LegendShapePainter({required this.constellationType});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paintNode = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    if (constellationType == 1) {
      canvas.drawCircle(Offset.zero, 4.5, paintNode);
      canvas.drawCircle(Offset.zero, 4.5, paintStroke);
    } else if (constellationType == 3) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 8),
        paintNode,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 8),
        paintStroke,
      );
    } else if (constellationType == 6) {
      var path = Path()
        ..moveTo(0, -5)
        ..lineTo(4.5, 3.5)
        ..lineTo(-4.5, 3.5)
        ..close();
      canvas.drawPath(path, paintNode);
      canvas.drawPath(path, paintStroke);
    } else {
      var path = Path()
        ..moveTo(0, -5)
        ..lineTo(4.5, 0)
        ..lineTo(0, 5)
        ..lineTo(-4.5, 0)
        ..close();
      canvas.drawPath(path, paintNode);
      canvas.drawPath(path, paintStroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LegendShapePainter oldDelegate) => false;
}
