// lib/widgets/senda_brand_label.dart
import 'dart:ui'; // 🔥 CRÍTIC: Import indispensable per poder utilitzar l'ImageFilter natiu
import 'package:flutter/material.dart';
import 'package:senda/theme/app_colors.dart'; // Importem els teus colors corporatius

class SendaBrandLabel extends StatelessWidget {
  const SendaBrandLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        14,
      ), // Retallem els vòre perquè el blur no surti del quadrat
      child: BackdropFilter(
        // 🌀 EFECTE VIDRE: Definim la intensitat del desfoque de la cartografia de fons
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            // 🎨 FONS TRANSLÚCID TENYIT: Barreja de blanc pur amb un toc del color de l'App (AppColors.primary)
            // L'opacitat .withAlpha(40) o .withOpacity(0.15) permet transmetre el color de marca sense tapar el fons
            color: AppColors.primary.withAlpha(35),
            borderRadius: BorderRadius.circular(14),

            // 💥 CONTORN DE CRISTALL: Una vora molt fina i translúcida blanca que simula el reflex del vidre
            border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "SENDA",
                style: TextStyle(
                  // 🟢 Mantenim el text blanc o el teu color de marca fosc segons el contrast que prefereixis.
                  // El blanc pur brilla molt bé sobre el desfoque del glassmorphism.
                  color: Colors.white.withAlpha(240),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing:
                      2.0, // Un pèl més d'espaiat per al look futurista del vidre
                  shadows: [
                    // Una ombra molt fina sota el text per assegurar la llegibilitat sobre fons de neu o mapes clars
                    Shadow(
                      color: Colors.black.withAlpha(40),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
