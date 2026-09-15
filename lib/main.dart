import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
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
      home: const GuardianHome(),
    );
  }
}

class GuardianHome extends StatefulWidget {
  const GuardianHome({super.key});

  @override
  State<GuardianHome> createState() => _GuardianHomeState();
}

class _GuardianHomeState extends State<GuardianHome> {
  final FlutterBlePeripheral blePeripheral =
      FlutterBlePeripheral();

  bool advertising = false;
  bool supported = false;

  String bleStatus = 'Checking Bluetooth...';

  // Guardian Circle manufacturer ID.
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

      if (!mounted) return;

      setState(() {
        supported = isSupported;

        if (isSupported) {
          bleStatus = 'BLE advertising supported';
        } else {
          bleStatus = 'BLE advertising not supported';
        }
      });
    } catch (e) {
      if (!mounted) return;

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

      if (!mounted) return;

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

      /*
       * WINDOWS BLE REQUIREMENT
       *
       * Windows requires either:
       *
       *   manufacturerData
       *
       * OR
       *
       *   serviceData
       *
       * to be present.
       *
       * We previously tried advertising only the service UUID,
       * which Windows rejected with:
       *
       * invalid_arguments:
       * Windows can only advertise manufactureData and
       * serviceData, one of which has to be set
       *
       * We now use only ONE manufacturer byte.
       *
       * This keeps the advertisement extremely small and
       * avoids the previous DATA_TOO_LARGE problem.
       *
       * 0x47 = ASCII 'G'
       *
       * The patient app will identify the Guardian using:
       *
       * manufacturer ID = 0x1234
       * manufacturer byte = 0x47
       */
      final result = await blePeripheral.start(
        advertiseData: AdvertiseDataCore(
          manufacturerId: guardianManufacturerId,
          manufacturerData: Uint8List.fromList([
            0x47,
          ]),
        ),
      );

      if (!mounted) return;

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
      if (!mounted) return;

      setState(() {
        advertising = false;
        bleStatus = 'BLE start failed: $e';
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

      if (!mounted) return;

      setState(() {
        advertising = false;
        bleStatus = 'BLE advertising stopped';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Guardian Circle BLE stopped',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        bleStatus = 'BLE stop failed: $e';
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
        title: const Text('Guardian Circle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.shield,
              size: 80,
            ),

            const SizedBox(height: 20),

            const Text(
              'Guardian Circle',
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
              onPressed: advertising
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
              onPressed: advertising
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
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const DashboardScreen(),
                  ),
                );
              },
              child: const Text(
                'OPEN GUARDIAN DASHBOARD',
              ),
            ),

            const SizedBox(height: 30),

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