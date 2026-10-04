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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor:
                                const Color(0xFFE8EEF5),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 30,
                              color: Color(0xFF1F3A5F),
                            ),
                          ),
                          Positioned(
                            right: 1,
                            bottom: 1,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PATIENT MONITORING',
                              style: TextStyle(
                                color: Color(0xFF1F3A5F),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              status.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(
                                  Icons.sync_rounded,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Updated ${_relativeTime(status.lastUpdated)}',
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.black54,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Latest updates from the patient',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EEF5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: Color(0xFF1F3A5F),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${events.length}',
                            style: const TextStyle(
                              color: Color(0xFF1F3A5F),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: EventTimelineList(
                    events: events,
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // MORE FEATURES
                // ==================================================

                const SizedBox(height: 4),

                Text(
                  'MORE FEATURES',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),

                const SizedBox(height: 12),

                _DashboardFeatureCard(
                  icon: Icons.location_on_rounded,
                  title: 'Live Location',
                  subtitle:
                      'View the patient\'s current location',
                  color: const Color(0xFF1F3A5F),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/map');
                  },
                ),

                const SizedBox(height: 12),

                _DashboardFeatureCard(
                  icon: Icons.route_rounded,
                  title: 'Planned Trips',
                  subtitle:
                      'Manage upcoming journeys and routes',
                  color: const Color(0xFF6C63A8),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/trips');
                  },
                ),

                const SizedBox(height: 12),

                _DashboardFeatureCard(
                  icon: Icons.person_rounded,
                  title: 'Elderly Profile',
                  subtitle:
                      'View and manage patient information',
                  color: const Color(0xFF1E8E5A),
                  onTap: () {
                    Navigator.of(context)
                        .pushNamed('/elderly-profile');
                  },
                ),

                const SizedBox(height: 12),
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

class _DashboardFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: color.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
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

class EscalationAlertScreen extends ConsumerWidget {
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
        backgroundColor: const Color(0xFFF8F9FC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ==================================================
                // ALERT HEADER
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F)
                            .withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'CRITICAL ALERT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$risk ALERT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==================================================
                // ALERT DETAILS
                // ==================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFD32F2F),
                          size: 23,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'What happened?',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              reason,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ==================================================
                // CALL
                // ==================================================

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
                      backgroundColor: const Color(0xFF1E8E5A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(
                      Icons.call_rounded,
                      size: 21,
                    ),
                    label: const Text(
                      'Call Patient Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // ACKNOWLEDGE
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ApiService.resolveAlert(
                          alertId,
                        );

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Alert acknowledged successfully',
                            ),
                          ),
                        );

                        Navigator.of(context).pop();
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not acknowledge alert: $e',
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F3A5F),
                      minimumSize: const Size.fromHeight(56),
                      side: BorderSide(
                        color: const Color(0xFF1F3A5F)
                            .withValues(alpha: 0.18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                    ),
                    label: const Text(
                      'Acknowledge Alert',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ==================================================
                // VIEW LOCATION
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();

                      Navigator.of(context).pushNamed('/map');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1F3A5F),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(
                      Icons.location_on_rounded,
                    ),
                    label: const Text(
                      'View Patient Location',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Please respond promptly to this alert.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

