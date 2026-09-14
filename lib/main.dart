import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/auth_gate.dart';
import 'features/ble/presentation/screens/ble_connection_screen.dart';
import 'features/map/presentation/screens/live_map_screen.dart';
import 'features/trips/presentation/screens/trips_screen.dart';

void main() {
  // Stops google_fonts from trying to download fonts over the network at
  // runtime (fails on emulators/devices without internet access). Falls
  // back to the closest bundled system font instead of throwing.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const ProviderScope(child: GuardianCircleApp()));
}

class GuardianCircleApp extends StatelessWidget {
  const GuardianCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Circle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
      routes: {
        '/map': (_) => const LiveMapScreen(),
        '/ble': (_) => const BleConnectionScreen(),
        '/trips': (_) => const TripsScreen(),
      },
    );
  }
}