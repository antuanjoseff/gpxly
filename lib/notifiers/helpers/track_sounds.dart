import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class TrackSounds {
  final AudioPlayer player = AudioPlayer();

  final Random _random = Random();

  Future<void> playOffTrackSound() async {
    try {
      await player.play(AssetSource('sound/off_track.mp3'), volume: 1.0);
    } catch (e) {
      print("Error playing off-track sound: $e");
    }
  }

  Future<void> playBackOnTrackSound() async {
    try {
      await player.play(AssetSource('sound/back_on_track.mp3'), volume: 1.0);
    } catch (e) {
      print("Error playing back-on-track sound: $e");
    }
  }

  Future<void> playEndTrackSound() async {
    try {
      // Genera un 0 o un 1 de forma aleatòria
      // Si és 0, usa fireworks.mp3; si és 1, usa fireworks2.mp3
      String fileName = _random.nextInt(2) == 0
          ? 'sound/fireworks.mp3'
          : 'sound/fireworks2.mp3';

      await player.play(AssetSource(fileName), volume: 1.0);
    } catch (e) {
      print("Error playing end-track sound: $e");
    }
  }
}
