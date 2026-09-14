import 'package:flutter/material.dart';
import 'package:guardian_circle/core/constants/risk_level.dart';
import 'package:guardian_circle/features/alerts/presentation/critical_alert_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alerts & safety log'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // 1. SIMULATION & TEST BANNER
            Card(
              color: const Color(0xFFF0EFF9),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science_outlined, color: Color(0xFF5D5B8D), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'UI Simulation & Testing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3C3A68),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Test how Guardian Circle escalates a high-priority emergency when an SOS or fall is detected.',
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => const CriticalAlertScreen.preview(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.emergency_rounded, size: 20),
                      label: const Text('Preview Emergency Escalation Screen'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. ACTIVE ALERTS SECTION (Honest Empty State)
            Text(
              'Active alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE7F6ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1E8E5A)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No active emergencies',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'All safety parameters look normal.',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 3. RECENT ALERT & EVENT HISTORY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent safety log',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE8F7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Preview history',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D5B8D)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _AlertHistoryCard(
              riskLevel: RiskLevel.low,
              title: 'Returned to Home Safe Zone',
              time: '12:03 PM today',
              reason: 'Automatic safe zone transition detected.',
              statusText: 'Normal routine',
            ),
            const SizedBox(height: 10),
            const _AlertHistoryCard(
              riskLevel: RiskLevel.medium,
              title: 'Soft Check-in Recommendation',
              time: '11:15 AM today',
              reason: 'Walk duration slightly exceeded expected market trip.',
              statusText: 'Resolved without escalation',
            ),
            const SizedBox(height: 10),
            const _AlertHistoryCard(
              riskLevel: RiskLevel.low,
              title: 'Morning Baseline Activity',
              time: '08:30 AM today',
              reason: 'Routine morning movement recorded.',
              statusText: 'Normal routine',
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertHistoryCard extends StatelessWidget {
  final RiskLevel riskLevel;
  final String title;
  final String time;
  final String reason;
  final String statusText;

  const _AlertHistoryCard({
    required this.riskLevel,
    required this.title,
    required this.time,
    required this.reason,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskLevel.backgroundTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: riskLevel.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(riskLevel.icon, size: 14, color: riskLevel.color),
                      const SizedBox(width: 4),
                      Text(
                        riskLevel.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: riskLevel.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
