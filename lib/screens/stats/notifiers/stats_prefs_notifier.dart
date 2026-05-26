import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsPrefsState {
  final List<String> order; // 🔥 L'ordre de les targetes
  final Map<String, int> indices; // Els índexs del carousel de cada targeta
  final bool isInitialized;

  StatsPrefsState({
    this.order = const ['dist', 'time', 'speed', 'alt'],
    this.indices = const {'dist': 0, 'time': 0, 'speed': 0, 'alt': 0},
    this.isInitialized = false,
  });

  StatsPrefsState copyWith({
    List<String>? order,
    Map<String, int>? indices,
    bool? isInitialized,
  }) {
    return StatsPrefsState(
      order: order ?? this.order,
      indices: indices ?? this.indices,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class StatsPrefsNotifier extends Notifier<StatsPrefsState> {
  @override
  StatsPrefsState build() {
    _loadPrefs();
    return StatsPrefsState();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Carreguem l'ordre (si no n'hi ha, usem el de defecte)
    final savedOrder =
        prefs.getStringList('stats_order') ?? ['dist', 'time', 'speed', 'alt'];

    final savedIndices = {
      'dist': prefs.getInt('stats_dist_idx') ?? 0,
      'time': prefs.getInt('stats_time_idx') ?? 0,
      'speed': prefs.getInt('stats_speed_idx') ?? 0,
      'alt': prefs.getInt('stats_alt_idx') ?? 0,
    };

    state = state.copyWith(
      order: savedOrder,
      indices: savedIndices,
      isInitialized: true,
    );
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;

    final newList = List<String>.from(state.order);
    final String item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);

    state = state.copyWith(order: newList);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('stats_order', newList);
  }

  Future<void> setCarouselIdx(String key, int val) async {
    final newIndices = Map<String, int>.from(state.indices);
    newIndices[key] = val;
    state = state.copyWith(indices: newIndices);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stats_${key}_idx', val);
  }
}

final statsPrefsProvider =
    NotifierProvider<StatsPrefsNotifier, StatsPrefsState>(
      StatsPrefsNotifier.new,
    );
