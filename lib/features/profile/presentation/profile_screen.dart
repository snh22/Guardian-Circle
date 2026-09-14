import 'package:flutter/material.dart';

/// Profile screen for the loved one and care circle.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loved One Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // PROFILE HEADER CARD
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFF1F3A5F).withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, size: 48, color: Color(0xFF1F3A5F)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Grandfather',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Primary care recipient • 78 yrs',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE8F7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Preview profile',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5D5B8D)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // OVERVIEW SECTIONS
          Text(
            'Care circle details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: [
                  const _ProfileDetailRow(
                    icon: Icons.family_restroom_rounded,
                    label: 'Relationship',
                    value: 'Grandfather',
                  ),
                  Divider(height: 24),
                  const _ProfileDetailRow(
                    icon: Icons.person_pin_rounded,
                    label: 'Primary caregiver',
                    value: 'You (Caregiver)',
                  ),
                  Divider(height: 24),
                  const _ProfileDetailRow(
                    icon: Icons.shield_outlined,
                    label: 'Safe zones assigned',
                    value: '3 configured zones',
                  ),
                  Divider(height: 24),
                  const _ProfileDetailRow(
                    icon: Icons.watch_outlined,
                    label: 'Wearable assigned',
                    value: 'Guardian Band (Not connected)',
                  ),
                  Divider(height: 24),
                  const _ProfileDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Upcoming trips',
                    value: '1 trip scheduled today',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // EMERGENCY SUMMARY
          Text(
            'Emergency contact protocol',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In the event of sustained fall detection or an emergency SOS button press, the caregiver app receives full-screen escalation and secondary contacts are alerted.',
                    style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1E8E5A), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Caregiver notifications: Active',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E8E5A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1F3A5F)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
