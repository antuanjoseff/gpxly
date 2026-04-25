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
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // 1. MAPA DE FONDO
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.map, size: 100, color: Colors.white),
            ),
          ),

          // 2. INDICADORES SUPERIORES
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (recording != RecordingSimulateState.idle)
                    _statusChip(
                      recording == RecordingSimulateState.recording
                          ? Icons.circle
                          : Icons.pause,
                      "Gravació",
                      recording == RecordingSimulateState.recording
                          ? Colors.red
                          : Colors.orange,
                    ),
                  const SizedBox(width: 8),
                  if (following != FollowingState.idle)
                    _statusChip(
                      following == FollowingState.following
                          ? Icons.navigation
                          : Icons.pause,
                      "Seguiment",
                      following == FollowingState.following
                          ? Colors.blue
                          : Colors.lightBlue,
                    ),
                ],
              ),
            ),
          ),

          // 3. PANEL DE CONTROL INFERIOR (Con SafeArea interno)
          Align(alignment: Alignment.bottomCenter, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      // El SafeArea asegura que el contenido no toque los botones del SO
      child: SafeArea(
        top: false, // Solo queremos el margen inferior
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (recording != RecordingSimulateState.idle ||
                  following != FollowingState.idle)
                _buildActiveUI(),

              if (recording == RecordingSimulateState.idle ||
                  following == FollowingState.idle)
                _buildLaunchButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaunchButtons() {
    bool isBothIdle =
        recording == RecordingSimulateState.idle &&
        following == FollowingState.idle;

    return Padding(
      padding: EdgeInsets.only(top: isBothIdle ? 0 : 16),
      child: Row(
        children: [
          if (recording == RecordingSimulateState.idle)
            Expanded(
              child: _actionButton(
                onTap: () => setState(
                  () => recording = RecordingSimulateState.recording,
                ),
                icon: Icons.fiber_manual_record,
                label: "Gravar",
                color: Colors.red,
              ),
            ),
          if (isBothIdle) const SizedBox(width: 12),
          if (following == FollowingState.idle)
            Expanded(
              child: _actionButton(
                onTap: () {
                  if (!hasTrackImported) {
                    _simulateImport();
                  } else {
                    setState(() => following = FollowingState.following);
                  }
                },
                icon: hasTrackImported ? Icons.play_arrow : Icons.file_upload,
                label: hasTrackImported ? "Seguir" : "Importar",
                color: Colors.blue,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recording != RecordingSimulateState.idle)
          _buildCompactRow(
            "Gravació",
            recording,
            (val) => setState(() => recording = val),
          ),

        if (recording != RecordingSimulateState.idle &&
            following != FollowingState.idle)
          Divider(color: Colors.grey[300], height: 24),

        if (following != FollowingState.idle)
          _buildCompactRow(
            "Seguiment",
            following,
            (val) => setState(() => following = val),
          ),
      ],
    );
  }

  Widget _buildCompactRow(
    String title,
    dynamic state,
    Function(dynamic) updateState,
  ) {
    bool isPaused =
        state == RecordingSimulateState.paused ||
        state == FollowingState.paused;
    Color colorTheme = title == "Gravació" ? Colors.red : Colors.blue;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isPaused ? "En pausa" : "En marxa...",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {
            if (title == "Gravació") {
              updateState(
                isPaused
                    ? RecordingSimulateState.recording
                    : RecordingSimulateState.paused,
              );
            } else {
              updateState(
                isPaused ? FollowingState.following : FollowingState.paused,
              );
            }
          },
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
        ),
        IconButton.filled(
          onPressed: () => _confirmStop(title),
          style: IconButton.styleFrom(backgroundColor: colorTheme),
          icon: const Icon(Icons.stop),
        ),
      ],
    );
  }

  // HELPERS
  Widget _actionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _statusChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _simulateImport() {
    setState(() => hasTrackImported = true);
  }

  void _confirmStop(String title) {
    setState(() {
      if (title == "Gravació")
        recording = RecordingSimulateState.idle;
      else
        following = FollowingState.idle;
    });
  }
}
