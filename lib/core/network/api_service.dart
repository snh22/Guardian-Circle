import '../../features/auth/domain/models/app_user.dart';
import '../../features/dashboard/domain/models/guardian_status.dart';
import '../../features/trips/domain/models/planned_trip.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

/// Every backend call goes through this class — screens and providers
/// never touch Dio directly. Matches the real FastAPI backend's routes
/// (auth.py, users.py, risk.py, events.py) as inspected from the actual
/// backend code, not a guessed contract.
class ApiService {
  static Future<dynamic> healthCheck() async {
    final response = await ApiClient.dio.get(ApiEndpoints.health);
    return response.data;
  }

  // ---------------------------------------------------------------------
  // Stage 3 — Auth
  // ---------------------------------------------------------------------

  /// POST /api/v1/auth/login
  /// Returns the raw access token string. Throws DioException on 401
  /// (invalid credentials) — let the caller catch and show a message.
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return response.data['access_token'] as String;
  }

  // ---------------------------------------------------------------------
  // Stage 4 — Current user
  // ---------------------------------------------------------------------

  /// GET /api/v1/users/me — requires the Bearer token to already be set
  /// via TokenHolder (ApiClient's interceptor attaches it automatically).
  static Future<AppUser> getCurrentUser() async {
    final response = await ApiClient.dio.get(ApiEndpoints.currentUser);
    return AppUser.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------
  // Stage 5 — Risk engine
  // ---------------------------------------------------------------------

  /// POST /api/v1/risk/analyze — no auth required on this one endpoint.
  /// Backend expects: movement, location_status, trip_status, event_type
  /// (all free-text strings the backend lowercases itself) and returns:
  /// { "risk_level": "LOW"|"MEDIUM"|"HIGH"|"CRITICAL", "reason": [...],
  ///   "recommended_action": "..." }
  static Future<Map<String, dynamic>> analyzeRisk({
    required String movement,
    required String locationStatus,
    required String tripStatus,
    required String eventType,
  }) async {
    final response = await ApiClient.dio.post(
      ApiEndpoints.riskAnalyze,
      data: {
        'movement': movement,
        'location_status': locationStatus,
        'trip_status': tripStatus,
        'event_type': eventType,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------
  // Stage 6 — Events
  // ---------------------------------------------------------------------

  /// GET /api/v1/events/user/{user_id} — requires auth.
  /// Backend events have NO summary text field (only event_type,
  /// risk_level, timestamp) — TimelineEvent.fromJson synthesizes a
  /// readable summary from event_type on the Flutter side.
  static Future<List<TimelineEvent>> getEventsForUser(int userId) async {
    final response =
        await ApiClient.dio.get(ApiEndpoints.eventsForUser('$userId'));
    final list = response.data as List<dynamic>;
    return list
        .map((json) => TimelineEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Stage 8: getAlertsForUser(userId), resolveAlert(alertId)

  // ---------------------------------------------------------------------
  // Stage 7 — Location
  // ---------------------------------------------------------------------

  /// POST /api/v1/location — sends the phone's current GPS fix.
  static Future<void> postLocation({
    required int userId,
    required double latitude,
    required double longitude,
  }) async {
    await ApiClient.dio.post(
      ApiEndpoints.location,
      data: {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  /// GET /api/v1/location/latest/{user_id}
  /// Returns null if no location has ever been recorded for this user
  /// (backend responds 404 in that case).
  static Future<Map<String, dynamic>?> getLatestLocation(int userId) async {
    try {
      final response =
          await ApiClient.dio.get(ApiEndpoints.locationLatest('$userId'));
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Stage 9 — Trips
  // ---------------------------------------------------------------------

  /// POST /api/v1/trips
  static Future<PlannedTrip> createTrip({
    required int userId,
    required String destination,
    required DateTime startTime,
  }) async {
    final response = await ApiClient.dio.post(
      ApiEndpoints.trips,
      data: {
        'user_id': userId,
        'destination': destination,
        'start_time': startTime.toUtc().toIso8601String(),
        'status': 'planned',
      },
    );
    return PlannedTrip.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/v1/trips/user/{user_id}
  static Future<List<PlannedTrip>> getTripsForUser(int userId) async {
    final response =
        await ApiClient.dio.get(ApiEndpoints.tripsForUser('$userId'));
    final list = response.data as List<dynamic>;
    return list
        .map((json) => PlannedTrip.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// PUT /api/v1/trips/{trip_id} — commonly used just to change status,
  /// e.g. "planned" -> "active" -> "completed"/"cancelled".
  static Future<PlannedTrip> updateTrip({
    required int tripId,
    String? destination,
    DateTime? startTime,
    String? status,
  }) async {
    final response = await ApiClient.dio.put(
      ApiEndpoints.tripById('$tripId'),
      data: {
        if (destination != null) 'destination': destination,
        if (startTime != null)
          'start_time': startTime.toUtc().toIso8601String(),
        if (status != null) 'status': status,
      },
    );
    return PlannedTrip.fromJson(response.data as Map<String, dynamic>);
  }

  /// DELETE /api/v1/trips/{trip_id}
  static Future<void> deleteTrip(int tripId) async {
    await ApiClient.dio.delete(ApiEndpoints.tripById('$tripId'));
  }
}