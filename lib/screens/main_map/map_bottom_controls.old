import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:senda/models/navigation_state.dart';
import 'package:senda/models/track.dart';
import 'package:senda/notifiers/imported_track_notifier.dart';
import 'package:senda/notifiers/navigation_notifier.dart';
import 'package:senda/notifiers/recording_notifier.dart';
import 'package:senda/screens/elevations/constants/chart_constants.dart';
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
    // 1. Lectures obligatòries de providers de Riverpod
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

    // 🧭 TRADUCCIÓ RECTIFICADA: Estats de la pestanya de Seguiment (Sempre en blanc)
    String navigationLabel = "Carregar track";
    IconData navigationIcon = Icons.file_upload_outlined;
    Color navigationColor = Colors.white;

    if (hasTrack && !navState.isFollowing) {
      navigationLabel = "Seguir";
      navigationIcon = Icons.explore_outlined;
      navigationColor = Colors.white;
    } else if (navState.isFollowing) {
      if (navState.isPaused) {
        navigationLabel = "Pausat";
        navigationIcon = Icons.explore_outlined;
        navigationColor = Colors.white;
      } else {
        navigationLabel = "Seguint...";
        navigationIcon = Icons.explore;
        navigationColor = Colors.white;
      }
    }

    final bool isAnySubMenuOpen =
        _showRecordingSubMenu || _showNavigationSubMenu;
    // ─────────────────────────────────────────────────────────────────────────
    // 📐 SECCIÓ DE PROPORCIONS DE L'STACK SUPERIOR (Mides netes al píxel)
    // ─────────────────────────────────────────────────────────────────────────
    final double screenHeight = MediaQuery.of(context).size.height;
    final double chartHeight = screenHeight * kElevationChartHeightRatio;

    // Calculem l'alçada dinàmica que necessita el contenidor Positioned pare
    // per albergar el gràfic, el menú de 64px i l'aire de seguretat dels submenús
    final double maxStackHeight = widget.isChartCollapsed
        ? (64.0 + MediaQuery.of(context).padding.bottom + 60.0)
        : (64.0 + chartHeight + MediaQuery.of(context).padding.bottom + 60.0);

    // 🟢 OPCIÓ B REORDENADA: Retornem Positioned amb alçada fixa 'maxStackHeight'.
    // Això obre el sostre geomètric perquè Flutter detecti correctament els clics dels submenús.
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: maxStackHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 📊 CAPA 1: EL GRÀFIC D'ELEVACIONS (Es pinta primer, al fons de l'Stack)
          if (isPanelActiveOnScreen)
            Positioned(
              bottom: 64.0 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isAnySubMenuOpen ? 0.35 : 1.0,
                child: IgnorePointer(
                  // 🟢 Si el submenú s'obre, tornem la caixa 'fantasma' per deixar passar els clics
                  ignoring: isAnySubMenuOpen,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: MediaQuery.of(context).size.width,
                    // Si el perfil està amagat (plegat) la caixa exterior mesura 0.0px.
                    // Si s'obre, fa exactament el 15% calculat de la pantalla
                    height: widget.isChartCollapsed ? 0.0 : chartHeight,
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
            ),
          // 📱 CAPA 2: SUB-MENÚS CONTEXTUALS (Es pinten a sobre del gràfic)
          // Al estar col·locats després en la llista, agafen prioritat absoluta davant del dit [INDEX].
          Positioned(
            bottom:
                64.0 +
                MediaQuery.of(context).padding.bottom +
                8.0, // Flota 8px per sobre de la línia del menú [INDEX]
            left: 12,
            right: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(
                  'submenus_stack_${_showRecordingSubMenu}_${_showNavigationSubMenu}',
                ),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showRecordingSubMenu)
                    _buildRecordingSubMenu(context, recordingState),
                  if (_showNavigationSubMenu)
                    _buildNavigationSubMenu(context, hasTrack, navState),
                ],
              ),
            ),
          ),

          // 📱 CAPA 3: MENÚ INFERIOR ORIGINAL (64px) - CLAVAT AL TERRA DELS GESTOS
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.primary,
              child: SafeArea(
                top: false,
                child: Container(
                  height: 64, // Alçada original exacta [INDEX]
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white12, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. GRAVAR
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

                      // 2. SEGUIR / CARREGAR TRACK
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

                      // 3. PERFIL D'ELEVACIONS
                      _buildMenuTab(
                        icon: widget.isChartCollapsed
                            ? Icons.landscape_outlined
                            : Icons.landscape_rounded,
                        label: "Perfil",
                        iconColor: !isPanelActiveOnScreen
                            ? Colors.white24
                            : (widget.isChartCollapsed
                                  ? Colors.white70
                                  : Colors.greenAccent),
                        onTap: !isPanelActiveOnScreen
                            ? null
                            : () {
                                setState(() {
                                  _showRecordingSubMenu = false;
                                  _showNavigationSubMenu = false;
                                });
                                widget.onToggleChart();
                              },
                      ),
                      const VerticalDivider(
                        color: Colors.white12,
                        indent: 16,
                        endIndent: 16,
                        width: 1,
                      ),

                      // 4. AJUSTOS
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
          ),
        ],
      ),
    );
  }

  // 📱 MÈTODE AUXILIAR: SUB-MENÚ DE CONTROL DE GRAVACIÓ
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
                  // 🟢 PAUSA INSTANTÀNIA SENSE DIÀLEGS DES DE LA BARRA
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
                  setState(() => _showNavigationSubMenu = false);
                  widget.onOpenNavigationControl(
                    true,
                  ); // Obre el Handler final directe de dos botons
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 📱 MÈTODE AUXILIAR: Pestanyes individuals restaurades a 1 línia amb FittedBox
  Widget _buildMenuTab({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback?
    onTap, // 🟢 SUPORT DE NULS AMB L'INTERROGANT PER DESACTIVAR EL CLIC
  }) {
    final bool isRecordingActive = label == "Gravant...";

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              onTap, // Si és null, InkWell es desactiva automàticament visualment
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
                              color: iconColor,
                              fontSize: 12,
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
