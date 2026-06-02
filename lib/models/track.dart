import 'package:maplibre_gl/maplibre_gl.dart';

import 'user_position.dart';

enum RecordingState {
  idle, // No gravant
  recording, // Gravació activa
  paused, // Pausa
}

class Track {
  final List<UserPosition> points; // Llista compacta de punts
  final TrackStats stats; // Mètriques globals precalculades
  final RecordingState recordingState;

  // Estat visual del punt blau a temps real (Independent de la gravació)
  final LatLng? currentPosition;
  final double currentHeading;
  final double currentSpeed;

  Track({
    this.points = const [],
    TrackStats? stats,
    this.recordingState = RecordingState.idle,
    this.currentPosition,
    this.currentHeading = 0.0,
    this.currentSpeed = 0.0,
  }) : stats = stats ?? TrackStats();

  Track copyWith({
    List<UserPosition>? points,
    TrackStats? stats,
    RecordingState? recordingState,
    LatLng? currentPosition,
    double? currentHeading,
    double? currentSpeed,
  }) {
    return Track(
      points: points ?? this.points,
      stats: stats ?? this.stats,
      recordingState: recordingState ?? this.recordingState,
      currentPosition: currentPosition ?? this.currentPosition,
      currentHeading: currentHeading ?? this.currentHeading,
      currentSpeed: currentSpeed ?? this.currentSpeed,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 🔌 GETTERS DE RETROCOMPATIBILITAT PER EVITAR TRENCAMENTS
  // ─────────────────────────────────────────────────────────────
  List<List<double>> get coordinates =>
      points.map((p) => [p.position.longitude, p.position.latitude]).toList();
  List<double> get distances => points.map((p) => p.distanceAtPoint).toList();
  List<double> get altitudes => points.map((p) => p.altitude).toList();
  List<bool> get isHgtFixed => points.map((p) => p.isHgtFixed).toList();
  List<DateTime> get timestamps => points.map((p) => p.timestamp).toList();
  List<double> get accuracies => points.map((p) => p.accuracy).toList();
  List<double> get speeds => points.map((p) => p.speed).toList();
  List<double> get headings => points.map((p) => p.heading).toList();
  List<int> get satellites => points.map((p) => p.satellites).toList();
  List<double> get vAccuracies => points.map((p) => p.vAccuracy).toList();

  // Redireccions cap a les estadístiques modulars
  Duration get stoppedDuration => stats.stoppedDuration;
  Duration get duration => stats.duration;
  double get distance => stats.distance;
  double get ascent => stats.ascent;
  double get descent => stats.descent;
  double get maxElevation => stats.maxElevation;
  double get minElevation => stats.minElevation;

  // ✅ CORREGIDO: Ahora apuntan a las variables reales procesadas por el motor
  double get averageSpeed => stats.averageSpeed;
  double get maxSpeed => stats.maxSpeed;

  double? get minLat => stats.minLat;
  double? get maxLat => stats.maxLat;
  double? get minLon => stats.minLon;
  double? get maxLon => stats.maxLon;

  // ─────────────────────────────────────────────────────────────
  // ⚙️ GETTERS DE LÒGICA DE NEGOCI MANTINGUTS INTACTES
  // ─────────────────────────────────────────────────────────────
  Duration get movingDuration => duration - stoppedDuration;

  String get formattedStopped {
    final total = stoppedDuration;
    final h = total.inHours.toString().padLeft(2, '0');
    final m = (total.inMinutes % 60).toString().padLeft(2, '0');
    final s = (total.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  double get currentSpeedKmH => currentSpeed * 3.6;
  int get currentSatellites => points.isNotEmpty ? points.last.satellites : 0;

  String get formattedDuration {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  bool get recording => recordingState == RecordingState.recording;
  bool get paused => recordingState == RecordingState.paused;

  bool get hasElevationData =>
      altitudes.isNotEmpty || minElevation != 0 || maxElevation != 0;
  bool get hasTimeData =>
      timestamps.isNotEmpty && timestamps.length == coordinates.length;
  bool get hasAscentDescent => ascent != 0 || descent != 0;

  // 🏃‍♂️ RITMO MEDIO EN MOVIMIENTO (Minutos por Kilómetro -> min/km)
  double get averagePace {
    if (distance <= 0) return 0.0;

    // Tiempo en movimiento en minutos dividido por la distancia en kilómetros
    final double movingMinutes = (duration - stoppedDuration).inSeconds / 60.0;
    final double distanceKm = distance / 1000.0;

    return movingMinutes / distanceKm;
  }

  // ⚙️ FORMATO TEXTO COMPACTO (Devuelve string formateado "MM:SS min/km")
  String get formattedAveragePace {
    final double pace = averagePace;
    if (pace <= 0 || pace.isInfinite || pace.isNaN) return "--:-- min/km";

    final int minutes = pace.floor();
    final int seconds = ((pace - minutes) * 60).round();

    // Blindaje por si el redondeo de los segundos llega a 60
    final int displaySeconds = seconds == 60 ? 59 : seconds;

    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = displaySeconds.toString().padLeft(2, '0');

    return "$mm:$ss min/km";
  }
}

// ─────────────────────────────────────────────────────────────
// 🔥 SUB-MODEL REFACTORIZADO CON VELOCIDADES REALES
// ─────────────────────────────────────────────────────────────
class TrackStats {
  final Duration duration;
  final Duration stoppedDuration;
  final double distance;
  final double ascent;
  final double descent;
  final double maxElevation;
  final double minElevation;
  final double averageSpeed;
  final double maxSpeed;

  // Bounding box geogràfic
  final double? minLat;
  final double? maxLat;
  final double? minLon;
  final double? maxLon;

  TrackStats({
    this.duration = Duration.zero,
    this.stoppedDuration = Duration.zero,
    this.distance = 0.0,
    this.ascent = 0.0,
    this.descent = 0.0,
    this.maxElevation = -9999.0,
    this.minElevation = 9999.0,
    this.averageSpeed = 0.0, // ✅ Inicializado
    this.maxSpeed = 0.0, // ✅ Inicializado
    this.minLat,
    this.maxLat,
    this.minLon,
    this.maxLon,
  });

  TrackStats copyWith({
    Duration? duration,
    Duration? stoppedDuration,
    double? distance,
    double? ascent,
    double? descent,
    double? maxElevation,
    double? minElevation,
    double? averageSpeed, // ✅ Añadido al copyWith
    double? maxSpeed, // ✅ Añadido al copyWith
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
  }) {
    return TrackStats(
      duration: duration ?? this.duration,
      stoppedDuration: stoppedDuration ?? this.stoppedDuration,
      distance: distance ?? this.distance,
      ascent: ascent ?? this.ascent,
      descent: descent ?? this.descent,
      maxElevation: maxElevation ?? this.maxElevation,
      minElevation: minElevation ?? this.minElevation,
      averageSpeed: averageSpeed ?? this.averageSpeed, // ✅ Mapeado
      maxSpeed: maxSpeed ?? this.maxSpeed, // ✅ Mapeado
      minLat: minLat ?? this.minLat,
      maxLat: maxLat ?? this.maxLat,
      minLon: minLon ?? this.minLon,
      maxLon: maxLon ?? this.maxLon,
    );
  }
}
