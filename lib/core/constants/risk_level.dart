import 'package:flutter/material.dart';

/// Maps 1:1 to the Guardian Circle risk engine's four escalation levels.
/// LOW/MEDIUM/HIGH mirror sustained-signal risk; CRITICAL is reserved for
/// high-confidence SOS / fall-like events that require immediate action.
enum RiskLevel { low, medium, high, critical }

extension RiskLevelX on RiskLevel {
  String get label => switch (this) {
        RiskLevel.low => 'Low Risk',
        RiskLevel.medium => 'Medium Risk',
        RiskLevel.high => 'High Risk',
        RiskLevel.critical => 'Critical',
      };

  String get description => switch (this) {
        RiskLevel.low => 'Stable location • Expected movement',
        RiskLevel.medium => 'Routine deviation • Soft check-in suggested',
        RiskLevel.high => 'Multiple signals agree • Please review',
        RiskLevel.critical => 'SOS / fall-like event • Immediate action needed',
      };

  /// High-contrast colors chosen for accessibility (WCAG AA+) — never rely on
  /// color alone since labels and icons always accompany status.
  Color get color => switch (this) {
        RiskLevel.low => const Color(0xFF1E8E5A), // green
        RiskLevel.medium => const Color(0xFFC98A00), // amber (darkened for contrast)
        RiskLevel.high => const Color(0xFFE2621B), // orange
        RiskLevel.critical => const Color(0xFFD32F2F), // red
      };

  Color get backgroundTint => switch (this) {
        RiskLevel.low => const Color(0xFFE7F6ED),
        RiskLevel.medium => const Color(0xFFFFF4DE),
        RiskLevel.high => const Color(0xFFFFEADD),
        RiskLevel.critical => const Color(0xFFFDE7E7),
      };

  IconData get icon => switch (this) {
        RiskLevel.low => Icons.check_circle_rounded,
        RiskLevel.medium => Icons.info_rounded,
        RiskLevel.high => Icons.warning_rounded,
        RiskLevel.critical => Icons.emergency_rounded,
      };

  /// Whether this level should trigger the full-screen escalation modal
  /// rather than an in-dashboard banner.
  bool get requiresFullScreenAlert => this == RiskLevel.critical;
}