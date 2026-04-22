import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class TrackSounds {
  final AudioPlayer player = AudioPlayer();
  final Random _random = Random();

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
        volume: 1.0,
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
        volume: 1.0,
        ctx: _alarmContext,
      );
    } catch (e) {
      print("Error playing back-on-track sound: $e");
    }
  }

  Future<void> playReversedTrackSound() async {
    try {
      await player.play(
        AssetSource('sound/snap_fingers.mp3'),
        volume: 1.0,
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

      await player.play(AssetSource(fileName), volume: 1.0, ctx: _alarmContext);
    } catch (e) {
      print("Error playing end-track sound: $e");
    }
  }
}
