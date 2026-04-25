import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpxly/l10n/app_localizations.dart'; // 👈 AFEGIT PER L10N
import 'package:gpxly/models/track.dart';
import 'package:gpxly/notifiers/track_follow_notifier.dart';
import 'bottom_bar_buttons.dart';

class BottomBarContainer extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final RecordingState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final bool hasImportedTrack;
  final VoidCallback onImportTrack;
  final VoidCallback onFollowTrack;
  final bool isFollowingTrack;

  const BottomBarContainer({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onImportTrack,
    required this.onFollowTrack,
    required this.hasImportedTrack,
    required this.isFollowingTrack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!; // 👈 OBTENIM TRADUCCIONS

    final followState = ref.watch(trackFollowNotifierProvider);
    final bool isFollowPaused = followState.isPaused;

    final bool isRecording = state == RecordingState.recording;
    final bool isPausedRec = state == RecordingState.paused;

    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    if (!isExpanded)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatusIndicator(
                            visible: isRecording || isPausedRec,
                            label: isPausedRec
                                ? t.paused.toUpperCase()
                                : t.recording.toUpperCase(), // 👈 MULTILANG
                            color: Colors.red,
                            showDot: isRecording,
                          ),
                          _StatusIndicator(
                            visible: isFollowingTrack,
                            label: isFollowPaused
                                ? t.followPaused
                                      .toUpperCase() // 👈 MULTILANG
                                : t.following.toUpperCase(), // 👈 MULTILANG
                            color: Colors.blue,
                            showDot: isFollowingTrack && !isFollowPaused,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                child: BottomBarButtons(
                  state: state,
                  onStart: onStart,
                  onPause: onPause,
                  onResume: onResume,
                  onStop: onStop,
                  onImportTrack: onImportTrack,
                  onFollowTrack: onFollowTrack,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool visible;
  final String label;
  final Color color;
  final bool showDot;

  const _StatusIndicator({
    required this.visible,
    required this.label,
    required this.color,
    required this.showDot,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
