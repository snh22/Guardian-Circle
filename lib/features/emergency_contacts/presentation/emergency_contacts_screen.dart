import 'package:flutter/material.dart';

/// Emergency Contacts management screen for Caregiver.
/// Uses honest, clearly marked demo contacts (no fake phone numbers).
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  void _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: const Text(
          'In production, contacts added here will receive automated escalation SMS and calls if a critical event is unacknowledged.\n\nBackend contact persistence will be added in Phase 2.',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add contact',
            onPressed: () => _showAddContactDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5D5B8D).withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.contact_phone_outlined, color: Color(0xFF5D5B8D), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Emergency contacts are notified sequentially during critical alerts if the primary caregiver does not acknowledge.',
                    style: TextStyle(
                      color: Color(0xFF3C3A68),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Care network (Preview)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE8F7),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Demo contacts',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D5B8D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const _ContactCard(
            name: 'Primary Caregiver (You)',
            relationship: 'Daughter / Designated Primary',
            phoneDisplay: 'Configured on this device',
            isPrimary: true,
          ),
          const SizedBox(height: 10),
          const _ContactCard(
            name: 'Secondary Contact (Demo)',
            relationship: 'Neighbor / Proximity Responder',
            phoneDisplay: 'Contact verification pending',
            isPrimary: false,
          ),
          const SizedBox(height: 10),
          const _ContactCard(
            name: 'Dr. Sharma (Demo)',
            relationship: 'Family Physician',
            phoneDisplay: 'Clinic contact pending',
            isPrimary: false,
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () => _showAddContactDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add verified contact'),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String relationship;
  final String phoneDisplay;
  final bool isPrimary;

  const _ContactCard({
    required this.name,
    required this.relationship,
    required this.phoneDisplay,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPrimary
                    ? const Color(0xFF1E8E5A).withValues(alpha: 0.12)
                    : const Color(0xFF1F3A5F).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPrimary ? Icons.star_rounded : Icons.person_outline_rounded,
                color: isPrimary ? const Color(0xFF1E8E5A) : const Color(0xFF1F3A5F),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F6ED),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E8E5A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relationship,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phoneDisplay,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
                    ),
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
