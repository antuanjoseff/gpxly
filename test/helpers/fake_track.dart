import 'package:gpxly/models/track.dart';

/// Track antic — el deixem per compatibilitat
Track makeLinearTrack() {
  return Track(
    coordinates: [
      [0.0, 0.0],
      [0.001, 0.0],
      [0.002, 0.0],
      [0.003, 0.0],
    ],
    distances: [],
    altitudes: [],
    timestamps: [],
    accuracies: [],
    speeds: [],
    headings: [],
    satellites: [],
    vAccuracies: [],
    recordingState: RecordingState.idle,
    duration: Duration.zero,
    distance: 300,
    ascent: 0,
    descent: 0,
    maxElevation: 0,
    minElevation: 0,
    minLat: 0,
    maxLat: 0.003,
    minLon: 0,
    maxLon: 0,
  );
}

/// Track antic circular — el deixem per compatibilitat
Track makeCircularTrack() {
  return Track(
    coordinates: [
      [0.0, 0.0],
      [0.001, 0.0],
      [0.001, 0.001],
      [0.0, 0.001],
      [0.0, 0.0], // final = inicial
    ],
    distances: [],
    altitudes: [],
    timestamps: [],
    accuracies: [],
    speeds: [],
    headings: [],
    satellites: [],
    vAccuracies: [],
    recordingState: RecordingState.idle,
    duration: Duration.zero,
    distance: 400,
    ascent: 0,
    descent: 0,
    maxElevation: 0,
    minElevation: 0,
    minLat: 0,
    maxLat: 0.001,
    minLon: 0,
    maxLon: 0.001,
  );
}

/// 🔥 TRACK DEFINITIU PER TOTS ELS TESTS
/// - Segments de ~33 metres (0.0003°)
/// - Tots < 50m → _distanceProgressOnTrack suma
/// - Últim segment molt curt → t > 0.95 fàcil
/// - Bearing estable → reversed funciona
/// - Distància 0 → ONTRACK fiable
Track makeDenseTrack() {
  return Track(
    coordinates: const [
      [0.0000, 0.0000],
      [0.0003, 0.0000],
      [0.0006, 0.0000],
      [0.0009, 0.0000],
      [0.0012, 0.0000],
      [0.0015, 0.0000],
      [0.0018, 0.0000],
      [0.0021, 0.0000],
      [0.0024, 0.0000],
      [0.0027, 0.0000],
      [0.0030, 0.0000],
      [0.0033, 0.0000],
      [0.0036, 0.0000],
      [0.0039, 0.0000], // penúltim
      [0.0040, 0.0000], // final del track
    ],
    distances: [],
    altitudes: [],
    timestamps: [],
    accuracies: [],
    speeds: [],
    headings: [],
    satellites: [],
    vAccuracies: [],
    recordingState: RecordingState.idle,
    duration: Duration.zero,
    distance: 400,
    ascent: 0,
    descent: 0,
    maxElevation: 0,
    minElevation: 0,
    minLat: 0,
    maxLat: 0.0,
    minLon: 0.0,
    maxLon: 0.0040,
  );
}
