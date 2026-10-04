import 'package:flutter/material.dart';

import '../../../../core/constants/risk_level.dart';
import '../../domain/models/guardian_status.dart';

class EventTimelineList extends StatelessWidget {
  final List<TimelineEvent> events;

  const EventTimelineList({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 28,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFE8EEF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Color(0xFF1F3A5F),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No recent activity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'New activity will appear here.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < events.length; i++)
          _TimelineTile(
            event: events[i],
            isLast: i == events.length - 1,
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final TimelineEvent event;
  final bool isLast;

  const _TimelineTile({
    required this.event,
    required this.isLast,
  });

  IconData get _icon => switch (event.kind) {
        EventKind.movement => Icons.directions_walk_rounded,
        EventKind.location => Icons.location_on_rounded,
        EventKind.ble => Icons.bluetooth_connected_rounded,
        EventKind.sos => Icons.sos_rounded,
        EventKind.fallLike => Icons.personal_injury_rounded,
        EventKind.checkIn => Icons.chat_bubble_outline_rounded,
        EventKind.tripStart => Icons.flight_takeoff_rounded,
        EventKind.tripEnd => Icons.flight_land_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color =
        event.associatedRisk?.color ?? const Color(0xFF1F3A5F);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =============================================================
          // TIMELINE
          // =============================================================

          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    _icon,
                    size: 18,
                    color: color,
                  ),
                ),

                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 5,
                      ),
                      color: color.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // =============================================================
          // EVENT CARD
          // =============================================================

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: Colors.black38,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(
                                event.timestamp,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.black26,
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