import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../../../core/network/token_holder.dart';
import '../domain/models/app_user.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Drives the login screen and gates the rest of the app. On success,
/// stores the JWT in TokenHolder (so ApiClient attaches it automatically
/// to every future request) and fetches the real user profile so the
/// dashboard can stop showing a hardcoded name.
class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState.unauthenticated());

  Future<void> login({required String email, required String password}) async {
    state = const AuthState(status: AuthStatus.authenticating);
    try {
      final token = await ApiService.login(email: email, password: password);
      TokenHolder.instance.setToken(token);

      final user = await ApiService.getCurrentUser();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      TokenHolder.instance.clear();
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  void logout() {
    TokenHolder.instance.clear();
    state = const AuthState.unauthenticated();
  }

  String _friendlyError(Object e) {
    final message = e.toString();
    if (message.contains('401')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('SocketException') ||
        message.contains('connection')) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController();
});