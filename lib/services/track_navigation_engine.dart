// lib/services/track_navigation_engine.dart
//
// Motor de navegació sobre el track guia (importedTrack).
//
// Principis de disseny (rigor):
//  1. TOTS els càlculs de distància es fan sobre el TRACK GUIA ORIGINAL,
//     mai sobre el track gravat. Els `distanceAtPoint` dels waypoints i dels
//     punts de la guia comparteixen la mateixa referència (metres acumulats
//     des de l'inici del GPX importat).
//  2. La posició de l'usuari dins del track (`currentTrackDistance`) es deriva
//     de la PROJECCIÓ del GPS sobre el segment més proper de la guia, no
//     d'índexs de punts.
//  3. El sentit de navegació (forward/reverse) NO modifica mai els
//     `distanceAtPoint`: només canvia la direcció de comparació.
//  4. La velocitat per a l'ETA es basa en la velocitat mitjana (o en la
//     velocitat filtrada sobre el track si la mitjana no està disponible), amb
//     el valor absolut per funcionar igual en forward i reverse.
//  5. `nextWaypointIndex` és monòton dins del sentit actiu: mai retrocedeix
//     per soroll GPS. Els salts de GPS que superen diversos waypoints es
//     gestionen amb un `while`.

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/waypoint.dart';
import 'package:strack_rec/utils/distance_utils.dart';

/// Sentit de la navegació sobre el track.
enum TrackDirection { forward, reverse }

/// Resultat immutable d'una actualització del motor.
class TrackNavigationResult {
  /// Distància de l'usuari sobre el track original (metres des de l'inici GPX).
  final double currentTrackDistance;

  /// Següent waypoint en el sentit actiu (null si no en queden).
  final Waypoint? nextWaypoint;

  /// Distància restant seguint el track fins al següent waypoint (metres).
  final double? distanceToNextWaypoint;

  /// Temps estimat d'arribada al següent waypoint (null si velocitat ~0 o
  /// si no hi ha waypoint).
  final Duration? eta;

  /// Velocitat filtrada usada per a l'ETA (m/s).
  final double filteredSpeedMps;

  const TrackNavigationResult({
    required this.currentTrackDistance,
    required this.nextWaypoint,
    required this.distanceToNextWaypoint,
    required this.eta,
    required this.filteredSpeedMps,
  });

  static const empty = TrackNavigationResult(
    currentTrackDistance: 0,
    nextWaypoint: null,
    distanceToNextWaypoint: null,
    eta: null,
    filteredSpeedMps: 0,
  );
}

class TrackNavigationEngine {
  // ─── CONFIGURACIÓ ───
  /// Tolerància per considerar que un waypoint s'ha assolit (metres).
  static const double arrivalThresholdMeters = 15.0;

  /// Velocitat mínima (m/s) per sota de la qual no es calcula ETA.
  static const double minSpeedMps = 0.15;

  /// Factor de suavització EMA per a la velocitat (0..1).
  /// 0.3 → respon en ~5-7 actualitzacions sense parpelleig.
  static const double speedEmaAlpha = 0.3;

  /// Màxim pas de progrés acceptat entre dues lectures (metres). Salts més
  /// grans es consideren soroll GPS i s'ignoren per a la velocitat.
  static const double maxProgressStepMeters = 80.0;

  /// Temps màxim que es manté l'últim ETA vàlid quan la velocitat cau o el
  /// GPS fa un salt (parades curtes: semàfor, foto...).
  static const Duration etaHoldDuration = Duration(seconds: 8);

  // ─── ESTAT ───
  List<double> _cumulativeDistances = const [];
  List<LatLng> _trackPoints = const [];
  List<Waypoint> _waypoints = const []; // ordenats per distanceAtPoint

  TrackDirection direction = TrackDirection.forward;

  double currentTrackDistance = 0.0;
  double filteredSpeedMps = 0.0;

  int nextWaypointIndex = 0;

  DateTime? _lastUpdateTime;
  double? _lastTrackDistanceForSpeed;

  Duration? _lastValidEta;
  DateTime? _lastValidEtaTime;

  bool get _hasTrack => _trackPoints.length >= 2;

  // ─────────────────────────────────────────────────────────────
  // CONFIGURACIÓ DEL TRACK I WAYPOINTS
  // ─────────────────────────────────────────────────────────────

  /// Carrega el track guia i els waypoints. Reinicia l'estat de progrés.
  ///
  /// [track] és el TRACK GUIA importat. Els [waypoints] s'ordenen per
  /// `distanceAtPoint` i mai es modifiquen després.
  void configure({
    required Track track,
    required List<Waypoint> waypoints,
    TrackDirection initialDirection = TrackDirection.forward,
  }) {
    _trackPoints = track.points.map((p) => p.position).toList();
    _cumulativeDistances = track.points
        .map((p) => p.distanceAtPoint)
        .toList(growable: false);

    // Rigor: si la guia no porta distàncies coherents, les reconstruïm.
    if (!_isCumulativeValid(_cumulativeDistances)) {
      _cumulativeDistances = _buildCumulative(_trackPoints);
    }

    _waypoints = [...waypoints]
      ..sort(
        (a, b) => (a.distanceAtPoint ?? double.infinity).compareTo(
          b.distanceAtPoint ?? double.infinity,
        ),
      );

    direction = initialDirection;
    resetProgress();
  }

  /// Empremta d'una configuració (per detectar si cal reconfigurar).
  /// Canvia si la guia o els waypoints canvien (inclòs després d'un reverse,
  /// que reindexa els `distanceAtPoint`).
  static int fingerprintOf(Track track, List<Waypoint> waypoints) {
    final points = track.points;
    final sorted = [...waypoints]
      ..sort(
        (a, b) => (a.distanceAtPoint ?? double.infinity).compareTo(
          b.distanceAtPoint ?? double.infinity,
        ),
      );
    return Object.hash(
      points.length,
      points.isEmpty ? 0 : points.last.distanceAtPoint,
      sorted.length,
      sorted.isEmpty ? 0 : sorted.first.distanceAtPoint ?? 0,
      sorted.isEmpty ? 0 : sorted.last.distanceAtPoint ?? 0,
    );
  }

  /// Reinicia el progrés (p. ex. en aturar la navegació).
  void resetProgress() {
    currentTrackDistance = direction == TrackDirection.forward
        ? 0.0
        : (_cumulativeDistances.isNotEmpty ? _cumulativeDistances.last : 0.0);
    filteredSpeedMps = 0.0;
    nextWaypointIndex = 0;
    _lastUpdateTime = null;
    _lastTrackDistanceForSpeed = null;
    _lastValidEta = null;
    _lastValidEtaTime = null;
  }

  /// Inverteix el sentit de la navegació.
  ///
  /// NOTA: [reverseImportedTrack] ja reindexa els waypoints i la guia de
  /// forma que la lògica forward segueixi sent vàlida després del gir.
  /// Aquest mètode només reinicia el filtre de velocitat i el progrés, i
  /// queda com a punt d'extensió si mai es vol un reverse "lògic" (sense
  /// reindexar dades).
  void reverseDirection() {
    direction = direction == TrackDirection.forward
        ? TrackDirection.reverse
        : TrackDirection.forward;

    // Reiniciem el filtre de velocitat: el "signe" del delta canvia.
    _lastTrackDistanceForSpeed = null;
    _lastUpdateTime = null;

    // Recalculem el següent waypoint en el nou sentit.
    nextWaypointIndex = 0;
    _advanceWaypointIndex();
  }

  // ─────────────────────────────────────────────────────────────
  // ACTUALITZACIÓ AMB NOVA POSICIÓ GPS
  // ─────────────────────────────────────────────────────────────

  /// Actualitza el motor amb una nova posició GPS i retorna l'estat calculat.
  ///
  /// Opceionalment accepta [averageSpeedMps] (m/s) per a fer servir la velocitat
  /// mitjana en el càlcul de l'ETA.
  TrackNavigationResult updatePosition(
    LatLng gpsPosition, {
    DateTime? time,
    double? averageSpeedMps,
  }) {
    if (!_hasTrack) return TrackNavigationResult.empty;

    final now = time ?? DateTime.now();

    // 1) Projecció del GPS sobre el segment més proper del track guia.
    final projection = _projectOnTrack(gpsPosition);
    currentTrackDistance = projection;

    // 2) Velocitat filtrada a partir del progrés real sobre el track.
    _updateFilteredSpeed(projection, now);

    // 3) Avança l'índex de waypoints (suporta salts de diversos waypoints).
    _advanceWaypointIndex();

    // 4) Waypoint següent i distància restant SEGUINT EL TRACK.
    final Waypoint? next = nextWaypointIndex < _waypoints.length
        ? _waypoints[nextWaypointIndex]
        : null;

    double? remaining;
    if (next != null && next.distanceAtPoint != null) {
      remaining = direction == TrackDirection.forward
          ? next.distanceAtPoint! - currentTrackDistance
          : currentTrackDistance - next.distanceAtPoint!;

      // Rigor: mai negativa; si el soroll GPS ens posa una mica més enllà,
      // considerem que hi som (0 m).
      if (remaining < 0) remaining = 0.0;
    }

    // 5) ETA amb hold: si no es pot calcular (velocitat ~0, salt GPS),
    // mantenim l'últim vàlid durant [etaHoldDuration]. Si no hi ha waypoint
    // (next == null), l'ETA es neteja immediatament: no té sentit mantenir
    // una estimació cap a un waypoint que ja hem superat.
    // Fem servir la velocitat mitjana si s'indica i és vàlida (> minSpeedMps);
    // si no, utilitzem la velocitat filtrada (EMA).
    final speedForEta =
        (averageSpeedMps != null && averageSpeedMps > minSpeedMps)
        ? averageSpeedMps
        : filteredSpeedMps;

    Duration? eta;
    if (remaining != null && speedForEta > minSpeedMps) {
      final seconds = remaining / speedForEta;
      if (seconds.isFinite && seconds >= 0) {
        eta = Duration(seconds: seconds.round());
      }
    }
    eta = _holdOrClearEta(eta, now, clear: next == null);

    return TrackNavigationResult(
      currentTrackDistance: currentTrackDistance,
      nextWaypoint: next,
      distanceToNextWaypoint: remaining,
      eta: eta,
      filteredSpeedMps: filteredSpeedMps,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // INTERNS
  // ─────────────────────────────────────────────────────────────

  /// Avança `nextWaypointIndex` fins al primer waypoint pendent en el sentit
  /// actiu. Monòton: mai retrocedeix. Gestiona salts de diversos waypoints.
  void _advanceWaypointIndex() {
    while (nextWaypointIndex < _waypoints.length) {
      final wp = _waypoints[nextWaypointIndex];
      final wpDist = wp.distanceAtPoint;
      if (wpDist == null) {
        nextWaypointIndex++;
        continue;
      }

      // Eliminem el ' - arrivalThresholdMeters' i el ' + arrivalThresholdMeters'.
      // Ara la condició és neta: distància actual contra distància del waypoint.
      final passed = direction == TrackDirection.forward
          ? currentTrackDistance >= wpDist
          : currentTrackDistance <= wpDist;

      if (!passed) break;
      nextWaypointIndex++;
    }
  }

  /// Manté l'últim ETA vàlid durant [etaHoldDuration] quan el càlcul
  /// retorna null. Si [clear] és cert (p. ex. no queden waypoints), la
  /// memòria s'esborra immediatament.
  Duration? _holdOrClearEta(Duration? eta, DateTime now, {bool clear = false}) {
    if (eta != null) {
      _lastValidEta = eta;
      _lastValidEtaTime = now;
      return eta;
    }
    if (clear) {
      _lastValidEta = null;
      _lastValidEtaTime = null;
      return null;
    }
    final lastEta = _lastValidEta;
    final lastTime = _lastValidEtaTime;
    if (lastEta != null &&
        lastTime != null &&
        now.difference(lastTime) < etaHoldDuration) {
      return lastEta;
    }
    _lastValidEta = null;
    _lastValidEtaTime = null;
    return null;
  }

  /// Velocitat filtrada: EMA sobre |delta distància sobre guia| / delta temps.
  void _updateFilteredSpeed(double newTrackDistance, DateTime now) {
    final lastD = _lastTrackDistanceForSpeed;
    final lastT = _lastUpdateTime;

    _lastTrackDistanceForSpeed = newTrackDistance;
    _lastUpdateTime = now;

    if (lastD == null || lastT == null) return;

    final dt = now.difference(lastT).inMilliseconds / 1000.0;
    if (dt <= 0) return;

    final step = (newTrackDistance - lastD).abs();
    if (step > maxProgressStepMeters) {
      // Salt de GPS: no contaminem el filtre de velocitat.
      return;
    }

    final instantSpeed = step / dt; // m/s

    // Decaienta activa en parada: si l'usuari no avança (step ≈ 0), el
    // filtre ha de caure de seguida per sota del mínim; si no, l'EMA
    // triga massa a decaure i el hold es refrescària contínuament amb
    // ETAs cada cop més grans (infinit a velocitat 0).
    if (instantSpeed < minSpeedMps) {
      filteredSpeedMps = 0.0;
      return;
    }

    filteredSpeedMps = filteredSpeedMps == 0.0
        ? instantSpeed
        : speedEmaAlpha * instantSpeed + (1 - speedEmaAlpha) * filteredSpeedMps;
  }

  /// Projeció eficient del punt sobre la polilínia del track guia.
  /// Retorna la distància acumulada (sobre la guia) del punt projectat.
  double _projectOnTrack(LatLng p) {
    double bestDist = double.infinity;
    double bestAlong = 0.0;

    final int maxSegment = _trackPoints.length - 2;

    // Optimització: finestra al voltant del segment anterior.
    int start = 0;
    int end = maxSegment;
    final prevIdx = _indexForDistance(currentTrackDistance);
    const window = 40; // segments
    start = (prevIdx - window).clamp(0, maxSegment);
    end = (prevIdx + window).clamp(0, maxSegment);

    for (int i = start; i <= end; i++) {
      final a = _trackPoints[i];
      final b = _trackPoints[i + 1];

      final along = _projectOnSegment(p, a, b, _cumulativeDistances[i]);
      final proj = _pointAtDistanceOnSegment(
        a,
        b,
        along,
        _cumulativeDistances[i],
      );

      final d = calculateDistanceManual(
        p.latitude,
        p.longitude,
        proj.latitude,
        proj.longitude,
      );

      if (d < bestDist) {
        bestDist = d;
        bestAlong = along;
      }
    }

    // Fallback: si la finestra no ha trobat res raonable (usuari molt lluny),
    // fem una cerca completa. Això passa en iniciar o en re-enganxar-se.
    if (bestDist > 60.0 && (start > 0 || end < maxSegment)) {
      for (int i = 0; i <= maxSegment; i++) {
        final a = _trackPoints[i];
        final b = _trackPoints[i + 1];

        final along = _projectOnSegment(p, a, b, _cumulativeDistances[i]);
        final proj = _pointAtDistanceOnSegment(
          a,
          b,
          along,
          _cumulativeDistances[i],
        );

        final d = calculateDistanceManual(
          p.latitude,
          p.longitude,
          proj.latitude,
          proj.longitude,
        );

        if (d < bestDist) {
          bestDist = d;
          bestAlong = along;
        }
      }
    }

    return bestAlong;
  }

  /// Índex del punt de la guia amb `distanceAtPoint` immediatament inferior
  /// o igual a [distance]. Cerca binària.
  int _indexForDistance(double distance) {
    if (_cumulativeDistances.isEmpty) return 0;
    int lo = 0, hi = _cumulativeDistances.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_cumulativeDistances[mid] <= distance) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// Retorna la distància acumulada del punt projectat de [p] sobre el
  /// segment [a]-[b], on [baseDistance] és la distància acumulada de [a].
  double _projectOnSegment(LatLng p, LatLng a, LatLng b, double baseDistance) {
    final abx = b.longitude - a.longitude;
    final aby = b.latitude - a.latitude;
    final apx = p.longitude - a.longitude;
    final apy = p.latitude - a.latitude;

    final ab2 = abx * abx + aby * aby;
    double t = 0.0;
    if (ab2 > 0) {
      t = ((apx * abx + apy * aby) / ab2).clamp(0.0, 1.0);
    }

    final segLen = calculateDistanceManual(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );

    return baseDistance + segLen * t;
  }

  /// Punt geogràfic sobre el segment a una distància acumulada donada.
  LatLng _pointAtDistanceOnSegment(
    LatLng a,
    LatLng b,
    double alongDistance,
    double baseDistance,
  ) {
    final segLen = calculateDistanceManual(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
    final t = segLen > 0 ? ((alongDistance - baseDistance) / segLen) : 0.0;
    final clamped = t.clamp(0.0, 1.0);
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * clamped,
      a.longitude + (b.longitude - a.longitude) * clamped,
    );
  }

  bool _isCumulativeValid(List<double> cumulative) {
    if (cumulative.length < 2) return false;
    for (int i = 1; i < cumulative.length; i++) {
      if (cumulative[i] < cumulative[i - 1]) return false;
    }
    return cumulative.last > 0;
  }

  List<double> _buildCumulative(List<LatLng> points) {
    if (points.isEmpty) return const [];
    final result = List<double>.filled(points.length, 0.0);
    double acc = 0.0;
    for (int i = 1; i < points.length; i++) {
      acc += calculateDistanceManual(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
      result[i] = acc;
    }
    return result;
  }
}
