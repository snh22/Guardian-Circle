import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../domain/models/guardian_status.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/risk_status_card.dart';
import '../widgets/event_timeline.dart';
import '../widgets/quick_actions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(guardianStatusProvider);
    final eventsAsync = ref.watch(dashboardEventsProvider);

    final events = eventsAsync.valueOrNull ?? const <TimelineEvent>[];

    // React to Critical risk immediately.
    ref.listen(
      shouldShowEscalationModalProvider,
      (previous, next) {
        if (next && previous != true) {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const EscalationAlertScreen(),
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guardian Circle',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Wearable
          IconButton(
            icon: const Icon(
              Icons.watch_outlined,
              color: Colors.black87,
            ),
            tooltip: 'Wearable connection',
            onPressed: () {
              Navigator.of(context).pushNamed('/ble');
            },
          ),

          // Logout
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: Colors.black87,
            ),
            tooltip: 'Log out',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),

      body: statusAsync.when(
        // ------------------------------------------------------------
        // LOADING
        // ------------------------------------------------------------
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        // ------------------------------------------------------------
        // ERROR
        // ------------------------------------------------------------
        error: (err, _) {
          return _ErrorState(
            message: err.toString(),
          );
        },

        // ------------------------------------------------------------
        // DATA
        // ------------------------------------------------------------
        data: (status) {
          return RefreshIndicator(
            onRefresh: () async {
              refreshDashboard(ref);
            },

            child: ListView(
              padding: const EdgeInsets.all(20),

              children: [
                // ------------------------------------------------------
                // ELDERLY USER NAME
                // ------------------------------------------------------
                Text(
                  status.userName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                ),

                const SizedBox(height: 4),

                // ------------------------------------------------------
                // LAST UPDATED
                // ------------------------------------------------------
                Text(
                  'Last updated ${_relativeTime(status.lastUpdated)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Colors.black54,
                      ),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------------
                // RISK STATUS CARD
                // ------------------------------------------------------
                RiskStatusCard(
                  status: status,
                  onTap: () {
                    Navigator.of(context).pushNamed('/map');
                  },
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------------
                // QUICK ACTIONS
                // ------------------------------------------------------
                QuickActionsRow(
                  onViewMap: () {
                    Navigator.of(context).pushNamed('/map');
                  },
                  onCall: () {
                    _placeCall(context);
                  },
                  onAcknowledge: () {
                    refreshDashboard(ref);
                  },
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------------
                // RECENT ACTIVITY TITLE
                // ------------------------------------------------------
                Text(
                  'Recent Activity',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                ),

                const SizedBox(height: 12),

                // ------------------------------------------------------
                // EVENT TIMELINE
                // ------------------------------------------------------
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: EventTimelineList(
                      events: events,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ------------------------------------------------------
                // PLANNED TRIPS
                // ------------------------------------------------------
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/trips');
                  },
                  child: const Text(
                    'Manage Planned Trips',
                    style: TextStyle(
                      color: Color(0xFF1F3A5F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // CALL CAREGIVER
  // ------------------------------------------------------------

  Future<void> _placeCall(BuildContext context) async {
    // Temporary predefined number.
    // Replace with the configured emergency contact later.
    final uri = Uri(
      scheme: 'tel',
      path: '+911234567890',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ------------------------------------------------------------
  // RELATIVE TIME
  // ------------------------------------------------------------

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);

    if (diff.inSeconds < 60) {
      return 'just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }

    return '${diff.inHours} hr ago';
  }
}

// ==================================================================
// ERROR STATE
// ==================================================================

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.black38,
            ),

            const SizedBox(height: 12),

            Text(
              'Unable to reach Guardian Circle.\n$message',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// CRITICAL ESCALATION SCREEN
// ==================================================================

class EscalationAlertScreen extends ConsumerWidget {
  const EscalationAlertScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref
        .watch(guardianStatusProvider)
        .valueOrNull;

    return PopScope(
      canPop: false,

      child: Scaffold(
        backgroundColor: const Color(0xFFD32F2F),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // ----------------------------------------------------
                // EMERGENCY ICON
                // ----------------------------------------------------
                const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 80,
                ),

                const SizedBox(height: 20),

                // ----------------------------------------------------
                // CRITICAL ALERT TITLE
                // ----------------------------------------------------
                Text(
                  'CRITICAL ALERT',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),

                const SizedBox(height: 8),

                // ----------------------------------------------------
                // EVENT MESSAGE
                // ----------------------------------------------------
                Text(
                  status?.latestEvent.summary ??
                      'SOS / fall-like event detected',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: Colors.white,
                      ),
                ),

                const SizedBox(height: 36),

                // ----------------------------------------------------
                // CALL NOW
                // ----------------------------------------------------
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri(
                        scheme: 'tel',
                        path: '+911234567890',
                      );

                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD32F2F),

                      minimumSize: const Size.fromHeight(56),
                    ),

                    icon: const Icon(
                      Icons.call_rounded,
                    ),

                    label: const Text(
                      'Call Now',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ----------------------------------------------------
                // ACKNOWLEDGE
                // ----------------------------------------------------
                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton(
                    onPressed: () {
                      refreshDashboard(ref);
                      Navigator.of(context).pop();
                    },

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),

                      foregroundColor: Colors.white,

                      minimumSize: const Size.fromHeight(56),
                    ),

                    child: const Text(
                      'Acknowledge — I\'m handling this',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}