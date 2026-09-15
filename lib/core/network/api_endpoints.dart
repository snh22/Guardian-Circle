/// All backend endpoint paths in one place, matching the routes that
/// already exist in the FastAPI backend (auth.py, users.py, location.py,
/// events.py, alerts.py, trips.py, risk.py). No logic here — just the
/// path strings, so nothing else in the app hardcodes a URL.
class ApiEndpoints {
  ApiEndpoints._();

  static const health = '/health';

  static const login = '/api/v1/auth/login';
  static const register = '/api/v1/auth/register';

  static const currentUser = '/api/v1/users/me';

  static const location = '/api/v1/location';
  static String locationLatest(String userId) =>
      '/api/v1/location/latest/$userId';

  static const events = '/api/v1/events';
  static String eventsForUser(String userId) => '/api/v1/events/user/$userId';

  static String alertsForUser(String userId) => '/api/v1/alerts/user/$userId';
  static String resolveAlert(String alertId) =>
      '/api/v1/alerts/$alertId/resolve';

  static const trips = '/api/v1/trips';
  static String tripsForUser(String userId) => '/api/v1/trips/user/$userId';
  static String tripById(String tripId) => '/api/v1/trips/$tripId';

  static const riskAnalyze = '/api/v1/risk/analyze';
}