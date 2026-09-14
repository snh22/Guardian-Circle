import 'package:flutter/material.dart';
import 'package:guardian_circle/features/emergency_contacts/presentation/emergency_contacts_screen.dart';
import 'package:guardian_circle/features/profile/presentation/profile_screen.dart';
import 'package:guardian_circle/features/safe_zones/presentation/safe_zones_screen.dart';
import 'package:guardian_circle/features/settings/presentation/settings_screen.dart';
import 'package:guardian_circle/features/wearable/presentation/wearable_screen.dart';

/// More / Menu screen providing navigation to secondary features.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Guardian Circle'),
        content: const Text(
          'Guardian Circle is a caregiver decision-support system designed to answer one question:\n\n"Is my loved one okay right now?"\n\nIt combines smartphone GPS, wearable movement sensing (MPU6050 via BLE), safe zone geofencing, and context-aware risk scoring to give caregivers peace of mind without overwhelming them with raw technical data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('More options'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // USER & LOVED ONE SUMMARY CARD
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF1F3A5F).withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF1F3A5F), size: 30),
                ),
                title: const Text(
                  'Grandfather',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                subtitle: const Text('View & manage care circle'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // SYSTEM & HARDWARE
            Text(
              'Devices & Zones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.watch_outlined,
                    title: 'Guardian Band',
                    subtitle: 'Wearable status & pairing',
                    statusBadge: 'Not paired',
                    badgeColor: const Color(0xFFC98A00),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WearableScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.shield_outlined,
                    title: 'Safe Zones',
                    subtitle: 'Home, hospital, and market boundaries',
                    statusBadge: '3 zones',
                    badgeColor: const Color(0xFF1F3A5F),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SafeZonesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // EMERGENCY & COMMUNICATION
            Text(
              'Safety & Escalation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.contact_phone_outlined,
                    title: 'Emergency Contacts',
                    subtitle: 'Caregivers and proximity responders',
                    statusBadge: 'Demo mode',
                    badgeColor: const Color(0xFF5D5B8D),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.tune_rounded,
                    title: 'Settings & Preferences',
                    subtitle: 'Notification quiet hours and sensitivity',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SUPPORT & INFO
            Text(
              'Support',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'How Guardian Circle Works',
                    subtitle: 'Understanding safety status and indicators',
                    onTap: () => _showHelpDialog(context),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'App Information',
                    subtitle: 'Version 0.1.0 (Phase 1 UI Prototype)',
                    onTap: () => _showHelpDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? statusBadge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.statusBadge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1F3A5F).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1F3A5F), size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          if (statusBadge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? const Color(0xFF1F3A5F)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusBadge!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor ?? const Color(0xFF1F3A5F),
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
      onTap: onTap,
    );
  }
}
