import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

/// Root-level switch: shows the login screen until the caregiver is
/// authenticated, then shows the real dashboard. Because TokenHolder is
/// in-memory only (see token_holder.dart), this currently resets to the
/// login screen on every app restart — swap in persistent token storage
/// later if "stay logged in" is wanted.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState.isAuthenticated) {
      return const DashboardScreen();
    }
    return const LoginScreen();
  }
}