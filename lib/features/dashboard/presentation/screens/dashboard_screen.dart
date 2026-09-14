import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardian_circle/core/constants/risk_level.dart';
import 'package:guardian_circle/core/navigation/caregiver_destination.dart';
import 'package:guardian_circle/features/dashboard/presentation/widgets/event_timeline.dart';
import 'package:guardian_circle/features/dashboard/presentation/widgets/quick_actions.dart';
import 'package:guardian_circle/features/dashboard/presentation/widgets/risk_status_card.dart';
import 'package:guardian_circle/features/dashboard/presentation/widgets/status_metric_card.dart';
import 'package:guardian_circle/features/dashboard/providers/dashboard_provider.dart';
import 'package:guardian_circle/features/wearable/presentation/wearable_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final ValueChanged<CaregiverDestination> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentation = ref.watch(dashboardPresentationProvider);
    final status = presentation.status;
    final isCritical = status.riskLevel == RiskLevel.critical;

    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          children: [
            // 1. GREETING & CAREGIVER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good afternoon 👋',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Caring for ${status.userName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1F3A5F).withValues(alpha: 0.1),
                  child: const Icon(Icons.person_outline_rounded, color: Color(0xFF1F3A5F)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. HONEST PREVIEW NOTICE BANNER
            _PreviewNoticeBanner(message: presentation.monitoringMessage),
            const SizedBox(height: 20),

            // 3. OVERALL SAFETY STATUS CARD
            Text(
              'Safety status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            RiskStatusCard(
              status: status,
              isPreview: presentation.isPreview,
              locationText: presentation.locationDisplay,
              movementText: presentation.movementDisplay,
            ),
            const SizedBox(height: 22),

            // 4. CORE OBSERVATION PILLARS: LOCATION, MOVEMENT, WEARABLE
            Text(
              'Observations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            StatusMetricCard(
              icon: Icons.location_on_outlined,
              title: 'Location',
              status: presentation.locationDisplay,
              subtext: presentation.locationSubtext,
              iconColor: const Color(0xFF1E8E5A),
              onTap: () => onNavigate(CaregiverDestination.location),
            ),
            const SizedBox(height: 10),
            StatusMetricCard(
              icon: Icons.directions_walk_rounded,
              title: 'Movement',
              status: presentation.movementDisplay,
              subtext: presentation.movementSubtext,
              iconColor: const Color(0xFF1F3A5F),
            ),
            const SizedBox(height: 10),
            StatusMetricCard(
              icon: Icons.watch_outlined,
              title: 'Wearable',
              status: presentation.wearableDisplay,
              subtext: presentation.wearableSubtext,
              iconColor: Colors.black54,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WearableScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // 5. CONTEXTUAL ACTIONS
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            QuickActions(
              actions: isCritical
                  ? [
                      DashboardAction(
                        label: 'View emergency details',
                        icon: Icons.emergency_rounded,
                        isPrimary: true,
                        customColor: const Color(0xFFD32F2F),
                        onPressed: () => onNavigate(CaregiverDestination.alerts),
                      ),
                      DashboardAction(
                        label: 'View location',
                        icon: Icons.location_on_outlined,
                        onPressed: () => onNavigate(CaregiverDestination.location),
                      ),
                    ]
                  : [
                      DashboardAction(
                        label: 'View location',
                        icon: Icons.location_on_outlined,
                        isPrimary: true,
                        onPressed: () => onNavigate(CaregiverDestination.location),
                      ),
                      DashboardAction(
                        label: 'View planned trips',
                        icon: Icons.event_note_outlined,
                        onPressed: () => onNavigate(CaregiverDestination.plans),
                      ),
                      DashboardAction(
                        label: 'View alerts & history',
                        icon: Icons.notifications_none_rounded,
                        onPressed: () => onNavigate(CaregiverDestination.alerts),
                      ),
                    ],
            ),
            const SizedBox(height: 28),

            // 6. RECENT ACTIVITY TIMELINE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: () => onNavigate(CaregiverDestination.alerts),
                  child: const Text('View log'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: EventTimelineList(
                  events: presentation.recentActivity,
                  isPreview: presentation.isPreview,
                  onViewAll: () => onNavigate(CaregiverDestination.alerts),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 7. PLANNED TRIP CARD
            Text(
              'Planned trip',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _PlannedTripCard(
              label: presentation.plannedTrip?.label ?? 'No trip scheduled',
              destination: presentation.plannedTrip?.destinationZone ?? 'Unavailable',
              start: presentation.plannedTrip?.start,
              isPreview: presentation.isPreview,
              onTap: () => onNavigate(CaregiverDestination.plans),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewNoticeBanner extends StatelessWidget {
  final String message;

  const _PreviewNoticeBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EFF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5D5B8D).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF5D5B8D), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF3C3A68),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedTripCard extends StatelessWidget {
  final String label;
  final String destination;
  final DateTime? start;
  final bool isPreview;
  final VoidCallback onTap;

  const _PlannedTripCard({
    required this.label,
    required this.destination,
    this.start,
    required this.isPreview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = start != null ? _formatTripTime(start!) : 'Time not set';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F3A5F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1F3A5F), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$destination • $timeStr',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTripTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
