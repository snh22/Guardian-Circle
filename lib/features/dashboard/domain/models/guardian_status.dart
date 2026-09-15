import '../../../../core/constants/risk_level.dart';

/// Parses the risk-engine's string value (e.g. "low", "medium") into the
/// app's RiskLevel enum. Backend contract: lowercase strings matching the
/// four escalation levels in the project's risk-engine design.
RiskLevel riskLevelFromString(String value) {
  return switch (value.toLowerCase()) {
    'low' => RiskLevel.low,
    'medium' => RiskLevel.medium,
    'high' => RiskLevel.high,
    'critical' => RiskLevel.critical,
    _ => RiskLevel.low,
  };
}

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

EventKind _eventKindFromString(String value) {
  return switch (value.toLowerCase()) {
    'movement' => EventKind.movement,
    'location' => EventKind.location,
    'ble' => EventKind.ble,
    'sos' => EventKind.sos,
    'fall_like' || 'falllike' => EventKind.fallLike,
    'check_in' || 'checkin' => EventKind.checkIn,
    'trip_start' || 'tripstart' => EventKind.tripStart,
    'trip_end' || 'tripend' => EventKind.tripEnd,
    _ => EventKind.movement,
  };
}

/// Turns the backend's raw event_type string into a readable phrase for
/// the timeline UI, since the backend doesn't store display text itself.
String _summaryFromEventType(String eventType) {
  return switch (eventType.toLowerCase()) {
    'movement' => 'Movement normal',
    'unusual_movement' || 'unusual movement' => 'Unusual movement detected',
    'location' => 'Location updated',
    'ble' => 'Band connected',
    'sos' => 'SOS triggered',
    'fall_like' || 'fall' => 'Possible fall detected',
    'check_in' => 'Check-in received',
    'trip_start' => 'Planned trip started',
    'trip_end' => 'Planned trip ended',
    _ => eventType.replaceAll('_', ' '),
  };
}

class TimelineEvent {
  final String id;
  final EventKind kind;
  final String summary; // e.g. "Movement normal"
  final DateTime timestamp;
  final RiskLevel? associatedRisk;

  const TimelineEvent({
    required this.id,
    required this.kind,
    required this.summary,
    required this.timestamp,
    this.associatedRisk,
  });

  /// The REAL backend's EventResponse has no summary text field — only
  /// { "event_id": 1, "user_id": 1, "event_type": "movement",
  ///   "risk_level": "LOW", "timestamp": "2026-09-13T10:24:00" }.
  /// So this synthesizes a human-readable summary from event_type on
  /// the Flutter side rather than expecting the backend to provide one.
  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    final eventType = json['event_type'] as String? ?? 'movement';
    return TimelineEvent(
      id: '${json['event_id']}',
      kind: _eventKindFromString(eventType),
      summary: _summaryFromEventType(eventType),
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      associatedRisk: json['risk_level'] != null
          ? riskLevelFromString(json['risk_level'] as String)
          : null,
    );
  }
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