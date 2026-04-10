import 'dart:math';

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000; // radi de la Terra en metres

  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c; // metres
}

double _degToRad(double deg) => deg * pi / 180.0;
