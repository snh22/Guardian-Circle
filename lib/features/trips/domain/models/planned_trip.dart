/// Matches the real backend's Trip model exactly:
/// { "trip_id": 1, "user_id": 1, "destination": "...",
///   "start_time": "2026-09-14T10:00:00", "status": "planned" }
/// Note: the backend has NO end_time field — trips are open-ended once
/// started, only "status" tracks whether they're still active.
class PlannedTrip {
  final int tripId;
  final String destination;
  final DateTime startTime;
  final String status; // "planned" | "active" | "completed" | "cancelled"

  const PlannedTrip({
    required this.tripId,
    required this.destination,
    required this.startTime,
    required this.status,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isPlanned => status.toLowerCase() == 'planned';

  factory PlannedTrip.fromJson(Map<String, dynamic> json) {
    return PlannedTrip(
      tripId: json['trip_id'] as int,
      destination: json['destination'] as String,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      status: json['status'] as String? ?? 'planned',
    );
  }
}