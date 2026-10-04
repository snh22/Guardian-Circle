import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/guardian_status.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/network/api_service.dart';
import '../../providers/dashboard_provider.dart';
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
  Timer? _alertTimer;

  // Current demo elderly user in the backend.
  // This is the elderly user whose alerts/location are being monitored.
  static const int elderlyUserId = 1;

  int? _lastShownAlertId;

  @override
  void initState() {
    super.initState();

    // Check for backend alerts periodically.
    _startAlertChecking();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BACKEND ALERT CHECK
  // ============================================================

  void _startAlertChecking() {
    _checkForAlerts();

    _alertTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        _checkForAlerts();
      },
    );
  }

  Future<void> _checkForAlerts() async {
    if (!mounted) return;

    try {
      final alerts =
          await ApiService.getAlertsForUser(elderlyUserId);

      if (!mounted || alerts.isEmpty) {
        return;
      }

      // Find the newest active critical/high alert.
      Map<String, dynamic>? activeAlert;

      for (final item in alerts) {
        if (item is! Map) continue;

        final alert =
            Map<String, dynamic>.from(item);

        final status =
            alert['status']?.toString().toLowerCase();

        final risk =
            alert['risk_level']?.toString().toLowerCase();

        if (status == 'active' &&
            (risk == 'critical' || risk == 'high')) {
          activeAlert = alert;
          break;
        }
      }

      if (activeAlert == null) {
        return;
      }

      final alertIdValue =
          activeAlert['alert_id'];

      if (alertIdValue == null) {
        return;
      }

      final alertId =
          int.tryParse(alertIdValue.toString());

      if (alertId == null) {
        return;
      }

      // Don't repeatedly open the same alert.
      if (_lastShownAlertId == alertId) {
        return;
      }

      _lastShownAlertId = alertId;

      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => EscalationAlertScreen(
            alertId: alertId,
            alertData: activeAlert!,
          ),
        ),
      );

      // Allow a future alert to appear after returning.
      if (mounted) {
        _lastShownAlertId = null;
        refreshDashboard(ref);
      }
    } catch (_) {
      // Keep dashboard running even if an alert check fails.
      // The normal dashboard remains usable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync =
        ref.watch(guardianStatusProvider);

    final eventsAsync =
        ref.watch(dashboardEventsProvider);

    final events =
        eventsAsync.valueOrNull ??
            const <TimelineEvent>[];

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
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: Colors.black87,
            ),
            tooltip: 'Log out',
            onPressed: () {
              ref
                  .read(
                    authControllerProvider.notifier,
                  )
                  .logout();
            },
          ),
        ],
      ),
      body: statusAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (err, _) {
          return _ErrorState(
            message: err.toString(),
          );
        },
        data: (status) {
          return RefreshIndicator(
            onRefresh: () async {
              refreshDashboard(ref);
              await _checkForAlerts();
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
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

                Text(
                  'Last updated '
                  '${_relativeTime(status.lastUpdated)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: Colors.black54,
                      ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // RISK STATUS
                // ==================================================

                RiskStatusCard(
                  status: status,
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/map');
                  },
                ),

                const SizedBox(height: 20),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================

                QuickActionsRow(
                  onViewMap: () {
                    Navigator.of(context)
                        .pushNamed('/map');
                  },
                  onCall: () {
                    _placeCall(context);
                  },
                  onAcknowledge: () {
                    _checkForAlerts();
                  },
                ),

                const SizedBox(height: 28),

                // ==================================================
                // RECENT ACTIVITY
                // ==================================================

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

                Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16),
                    child: EventTimelineList(
                      events: events,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // MAP / GPS
                // ==================================================

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed('/map');
                  },
                  icon: const Icon(
                    Icons.location_on_outlined,
                  ),
                  label: const Text(
                    'View Live Location',
                  ),
                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(50),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // TRIPS
                // ==================================================

                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed('/trips');
                  },
                  child: const Text(
                    'Manage Planned Trips',
                    style: TextStyle(
                      color: Color(0xFF1F3A5F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ==================================================
                // ELDERLY PROFILE
                // ==================================================

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed('/elderly-profile');
                  },
                  icon: const Icon(
                    Icons.person_outline,
                  ),
                  label: const Text(
                    'Elderly Profile',
                    style: TextStyle(
                      color: Color(0xFF1F3A5F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<void> _placeCall(
    BuildContext context,
  ) async {
    final uri = Uri(
      scheme: 'tel',
      path: '+911234567890',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ============================================================
  // RELATIVE TIME
  // ============================================================

  String _relativeTime(DateTime t) {
    final diff =
        DateTime.now().difference(t);

    if (diff.inSeconds < 60) {
      return 'just now';
    }

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }

    return '${diff.inHours} hr ago';
  }
}

// ================================================================
// ERROR STATE
// ================================================================

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to reach Guardian Circle.\n$message',
              textAlign:
                  TextAlign.center,
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

// ================================================================
// CRITICAL ESCALATION SCREEN
// ================================================================

class EscalationAlertScreen
    extends ConsumerWidget {
  final int alertId;
  final Map<String, dynamic> alertData;

  const EscalationAlertScreen({
    super.key,
    required this.alertId,
    required this.alertData,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final reason =
        alertData['reason']?.toString() ??
            'SOS / fall-like event detected';

    final risk =
        alertData['risk_level']?.toString() ??
            'CRITICAL';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
            const Color(0xFFD32F2F),
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 80,
                ),

                const SizedBox(height: 20),

                Text(
                  'CRITICAL ALERT',
                  textAlign:
                      TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$risk ALERT\n$reason',
                  textAlign:
                      TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w500,
                      ),
                ),

                const SizedBox(height: 36),

                // ==================================================
                // CALL
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri(
                        scheme: 'tel',
                        path: '+911234567890',
                      );

                      if (await canLaunchUrl(
                        uri,
                      )) {
                        await launchUrl(uri);
                      }
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.white,
                      foregroundColor:
                          const Color(
                              0xFFD32F2F),
                      minimumSize:
                          const Size.fromHeight(
                        56,
                      ),
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

                // ==================================================
                // ACKNOWLEDGE
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  child:
                      OutlinedButton(
                    onPressed: () async {
                      try {
                        await ApiService
                            .resolveAlert(
                          alertId,
                        );

                        if (!context
                            .mounted) {
                          return;
                        }

                        ScaffoldMessenger
                            .of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Alert acknowledged successfully',
                            ),
                          ),
                        );

                        Navigator.of(
                          context,
                        ).pop();
                      } catch (e) {
                        if (!context
                            .mounted) {
                          return;
                        }

                        ScaffoldMessenger
                            .of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not acknowledge alert: $e',
                            ),
                          ),
                        );
                      }
                    },
                    style:
                        OutlinedButton.styleFrom(
                      side:
                          const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      foregroundColor:
                          Colors.white,
                      minimumSize:
                          const Size.fromHeight(
                        56,
                      ),
                    ),
                    child: const Text(
                      'Acknowledge — I\'m handling this',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // VIEW LOCATION
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop();

                      Navigator.of(
                        context,
                      ).pushNamed('/map');
                    },
                    style:
                        TextButton.styleFrom(
                      foregroundColor:
                          Colors.white,
                    ),
                    icon: const Icon(
                      Icons.location_on,
                    ),
                    label: const Text(
                      'View Patient Location',
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