import 'package:flutter/material.dart';
import 'package:guardian_circle/core/constants/risk_level.dart';
import 'package:guardian_circle/features/dashboard/domain/models/guardian_status.dart';

/// The central safety status card: answers "is my loved one okay right now?"
/// Designed with strong visual hierarchy, accessible WCAG AA+ contrast,
/// large clear typography, and an honest preview badge.
/// No misleading pulsing animations are used.
class RiskStatusCard extends StatelessWidget {
  final GuardianStatus status;
  final bool isPreview;
  final String locationText;
  final String movementText;

  const RiskStatusCard({
    super.key,
    required this.status,
    required this.isPreview,
    required this.locationText,
    required this.movementText,
  });

  @override
  Widget build(BuildContext context) {
    final level = status.riskLevel;

    return Semantics(
      label: '${level.label}. ${level.description}',
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: level.backgroundTint,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: level.color.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPreview) ...[
              const _PreviewBadge(),
              const SizedBox(height: 14),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: level.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(level.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: level.color,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black87,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(color: level.color.withValues(alpha: 0.25)),
            const SizedBox(height: 12),
            _StatusRow(
              icon: Icons.place_outlined,
              label: 'Location: $locationText',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              icon: Icons.directions_walk_rounded,
              label: 'Movement: $movementText',
            ),
            const SizedBox(height: 8),
            _StatusRow(
              icon: Icons.access_time_rounded,
              label: 'Updated ${_formatTime(status.lastUpdated)} (Preview)',
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
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
        color: const Color(0xFFEAE8F7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF5D5B8D)),
          SizedBox(width: 6),
          Text(
            'Preview — not live',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5D5B8D),
            ),
          ),
        ],
      ),
    );
  }
}
