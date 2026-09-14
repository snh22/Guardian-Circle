import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/dashboard_provider.dart';
import '../widgets/risk_status_card.dart';
import '../widgets/event_timeline.dart';
import '../widgets/quick_actions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(guardianStatusProvider);
    final events = ref.watch(timelineControllerProvider);

    ref.listen(shouldShowEscalationModalProvider, (previous, next) {
      if (next && previous != true) {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const EscalationAlertScreen(),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Circle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.watch_outlined),
            tooltip: 'Wearable connection',
            onPressed: () => Navigator.of(context).pushNamed('/ble'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(message: err.toString()),
        data: (status) => RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                status.userName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Last updated ${_relativeTime(status.lastUpdated)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              RiskStatusCard(
                status: status,
                onTap: () => Navigator.of(context).pushNamed('/map'),
              ),
              const SizedBox(height: 20),
              QuickActionsRow(
                onViewMap: () =>
                    Navigator.of(context).pushNamed('/map'),
                onCall: () => _placeCall(context),
                onAcknowledge: () => ref
                    .read(timelineControllerProvider.notifier)
                    .acknowledgeLatest(),
              ),
              const SizedBox(height: 28),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: EventTimelineList(events: events),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/trips'),
                child: const Text('Manage Planned Trips'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeCall(BuildContext context) async {
    final uri = Uri(
      scheme: 'tel',
      path: '+911234567890',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, hard-to-dismiss escalation view for CRITICAL events.
class EscalationAlertScreen extends ConsumerWidget {
  const EscalationAlertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(guardianStatusProvider).valueOrNull;

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
                const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  'CRITICAL ALERT',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
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
                    ),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call Now'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ref
                          .read(
                            timelineControllerProvider.notifier,
                          )
                          .acknowledgeLatest();

                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      foregroundColor: Colors.white,
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