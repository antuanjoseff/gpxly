import 'package:flutter_riverpod/flutter_riverpod.dart';

// 📦 1. La estructura de un rectángulo simple
class DemBounds {
  final double minLon;
  final double minLat;
  final double maxLon;
  final double maxLat;

  const DemBounds({
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
  });
}

// 🧠 2. El controlador que gestiona la lista en la memoria de la App
class DemBoundsNotifier extends Notifier<List<DemBounds>> {
  @override
  List<DemBounds> build() {
    return const []; // Al arrancar la app, la lista empieza vacía
  }

  // Función para apuntar un nuevo rectángulo en la pizarra
  void addCell(double minLon, double minLat, double maxLon, double maxLat) {
    // Si ya lo tenemos apuntado exactamente igual, lo ignoramos para ahorrar RAM
    final exists = state.any(
      (b) =>
          b.minLon == minLon &&
          b.minLat == minLat &&
          b.maxLon == maxLon &&
          b.maxLat == maxLat,
    );

    if (!exists) {
      // Añadimos el nuevo rectángulo a la lista de forma inmutable
      state = [
        ...state,
        DemBounds(
          minLon: minLon,
          minLat: minLat,
          maxLon: maxLon,
          maxLat: maxLat,
        ),
      ];
    }
  }

  // Por si en algún momento necesitas vaciar el mapa
  void clearAll() {
    state = const [];
  }
}

// 🌍 3. El proveedor global que escuchará el mapa
final demBoundsProvider = NotifierProvider<DemBoundsNotifier, List<DemBounds>>(
  () {
    return DemBoundsNotifier();
  },
);
