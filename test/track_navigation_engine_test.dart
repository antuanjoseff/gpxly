// test/track_navigation_engine_test.dart
//
// Tests del motor de navegació: projecció sobre la guia, waypoint següent
// només endavant, salts de GPS, ETA i reverse.

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:strack_rec/models/track.dart';
import 'package:strack_rec/models/user_position.dart';
import 'package:strack_rec/models/waypoint.dart';
import 'package:strack_rec/services/track_navigation_engine.dart';

/// Construeix una guia recta de ~1111 m (0.01° lat) amb N punts.
Track _buildGuide({int points = 11, double totalMeters = 1000}) {
  final stepMeters = totalMeters / (points - 1);
  // 1° lat ≈ 111320 m
  final stepDeg = stepMeters / 111320.0;
  final now = DateTime(2026, 1, 1, 10);

  final pts = <UserPosition>[];
  for (int i = 0; i < points; i++) {
    pts.add(
      UserPosition(
        position: LatLng(41.0 + stepDeg * i, 2.0),
        altitude: 100,
        isHgtFixed: false,
        timestamp: now.add(Duration(seconds: i * 10)),
        accuracy: 5,
        vAccuracy: 5,
        speed: 1.0,
        heading: 0,
        satellites: 10,
        distanceAtPoint: stepMeters * i,
      ),
    );
  }

  return Track(
    points: pts,
    recordingState: RecordingState.idle,
    stats: TrackStats(
      duration: Duration.zero,
      stoppedDuration: Duration.zero,
      distance: totalMeters,
      ascent: 0,
      descent: 0,
      maxElevation: 0,
      minElevation: 0,
      averageSpeed: 0,
      maxSpeed: 0,
      minLat: 0,
      maxLat: 0,
      minLon: 0,
      maxLon: 0,
    ),
  );
}

Waypoint _wp(String id, double meters, double lat) => Waypoint(
  id: id,
  name: id,
  lat: lat,
  lon: 2.0,
  trackIndex: 0, // irrellevant per al motor
  distanceAtPoint: meters,
);

void main() {
  group('TrackNavigationEngine', () {
    test(
      'waypoint següent només endavant: els que queden enrere s\'ignoren',
      () {
        final guide = _buildGuide();
        // Waypoints a 300 m i 700 m.
        final wps = [_wp('wp1', 300, 41.0027), _wp('wp2', 700, 41.0063)];

        final engine = TrackNavigationEngine()
          ..configure(track: guide, waypoints: wps);

        // Usuari a ~500 m (punt 5). Ha passat wp1; el següent ha de ser wp2.
        final t = DateTime(2026, 1, 1, 12);
        var r = engine.updatePosition(guide.points[5].position, time: t);
        expect(r.nextWaypoint?.id, 'wp2');
        expect(r.distanceToNextWaypoint, closeTo(200, 30));

        // Velocitat: segon update 10 s després, 100 m més endavant → 10 m/s.
        // NOTA: el primer update inicialitza el filtre (velocitat 0); el segon
        // calcula la velocitat real. Però 100 m > maxProgressStepMeters (80) →
        // es descarta com a salt GPS. Fem un pas de 50 m en 5 s → 10 m/s.
        r = engine.updatePosition(
          guide.points[5].position,
          time: t.add(const Duration(seconds: 1)),
        );
        r = engine.updatePosition(
          LatLng(
            guide.points[5].position.latitude +
                (guide.points[6].position.latitude -
                        guide.points[5].position.latitude) *
                    0.5,
            2.0,
          ),
          time: t.add(const Duration(seconds: 6)),
        );
        expect(r.filteredSpeedMps, greaterThan(5));
        expect(r.eta, isNotNull);
        expect(r.eta!.inSeconds, lessThan(60));
      },
    );

    test('salt de GPS que supera diversos waypoints', () {
      final guide = _buildGuide();
      final wps = [_wp('wp1', 300, 41.0027), _wp('wp2', 700, 41.0063)];
      final engine = TrackNavigationEngine()
        ..configure(track: guide, waypoints: wps);

      // Salt directe a 900 m: tots dos waypoints queden superats.
      final r = engine.updatePosition(guide.points[9].position);
      expect(r.nextWaypoint, isNull);
      expect(r.eta, isNull);
    });

    test('ETA null quan la velocitat és ~0 (sense ETA previ)', () {
      final guide = _buildGuide();
      final wps = [_wp('wp1', 500, 41.0045)];
      final engine = TrackNavigationEngine()
        ..configure(track: guide, waypoints: wps);

      final t = DateTime(2026, 1, 1, 12);
      // Dues lectures a la mateixa posició → velocitat 0, sense ETA previ.
      engine.updatePosition(guide.points[2].position, time: t);
      final r = engine.updatePosition(
        guide.points[2].position,
        time: t.add(const Duration(seconds: 5)),
      );
      expect(r.eta, isNull);
      expect(r.nextWaypoint?.id, 'wp1');
    });

    test('hold: para curta manté l\'últim ETA, parada llarga el neteja', () {
      final guide = _buildGuide();
      final wps = [_wp('wp1', 700, 41.0063)];
      final engine = TrackNavigationEngine()
        ..configure(track: guide, waypoints: wps);

      final t = DateTime(2026, 1, 1, 12);
      // Moviment: 400 m → 450 m en 5 s = 10 m/s → ETA vàlid.
      engine.updatePosition(guide.points[4].position, time: t);
      final moving = engine.updatePosition(
        LatLng(
          (guide.points[4].position.latitude +
                  guide.points[5].position.latitude) /
              2,
          2.0,
        ),
        time: t.add(const Duration(seconds: 5)),
      );
      expect(moving.eta, isNotNull);

      // Para curta: l'usuari s'atura bruscament (varis updates a la mateixa
      // posició → velocitat instantània 0 → l'EMA cau per sota del mínim i
      // l'ETA calculat és null). El hold (8 s) manté l'últim ETA vàlid.
      var stopped = engine.updatePosition(
        guide.points[4].position,
        time: t.add(const Duration(seconds: 6)),
      );
      stopped = engine.updatePosition(
        guide.points[4].position,
        time: t.add(const Duration(seconds: 10)),
      );
      expect(stopped.eta, isNotNull);

      // Para llarga: seguim aturats molt més temps (> 8 s sense ETA nou):
      // el hold expira i l'ETA s'esborra.
      stopped = engine.updatePosition(
        guide.points[4].position,
        time: t.add(const Duration(seconds: 15)),
      );
      stopped = engine.updatePosition(
        guide.points[4].position,
        time: t.add(const Duration(seconds: 20)),
      );
      stopped = engine.updatePosition(
        guide.points[4].position,
        time: t.add(const Duration(seconds: 25)),
      );
      stopped = engine.updatePosition(
        guide.points[4].position,
        time: t.add(const Duration(seconds: 30)),
      );
      stopped = engine.updatePosition(
        guide.points[4].position,
        time: t.add(const Duration(seconds: 40)),
      );
      stopped = engine.updatePosition(
        guide.points[4].position,
        time: t.add(const Duration(seconds: 50)),
      );
      expect(stopped.eta, isNull);
    });

    test('sempre sobre la guia: la posició es projecta, no s\'indexa', () {
      final guide = _buildGuide();
      final wps = [_wp('wp1', 550, 41.005)];
      final engine = TrackNavigationEngine()
        ..configure(track: guide, waypoints: wps);

      // Posició exacta a mig camí entre el punt 4 (400 m) i el 5 (500 m).
      final a = guide.points[4].position;
      final b = guide.points[5].position;
      final mid = LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );
      final r = engine.updatePosition(mid);
      expect(r.currentTrackDistance, closeTo(450, 60));
      expect(r.distanceToNextWaypoint, closeTo(100, 60));
    });
  });
}
