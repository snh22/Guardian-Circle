import 'package:flutter/material.dart';

/// Full-screen emergency escalation screen for CRITICAL events (SOS / fall detection).
/// Designed with urgent visual clarity and calm, actionable guidance.
/// In Phase 1, this runs in preview mode with honest demo actions.
class CriticalAlertScreen extends StatelessWidget {
  final bool isPreview;
  final VoidCallback? onNavigateToLocation;

  const CriticalAlertScreen.preview({
    super.key,
    this.onNavigateToLocation,
  }) : isPreview = true;

  void _showCallInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Call Simulation'),
        content: const Text(
          'In production, this button will immediately dial your verified emergency contact or local services.\n\nPhone integration will be enabled in Phase 2 once verified emergency numbers are registered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFD32F2F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Emergency alert'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPreview) const _PreviewBadge(),
                const Spacer(flex: 1),
                const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 68,
                ),
                const SizedBox(height: 18),
                Text(
                  'EMERGENCY DETECTED',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grandfather needs your immediate attention',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),

                // EMERGENCY EVENT CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _EventDetailRow(
                        icon: Icons.personal_injury_rounded,
                        label: 'Event',
                        value: 'High-impact fall-like event',
                      ),
                      SizedBox(height: 8),
                      const _EventDetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Detected',
                        value: 'Just now (Simulated)',
                      ),
                      SizedBox(height: 8),
                      const _EventDetailRow(
                        icon: Icons.place_outlined,
                        label: 'Context',
                        value: 'Inside Home Safe Zone',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Recommended action:\nAttempt a voice call first, then check their safe zone location.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 2),

                // ACTION BUTTONS
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCallInfo(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD32F2F),
                    ),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call loved one'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNavigateToLocation?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('View location'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Simulation alert acknowledged.'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.9),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Acknowledge simulation'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _EventDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'Preview Simulation — No live emergency',
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
