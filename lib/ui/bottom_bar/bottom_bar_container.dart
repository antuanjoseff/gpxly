import 'package:flutter/material.dart';
import 'package:gpxly/models/track.dart';
import 'package:gpxly/theme/app_colors.dart';
import 'bottom_bar_buttons.dart';

class BottomBarContainer extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final RecordingState state;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final Widget importButton;

  const BottomBarContainer({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.state,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.importButton,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        padding: EdgeInsets.fromLTRB(
          16,
          5,
          16,
          MediaQuery.of(context).padding.bottom + 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            if (isExpanded) ...[
              const SizedBox(height: 8),
              BottomBarButtons(
                state: state,
                onStart: onStart,
                onPause: onPause,
                onResume: onResume,
                onStop: onStop,
                importButton: importButton,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
