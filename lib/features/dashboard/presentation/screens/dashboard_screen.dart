import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/dashboard_provider.dart';
import '../../services/fall_event_service.dart';
import '../widgets/risk_status_card.dart';
import '../widgets/event_timeline.dart';
import '../widgets/quick_actions.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends ConsumerState<DashboardScreen> {
  // ============================================================
  // GUARDIAN CIRCLE
  // ============================================================

  double guardianCircleRange = 10.0;

  bool guardianCircleLoading = true;
  bool guardianCircleUpdating = false;

  static const List<double> guardianCircleRanges = [
    5.0,
    10.0,
    15.0,
    20.0,
  ];

  final FallEventService _fallEventService =
      FallEventService();

  @override
  void initState() {
    super.initState();

    _loadGuardianCircleRange();
  }

  Future<void> _loadGuardianCircleRange() async {
    try {
      final range =
          await _fallEventService.fetchGuardianCircleRange();

      if (!mounted) {
        return;
      }

      setState(() {
        guardianCircleRange = range;
        guardianCircleLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        guardianCircleLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load Guardian Circle settings: $e',
          ),
        ),
      );
    }
  }

  Future<void> changeGuardianCircleRange(
    double newRange,
  ) async {
    if (guardianCircleUpdating) {
      return;
    }

    final previousRange = guardianCircleRange;

    setState(() {
      guardianCircleRange = newRange;
      guardianCircleUpdating = true;
    });

    try {
      final updatedRange =
          await _fallEventService.updateGuardianCircleRange(
        newRange,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        guardianCircleRange = updatedRange;
        guardianCircleUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guardian Circle set to '
            '${updatedRange.toStringAsFixed(0)} metres',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        guardianCircleRange = previousRange;
        guardianCircleUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update Guardian Circle: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => _ErrorState(
          message: err.toString(),
        ),
        data: (status) => RefreshIndicator(
          onRefresh: () async {
            await _loadGuardianCircleRange();
          },
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
                    ?.copyWith(
                      color: Colors.black54,
                    ),
              ),

              const SizedBox(height: 16),

              RiskStatusCard(
                status: status,
                onTap: () => Navigator.of(context).pushNamed('/map'),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // GUARDIAN CIRCLE SETTINGS
              // ==================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Guardian Circle',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Alert me when the patient moves '
                        'outside this range.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Circle radius',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      if (guardianCircleLoading)
                        const LinearProgressIndicator()
                      else
                        DropdownButtonFormField<double>(
                          initialValue: guardianCircleRange,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon:
                                Icon(Icons.radar_rounded),
                          ),
                          items:
                              guardianCircleRanges.map(
                            (range) {
                              return DropdownMenuItem<double>(
                                value: range,
                                child: Text(
                                  '${range.toStringAsFixed(0)} metres',
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: guardianCircleUpdating
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }

                                  changeGuardianCircleRange(
                                    value,
                                  );
                                },
                        ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(10),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current radius: '
                                '${guardianCircleRange.toStringAsFixed(0)} m',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (guardianCircleUpdating)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              QuickActionsRow(
                onViewMap: () =>
                    Navigator.of(context).pushNamed('/map'),
                onCall: () => _placeCall(context),
                onAcknowledge: () => ref
                    .read(
                      timelineControllerProvider.notifier,
                    )
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
                child: const Text(
                  'Manage Planned Trips',
                ),
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
    final status =
        ref.watch(guardianStatusProvider).valueOrNull;

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
                      foregroundColor:
                          const Color(0xFFD32F2F),
                    ),
                    icon: const Icon(
                      Icons.call_rounded,
                    ),
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
