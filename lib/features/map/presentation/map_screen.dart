import 'package:flutter/material.dart';

/// Location & Safe Zone preview screen for Caregiver.
/// In Phase 1, displays an honest, polished map placeholder clearly indicating
/// that live GPS streaming is pending backend connection.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Location & Safe Zones'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // HONEST STATUS BANNER
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF5D5B8D).withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF5D5B8D), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Live GPS is not connected — displaying preview safe zone.',
                      style: TextStyle(
                        color: Color(0xFF3C3A68),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // POLISHED MAP PLACEHOLDER AREA
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD3DDE8)),
              ),
              child: Stack(
                children: [
                  // Grid-like background simulation
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapGridPainter(),
                    ),
                  ),
                  // Simulated Safe Zone Circle
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E8E5A).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1E8E5A).withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_rounded, color: Color(0xFF1E8E5A), size: 32),
                            SizedBox(height: 4),
                            Text(
                              'Home Zone\n(500m)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E8E5A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom overlay tag
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF1E8E5A), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Grandfather • Inside Home Safe Zone',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            'Preview',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // LOCATION DETAILS
            Text(
              'Location status',
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
                    const _InfoRow(
                      icon: Icons.place_outlined,
                      label: 'Current zone',
                      value: 'At Home (Safe Zone)',
                    ),
                    Divider(height: 24),
                    const _InfoRow(
                      icon: Icons.access_time_rounded,
                      label: 'Last recorded update',
                      value: '12:03 PM (Preview)',
                    ),
                    Divider(height: 24),
                    const _InfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Geofence state',
                      value: 'Within designated boundary',
                    ),
                    Divider(height: 24),
                    const _InfoRow(
                      icon: Icons.near_me_outlined,
                      label: 'GPS accuracy',
                      value: 'Unavailable in preview mode',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CONFIGURED SAFE ZONES PREVIEW
            Text(
              'Active safe zones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            const _ZoneCard(
              title: 'Home Zone',
              subtitle: 'Primary residence • 500m radius',
              isCurrent: true,
            ),
            const SizedBox(height: 8),
            const _ZoneCard(
              title: 'City Hospital Zone',
              subtitle: 'Medical clinic • 300m radius',
              isCurrent: false,
            ),
            const SizedBox(height: 8),
            const _ZoneCard(
              title: 'Local Market Zone',
              subtitle: 'Daily market • 250m radius',
              isCurrent: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
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

class _ZoneCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCurrent;

  const _ZoneCard({
    required this.title,
    required this.subtitle,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isCurrent ? const Color(0xFF1E8E5A) : Colors.black38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F6ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Present',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E8E5A),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD6E0EC)
      ..strokeWidth = 1;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
