import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/notifiers/imported_track_notifier.dart';
import 'package:gpxly/notifiers/track_notifier.dart';
import 'package:gpxly/notifiers/selected_track_source_notifier.dart';
import 'package:gpxly/providers/track_source.dart'; // ✔ CORRECTE

class TrackSourceSelectorAppBar extends ConsumerWidget {
  const TrackSourceSelectorAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorded = ref.watch(trackProvider);
    final imported = ref.watch(importedTrackProvider);

    final hasRecorded = recorded.coordinates.isNotEmpty;
    final hasImported = imported != null;

    // 0 tracks → no mostrar res
    if (!hasRecorded && !hasImported) {
      return const SizedBox.shrink();
    }

    // 1 track → seleccionar-lo automàticament i NO mostrar selector
    if (hasRecorded ^ hasImported) {
      ref
          .read(selectedTrackSourceProvider.notifier)
          .forceSelectSingle(
            hasRecorded: hasRecorded,
            hasImported: hasImported,
          );

      return const SizedBox.shrink();
    }

    // 2 tracks → mostrar selector
    final selected = ref.watch(selectedTrackSourceProvider);

    return PopupMenuButton<TrackSource>(
      icon: const Icon(Icons.swap_horiz, color: Colors.white),
      initialValue: selected,
      onSelected: (value) {
        ref.read(selectedTrackSourceProvider.notifier).select(value);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: TrackSource.recorded, child: Text("Track gravat")),
        PopupMenuItem(
          value: TrackSource.imported,
          child: Text("Track importat"),
        ),
      ],
    );
  }
}
