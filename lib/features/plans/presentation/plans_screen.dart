import 'package:flutter/material.dart';

/// Planned Trips preview screen for Caregiver.
/// Informs the risk engine when travel outside the home zone is expected,
/// reducing false alarms during routine visits.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  void _showAddTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Planned Trip'),
        content: const Text(
          'In later integration phases, scheduling a trip will notify the context engine to expect travel outside safe zones without raising false alerts.\n\nBackend trip creation will be connected in Phase 2.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planned trips'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add trip',
              onPressed: () => _showAddTripDialog(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // EXPLANATION CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF5D5B8D).withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.event_available_rounded, color: Color(0xFF5D5B8D), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Planned trips help Guardian Circle know when travel is scheduled, preventing unnecessary check-ins.',
                      style: TextStyle(
                        color: Color(0xFF3C3A68),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // UPCOMING TRIPS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming trips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE8F7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Preview trips',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D5B8D)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _TripCard(
              destination: 'City Hospital Check-up',
              destinationZone: 'City Hospital Safe Zone',
              timeRange: 'Today • 3:00 PM – 5:00 PM',
              status: 'Scheduled',
              statusColor: Color(0xFF1E8E5A),
              icon: Icons.local_hospital_outlined,
            ),
            const SizedBox(height: 10),
            const _TripCard(
              destination: 'Market Grocery Visit',
              destinationZone: 'Local Market Safe Zone',
              timeRange: 'Tomorrow • 10:30 AM – 11:30 AM',
              status: 'Scheduled',
              statusColor: Color(0xFF1E8E5A),
              icon: Icons.storefront_outlined,
            ),
            const SizedBox(height: 28),

            // PAST TRIPS SECTION
            Text(
              'Past trips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            const _TripCard(
              destination: 'Community Park Walk',
              destinationZone: 'Park Area',
              timeRange: 'Yesterday • 4:00 PM – 4:45 PM',
              status: 'Completed',
              statusColor: Colors.black54,
              icon: Icons.park_outlined,
              isPast: true,
            ),
            const SizedBox(height: 20),

            // ADD TRIP ACTION BUTTON
            OutlinedButton.icon(
              onPressed: () => _showAddTripDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add planned trip'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String destination;
  final String destinationZone;
  final String timeRange;
  final String status;
  final Color statusColor;
  final IconData icon;
  final bool isPast;

  const _TripCard({
    required this.destination,
    required this.destinationZone,
    required this.timeRange,
    required this.status,
    required this.statusColor,
    required this.icon,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1F3A5F).withValues(alpha: isPast ? 0.05 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isPast ? Colors.black45 : const Color(0xFF1F3A5F), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          destination,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isPast ? Colors.black87 : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    destinationZone,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(
                        timeRange,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
