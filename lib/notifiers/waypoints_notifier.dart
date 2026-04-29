import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/waypoint.dart';

class WaypointsNotifier extends Notifier<List<Waypoint>> {
  static const _prefsKey = "recorded_waypoints";

  @override
  List<Waypoint> build() {
    // No carreguem res automàticament
    return const [];
  }

  // -----------------------------
  // SET (substituir tota la llista)
  // -----------------------------
  void setWaypoints(List<Waypoint> newList) {
    state = List.unmodifiable(newList);
    _saveToPrefs();
  }

  // -----------------------------
  // ADD
  // -----------------------------
  void add(Waypoint wp) {
    state = [...state, wp];
    _saveToPrefs();
  }

  // -----------------------------
  // REMOVE
  // -----------------------------
  void remove(String id) {
    state = state.where((w) => w.id != id).toList();
    _saveToPrefs();
  }

  // -----------------------------
  // CLEAR
  // -----------------------------
  void clear() {
    state = const [];
    _clearPrefs();
  }

  // ============================================================
  // 🔽 PERSISTÈNCIA A SHAREDPREFERENCES
  // ============================================================

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final list = state
        .map(
          (w) => {
            "id": w.id,
            "name": w.name,
            "lat": w.lat,
            "lon": w.lon,
            "trackIndex": w.trackIndex,
          },
        )
        .toList();

    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  // 🔥 Renombrada i feta pública
  Future<void> restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);

    if (jsonString == null) return;

    final list = jsonDecode(jsonString) as List;

    final loaded = list
        .map(
          (m) => Waypoint(
            id: m["id"],
            name: m["name"],
            lat: m["lat"],
            lon: m["lon"],
            trackIndex: m["trackIndex"],
          ),
        )
        .toList();

    state = List.unmodifiable(loaded);
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  // -----------------------------
  // Helper
  // -----------------------------
  bool get hasSavedWaypoints => state.isNotEmpty;
}

final waypointsProvider = NotifierProvider<WaypointsNotifier, List<Waypoint>>(
  WaypointsNotifier.new,
);
