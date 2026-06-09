// lib/screens/main_map/widgets/map_action_speed_dial.dart (Bloc 1 de 2)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/screens/settings/settings_screen.dart';

class MapActionSpeedDial extends ConsumerStatefulWidget {
  final bool isChartCollapsed;
  final double systemBottomPadding;
  final VoidCallback onOpenRecordingControl;
  final void Function(bool) onOpenNavigationControl;
  final void Function(String?) onHandleNavigationAction;

  const MapActionSpeedDial({
    super.key,
    required this.isChartCollapsed,
    required this.systemBottomPadding,
    required this.onOpenRecordingControl,
    required this.onOpenNavigationControl,
    required this.onHandleNavigationAction,
  });

  @override
  ConsumerState<MapActionSpeedDial> createState() => _MapActionSpeedDialState();
}

class _MapActionSpeedDialState extends ConsumerState<MapActionSpeedDial>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;

  // ⏱️ Control del temporitzador de tancament retardat
  Timer? _menuDelayedCloseTimer;

  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      value: 0.0,
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _menuDelayedCloseTimer?.cancel(); // Netegem el temporitzador de seguretat
    super.dispose();
  }

  void _toggleMenu() {
    _menuDelayedCloseTimer
        ?.cancel(); // Cancel·lem qualsevol tancament pendent si l'usuari prem l'hamburguesa manualment
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // 🎯 FUNCIÓ NOVA: Força un retard de 3 segons exactes abans de tancar de forma animada
  void _toggleMenuWithDelay() {
    _menuDelayedCloseTimer?.cancel();
    _menuDelayedCloseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isMenuOpen) {
        setState(() {
          _isMenuOpen = false;
          _animationController.reverse();
        });
      }
    });
  }

  // lib/screens/main_map/widgets/map_action_speed_dial.dart (Bloc 2 de 2)
  @override
  Widget build(BuildContext context) {
    final dynamic rawTrack = ref.watch(importedTrackProvider);
    final navState = ref.watch(navigationProvider);
    final recordingState = ref.watch(
      trackRecordingProvider.select((t) => t.recordingState),
    );

    bool hasTrack = false;
    if (rawTrack != null && rawTrack is Track) {
      try {
        hasTrack = rawTrack.coordinates.isNotEmpty;
      } catch (_) {
        hasTrack = false;
      }
    }

    final double effectivePadding = widget.systemBottomPadding > 0
        ? widget.systemBottomPadding
        : 16.0;
    double bottomPosition;

    if (!hasTrack && recordingState == RecordingState.idle) {
      bottomPosition = effectivePadding + 12.0;
    } else if (widget.isChartCollapsed) {
      bottomPosition = 38.0 + effectivePadding + 12.0;
    } else {
      bottomPosition = 220.0 + effectivePadding + 12.0;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      bottom: bottomPosition,
      right: 12,
      child: _buildPureStateMachineUI(hasTrack, navState, recordingState),
    );
  }

  Widget _buildPureStateMachineUI(
    bool hasTrack,
    dynamic navState,
    RecordingState recordingState,
  ) {
    final bool isRecordingRunning =
        recordingState == RecordingState.recording ||
        recordingState == RecordingState.paused;
    final bool isFollowingActive = navState.isFollowing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Column(
            children: [
              // 🔴 SUB-BOTÓ 1: CONTROL DE GRAVACIÓ DE RUTA
              _buildMiniMenuButton(
                icon: isRecordingRunning
                    ? Icons.pause_circle_outline_rounded
                    : Icons.fiber_manual_record_rounded,
                color: isRecordingRunning ? Colors.amber : Colors.red,
                onTap: () {
                  _toggleMenuWithDelay(); // 🎯 MODIFICAT: Tancament retardat de 3 segons
                  widget.onOpenRecordingControl();
                },
              ),
              const SizedBox(height: 10),

              // 🧭 SUB-BOTÓ 2: NAVEGACIÓ I UPLOAD GPX
              _buildMiniMenuButton(
                icon: !hasTrack
                    ? Icons.file_upload_outlined
                    : (isFollowingActive
                          ? Icons.pause_circle_filled_rounded
                          : Icons.explore_rounded),
                color: !hasTrack
                    ? Colors.blue
                    : (isFollowingActive
                          ? Colors.orange.shade800
                          : Colors.cyan),
                onTap: () {
                  _toggleMenuWithDelay(); // 🎯 MODIFICAT: Tancament retardat de 3 segons

                  if (!hasTrack) {
                    widget.onOpenNavigationControl(false);
                  } else if (!isFollowingActive) {
                    widget.onOpenNavigationControl(true);
                  } else {
                    widget.onOpenNavigationControl(true);
                  }
                },
              ),
              const SizedBox(height: 10),

              // ⚙️ SUB-BOTÓ 3: AJUSTOS DE CAPA
              _buildMiniMenuButton(
                icon: Icons.settings_outlined,
                color: AppColors.primary,
                onTap: () {
                  _toggleMenuWithDelay(); // 🎯 MODIFICAT: Tancament retardat de 3 segons
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // 🍔 BOTÓ PRINCIPAL DE CONTROL: Hamburguesa Inmutable de 52px (Obre/Tanca)
        GestureDetector(
          onTap: _toggleMenu,
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tertiary,
            ),
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _expandAnimation,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMenuButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
