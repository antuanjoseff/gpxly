import 'package:geolocator/geolocator.dart';

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
