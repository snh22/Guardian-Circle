import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/auth_gate.dart';
import 'features/ble/presentation/screens/ble_connection_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/map/presentation/screens/live_map_screen.dart';
import 'features/trips/presentation/screens/trips_screen.dart';

void main() {
  // Stops google_fonts from trying to download fonts over the network at
  // runtime. Falls back to the closest bundled system font.
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    const ProviderScope(
      child: GuardianCircleApp(),
    ),
  );
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
        '/dashboard': (_) => const DashboardScreen(),
        '/guardian-ble': (_) => const GuardianBleAdvertiserScreen(),
      },
    );
  }
}

// ============================================================================
// GUARDIAN BLE ADVERTISER
//
// The caretaker device advertises a tiny BLE manufacturer packet.
//
// Manufacturer ID: 0x1234
// Identifier byte: 0x47 ('G')
//
// The patient phone scans for this advertisement to identify the Guardian.
// ============================================================================

class GuardianBleAdvertiserScreen extends StatefulWidget {
  const GuardianBleAdvertiserScreen({
    super.key,
  });

  @override
  State<GuardianBleAdvertiserScreen> createState() =>
      _GuardianBleAdvertiserScreenState();
}

class _GuardianBleAdvertiserScreenState
    extends State<GuardianBleAdvertiserScreen> {
  final FlutterBlePeripheral blePeripheral =
      FlutterBlePeripheral();

  bool advertising = false;
  bool supported = false;

  String bleStatus = 'Checking Bluetooth...';

  static const int guardianManufacturerId = 0x1234;

  @override
  void initState() {
    super.initState();
    checkBle();
  }

  Future<void> checkBle() async {
    try {
      final isSupported =
          await blePeripheral.isSupported;

      if (!mounted) {
        return;
      }

      setState(() {
        supported = isSupported;

        if (isSupported) {
          bleStatus = 'BLE advertising supported';
        } else {
          bleStatus =
              'BLE advertising not supported';
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        bleStatus = 'BLE check failed: $e';
      });
    }
  }

  Future<void> startGuardianBle() async {
    try {
      if (!supported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'BLE advertising is not supported.',
            ),
          ),
        );

        return;
      }

      final permission =
          await blePeripheral.requestPermission();

      if (!mounted) {
        return;
      }

      final permissionString =
          permission.toString().toLowerCase();

      if (permissionString.contains('denied') ||
          permissionString.contains('unsupported')) {
        setState(() {
          bleStatus =
              'BLE permission/support issue: $permission';
        });

        return;
      }

      // Windows requires manufacturerData or serviceData.
      //
      // Keep the packet extremely small:
      //
      // Manufacturer ID = 0x1234
      // Identifier      = 0x47 ('G')
      //
      // The patient app uses this combination to identify
      // the Guardian Circle device.

      final result = await blePeripheral.start(
        advertiseData: AdvertiseDataCore(
          manufacturerId:
              guardianManufacturerId,
          manufacturerData:
              Uint8List.fromList([
            0x47,
          ]),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        advertising = true;
        bleStatus =
            'GUARDIAN CIRCLE BLE ADVERTISING';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'BLE started: $result',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        advertising = false;
        bleStatus =
            'BLE start failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'BLE advertising failed: $e',
          ),
        ),
      );
    }
  }

  Future<void> stopGuardianBle() async {
    try {
      await blePeripheral.stop();

      if (!mounted) {
        return;
      }

      setState(() {
        advertising = false;
        bleStatus =
            'BLE advertising stopped';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Guardian Circle BLE stopped',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        bleStatus =
            'BLE stop failed: $e';
      });
    }
  }

  @override
  void dispose() {
    blePeripheral.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Guardian BLE',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.bluetooth,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'Guardian Circle BLE',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'BLE STATUS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              bleStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              supported
                  ? 'Peripheral mode supported'
                  : 'Checking peripheral support...',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed:
                  advertising
                      ? null
                      : startGuardianBle,
              icon: const Icon(
                Icons.bluetooth,
              ),
              label: Text(
                advertising
                    ? 'BLE ADVERTISING'
                    : 'START GUARDIAN BLE',
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed:
                  advertising
                      ? stopGuardianBle
                      : null,
              icon: const Icon(
                Icons.bluetooth_disabled,
              ),
              label: const Text(
                'STOP GUARDIAN BLE',
              ),
            ),

            const SizedBox(height: 40),

            const Divider(),

            const SizedBox(height: 20),

            const Text(
              'Guardian Circle BLE Identifier',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Manufacturer ID: 0x1234\n'
              'Identifier: 0x47 (G)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
