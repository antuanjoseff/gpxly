// lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/theme/app_colors.dart';

class EmbeddedElevationProfile extends ConsumerWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  // Paràmetres locals que venen des del mapa principal
  final int? selectedIndexStart;
  final int? selectedIndexEnd;
  final int? selectedIndexGraph;

  // Callbacks de retorn de gestos que connecten amb map_screen
  final void Function(int index) onNeedleMove;
  final void Function(int start, int end) onRangeSelected;
  final VoidCallback onClearSelection;

  const EmbeddedElevationProfile({
    super.key,
    required this.isCollapsed,
    required this.onToggle,
    required this.selectedIndexStart,
    required this.selectedIndexEnd,
    required this.selectedIndexGraph,
    required this.onNeedleMove,
    required this.onRangeSelected,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenim el coixí inferior natiu del telèfon per no perdre la nansa darrere de la barra del sistema
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      // Si està col·lapsat fa 38px fixes, si està obert fa 220px fixes (més el coixí del mòbil)
      height: isCollapsed
          ? (38.0 + systemBottomPadding)
          : (220.0 + systemBottomPadding),
      padding: EdgeInsets.only(bottom: systemBottomPadding),
      decoration: BoxDecoration(
        color: AppColors.skyBlueDark.withOpacity(0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      // El SingleChildScrollView rígid impedeix qualsevol overflow de text en col·lapsar,
      // amagant el contingut de sota sense alterar la mida de les caixes tàctils.
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // ───────────────────────────────────────────────────────────────────
            // 1. LA NANSA DE CONTROL SUPERIOR (Àrea premible de 36px de fàbrica)
            // ───────────────────────────────────────────────────────────────────
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                height: 36,
                color: Colors
                    .transparent, // Fa tota l'amplada de la barra sensible al tap
                alignment: Alignment.center,
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(90),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
            // lib/screens/map/widgets/embedded_elevation_profile.dart (BLOC 2 DE 2)
            // ───────────────────────────────────────────────────────────────────
            // 2. LA ZONA DE CAPTURA DE GESTOS (El teu giny d'or unificat de fàbrica)
            // ───────────────────────────────────────────────────────────────────
            if (!isCollapsed)
              SizedBox(
                height:
                    160, // Forçem una caixa d'alçada fixa i totalment estable
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    return GestureDetector(
                      behavior: HitTestBehavior
                          .opaque, // Escut total contra el mapa de fons

                      onLongPressStart: (details) {
                        final double x = details.localPosition.dx;
                        int simStart = ((x / width) * 100).round().clamp(
                          0,
                          100,
                        );
                        int simEnd = (simStart + 20).clamp(0, 100);

                        print(
                          "🎯 [TACTIL] LongPress a X: ${x.toStringAsFixed(1)}px -> Rang: $simStart a $simEnd",
                        );
                        onRangeSelected(simStart, simEnd);
                      },

                      onTapUp: (_) {
                        print("🎯 [TACTIL] TapUp -> Neteja.");
                        onClearSelection();
                      },

                      onPanDown: (details) {
                        final double x = details.localPosition.dx;
                        int simIdx = ((x / width) * 100).round().clamp(0, 100);

                        print(
                          "🎯 [TACTIL] PanDown a X: ${x.toStringAsFixed(1)}px -> Índex: $simIdx",
                        );
                        onNeedleMove(simIdx);
                      },

                      onPanUpdate: (details) {
                        final double x = details.localPosition.dx;
                        int simIdx = ((x / width) * 100).round().clamp(0, 100);

                        print(
                          "🎯 [TACTIL] PanUpdate a X: ${x.toStringAsFixed(1)}px -> Índex: $simIdx",
                        );
                        onNeedleMove(simIdx);
                      },

                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "LIENZO DE PRUEBA TÁCTIL",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Mira: ${selectedIndexGraph ?? '-'}  |  Rang: [${selectedIndexStart ?? '-'} , ${selectedIndexEnd ?? '-'}]",
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
