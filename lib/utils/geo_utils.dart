import 'dart:math';

import 'package:maplibre_gl/maplibre_gl.dart';

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

double distanceBetween(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000; // metres

  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

double _degToRad(double deg) => deg * pi / 180.0;

double distancePointToSegment(LatLng p, LatLng a, LatLng b) {
  // Convertim a vectors
  final px = p.longitude;
  final py = p.latitude;
  final ax = a.longitude;
  final ay = a.latitude;
  final bx = b.longitude;
  final by = b.latitude;

  final dx = bx - ax;
  final dy = by - ay;

  if (dx == 0 && dy == 0) {
    // Segment degenerat
    return distanceInMeters(p, a);
  }

  // Projectem p sobre el segment AB
  final t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);

  if (t < 0) return distanceInMeters(p, a);
  if (t > 1) return distanceInMeters(p, b);

  final proj = LatLng(ay + t * dy, ax + t * dx);
  return distanceInMeters(p, proj);
}

double distanceToTrack(LatLng p, List<List<double>> coords) {
  double minDist = double.infinity;

  for (int i = 0; i < coords.length - 1; i++) {
    final a = LatLng(coords[i][1], coords[i][0]);
    final b = LatLng(coords[i + 1][1], coords[i + 1][0]);
    final d = distancePointToSegment(p, a, b);
    if (d < minDist) minDist = d;
  }

  return minDist;
}

double distanceInMeters(LatLng a, LatLng b) {
  const R = 6371000; // Radi de la Terra en metres

  final lat1 = a.latitude * pi / 180;
  final lat2 = b.latitude * pi / 180;
  final dLat = (b.latitude - a.latitude) * pi / 180;
  final dLon = (b.longitude - a.longitude) * pi / 180;

  final h =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

  final c = 2 * atan2(sqrt(h), sqrt(1 - h));

  return R * c;
}
