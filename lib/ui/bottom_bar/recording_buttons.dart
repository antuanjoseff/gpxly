// lib/widgets/recording_buttons.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
// ✅ ADAPTAT: Importem el nou proveïdor analític de navegació de la branca
import 'package:senda/notifiers/navigation_notifier.dart'; // Bloc 3: Lògica de seguiment
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/track_base_button.dart';

class RecordingButtons extends ConsumerWidget {
  final VoidCallback onPause;
  final VoidCallback onImportTrack;
  final VoidCallback onFollowTrack;

  const RecordingButtons({
    super.key,
    required this.onPause,
    required this.onImportTrack,
    required this.onFollowTrack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;

    // ✅ ADAPTAT: Escoltem el nou navigationProvider de la branca
    final navigationState = ref.watch(navigationProvider);
    final imported = ref.watch(importedTrackProvider);

    // ✅ OPTIMITZAT: Mirem directament la llista compacta de punts inmutables
    final hasImported = imported != null && imported.points.isNotEmpty;

    return Row(
      children: [
        // PAUSA
        Expanded(
          child: TrackBaseButton(
            color: AppColors.secondary,
            onPressed: onPause,
            icon: Icons.pause,
            text: t.pause,
          ),
        ),

        const SizedBox(width: 12),

        // SI NO HI HA TRACK IMPORTAT → MOSTRAR IMPORTAR
        if (!hasImported)
          Expanded(
            child: TrackBaseButton(
              color: AppColors.secondary,
              onPressed: onImportTrack,
              icon: Icons.route,
              text: "Track",
            ),
          ),

        // SI HI HA TRACK IMPORTAT → MOSTRAR SEGUIR / ATURA SEGUIMENT
        if (hasImported)
          Expanded(
            child: TrackBaseButton(
              // ✅ ADAPTAT: Commuta el color i l'icona segons els flags del NavigationState unificat
              color: navigationState.isFollowing
                  ? AppColors.alert
                  : AppColors.tertiary,
              onPressed: onFollowTrack,
              icon: navigationState.isFollowing
                  ? Icons.close
                  : Icons.navigation,
              text: navigationState.isFollowing ? t.stopFollowing : t.follow,
            ),
          ),
      ],
    );
  }
}
