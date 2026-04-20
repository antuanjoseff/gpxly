import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class TrackSounds {
  final AudioPlayer player = AudioPlayer();

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
      await player.play(AssetSource('sound/fireworks.mp3'), volume: 1.0);
    } catch (e) {
      print("Error playing end-track sound: $e");
    }
  }
}
