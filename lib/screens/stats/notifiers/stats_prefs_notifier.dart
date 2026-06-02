import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsPrefsState {
  final List<String> order;
  final Map<String, int> indices; // Els índexs del carousel de cada targeta
  final bool isInitialized;

  StatsPrefsState({
    // 🛰️ Afegit 'gps' a la llista total per defecte (ara són 6 targetes)
    this.order = const ['dist', 'time', 'speed', 'alt', 'coords', 'gps'],
    this.indices = const {
      'dist': 0,
      'time': 0,
      'speed': 0,
      'alt': 0,
      'coords': 0,
      'gps': 0,
    },
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

    // 1. Carreguem l'ordre incloent 'gps' al valor de rescat per defecte
    List<String> savedOrder =
        prefs.getStringList('stats_order') ??
        ['dist', 'time', 'speed', 'alt', 'coords', 'gps'];

    // 🚀 BLINDATGE CORE: Si el telèfon ja tenia una llista antiga (de 4 o 5 elements),
    // hi afegim 'gps' automàticament al final i actualitzem el disc perquè es dibuixi de seguida.
    bool needsSave = false;
    if (!savedOrder.contains('coords')) {
      savedOrder = [...savedOrder, 'coords'];
      needsSave = true;
    }
    if (!savedOrder.contains('gps')) {
      savedOrder = [...savedOrder, 'gps'];
      needsSave = true;
    }

    if (needsSave) {
      await prefs.setStringList('stats_order', savedOrder);
    }

    // Carreguem tots els índexs individuals de SharedPreferences
    final savedIndices = {
      'dist': prefs.getInt('stats_dist_idx') ?? 0,
      'time': prefs.getInt('stats_time_idx') ?? 0,
      'speed': prefs.getInt('stats_speed_idx') ?? 0,
      'alt': prefs.getInt('stats_alt_idx') ?? 0,
      'coords': prefs.getInt('stats_coords_idx') ?? 0,
      'gps':
          prefs.getInt('stats_gps_idx') ??
          0, // 👈 Registre dinàmic desat a disc
    };

    state = state.copyWith(
      order: savedOrder,
      indices: savedIndices,
      isInitialized: true,
    );
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
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
