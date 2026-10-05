import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_provider.dart';
import '../widgets/event_timeline.dart';

class ActivityHistoryScreen extends ConsumerWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(dashboardEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF163B68),
        foregroundColor: Colors.white,
        title: const Text(
          'Activity History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: eventsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFD9534F),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unable to load activity history',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(dashboardEventsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (events) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardEventsProvider);
              await ref.read(dashboardEventsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE8ECF2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF183B60)
                            .withValues(alpha: 0.055),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1F8),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Color(0xFF24598B),
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Patient Activity',
                              style: TextStyle(
                                color: Color(0xFF183B60),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${events.length} recorded activities',
                              style: const TextStyle(
                                color: Color(0xFF7C8797),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8ECF2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF183B60)
                            .withValues(alpha: 0.055),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: EventTimelineList(
                    events: events,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
