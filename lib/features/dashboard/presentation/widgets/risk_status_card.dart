import 'package:flutter/material.dart';

import '../../../../core/constants/risk_level.dart';
import '../../domain/models/guardian_status.dart';

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
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: level.color.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // TOP LABEL
              // =========================================================

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: level.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          size: 15,
                          color: level.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CURRENT SAFETY STATUS',
                          style: TextStyle(
                            color: level.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: Colors.black38,
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // =========================================================
              // MAIN STATUS
              // =========================================================

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StatusIcon(level: level),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.label,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: level.color,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          level.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // =========================================================
              // INFORMATION PANEL
              // =========================================================

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _StatusRow(
                      icon: Icons.location_on_rounded,
                      label: status.safeZoneState.displayText,
                    ),

                    const SizedBox(height: 12),

                    _StatusRow(
                      icon: Icons.history_rounded,
                      label:
                          '${status.latestEvent.summary} • ${_formatTime(status.latestEvent.timestamp)}',
                    ),

                    if (status.batteryPercent != null) ...[
                      const SizedBox(height: 12),
                      _StatusRow(
                        icon: Icons.battery_std_rounded,
                        label:
                            'Band battery ${status.batteryPercent!.round()}%',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // =========================================================
              // VIEW LOCATION HINT
              // =========================================================

              if (onTap != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 16,
                      color: const Color(0xFF1F3A5F),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tap to view patient location',
                      style: TextStyle(
                        color: const Color(0xFF1F3A5F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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

// =======================================================================
// STATUS ICON
// =======================================================================

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
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: widget.level.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: widget.level.color.withValues(alpha: 0.25),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        widget.level.icon,
        color: Colors.white,
        size: 31,
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

// =======================================================================
// STATUS ROW
// =======================================================================

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
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EEF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF1F3A5F),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
