/// Holds the current session's JWT in memory so ApiClient's interceptor
/// can attach it to every outgoing request without each call site having
/// to pass it around manually.
///
/// NOTE: this is intentionally simple (in-memory only) to get login
/// working end-to-end first. It means the token is lost on app restart,
/// requiring a fresh login each time. Once the core flow is proven out,
/// swap this for flutter_secure_storage so the session persists — that's
/// a drop-in change localized entirely to this one file.
class TokenHolder {
  TokenHolder._();
  static final TokenHolder instance = TokenHolder._();

  String? _token;

  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  void setToken(String token) => _token = token;
  void clear() => _token = null;
}