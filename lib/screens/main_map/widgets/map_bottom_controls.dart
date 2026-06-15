// lib/screens/main_map/widgets/map_bottom_controls.dart (BLOC 1 DE 2)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/navigation_state.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/screens/settings/settings_screen.dart';
import 'package:senda/theme/app_colors.dart';
import 'package:senda/widgets/embedded_elevation_profile.dart';

class MapBottomControls extends ConsumerStatefulWidget {
  final bool isChartCollapsed;
  final double systemBottomPadding;
  final VoidCallback onAddWaypoint;
  final VoidCallback onOpenRecordingControl;
  final void Function(bool) onOpenNavigationControl;
  final void Function(String?) onHandleNavigationAction;
  final VoidCallback onToggleChart;

  const MapBottomControls({
    super.key,
    required this.isChartCollapsed,
    required this.systemBottomPadding,
    required this.onAddWaypoint,
    required this.onOpenRecordingControl,
    required this.onOpenNavigationControl,
    required this.onHandleNavigationAction,
    required this.onToggleChart,
  });

  @override
  ConsumerState<MapBottomControls> createState() => _MapBottomControlsState();
}

class _MapBottomControlsState extends ConsumerState<MapBottomControls> {
  bool _showRecordingSubMenu = false;
  bool _showNavigationSubMenu = false;

  @override
  Widget build(BuildContext context) {
    final importedTrack = ref.watch(importedTrackProvider);
    final navState = ref.watch(navigationProvider);
    final recordingState = ref.watch(
      trackRecordingProvider.select((t) => t.recordingState),
    );

    final bool hasTrack =
        importedTrack != null && importedTrack.coordinates.isNotEmpty;
    final bool isPanelActiveOnScreen =
        hasTrack || recordingState != RecordingState.idle;

    // Definim si el perfil d'elevacions s'està mostrant a la pantalla
    final bool isChartVisible = isPanelActiveOnScreen;

    // 🔴 Traducció de textos i icones de Gravació
    String recordingLabel = "Gravar";
    IconData recordingIcon = Icons.fiber_manual_record_outlined;
    Color recordingColor = Colors.white;

    if (recordingState == RecordingState.recording) {
      recordingLabel = "Gravant...";
      recordingIcon = Icons.fiber_manual_record;
      recordingColor = Colors.red;
    } else if (recordingState == RecordingState.paused) {
      recordingLabel = "Pausat";
      recordingIcon = Icons.pause_circle_filled_rounded;
      recordingColor = Colors.amber;
    }

    // 🧭 TRADUCCIÓ RECTIFICADA: Estats de la pestanya de Seguiment
    String navigationLabel = "Carregar track";
    IconData navigationIcon =
        Icons.file_upload_outlined; // 🟢 NOVA: Icona d'upload si no hi ha track
    Color navigationColor = Colors.white;
    if (hasTrack && !navState.isFollowing) {
      // Un cop importat el gpx, el text canvia a "Seguir" i commuta a la brúixola
      navigationLabel = "Seguir";
      navigationIcon = Icons.explore_outlined;
      navigationColor = Colors.white; // 🟢 FORÇAT EN BLANC
    } else if (navState.isFollowing) {
      if (navState.isPaused) {
        navigationLabel = "Pausat";
        navigationIcon = Icons.explore_outlined;
        navigationColor = Colors.white; // 🟢 FORÇAT EN BLANC
      } else {
        navigationLabel = "Seguint...";
        navigationIcon = Icons.explore; // Brúixola plena en moviment
        navigationColor = Colors.white; // 🟢 FORÇAT EN BLANC
      }
    }

    // Condició: Si el submenú està obert, apliquem opacitat i desactivem esdeveniments al gràfic
    final bool isAnySubMenuOpen =
        _showRecordingSubMenu || _showNavigationSubMenu;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 📊 CAPA A: GRÀFIC D'ELEVACIONS - ENGANXAT AL MENÚ
          if (isPanelActiveOnScreen)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isAnySubMenuOpen ? 0.35 : 1.0,
              child: IgnorePointer(
                ignoring: isAnySubMenuOpen,
                child: Container(
                  width: MediaQuery.of(context).size.width,

                  // 🟢 SOLUCIÓN AL OVERFLOW: Eliminamos por completo la suma del 'systemBottomPadding'
                  // de la altura del contenedor del gráfico. Al ser un Column, el SafeArea del menú
                  // inferior ya empuja todo el bloque hacia arriba de forma nativa.
                  height: null,

                  color: Colors.transparent,
                  child: EmbeddedElevationProfile(
                    key: const ValueKey(
                      'embedded_elevation_profile_fix_peanya',
                    ),
                    isCollapsed: widget.isChartCollapsed,
                    onToggle: widget.onToggleChart,
                  ),
                ),
              ),
            ),

          // 📱 CAPA B: SUB-MENÚS CONTEXTUALS
          if (_showRecordingSubMenu) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildRecordingSubMenu(context, recordingState),
            ),
            const SizedBox(height: 8),
          ],
          if (_showNavigationSubMenu) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildNavigationSubMenu(context, hasTrack, navState),
            ),
            const SizedBox(height: 8),
          ],

          // 📱 MENÚ INFERIOR ENGANCHAT AL GRÀFIC - SENSE GAPS
          Container(
            color: AppColors
                .primary, // Fons sòlid que va de punta a punta del telèfon [INDEX]
            child: SafeArea(
              top:
                  false, // Només protegim el topall inferior del SafeArea (barres d'iOS/Android) [INDEX]
              child: Container(
                height: 64,
                width: double.infinity,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white12, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMenuTab(
                      icon: recordingIcon,
                      label: recordingLabel,
                      iconColor: recordingColor,
                      onTap: () {
                        setState(() {
                          _showRecordingSubMenu = !_showRecordingSubMenu;
                          _showNavigationSubMenu = false;
                        });
                      },
                    ),
                    const VerticalDivider(
                      color: Colors.white12,
                      indent: 16,
                      endIndent: 16,
                      width: 1,
                    ),
                    _buildMenuTab(
                      icon: navigationIcon,
                      label: navigationLabel,
                      iconColor: navigationColor,
                      onTap: () {
                        setState(() {
                          _showNavigationSubMenu = !_showNavigationSubMenu;
                          _showRecordingSubMenu = false;
                        });
                      },
                    ),
                    const VerticalDivider(
                      color: Colors.white12,
                      indent: 16,
                      endIndent: 16,
                      width: 1,
                    ),
                    _buildMenuTab(
                      icon: Icons.settings_outlined,
                      label: "Ajustos",
                      iconColor: Colors.white,
                      onTap: () {
                        setState(() {
                          _showRecordingSubMenu = false;
                          _showNavigationSubMenu = false;
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // � MÈTODE AUXILIAR: SUB-MENÚ DE CONTROL DE GRAVACIÓ
  Widget _buildRecordingSubMenu(BuildContext context, RecordingState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (state == RecordingState.idle)
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.greenAccent,
                  size: 24,
                ),
                label: const Text(
                  "Iniciar gravació",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() => _showRecordingSubMenu = false);
                  widget.onOpenRecordingControl();
                },
              ),
            ),
          if (state == RecordingState.recording) ...[
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.pause_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
                label: const Text(
                  "Pausar",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  setState(() => _showRecordingSubMenu = false);
                  widget.onOpenRecordingControl();
                },
              ),
            ),
            const VerticalDivider(
              color: Colors.white12,
              indent: 8,
              endIndent: 8,
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.stop_rounded,
                  color: AppColors.redAlert,
                  size: 22,
                ),
                label: const Text(
                  "Finalitzar",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  setState(() => _showRecordingSubMenu = false);
                  widget.onOpenRecordingControl();
                },
              ),
            ),
          ],
          if (state == RecordingState.paused) ...[
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.greenAccent,
                  size: 22,
                ),
                label: const Text(
                  "Reprendre",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  setState(() => _showRecordingSubMenu = false);
                  widget.onOpenRecordingControl();
                },
              ),
            ),
            const VerticalDivider(
              color: Colors.white12,
              indent: 8,
              endIndent: 8,
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.stop_rounded,
                  color: AppColors.redAlert,
                  size: 22,
                ),
                label: const Text(
                  "Finalitzar",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  setState(() => _showRecordingSubMenu = false);
                  widget.onOpenRecordingControl();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🧭 MÈTODE AUXILIAR: SUB-MENÚ DE NAVEGACIÓ / SEGUIMENT
  Widget _buildNavigationSubMenu(
    BuildContext context,
    bool hasTrack,
    NavigationState navState,
  ) {
    final bool isFollowing = navState.isFollowing;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!hasTrack)
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.file_upload_outlined,
                  color: Colors.blueAccent,
                  size: 24,
                ),
                label: const Text(
                  "Importar GPX",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() => _showNavigationSubMenu = false);
                  widget.onOpenNavigationControl(false);
                },
              ),
            ),
          if (hasTrack && !isFollowing) ...[
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.greenAccent,
                  size: 24,
                ),
                label: const Text(
                  "Iniciar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() => _showNavigationSubMenu = false);
                  widget.onOpenNavigationControl(true);
                },
              ),
            ),
            const VerticalDivider(
              color: Colors.white12,
              indent: 8,
              endIndent: 8,
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.grey,
                  size: 22,
                ),
                label: const Text(
                  "Cancel·lar",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  setState(() => _showNavigationSubMenu = false);
                  widget.onOpenNavigationControl(true);
                },
              ),
            ),
          ],
          if (isFollowing) ...[
            Expanded(
              child: TextButton.icon(
                icon: Icon(
                  navState.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: Colors.amber,
                  size: 22,
                ),
                label: Text(
                  navState.isPaused ? "Reprendre" : "Pausar",
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  // 🟢 PAUSA INSTANTÀNIA SENSE DIÀLEGS: Commuta la pausa directament a Riverpod
                  // en el mateix mil·lisegon que es fa clic, mantenint el menú tancat.
                  setState(() => _showNavigationSubMenu = false);
                  ref.read(navigationProvider.notifier).state = navState
                      .copyWith(isPaused: !navState.isPaused);
                },
              ),
            ),
            const VerticalDivider(
              color: Colors.white12,
              indent: 8,
              endIndent: 8,
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(
                  Icons.stop_rounded,
                  color: AppColors.redAlert,
                  size: 22,
                ),
                label: const Text(
                  "Finalitzar",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  // 🟢 FINALITZACIÓ PROTEGIDA: Aquest botó sí que va al Handler,
                  // el qual obrirà el cas "stop_follow" per demanar confirmació i esborrar el track.
                  setState(() => _showNavigationSubMenu = false);
                  widget.onOpenNavigationControl(true);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 📱 MÈTODE AUXILIAR REFORMAT: Pestanyes de la barra inferior amb disseny de targeta per a la gravació
  Widget _buildMenuTab({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    // 🟢 DETECTOR: Comprovem si el text és "Gravant..." per saber si hem de pintar la targeta blanca
    final bool isRecordingActive = label == "Gravant...";

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: isRecordingActive
                      ? Container(
                          // 🟢 DISSENY CARD BLINDAT: Fons blanc amb cantonades arrodonides
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color:
                                  iconColor, // El color vermell corporatiu (Colors.red)
                              fontSize:
                                  10.5, // Una mica més petita per cabre dins de la targeta
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                          ),
                        )
                      : Text(
                          label,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
