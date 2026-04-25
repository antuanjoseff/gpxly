import 'package:flutter/material.dart';

enum RecordingSimulateState { idle, recording, paused }

enum FollowingState { idle, following, paused }

class RecordingFollowingSimulatorPage extends StatefulWidget {
  const RecordingFollowingSimulatorPage({super.key});

  @override
  State<RecordingFollowingSimulatorPage> createState() =>
      _RecordingFollowingSimulatorPageState();
}

class _RecordingFollowingSimulatorPageState
    extends State<RecordingFollowingSimulatorPage> {
  RecordingSimulateState recording = RecordingSimulateState.idle;
  FollowingState following = FollowingState.idle;
  bool hasTrackImported = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Simulem l'AppBar que ja tens
      appBar: AppBar(
        title: const Text("Explora"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. MAPA DE FONDO (Simulat)
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.map, size: 100, color: Colors.white),
            ),
          ),

          // 2. INDICADORES SUPERIORES (Dins de l'stack sobre el mapa)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderChip(
                  visible: recording != RecordingSimulateState.idle,
                  icon: recording == RecordingSimulateState.recording
                      ? Icons.circle
                      : Icons.pause,
                  label: "Gravant",
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                _buildHeaderChip(
                  visible: following != FollowingState.idle,
                  icon: following == FollowingState.following
                      ? Icons.navigation
                      : Icons.pause,
                  label: "Seguint",
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          // 3. PANELL DE CONTROL INFERIOR DIVIDIT
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSplitPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSplitPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: IntrinsicHeight(
          // Fa que el separador vertical s'ajusti a l'alçada
          child: Row(
            children: [
              // COLUMNA ESQUERRA: GRAVACIÓ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: _buildRecordingSlot(),
                  ),
                ),
              ),

              // SEPARADOR
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Colors.grey[200],
                indent: 20,
                endIndent: 20,
              ),

              // COLUMNA DRETA: SEGUIMENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: _buildFollowingSlot(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGICA GRAVACIÓ ---
  Widget _buildRecordingSlot() {
    if (recording == RecordingSimulateState.idle) {
      return _bigActionButton(
        key: const ValueKey("btn_rec_idle"),
        label: "Gravar",
        icon: Icons.fiber_manual_record,
        color: Colors.red,
        onTap: () =>
            setState(() => recording = RecordingSimulateState.recording),
      );
    }
    return _activeControlUI(
      key: const ValueKey("btn_rec_active"),
      title: "GRAVACIÓ",
      isPaused: recording == RecordingSimulateState.paused,
      color: Colors.red,
      onToggle: () => setState(
        () => recording = (recording == RecordingSimulateState.recording)
            ? RecordingSimulateState.paused
            : RecordingSimulateState.recording,
      ),
      onStop: () => _confirmStop("Gravació"),
    );
  }

  // --- LOGICA SEGUIMENT ---
  Widget _buildFollowingSlot() {
    if (following == FollowingState.idle) {
      return _bigActionButton(
        key: const ValueKey("btn_foll_idle"),
        label: hasTrackImported ? "Seguir" : "Ruta",
        icon: hasTrackImported ? Icons.play_arrow : Icons.file_upload,
        color: Colors.blue,
        onTap: () {
          if (!hasTrackImported)
            _simulateImport();
          else
            setState(() => following = FollowingState.following);
        },
      );
    }
    return _activeControlUI(
      key: const ValueKey("btn_foll_active"),
      title: "SEGUIMENT",
      isPaused: following == FollowingState.paused,
      color: Colors.blue,
      onToggle: () => setState(
        () => following = (following == FollowingState.following)
            ? FollowingState.paused
            : FollowingState.following,
      ),
      onStop: () => _confirmStop("Seguiment"),
    );
  }

  // --- COMPONENTS UI REUTILITZABLES ---

  Widget _bigActionButton({
    required Key key,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _activeControlUI({
    required Key key,
    required String title,
    required bool isPaused,
    required Color color,
    required VoidCallback onToggle,
    required VoidCallback onStop,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _circleButton(
              icon: isPaused ? Icons.play_arrow : Icons.pause,
              color: color,
              onTap: onToggle,
              isSmall: true,
            ),
            _circleButton(icon: Icons.stop, color: color, onTap: onStop),
          ],
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isSmall ? 8 : 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(icon, color: color, size: isSmall ? 20 : 26),
      ),
    );
  }

  Widget _buildHeaderChip({
    required bool visible,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: visible ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateImport() {
    setState(() => hasTrackImported = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Ruta preparada per seguir!")));
  }

  void _confirmStop(String type) {
    // Aquí podries posar un Dialog de confirmació real
    setState(() {
      if (type == "Gravació")
        recording = RecordingSimulateState.idle;
      else
        following = FollowingState.idle;
    });
  }
}
