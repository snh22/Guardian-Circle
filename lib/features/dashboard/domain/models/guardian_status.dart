import 'package:guardian_circle/core/constants/risk_level.dart';

/// Snapshot of "is the person safe?" — the single question the whole
/// dashboard is designed around.
class GuardianStatus {
  final RiskLevel riskLevel;
  final String userName;
  final SafeZoneState safeZoneState;
  final TimelineEvent latestEvent;
  final double? batteryPercent; // band battery, null if disconnected
  final DateTime lastUpdated;

  const GuardianStatus({
    required this.riskLevel,
    required this.userName,
    required this.safeZoneState,
    required this.latestEvent,
    required this.lastUpdated,
    this.batteryPercent,
  });

  GuardianStatus copyWith({
    RiskLevel? riskLevel,
    SafeZoneState? safeZoneState,
    TimelineEvent? latestEvent,
    double? batteryPercent,
    DateTime? lastUpdated,
  }) {
    return GuardianStatus(
      riskLevel: riskLevel ?? this.riskLevel,
      userName: userName,
      safeZoneState: safeZoneState ?? this.safeZoneState,
      latestEvent: latestEvent ?? this.latestEvent,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

enum SafeZoneStatus { insideHome, outsidePlannedTrip, outsideUnplanned, unknown }

class SafeZoneState {
  final SafeZoneStatus status;
  final String zoneLabel; // e.g. "Home Zone", "Market Trip"
  final bool tripActive;

  const SafeZoneState({
    required this.status,
    required this.zoneLabel,
    this.tripActive = false,
  });

  String get displayText => switch (status) {
        SafeZoneStatus.insideHome => 'Inside $zoneLabel',
        SafeZoneStatus.outsidePlannedTrip => 'Outside $zoneLabel • Trip active',
        SafeZoneStatus.outsideUnplanned => 'Outside $zoneLabel • No trip planned',
        SafeZoneStatus.unknown => 'Zone unknown',
      };
}

enum EventKind { movement, location, ble, sos, fallLike, checkIn, tripStart, tripEnd }

class TimelineEvent {
  final String id;
  final EventKind kind;
  final String summary; // e.g. "Movement normal"
  final DateTime timestamp;
  final RiskLevel? associatedRisk;
  final String? context;

  const TimelineEvent({
    required this.id,
    required this.kind,
    required this.summary,
    required this.timestamp,
    this.associatedRisk,
    this.context,
  });
}

class PlannedTrip {
  final String id;
  final String label;
  final DateTime start;
  final DateTime end;
  final String destinationZone;
  final bool isActive;

  const PlannedTrip({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    required this.destinationZone,
    this.isActive = false,
  });
}

enum BandConnectionState { disconnected, scanning, connecting, connected }

class BandTelemetry {
  final BandConnectionState connectionState;
  final double? batteryPercent;
  final String? deviceName;
  final DateTime? lastSeen;

  const BandTelemetry({
    required this.connectionState,
    this.batteryPercent,
    this.deviceName,
    this.lastSeen,
  });
}
