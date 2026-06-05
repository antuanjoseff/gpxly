// lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';

class EmbeddedElevationProfile extends StatefulWidget {
  // Passem variables de control de l'estat del mapa si cal previsualitzar
  final int? selectedIndexStart;
  final int? selectedIndexEnd;
  final int? selectedIndexGraph;

  // Callbacks per notificar a la pantalla principal map_screen
  final void Function(int index) onNeedleMove;
  final void Function(int start, int end) onRangeSelected;
  final VoidCallback onClearSelection;

  const EmbeddedElevationProfile({
    super.key,
    required this.selectedIndexStart,
    required this.selectedIndexEnd,
    required this.selectedIndexGraph,
    required this.onNeedleMove,
    required this.onRangeSelected,
    required this.onClearSelection,
  });

  @override
  State<EmbeddedElevationProfile> createState() =>
      _EmbeddedElevationProfileState();
}

class _EmbeddedElevationProfileState extends State<EmbeddedElevationProfile> {
  @override
  Widget build(BuildContext context) {
    // Alçada fixa controlada per aïllar completament l'espai de col·lisió de la GPU
    return Container(
      height: 200,
      color: const Color(0xFF1E293B), // Blau fosc sòlid corporatiu
      // lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 2 DE 2)
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;

          return GestureDetector(
            // 🛡️ ESCUT DE L'ARENA DE GESTOS: Opaque absorbeix el dit abans de que baixi al mapa
            behavior: HitTestBehavior.opaque,

            // 📐 1. LONG PRESS (Selecció de tram/rang)
            onLongPressStart: (LongPressStartDetails details) {
              final double x = details.localPosition.dx;
              // Calculem de forma proporcional un índex de 0 a 100 segons on col·loquis el dit
              int startIdx = ((x / width) * 100).round().clamp(0, 100);
              int endIdx = (startIdx + 20).clamp(
                0,
                100,
              ); // Generem un rang de proves

              print(
                "🎯 [TACTIL PROVA] LongPress a X: ${x.toStringAsFixed(1)}px -> Rang: $startIdx a $endIdx",
              );
              widget.onRangeSelected(startIdx, endIdx);
            },

            // 👆 2. TAP UP (Clic simple a zona buida per netejar)
            onTapUp: (TapUpDetails details) {
              print("🎯 [TACTIL PROVA] TapUp de seguretat -> Neteja.");
              widget.onClearSelection();
            },

            // 🎚️ 3. PAN DOWN (Inici d'arrossegament de l'agulla)
            onPanDown: (DragDownDetails details) {
              final double x = details.localPosition.dx;
              int idx = ((x / width) * 100).round().clamp(0, 100);

              print(
                "🎯 [TACTIL PROVA] PanDown a X: ${x.toStringAsFixed(1)}px -> Índex: $idx",
              );
              widget.onNeedleMove(idx);
            },

            // 🎚️ 4. PAN UPDATE (Moviment continu del drag de l'agulla)
            onPanUpdate: (DragUpdateDetails details) {
              final double x = details.localPosition.dx;
              int idx = ((x / width) * 100).round().clamp(0, 100);

              print(
                "🎯 [TACTIL PROVA] PanUpdate a X: ${x.toStringAsFixed(1)}px -> Índex: $idx",
              );
              widget.onNeedleMove(idx);
            },

            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "HUD DE CONTROL SÈNDA TACTIL",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Mira: ${widget.selectedIndexGraph ?? '-'}  |  Rang: [${widget.selectedIndexStart ?? '-'} , ${widget.selectedIndexEnd ?? '-'}]",
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
