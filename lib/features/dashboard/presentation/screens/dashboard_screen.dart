import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/guardian_status.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/risk_level.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/event_timeline.dart';

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
    final statusAsync = ref.watch(guardianStatusProvider);
    final eventsAsync = ref.watch(dashboardEventsProvider);

    final events =
        eventsAsync.valueOrNull ?? const <TimelineEvent>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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

          final Color riskColor;
          final Color riskLight;
          final IconData riskIcon;
          final String riskTitle;
          final String riskSubtitle;

          switch (status.riskLevel) {
            case RiskLevel.low:
              riskColor = const Color(0xFF1E9B67);
              riskLight = const Color(0xFFE6F7EF);
              riskIcon = Icons.verified_rounded;
              riskTitle = 'SAFE';
              riskSubtitle = 'No immediate concerns detected';
              break;

            case RiskLevel.medium:
              riskColor = const Color(0xFFD98A00);
              riskLight = const Color(0xFFFFF2D9);
              riskIcon = Icons.warning_amber_rounded;
              riskTitle = 'CAUTION';
              riskSubtitle = 'Please keep an eye on the patient';
              break;

            case RiskLevel.high:
              riskColor = const Color(0xFFE46A2A);
              riskLight = const Color(0xFFFFE9DE);
              riskIcon = Icons.priority_high_rounded;
              riskTitle = 'HIGH RISK';
              riskSubtitle = 'Attention may be required';
              break;

            case RiskLevel.critical:
              riskColor = const Color(0xFFD9363E);
              riskLight = const Color(0xFFFFE4E6);
              riskIcon = Icons.emergency_rounded;
              riskTitle = 'CRITICAL';
              riskSubtitle = 'Immediate attention may be required';
              break;
          }

          final batteryText = status.batteryPercent == null
              ? '--'
              : '${status.batteryPercent!.round()}%';

          return RefreshIndicator(
            color: const Color(0xFF1F3A5F),
            onRefresh: () async {
              refreshDashboard(ref);
              await _checkForAlerts();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF163B68),
                        Color(0xFF24598B),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(34),
                      bottomRight: Radius.circular(34),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.shield_rounded,
                                color: Colors.white,
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GUARDIAN CIRCLE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Safer today • Healthier tomorrow',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _HeaderIconButton(
                              icon: Icons.watch_outlined,
                              tooltip: 'Wearable connection',
                              onTap: () {
                                Navigator.of(context).pushNamed('/ble');
                              },
                            ),
                            const SizedBox(width: 8),
                            _HeaderIconButton(
                              icon: Icons.logout_rounded,
                              tooltip: 'Log out',
                              onTap: () {
                                ref
                                    .read(
                                      authControllerProvider.notifier,
                                    )
                                    .logout();
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF63D6A0)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF9AE6C2)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                color: Color(0xFF78E2A8),
                                size: 8,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'LIVE MONITORING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.14),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF24598B),
                                    size: 32,
                                  ),
                                ),
                                Positioned(
                                  right: 1,
                                  bottom: 1,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF59D493),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF24598B),
                                        width: 3,
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
                                      color: Colors.white60,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    status.userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Updated ${_relativeTime(status.lastUpdated)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT SAFETY STATUS',
                        style: TextStyle(
                          color: Color(0xFF687386),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),

                      const SizedBox(height: 11),


                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed('/map');
                          },
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: riskColor.withValues(alpha: 0.10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF183B60)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: riskLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        riskIcon,
                                        color: riskColor,
                                        size: 38,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            riskTitle,
                                            style: TextStyle(
                                              color: riskColor,
                                              fontSize: 27,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            riskSubtitle,
                                            style: const TextStyle(
                                              color: Color(0xFF687386),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F9FC),
                                    borderRadius: BorderRadius.circular(19),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _StatusMetric(
                                          icon: Icons.location_on_rounded,
                                          label: 'SAFE ZONE',
                                          value:
                                              status.safeZoneState.zoneLabel,
                                          color: const Color(0xFF2674B8),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 38,
                                        color: const Color(0xFFE2E7EE),
                                      ),
                                      Expanded(
                                        child: _StatusMetric(
                                          icon: Icons.battery_6_bar_rounded,
                                          label: 'BATTERY',
                                          value: batteryText,
                                          color: const Color(0xFF1E9B67),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 38,
                                        color: const Color(0xFFE2E7EE),
                                      ),
                                      Expanded(
                                        child: _StatusMetric(
                                          icon: Icons.schedule_rounded,
                                          label: 'UPDATED',
                                          value:
                                              _relativeTime(status.lastUpdated),
                                          color: const Color(0xFF7A65B7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 13),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.touch_app_rounded,
                                      size: 15,
                                      color: riskColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tap to view patient location',
                                      style: TextStyle(
                                        color: riskColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 17,
                                      color: riskColor,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'QUICK ACTIONS',
                              style: TextStyle(
                                color: Color(0xFF687386),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Text(
                            '${events.length} recent events',
                            style: const TextStyle(
                              color: Color(0xFF9AA3B2),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),

                      Row(
                        children: [
                          Expanded(
                            child: _ModernActionCard(
                              icon: Icons.call_rounded,
                              title: 'Call',
                              subtitle: 'Patient',
                              color: const Color(0xFF1E9B67),
                              onTap: () {
                                _placeCall(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ModernActionCard(
                              icon: Icons.notifications_active_rounded,
                              title: 'Alerts',
                              subtitle: 'Check now',
                              color: const Color(0xFFD98A00),
                              onTap: () {
                                _checkForAlerts();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ModernActionCard(
                              icon: Icons.location_on_rounded,
                              title: 'Location',
                              subtitle: 'View map',
                              color: const Color(0xFF2674B8),
                              onTap: () {
                                Navigator.of(context).pushNamed('/map');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RECENT ACTIVITY',
                                  style: TextStyle(
                                    color: Color(0xFF687386),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Latest updates from the patient',
                                  style: TextStyle(
                                    color: Color(0xFF9AA3B2),
                                    fontSize: 11,
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
                              color: const Color(0xFFEAF1F8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  size: 14,
                                  color: Color(0xFF24598B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${events.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF24598B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
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
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFE8ECF2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF183B60).withValues(alpha: 0.055),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            EventTimelineList(
                              events: events.take(3).toList(),
                            ),
                            if (events.length > 3) ...[
                              const SizedBox(height: 10),
                              const Divider(
                                height: 1,
                                color: Color(0xFFE8ECF2),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamed('/activity-history');
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.history_rounded, size: 18, color: Color(0xFF24598B)),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text(
                                          'View All Activities',
                                          style: TextStyle(
                                            color: Color(0xFF24598B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF24598B)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'MORE FEATURES',
                        style: TextStyle(
                          color: Color(0xFF687386),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _ModernFeatureTile(
                              icon: Icons.location_on_rounded,
                              title: 'Live Location',
                              subtitle: 'Track patient',
                              color: const Color(0xFF2674B8),
                              onTap: () {
                                Navigator.of(context).pushNamed('/map');
                              },
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: _ModernFeatureTile(
                              icon: Icons.route_rounded,
                              title: 'Planned Trips',
                              subtitle: 'Manage routes',
                              color: const Color(0xFF7A65B7),
                              onTap: () {
                                Navigator.of(context).pushNamed('/trips');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),

                      Row(
                        children: [
                          Expanded(
                            child: _ModernFeatureTile(
                              icon: Icons.person_rounded,
                              title: 'Patient Profile',
                              subtitle: 'View details',
                              color: const Color(0xFF1E9B67),
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed('/elderly-profile');
                              },
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: _ModernFeatureTile(
                              icon: Icons.security_rounded,
                              title: 'Risk Status',
                              subtitle: 'Safety overview',
                              color: const Color(0xFFD98A00),
                              onTap: () {
                                Navigator.of(context).pushNamed('/map');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 11),

                      Row(
                        children: [
                          Expanded(
                            child: _ModernFeatureTile(
                              icon: Icons.help_outline_rounded,
                              title: 'Help & Support',
                              subtitle: 'Get assistance',
                              color: const Color(0xFF5B78A6),
                              onTap: () {
                                Navigator.of(context).pushNamed('/help-support');
                              },
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: _ModernFeatureTile(
                              icon: Icons.info_outline_rounded,
                              title: 'About',
                              subtitle: 'Guardian Circle',
                              color: const Color(0xFF3E7C8F),
                              onTap: () {
                                Navigator.of(context).pushNamed('/about-guardian-circle');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                    ],
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

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9AA3B2),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF26364A),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModernActionCard({
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
          height: 108,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF183B60).withValues(alpha: 0.045),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF26364A),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9AA3B2),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModernFeatureTile({
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
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: const Color(0xFFE8ECF2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF183B60).withValues(alpha: 0.045),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF26364A),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: color.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9AA3B2),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
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
