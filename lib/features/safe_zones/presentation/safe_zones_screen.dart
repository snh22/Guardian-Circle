import 'package:flutter/material.dart';

/// Safe Zones management screen for Caregiver.
/// Presentation UI for designated geographic safe areas.
class SafeZonesScreen extends StatelessWidget {
  const SafeZonesScreen({super.key});

  void _showAddZoneInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Safe Zone'),
        content: const Text(
          'In production, you can drop a pin on a map and specify a safe geofence radius.\n\nBackend persistence and real geofencing will be connected in Phase 2.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Zones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add safe zone',
            onPressed: () => _showAddZoneInfo(context),
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
                Icon(Icons.shield_outlined, color: Color(0xFF5D5B8D), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Safe zones are trusted locations where your loved one spends regular time. Being inside a safe zone tells the system they are safe.',
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
                'Configured zones (3)',
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
                  'Preview zones',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5D5B8D)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ZoneItemCard(
            title: 'Home Safe Zone',
            description: 'Primary residence • 24/7 active',
            radiusText: '500 m radius',
            icon: Icons.home_outlined,
            isPrimary: true,
          ),
          const SizedBox(height: 10),
          const _ZoneItemCard(
            title: 'City Hospital Zone',
            description: 'Medical clinic & pharmacy',
            radiusText: '300 m radius',
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(height: 10),
          const _ZoneItemCard(
            title: 'Local Market Zone',
            description: 'Grocery & neighborhood shops',
            radiusText: '250 m radius',
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showAddZoneInfo(context),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add a new safe zone'),
          ),
        ],
      ),
    );
  }
}

class _ZoneItemCard extends StatelessWidget {
  final String title;
  final String description;
  final String radiusText;
  final IconData icon;
  final bool isPrimary;

  const _ZoneItemCard({
    required this.title,
    required this.description,
    required this.radiusText,
    required this.icon,
    this.isPrimary = false,
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                        title,
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
                            'Home',
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
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    radiusText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F3A5F),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
