import 'package:flutter/material.dart';

/// Caregiver settings and safety preferences screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _smsEscalation = true;
  bool _routineCheckIn = true;
  bool _highContrast = false;

  void _showNotice(String setting) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$setting preference updated (local preview).'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // NOTIFICATIONS SECTION
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Critical emergency alerts'),
                  subtitle: const Text('Sound alarm even in Do Not Disturb mode'),
                  value: _pushNotifications,
                  onChanged: (val) {
                    setState(() => _pushNotifications = val);
                    _showNotice('Emergency alerts');
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('SMS escalation fallback'),
                  subtitle: const Text('Send SMS if internet is disconnected'),
                  value: _smsEscalation,
                  onChanged: (val) {
                    setState(() => _smsEscalation = val);
                    _showNotice('SMS fallback');
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Routine check-in reminders'),
                  subtitle: const Text('Soft alerts for scheduled trips & arrival'),
                  value: _routineCheckIn,
                  onChanged: (val) {
                    setState(() => _routineCheckIn = val);
                    _showNotice('Routine reminders');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // SAFETY PREFERENCES
          Text(
            'Safety preferences',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Fall sensitivity threshold'),
                  subtitle: const Text('Standard (Impact + subsequent inactivity)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showNotice('Fall sensitivity'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Safe zone buffer distance'),
                  subtitle: const Text('50 meters grace threshold'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showNotice('Geofence buffer'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ACCESSIBILITY & DISPLAY
          Text(
            'Accessibility & display',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('High-contrast status badges'),
                  subtitle: const Text('Enhances text borders and tints'),
                  value: _highContrast,
                  onChanged: (val) {
                    setState(() => _highContrast = val);
                    _showNotice('High-contrast mode');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Text sizing'),
                  subtitle: const Text('Large (Optimized for rapid readability)'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showNotice('Text sizing'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ABOUT & SYSTEM INFO
          Text(
            'System & About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                const ListTile(
                  title: Text('Guardian Circle Version'),
                  subtitle: Text('Phase 1 UI/UX Preview (v0.1.0)'),
                  trailing: Text('Preview', style: TextStyle(color: Color(0xFF5D5B8D), fontWeight: FontWeight.w600)),
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Role'),
                  subtitle: Text('Decision-support system for caregivers'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Privacy & Local Data Notice'),
                  subtitle: const Text('Caregiver and loved one privacy information'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Privacy & Safety Notice'),
                        content: const Text(
                          'Guardian Circle is a decision-support system designed to reassure caregivers. It is not a medical diagnostic device.\n\nAll location, sensor, and health data are stored securely and used solely for safety monitoring.',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
