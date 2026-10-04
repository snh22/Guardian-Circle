/// All backend endpoint paths in one place, matching the routes that
/// already exist in the FastAPI backend (auth.py, users.py, location.py,
/// events.py, alerts.py, trips.py, risk.py, profile.py).
/// No logic here — just the path strings, so nothing else in the app
/// hardcodes a URL.
class ApiEndpoints {
  ApiEndpoints._();

  static const health = '/health';

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  static const login = '/api/v1/auth/login';
  static const register = '/api/v1/auth/register';

  // ---------------------------------------------------------------------
  // Current user
  // ---------------------------------------------------------------------

  static const currentUser = '/api/v1/users/me';

  // ---------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------

  static const location = '/api/v1/location';

  static String locationLatest(String userId) =>
      '/api/v1/location/latest/$userId';

  // ---------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------

  static const events = '/api/v1/events';

  static String eventsForUser(String userId) =>
      '/api/v1/events/user/$userId';

  // ---------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------

  static String alertsForUser(String userId) =>
      '/api/v1/alerts/user/$userId';

  static String resolveAlert(String alertId) =>
      '/api/v1/alerts/$alertId/resolve';

  // ---------------------------------------------------------------------
  // Elderly Profile
  // ---------------------------------------------------------------------

  static String elderlyProfile(String elderlyUserId) =>
      '/api/v1/profile/$elderlyUserId';

  static const linkElderlyProfile = '/api/v1/profile/link';

  // ---------------------------------------------------------------------
  // Trips
  // ---------------------------------------------------------------------

  static const trips = '/api/v1/trips';

  static String tripsForUser(String userId) =>
      '/api/v1/trips/user/$userId';

  static String tripById(String tripId) =>
      '/api/v1/trips/$tripId';

  // ---------------------------------------------------------------------
  // Risk
  // ---------------------------------------------------------------------

  static const riskAnalyze = '/api/v1/risk/analyze';
}