import 'package:flutter/material.dart';
import 'package:guardian_circle/core/constants/risk_level.dart';
import 'package:guardian_circle/features/dashboard/domain/models/guardian_status.dart';

class EventTimelineList extends StatelessWidget {
  final List<TimelineEvent> events;
  final VoidCallback? onViewAll;
  final bool isPreview;

  const EventTimelineList({
    super.key,
    required this.events,
    this.onViewAll,
    required this.isPreview,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No activity recorded yet today.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPreview)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFF9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF5D5B8D)),
                SizedBox(width: 6),
                Text(
                  'Preview activity — illustrative routine',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5D5B8D), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        for (int i = 0; i < events.length; i++)
          _TimelineTile(event: events[i], isLast: i == events.length - 1),
        if (onViewAll != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('View full activity log'),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineTile({required this.event, required this.isLast});

  IconData get _icon => switch (event.kind) {
        EventKind.movement => Icons.directions_walk_rounded,
        EventKind.location => Icons.place_outlined,
        EventKind.ble => Icons.bluetooth_connected_rounded,
        EventKind.sos => Icons.emergency_rounded,
        EventKind.fallLike => Icons.personal_injury_rounded,
        EventKind.checkIn => Icons.chat_bubble_outline_rounded,
        EventKind.tripStart => Icons.directions_walk_rounded,
        EventKind.tripEnd => Icons.home_work_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final color = event.associatedRisk?.color ?? const Color(0xFF1F3A5F);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 16, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E6EC),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(event.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F3A5F),
                            ),
                      ),
                      if (event.context != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${event.context}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
