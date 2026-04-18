import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;

  void clear() => state = false;
}

final settingsPendingProvider = NotifierProvider<SettingsPendingNotifier, bool>(
  SettingsPendingNotifier.new,
);

class GpsPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
  void clear() => state = false;
}

final gpsPendingProvider = NotifierProvider<GpsPendingNotifier, bool>(
  GpsPendingNotifier.new,
);

class GpxPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
  void clear() => state = false;
}

final gpxPendingProvider = NotifierProvider<GpxPendingNotifier, bool>(
  GpxPendingNotifier.new,
);

class TrackPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
  void clear() => state = false;
}

final trackPendingProvider = NotifierProvider<TrackPendingNotifier, bool>(
  TrackPendingNotifier.new,
);

class ImportedTrackPendingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mark() => state = true;
  void clear() => state = false;
}

final importedTrackPendingProvider =
    NotifierProvider<ImportedTrackPendingNotifier, bool>(
      ImportedTrackPendingNotifier.new,
    );
