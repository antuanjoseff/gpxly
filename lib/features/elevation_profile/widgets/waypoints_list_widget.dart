import 'package:flutter/material.dart';
import 'package:senda/l10n/app_localizations.dart';
import 'package:senda/models/waypoint.dart';
import 'package:senda/theme/app_colors.dart';

class WaypointsListWidget extends StatefulWidget {
  final List<Waypoint> recorded;
  final List<Waypoint> imported;
  final int? selectedStartIndex;
  final int? selectedEndIndex;
  final void Function(Waypoint wp) onToggleWaypoint;

  const WaypointsListWidget({
    super.key,
    required this.recorded,
    required this.imported,
    required this.selectedStartIndex,
    required this.selectedEndIndex,
    required this.onToggleWaypoint,
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
    if (widget.recorded.isEmpty && widget.imported.isEmpty)
      return const SizedBox.shrink();

    return Column(
      children: [
        if (widget.recorded.isNotEmpty)
          _section(
            title: t.waypointsRecorded,
            expanded: expandRecorded,
            onToggle: () => setState(() => expandRecorded = !expandRecorded),
            children: [
              for (int i = 0; i < widget.recorded.length; i++)
                _tile(
                  widget.recorded[i],
                  widget.recorded[i].trackIndex,
                  i == widget.recorded.length - 1,
                ),
            ],
          ),
        if (widget.imported.isNotEmpty)
          _section(
            title: t.waypointsImported,
            expanded: expandImported,
            onToggle: () => setState(() => expandImported = !expandImported),
            children: [
              for (int i = 0; i < widget.imported.length; i++)
                _tile(
                  widget.imported[i],
                  widget.imported[i].trackIndex,
                  i == widget.imported.length - 1,
                ),
            ],
          ),
      ],
    );
  }

  Widget _section({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: children),
          ),
      ],
    );
  }

  Widget _tile(Waypoint wp, int idx, bool isLast) {
    final bool isStart = widget.selectedStartIndex == idx;
    final bool isEnd = widget.selectedEndIndex == idx;
    final bool isSelected = isStart || isEnd;
    final Color activeColor = isStart
        ? Colors.green
        : (isEnd ? Colors.red : AppColors.primary);

    return Column(
      children: [
        ListTile(
          onTap: () => widget.onToggleWaypoint(wp),
          visualDensity: VisualDensity.compact,
          leading: Icon(
            isSelected
                ? (isStart ? Icons.play_circle_fill : Icons.stop_circle)
                : Icons.location_on_outlined,
            color: isSelected ? activeColor : Colors.black12,
            size: 22,
          ),
          title: Text(
            wp.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : Colors.black87,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: activeColor.withAlpha(80),
                  size: 16,
                )
              : const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Colors.black12,
                ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 52,
            endIndent: 12,
            color: Colors.grey.withAlpha(30),
          ),
      ],
    );
  }
}
