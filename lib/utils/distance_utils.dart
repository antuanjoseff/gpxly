import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

List<double> calculateDistances(List<List<double>> coordinates) {
  if (coordinates.isEmpty) return [];

  List<double> distances = [0.0];
  double total = 0.0;

  for (int i = 0; i < coordinates.length - 1; i++) {
    total += Geolocator.distanceBetween(
      coordinates[i][1],
      coordinates[i][0],
      coordinates[i + 1][1],
      coordinates[i + 1][0],
    );
    distances.add(total);
  }
  return distances;
}

String formatDistance(double metres) {
  if (metres < 1000) {
    return "${metres.toStringAsFixed(0)} m";
  } else {
    final km = metres / 1000;
    return "${km.toStringAsFixed(km < 10 ? 2 : 1)} km";
  }
}

double calculateDistanceManual(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const r = 6371000; // Radi de la Terra en metres
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}
