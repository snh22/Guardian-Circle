import 'package:flutter/material.dart';

import '../../../../core/constants/risk_level.dart';
import '../../domain/models/guardian_status.dart';

/// The single most important widget in the app: answers "is the person
/// safe?" at a glance. Large type, a solid color block (never color alone —
/// always paired with icon + label text), and a subtle pulse for
/// Critical so it can't be missed even in a peripheral glance.
class RiskStatusCard extends StatelessWidget {
  final GuardianStatus status;
  final VoidCallback? onTap;

  const RiskStatusCard({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final level = status.riskLevel;

    return Semantics(
      label: '${level.label}. ${level.description}',
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
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
              Row(
                children: [
                  _StatusIcon(level: level),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // RISK LEVEL
                        Text(
                          level.label,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: level.color,
                              ),
                        ),

                        const SizedBox(height: 4),

                        // RISK DESCRIPTION
                        Text(
                          level.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Divider(
                color: level.color.withValues(alpha: 0.25),
              ),

              const SizedBox(height: 12),

              // SAFE ZONE
              _StatusRow(
                icon: Icons.location_on_outlined,
                label: status.safeZoneState.displayText,
              ),

              const SizedBox(height: 8),

              // LATEST EVENT
              _StatusRow(
                icon: Icons.history_toggle_off_rounded,
                label:
                    '${status.latestEvent.summary} • ${_formatTime(status.latestEvent.timestamp)}',
              ),

              // BATTERY
              if (status.batteryPercent != null) ...[
                const SizedBox(height: 8),

                _StatusRow(
                  icon: Icons.watch_outlined,
                  label:
                      'Band battery ${status.batteryPercent!.round()}%',
                ),
              ],
            ],
          ),
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

/// Pulsing ring for Critical, static for everything else.
class _StatusIcon extends StatefulWidget {
  final RiskLevel level;

  const _StatusIcon({
    required this.level,
  });

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCritical =
        widget.level == RiskLevel.critical;

    final child = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: widget.level.color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        widget.level.icon,
        color: Colors.white,
        size: 30,
      ),
    );

    if (!isCritical) {
      return child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale =
            1.0 + (_controller.value * 0.12);

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }
}

/// Individual information row inside the risk card.
///
/// Text color is explicitly set to dark so that values such as
/// "Zone unknown" and "Waiting for first signal" remain readable
/// regardless of the global theme.
class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.black54,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: Colors.black87,
                ),
          ),
        ),
      ],
    );
  }
}