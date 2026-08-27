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
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  Future<void> playOffTrackSound() async {
    try {
      await player.play(
        AssetSource('sound/off_track.mp3'),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing off-track sound: $e");
    }
  }

  Future<void> playBackOnTrackSound() async {
    try {
      await player.play(
        AssetSource('sound/back_on_track.mp3'),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing back-on-track sound: $e");
    }
  }

  Future<void> playReversedTrackSound() async {
    try {
      final fileName = _random.nextInt(2) == 0
          ? 'sound/five_door_knocks.mp3'
          : 'sound/metal_hammer.mp3';

      await player.play(
        AssetSource(fileName),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing reversed-track sound: $e");
    }
  }

  Future<void> playEndTrackSound() async {
    try {
      final fileName = _random.nextInt(2) == 0
          ? 'sound/fireworks.mp3'
          : 'sound/fireworks2.mp3';

      await player.play(
        AssetSource(fileName),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing end-track sound: $e");
    }
  }

  Future<void> playDistanceAlarm() async {
    try {
      await player.play(
        AssetSource('sound/sonar_sound.mp3'),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing distance alarm: $e");
    }
  }

  Future<void> playWaypointAlarm() async {
    try {
      await player.play(
        AssetSource('sound/success_wpt.mp3'),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing waypoint alarm: $e");
    }
  }

  Future<void> playCotaAlarm() async {
    try {
      await player.play(
        AssetSource('sound/owl_sound.mp3'),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing altitude alarm: $e");
    }
  }

  Future<void> playAccumulatedAlarm() async {
    try {
      await player.play(
        AssetSource('sound/cardinal_sound.mp3'),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing altitude alarm: $e");
    }
  }

  Future<void> playTimeAlarm() async {
    try {
      await player.play(
        AssetSource('sound/beep_sound.mp3'),
        volume: _volume,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing time alarm: $e");
    }
  }
}
