import 'package:flutter_riverpod/flutter_riverpod.dart';

class WaypointDrawingNotifier extends Notifier<bool> {
  @override
  bool build() => false; // per defecte NO dibuixar waypoints

  void enable() => state = true;
  void disable() => state = false;
}

final waypointDrawingProvider = NotifierProvider<WaypointDrawingNotifier, bool>(
  WaypointDrawingNotifier.new,
);
