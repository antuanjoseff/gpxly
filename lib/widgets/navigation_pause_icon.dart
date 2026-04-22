import 'package:flutter/material.dart';

class NavigationPauseIconV2 extends StatelessWidget {
  final double size;

  const NavigationPauseIconV2({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final double navIconSize = size * 0.85;
    final double pauseIconSize = size * 0.38;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ICONA DE NAVEGACIÓ (MÉS CAP A L'ESQUERRA)
          Align(
            alignment: const Alignment(-0.65, 0), // mou cap a l'esquerra
            child: Icon(
              Icons.navigation,
              size: navIconSize,
              color: Colors.red.shade600,
            ),
          ),

          // ICONA DE PAUSA (MÉS CAP A LA DRETA)
          Positioned(
            top: -3,
            right: -6,
            child: Align(
              alignment: const Alignment(2.5, 0), // mou cap a la dreta
              child: Container(
                width: pauseIconSize * 1.7,
                height: pauseIconSize * 1.7,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.pause,
                  size: pauseIconSize * 1.3,
                  color: Colors.white.withAlpha(230),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
