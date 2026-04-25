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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Simulador UI"),
        backgroundColor: Colors.black87,
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // 🔵 Indicadors d'estat
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (recording == RecordingSimulateState.recording)
                _statusChip(Icons.fiber_manual_record, "Gravant", Colors.red),
              if (recording == RecordingSimulateState.paused)
                _statusChip(
                  Icons.pause_circle,
                  "Gravació pausada",
                  Colors.orange,
                ),

              if (following == FollowingState.following)
                _statusChip(Icons.navigation, "Seguint track", Colors.blue),
              if (following == FollowingState.paused)
                _statusChip(
                  Icons.pause_circle,
                  "Seguiment pausat",
                  Colors.lightBlue,
                ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: Text(
                "MAPA SIMULAT",
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      // 🔥 Bottom bar dividida en dues columnes
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          border: Border(top: BorderSide(color: Colors.grey.shade800)),
        ),
        child: Row(
          children: [
            // 🟥 Columna GRAVACIÓ
            Expanded(child: _buildRecordingColumn()),

            const SizedBox(width: 12),

            // 🟦 Columna SEGUIMENT
            Expanded(child: _buildFollowingColumn()),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔴 Columna de GRAVACIÓ
  // ------------------------------------------------------------
  Widget _buildRecordingColumn() {
    switch (recording) {
      case RecordingSimulateState.idle:
        return _columnButtons([
          _btn(Icons.fiber_manual_record, "Iniciar gravació", Colors.red, () {
            setState(() => recording = RecordingSimulateState.recording);
          }),
        ]);

      case RecordingSimulateState.recording:
        return _columnButtons([
          _btn(Icons.pause, "Pausar gravació", Colors.orange, () {
            setState(() => recording = RecordingSimulateState.paused);
          }),
        ]);

      case RecordingSimulateState.paused:
        return _columnButtons([
          _btn(Icons.play_arrow, "Reprendre gravació", Colors.green, () {
            setState(() => recording = RecordingSimulateState.recording);
          }),
          _btn(Icons.stop, "Finalitzar gravació", Colors.red, () {
            setState(() => recording = RecordingSimulateState.idle);
          }),
        ]);
    }
  }

  // ------------------------------------------------------------
  // 🔵 Columna de SEGUIMENT
  // ------------------------------------------------------------
  Widget _buildFollowingColumn() {
    switch (following) {
      case FollowingState.idle:
        return _columnButtons([
          _btn(Icons.file_upload, "Importar track", Colors.blueGrey, () {}),
          _btn(Icons.navigation, "Iniciar seguiment", Colors.blue, () {
            setState(() => following = FollowingState.following);
          }),
        ]);

      case FollowingState.following:
        return _columnButtons([
          _btn(Icons.pause, "Pausar seguiment", Colors.orange, () {
            setState(() => following = FollowingState.paused);
          }),
        ]);

      case FollowingState.paused:
        return _columnButtons([
          _btn(Icons.play_arrow, "Reprendre seguiment", Colors.green, () {
            setState(() => following = FollowingState.following);
          }),
          _btn(Icons.stop, "Finalitzar seguiment", Colors.blue, () {
            setState(() => following = FollowingState.idle);
          }),
        ]);
    }
  }

  // ------------------------------------------------------------
  // Helpers UI
  // ------------------------------------------------------------
  Widget _columnButtons(List<Widget> children) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children
          .map(
            (c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c),
          )
          .toList(),
    );
  }

  Widget _btn(IconData icon, String text, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _statusChip(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
