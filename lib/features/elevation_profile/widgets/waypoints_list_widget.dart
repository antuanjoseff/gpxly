import 'package:flutter/material.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/theme/app_colors.dart';

class WaypointsListWidget extends StatefulWidget {
  final List<Waypoint> recorded;
  final List<Waypoint> imported;

  final int? selectedStartIndex;
  final int? selectedEndIndex;

  final void Function(Waypoint wp) onSetStart;
  final void Function(Waypoint wp) onSetEnd;

  const WaypointsListWidget({
    super.key,
    required this.recorded,
    required this.imported,
    required this.selectedStartIndex,
    required this.selectedEndIndex,
    required this.onSetStart,
    required this.onSetEnd,
  });

  @override
  State<WaypointsListWidget> createState() => _WaypointsListWidgetState();
}

class _WaypointsListWidgetState extends State<WaypointsListWidget> {
  bool expandRecorded = true;
  bool expandImported = true;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final hasRecorded = widget.recorded.isNotEmpty;
    final hasImported = widget.imported.isNotEmpty;

    if (!hasRecorded && !hasImported) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (hasRecorded)
          _section(
            title: t.waypointsRecorded,
            expanded: expandRecorded,
            onToggle: () => setState(() => expandRecorded = !expandRecorded),
            children: widget.recorded.map((wp) => _waypointTile(wp)).toList(),
          ),

        if (hasImported)
          _section(
            title: t.waypointsImported,
            expanded: expandImported,
            onToggle: () => setState(() => expandImported = !expandImported),
            children: widget.imported.map((wp) => _waypointTile(wp)).toList(),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SECCIÓ PLEGABLE
  // ─────────────────────────────────────────────
  Widget _section({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withAlpha(13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Contingut
          if (expanded) Column(children: children),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TILE DE WAYPOINT
  // ─────────────────────────────────────────────
  Widget _waypointTile(Waypoint wp) {
    final isStart = widget.selectedStartIndex == wp.trackIndex;
    final isEnd = widget.selectedEndIndex == wp.trackIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withAlpha(13)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: Text(
              wp.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          _actionBtn(
            icon: Icons.flag_circle,
            active: isStart,
            activeColor: AppColors.trackGreen,
            onTap: () => widget.onSetStart(wp),
          ),

          _actionBtn(
            icon: Icons.flag,
            active: isEnd,
            activeColor: AppColors.redAlert,
            onTap: () => widget.onSetEnd(wp),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTÓ COMPACTE
  // ─────────────────────────────────────────────
  Widget _actionBtn({
    required IconData icon,
    required bool active,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return IconButton(
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      iconSize: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
      icon: Icon(icon, size: 20, color: active ? activeColor : Colors.black26),

      onPressed: onTap,
    );
  }
}
