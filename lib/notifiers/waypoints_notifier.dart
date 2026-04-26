import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/waypoint.dart';

class WaypointsNotifier extends Notifier<List<Waypoint>> {
  @override
  List<Waypoint> build() {
    return const []; // estat inicial
  }

  // -----------------------------
  // ADD
  // -----------------------------
  void add(Waypoint wp) {
    state = [...state, wp];
  }

  // -----------------------------
  // REMOVE
  // -----------------------------
  void remove(String id) {
    state = state.where((w) => w.id != id).toList();
  }

  // -----------------------------
  // CLEAR
  // -----------------------------
  void clear() {
    state = const [];
  }
}

final waypointsProvider = NotifierProvider<WaypointsNotifier, List<Waypoint>>(
  WaypointsNotifier.new,
);
