import 'package:flutter/material.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onViewMap;
  final VoidCallback onCall;
  final VoidCallback onAcknowledge;
  final bool acknowledgeEnabled;

  const QuickActionsRow({
    super.key,
    required this.onViewMap,
    required this.onCall,
    required this.onAcknowledge,
    this.acknowledgeEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.map_rounded,
                label: 'Map',
                subtitle: 'Location',
                color: const Color(0xFF1F3A5F),
                onTap: onViewMap,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _ActionCard(
                icon: Icons.call_rounded,
                label: 'Call',
                subtitle: 'Patient',
                color: const Color(0xFF1E8E5A),
                onTap: onCall,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _ActionCard(
                icon: Icons.check_circle_rounded,
                label: 'Acknowledge',
                subtitle: 'Alerts',
                color: const Color(0xFF1F3A5F),
                onTap: acknowledgeEnabled ? onAcknowledge : null,
                enabled: acknowledgeEnabled,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        enabled ? color : Colors.grey;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 116,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: effectiveColor.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: effectiveColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled
                      ? Colors.black87
                      : Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled
                      ? Colors.black45
                      : Colors.black26,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}