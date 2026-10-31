import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

class TrackSounds {
  final AudioPlayer player = AudioPlayer();
  final Random _random = Random();
  double _volume = 1.0;

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  static final _alarmContext = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.alarm,
      contentType: AndroidContentType.music,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  // Sense gestió de focus, una trucada no deixa el reproductor aturat; abans
  // de cada so es reinicia l'estat per recuperar-se d'una interrupció.
  Future<void> _play(Source source) async {
    try {
      await player.stop();
    } catch (_) {}
    await player.setAudioContext(_alarmContext);
    await player.play(source, volume: _volume, ctx: _alarmContext);
  }

  Future<void> playOffTrackSound() async {
    try {
      await _play(AssetSource('sound/off_track.mp3'));
    } catch (e) {
      print("Error playing off-track sound: $e");
    }
  }

  Future<void> playBackOnTrackSound() async {
    try {
      await _play(AssetSource('sound/back_on_track.mp3'));
    } catch (e) {
      print("Error playing back-on-track sound: $e");
    }
  }

  Future<void> playReversedTrackSound() async {
    try {
      final fileName = _random.nextInt(2) == 0
          ? 'sound/five_door_knocks.mp3'
          : 'sound/metal_hammer.mp3';

      await _play(AssetSource(fileName));
    } catch (e) {
      print("Error playing reversed-track sound: $e");
    }
  }

  Future<void> playEndTrackSound() async {
    try {
      final fileName = _random.nextInt(2) == 0
          ? 'sound/fireworks.mp3'
          : 'sound/fireworks2.mp3';

      await _play(AssetSource(fileName));
    } catch (e) {
      print("Error playing end-track sound: $e");
    }
  }

  Future<void> playDistanceAlarm() async {
    try {
      await _play(AssetSource('sound/sonar_sound.mp3'));
    } catch (e) {
      print("Error playing distance alarm: $e");
    }
  }

  Future<void> playWaypointAlarm() async {
    try {
      await _play(AssetSource('sound/success_wpt.mp3'));
    } catch (e) {
      print("Error playing waypoint alarm: $e");
    }
  }

  Future<void> playCotaAlarm() async {
    try {
      await _play(AssetSource('sound/owl_sound.mp3'));
    } catch (e) {
      print("Error playing altitude alarm: $e");
    }
  }

  Future<void> playAccumulatedAlarm() async {
    try {
      await _play(AssetSource('sound/cardinal_sound.mp3'));
    } catch (e) {
      print("Error playing altitude alarm: $e");
    }
  }

  Future<void> playTimeAlarm() async {
    try {
      await _play(AssetSource('sound/beep_sound.mp3'));
    } catch (e) {
      print("Error playing time alarm: $e");
    }
  }
}
