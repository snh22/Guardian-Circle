import 'package:flutter/material.dart';
import '../../../../core/constants/risk_level.dart';
import '../../domain/models/guardian_status.dart';

class EventTimelineList extends StatelessWidget {
  final List<TimelineEvent> events;
  const EventTimelineList({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('No events yet today.')),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < events.length; i++)
          _TimelineTile(event: events[i], isLast: i == events.length - 1),
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
        EventKind.location => Icons.place_rounded,
        EventKind.ble => Icons.bluetooth_connected_rounded,
        EventKind.sos => Icons.sos_rounded,
        EventKind.fallLike => Icons.personal_injury_rounded,
        EventKind.checkIn => Icons.chat_bubble_outline_rounded,
        EventKind.tripStart => Icons.flight_takeoff_rounded,
        EventKind.tripEnd => Icons.flight_land_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = event.associatedRisk?.color ?? Colors.blueGrey;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(_icon, size: 16, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: Colors.black12),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.summary, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimestamp(event.timestamp),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.black54),
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