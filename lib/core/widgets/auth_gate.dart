import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/location/presentation/screens/elderly_tracking_screen.dart';

/// Root-level switch:
/// - caretaker -> caretaker dashboard
/// - elderly -> elderly GPS tracking screen
/// - unauthenticated -> login screen
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    final user = authState.user;

    if (user?.role == 'elderly') {
      return const ElderlyTrackingScreen();
    }

    return const DashboardScreen();
  }
}