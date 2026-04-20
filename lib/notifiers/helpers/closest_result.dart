import 'package:maplibre_gl/maplibre_gl.dart';

class ClosestResult {
  final double distance;
  final double bearing;
  final double userBearing;
  final int segmentIndex;
  final double t;
  final LatLng projectedPoint;

  ClosestResult({
    required this.distance,
    required this.bearing,
    required this.userBearing,
    required this.segmentIndex,
    required this.t,
    required this.projectedPoint,
  });
}
