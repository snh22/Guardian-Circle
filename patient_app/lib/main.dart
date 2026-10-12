import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'proximity/ble_proximity_engine.dart';
import 'sensors/fall_detector.dart';

void main() {
  runApp(const SensorApp());
}

class SensorApp extends StatelessWidget {
  const SensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F8F9D),
          brightness: Brightness.light,
          primary: const Color(0xFF24445F),
          secondary: const Color(0xFF2F8F9D),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F8FA),
          foregroundColor: Color(0xFF1F3A52),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF24445F),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2F8F9D),
            side: const BorderSide(color: Color(0xFF2F8F9D)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF2F8F9D)),
        ),
      ),
      home: const SensorPage(),
    );
  }
}

class SensorPage extends StatefulWidget {
  const SensorPage({super.key});

  @override
  State<SensorPage> createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final FallDetector detector = FallDetector();

  // Patient-side fall alarm. Independent of detector reset and network status.
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _alarmActive = false;
  bool _showEmergencyOverlay = false;

  Future<void> _startAlarm() async {
    if (_alarmActive) return;
    _alarmActive = true;

    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.play(
        AssetSource('audio/critical_alert.wav'),
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('Patient alarm audio error: $e');
    }

    if (!_alarmActive) return;

    try {
      await Vibration.vibrate(pattern: [0, 500, 300, 500], repeat: 0);
    } catch (e) {
      debugPrint('Patient alarm vibration error: $e');
    }
  }

  Future<void> _stopAlarm() async {
    _alarmActive = false;
    try {
      await _alarmPlayer.stop();
    } catch (e) {
      debugPrint('Patient alarm stop error: $e');
    }
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Patient vibration cancel error: $e');
    }
  }

  bool sendingFall = false;
  bool automaticFallSent = false;

  bool gettingLocation = false;
  Position? currentPosition;

  int locationFixCount = 0;
  double? bestLocationAccuracy;
  String locationQuality = 'NOT TESTED';

  // ============================================================
  // BLE
  // ============================================================

  bool scanningBle = false;

  final Map<String, ScanResult> bleDevices = {};

  final Map<String, BleProximityEngine> proximityEngines = {};

  String? guardianDeviceId;

  BleProximityResult? guardianProximity;

  int totalBleResults = 0;

  // This must match the Guardian Circle Windows advertiser.
  static const int guardianManufacturerId = 0x1234;

  // 0x47 = ASCII 'G'
  static const int guardianIdentifierByte = 0x47;

  // ============================================================
  // GUARDIAN CIRCLE BACKEND
  // ============================================================

  // Android emulator -> Mac localhost
  static const String eventsUrl = 'http://192.168.1.10:8000/api/v1/events';

  // Elderly Test user in PostgreSQL
  static const int elderlyUserId = 3;

  // Paste your FRESH JWT here.
  // DO NOT share this token with anyone.
  static const String accessToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIzIiwiZXhwIjoxNzkxNzI1ODM1fQ.JAvVfmneax_04hLsGGNaKzc4KqATZEZgu1jmaggQ8GM';

  @override
  void initState() {
    super.initState();

    detector.onUpdate = () {
      if (!mounted) return;

      setState(() {});

      if (detector.fallState == 'POSSIBLE FALL' &&
          !automaticFallSent &&
          !sendingFall) {
        setState(() {
          _showEmergencyOverlay = true;
        });
        automaticFallSent = true;
        _startAlarm();
        sendAutomaticFall();
      }
    };

    detector.start();
  }

  // ============================================================
  // FALL DETECTION
  // ============================================================

  Future<void> sendAutomaticFall() async {
    debugPrint('🔥 sendAutomaticFall() CALLED');

    setState(() {
      sendingFall = true;
    });

    try {
      debugPrint('🔥 Sending FALL EVENT...');

      // STEP 1: Send fall event
      final eventResponse = await http.post(
        Uri.parse(eventsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'user_id': elderlyUserId,
          'event_type': 'fall',
          'risk_level': 'critical',
        }),
      );

      if (eventResponse.statusCode != 200) {
        if (!mounted) return;

        automaticFallSent = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fall event failed: '
              '${eventResponse.statusCode}\n'
              '${eventResponse.body}',
            ),
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FALL DETECTED — CARETAKER ALERT SENT")),
      );

      detector.resetFallState();
      automaticFallSent = false;
    } catch (e) {
      if (!mounted) return;

      automaticFallSent = false;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Automatic alert error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          sendingFall = false;
        });
      }
    }
  }

  Future<void> sendTestFall() async {
    await _startAlarm();
    if (!mounted) return;
    setState(() {
      sendingFall = true;
    });

    try {
      // STEP 1: Send fall event
      final eventResponse = await http.post(
        Uri.parse(eventsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'user_id': elderlyUserId,
          'event_type': 'fall',
          'risk_level': 'critical',
        }),
      );

      if (eventResponse.statusCode != 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fall event failed: '
              '${eventResponse.statusCode}\n'
              '${eventResponse.body}',
            ),
          ),
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        _showEmergencyOverlay = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FALL DETECTED — CARETAKER ALERT SENT")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Connection error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          sendingFall = false;
        });
      }
    }
  }

  // ============================================================
  // GPS
  // ============================================================

  Future<Position?> getAccurateLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final locationAccuracy = await Geolocator.getLocationAccuracy();

    if (locationAccuracy != LocationAccuracyStatus.precise) {
      if (mounted) {
        setState(() {
          locationQuality = 'APPROXIMATE LOCATION';
        });
      }

      return null;
    }

    Position? bestPosition;

    locationFixCount = 0;
    bestLocationAccuracy = null;

    for (int i = 0; i < 5; i++) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        locationFixCount++;

        if (bestPosition == null || position.accuracy < bestPosition.accuracy) {
          bestPosition = position;
          bestLocationAccuracy = position.accuracy;
        }

        if (mounted) {
          setState(() {
            currentPosition = bestPosition;
            bestLocationAccuracy = bestPosition?.accuracy;

            if (bestPosition != null) {
              if (bestPosition.accuracy <= 5) {
                locationQuality = 'EXCELLENT';
              } else if (bestPosition.accuracy <= 10) {
                locationQuality = 'GOOD';
              } else if (bestPosition.accuracy <= 20) {
                locationQuality = 'FAIR';
              } else {
                locationQuality = 'POOR';
              }
            }
          });
        }

        if (bestPosition != null) {
          final locationResponse = await http.post(
            Uri.parse('http://192.168.1.10:8000/api/v1/location'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'user_id': elderlyUserId,
              'latitude': bestPosition.latitude,
              'longitude': bestPosition.longitude,
              'accuracy': bestPosition.accuracy,
            }),
          );

          debugPrint(
            'LOCATION UPLOAD: ${locationResponse.statusCode} '
            '${locationResponse.body}',
          );
        }

        if (bestPosition != null && bestPosition.accuracy <= 5) {
          break;
        }

        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('LOCATION ERROR: $e');
        // Try the next fix.
      }
    }

    return bestPosition;
  }

  Future<void> getLocation() async {
    setState(() {
      gettingLocation = true;
      locationQuality = 'ACQUIRING...';
      locationFixCount = 0;
      bestLocationAccuracy = null;
    });

    try {
      final position = await getAccurateLocation();

      if (!mounted) return;

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to get precise location. '
              'Check GPS and location permissions.',
            ),
          ),
        );

        return;
      }

      setState(() {
        currentPosition = position;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Best GPS accuracy: '
            '${position.accuracy.toStringAsFixed(1)} m',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Location error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          gettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // GUARDIAN IDENTIFICATION
  // ============================================================

  bool isGuardianAdvertisement(AdvertisementData advertisementData) {
    final manufacturerData = advertisementData.manufacturerData;

    final guardianData = manufacturerData[guardianManufacturerId];

    if (guardianData != null &&
        guardianData.isNotEmpty &&
        guardianData[0] == guardianIdentifierByte) {
      return true;
    }

    for (final entry in manufacturerData.entries) {
      final bytes = entry.value;

      final text = String.fromCharCodes(
        bytes.where((byte) => byte >= 32 && byte <= 126),
      );

      if (text.contains('GUARDIAN')) {
        return true;
      }
    }

    final name = advertisementData.advName.toUpperCase();

    return name.contains('GUARDIAN');
  }

  String manufacturerDataText(AdvertisementData advertisementData) {
    if (advertisementData.manufacturerData.isEmpty) {
      return 'None';
    }

    final parts = <String>[];

    advertisementData.manufacturerData.forEach((id, bytes) {
      final hex = bytes
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(' ');

      parts.add('0x${id.toRadixString(16)}: $hex');
    });

    return parts.join('\n');
  }

  // ============================================================
  // BLE SCANNING
  // ============================================================

  Future<void> startBleScan() async {
    if (scanningBle) {
      return;
    }

    if (!await FlutterBluePlus.isSupported) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth LE is not supported on this phone.'),
        ),
      );

      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;

    if (adapterState != BluetoothAdapterState.on) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn Bluetooth ON.')),
      );

      return;
    }

    setState(() {
      scanningBle = true;
      bleDevices.clear();
      proximityEngines.clear();
      guardianDeviceId = null;
      guardianProximity = null;
      totalBleResults = 0;
    });

    try {
      await FlutterBluePlus.stopScan();

      final subscription = FlutterBluePlus.onScanResults.listen((results) {
        if (!mounted) return;

        setState(() {
          for (final result in results) {
            totalBleResults++;

            final deviceId = result.device.remoteId.str;

            bleDevices[deviceId] = result;

            proximityEngines.putIfAbsent(deviceId, () => BleProximityEngine());

            final isGuardian = isGuardianAdvertisement(
              result.advertisementData,
            );

            if (isGuardian && guardianDeviceId == null) {
              guardianDeviceId = deviceId;

              proximityEngines[deviceId]!.reset();
            }

            if (deviceId == guardianDeviceId) {
              guardianProximity = proximityEngines[deviceId]!.addRssi(
                result.rssi,
              );
            }
          }
        });
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 60),
        androidScanMode: AndroidScanMode.lowLatency,
        continuousUpdates: true,
        continuousDivisor: 1,
      );

      await FlutterBluePlus.isScanning.where((value) => value == false).first;

      await subscription.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('BLE scan error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          scanningBle = false;
        });
      }
    }
  }

  // ============================================================
  // GUARDIAN DEVICE SELECTION
  // ============================================================

  void selectGuardianDevice(String deviceId) {
    proximityEngines.putIfAbsent(deviceId, () => BleProximityEngine());

    setState(() {
      guardianDeviceId = deviceId;
      guardianProximity = null;
    });

    final device = bleDevices[deviceId];

    final name = device?.advertisementData.advName ?? '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          name.isEmpty
              ? 'Guardian Circle device selected'
              : '$name selected as Guardian Circle',
        ),
      ),
    );
  }

  void clearGuardianDevice() {
    setState(() {
      guardianDeviceId = null;
      guardianProximity = null;
    });
  }

  String proximityStateText(ProximityState? state) {
    switch (state) {
      case ProximityState.inside:
        return 'INSIDE GUARDIAN CIRCLE';

      case ProximityState.boundary:
        return 'BOUNDARY';

      case ProximityState.outside:
        return 'OUTSIDE GUARDIAN CIRCLE';

      case ProximityState.signalUncertain:
        return 'SIGNAL UNCERTAIN';

      case null:
        return 'NO GUARDIAN DEVICE';
    }
  }

  // ============================================================
  // FALL STATE RESET
  // ============================================================

  void resetFallState() {
    automaticFallSent = false;
    detector.resetFallState();
    _stopAlarm();
  }

  @override
  void dispose() {
    _alarmActive = false;
    Vibration.cancel();
    _alarmPlayer.stop();
    _alarmPlayer.dispose();
    detector.dispose();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final proximity = guardianProximity;

    Color fallColor() {
      switch (detector.fallState) {
        case 'POSSIBLE FALL':
          return const Color(0xFFC62828);
        case 'CHECKING AFTER IMPACT':
          return const Color(0xFFE58A00);
        case 'LOW DETECTED':
          return const Color(0xFFE58A00);
        default:
          return const Color(0xFF2E8B57);
      }
    }

    Color sensorStatusColor() {
      if (detector.status == 'HIGH ACCELERATION') {
        return const Color(0xFFC62828);
      }
      if (detector.status == 'LOW ACCELERATION') {
        return const Color(0xFFE58A00);
      }
      return const Color(0xFF2E8B57);
    }

    Widget sectionCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required Widget child,
    }) {
      return Card(
        elevation: 2,
        shadowColor: Colors.black12,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6F7),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: const Color(0xFF24445F), size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF1F3A52),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      );
    }

    Widget metricCard({
      required String label,
      required String value,
      required String unit,
      IconData? icon,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCE8EE)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: const Color(0xFF2F8F9D)),
              const SizedBox(width: 7),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF1F3A52),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(color: Colors.black45, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget valueTile({
      required String label,
      required String value,
      required String unit,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFC),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE0E9EE)),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF24445F),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(color: Colors.black45, fontSize: 9),
              ),
            ],
          ),
        ),
      );
    }

    Widget statusPill({required String text, required Color color}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF4F8FA),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFFF4F8FA),
            foregroundColor: const Color(0xFF1F3A52),
            titleSpacing: 20,
            title: const Text(
              'Patient Sensor Monitor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF24445F), Color(0xFF3F6F95)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GUARDIAN CIRCLE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Patient Safety Monitor',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Live sensor monitoring is active',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0x332E8B57),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.wifi_tethering_rounded,
                            color: Color(0xFFB8F2CF),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      statusPill(
                        text: 'MONITORING ACTIVE',
                        color: const Color(0xFF2E8B57),
                      ),
                      const Spacer(),
                      Text(
                        'User ID: $elderlyUserId',
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ACCELEROMETER
                  sectionCard(
                    icon: Icons.speed_rounded,
                    title: 'Accelerometer',
                    subtitle: 'Live movement and acceleration',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            valueTile(
                              label: 'X AXIS',
                              value: detector.x.toStringAsFixed(2),
                              unit: 'm/s²',
                            ),
                            const SizedBox(width: 8),
                            valueTile(
                              label: 'Y AXIS',
                              value: detector.y.toStringAsFixed(2),
                              unit: 'm/s²',
                            ),
                            const SizedBox(width: 8),
                            valueTile(
                              label: 'Z AXIS',
                              value: detector.z.toStringAsFixed(2),
                              unit: 'm/s²',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: metricCard(
                                label: 'CURRENT MAGNITUDE',
                                value: detector.magnitude.toStringAsFixed(2),
                                unit: 'm/s²',
                                icon: Icons.show_chart_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: metricCard(
                                label: 'PEAK ACCELERATION',
                                value: detector.peakAcceleration
                                    .toStringAsFixed(2),
                                unit: 'm/s²',
                                icon: Icons.trending_up_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // GYROSCOPE
                  sectionCard(
                    icon: Icons.screen_rotation_alt_rounded,
                    title: 'Gyroscope',
                    subtitle: 'Live rotation and orientation',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            valueTile(
                              label: 'X AXIS',
                              value: detector.gyroX.toStringAsFixed(2),
                              unit: 'rad/s',
                            ),
                            const SizedBox(width: 8),
                            valueTile(
                              label: 'Y AXIS',
                              value: detector.gyroY.toStringAsFixed(2),
                              unit: 'rad/s',
                            ),
                            const SizedBox(width: 8),
                            valueTile(
                              label: 'Z AXIS',
                              value: detector.gyroZ.toStringAsFixed(2),
                              unit: 'rad/s',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: metricCard(
                                label: 'ROTATION MAGNITUDE',
                                value: detector.gyroMagnitude.toStringAsFixed(
                                  2,
                                ),
                                unit: 'rad/s',
                                icon: Icons.rotate_right_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: metricCard(
                                label: 'PEAK ROTATION',
                                value: detector.peakGyro.toStringAsFixed(2),
                                unit: 'rad/s',
                                icon: Icons.trending_up_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        metricCard(
                          label: 'WINDOW GYRO PEAK',
                          value: detector.windowGyroPeak.toStringAsFixed(2),
                          unit: 'rad/s',
                          icon: Icons.timeline_rounded,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: detector.resetPeak,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reset Sensor Peaks'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // FALL DETECTION
                  sectionCard(
                    icon: Icons.health_and_safety_rounded,
                    title: 'Fall Detection',
                    subtitle: 'Real-time safety state monitoring',
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: fallColor().withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: fallColor().withOpacity(0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: fallColor().withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  detector.fallState == 'POSSIBLE FALL'
                                      ? Icons.warning_rounded
                                      : Icons.shield_rounded,
                                  color: fallColor(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CURRENT FALL STATE',
                                      style: TextStyle(
                                        color: Colors.black45,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      detector.fallState,
                                      style: TextStyle(
                                        color: fallColor(),
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: metricCard(
                                label: 'LIVE SENSOR STATUS',
                                value: detector.status,
                                unit: 'current',
                                icon: Icons.monitor_heart_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: metricCard(
                                label: 'IMPACT PEAK',
                                value: detector.windowPeak.toStringAsFixed(2),
                                unit: 'm/s²',
                                icon: Icons.bolt_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        metricCard(
                          label: 'LOW MOVEMENT READINGS',
                          value: '${detector.lowMovementCount}',
                          unit: 'readings',
                          icon: Icons.directions_walk_rounded,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              bool caretakerNotified = false;

                              try {
                                final response = await http.post(
                                  Uri.parse(eventsUrl),
                                  headers: {
                                    'Content-Type': 'application/json',
                                    'Authorization': 'Bearer $accessToken',
                                  },
                                  body: jsonEncode({
                                    'user_id': elderlyUserId,
                                    'event_type': 'patient_ok',
                                    'risk_level': 'low',
                                  }),
                                );

                                caretakerNotified = response.statusCode == 200;
                                debugPrint(
                                  'Patient OK event response: ${response.statusCode}',
                                );
                              } catch (e) {
                                debugPrint(
                                  'Patient OK notification failed: $e',
                                );
                              }

                              await _stopAlarm();
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    caretakerNotified
                                        ? 'You confirmed OK. The caretaker activity was updated.'
                                        : 'Alarm stopped on this phone, but the caretaker was NOT notified. Check connection and login.',
                                  ),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                            label: const Text('I AM OK'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: resetFallState,
                            icon: const Icon(Icons.restart_alt_rounded),
                            label: const Text(
                              'Stop Alarm & Reset Fall Detection',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // GPS
                  sectionCard(
                    icon: Icons.location_on_rounded,
                    title: 'GPS Location',
                    subtitle: 'Accurate location and signal quality',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentPosition == null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8FA),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.location_searching_rounded,
                                  color: Color(0xFF2F8F9D),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Location not obtained yet',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: metricCard(
                                  label: 'LATITUDE',
                                  value: currentPosition!.latitude
                                      .toStringAsFixed(6),
                                  unit: 'degrees',
                                  icon: Icons.north_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: metricCard(
                                  label: 'LONGITUDE',
                                  value: currentPosition!.longitude
                                      .toStringAsFixed(6),
                                  unit: 'degrees',
                                  icon: Icons.east_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: metricCard(
                                  label: 'BEST ACCURACY',
                                  value: currentPosition!.accuracy
                                      .toStringAsFixed(1),
                                  unit: 'meters',
                                  icon: Icons.gps_fixed_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: metricCard(
                                  label: 'FIXES COLLECTED',
                                  value: '$locationFixCount',
                                  unit: 'location fixes',
                                  icon: Icons.my_location_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF2E8B57),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'GPS QUALITY',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  locationQuality,
                                  style: const TextStyle(
                                    color: Color(0xFF2E8B57),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: gettingLocation ? null : getLocation,
                            icon: Icon(
                              gettingLocation
                                  ? Icons.hourglass_top_rounded
                                  : Icons.my_location_rounded,
                            ),
                            label: Text(
                              gettingLocation
                                  ? 'Getting Location...'
                                  : 'Get Best Location',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // BLE
                  sectionCard(
                    icon: Icons.bluetooth_rounded,
                    title: 'Bluetooth LE',
                    subtitle: 'Guardian wearable discovery and proximity',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            statusPill(
                              text: scanningBle ? 'SCANNING' : 'SCAN IDLE',
                              color: scanningBle
                                  ? const Color(0xFF2E8B57)
                                  : const Color(0xFF2F8F9D),
                            ),
                            const Spacer(),
                            Text(
                              '${bleDevices.length} devices',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            scanningBle
                                ? 'Scanning continuously...'
                                : 'Scan results received: $totalBleResults',
                            style: const TextStyle(
                              color: Color(0xFF24445F),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: scanningBle ? null : startBleScan,
                            icon: const Icon(Icons.bluetooth_searching_rounded),
                            label: Text(
                              scanningBle
                                  ? 'Scanning for 60 seconds...'
                                  : 'Scan for BLE Devices',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (guardianDeviceId != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EF),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: const Color(0xFFBFE3CC),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shield_rounded,
                                      color: Color(0xFF2E8B57),
                                    ),
                                    const SizedBox(width: 9),
                                    const Expanded(
                                      child: Text(
                                        'Guardian Circle Device',
                                        style: TextStyle(
                                          color: Color(0xFF245C3B),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    statusPill(
                                      text: 'SELECTED',
                                      color: const Color(0xFF2E8B57),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  proximityStateText(proximity?.state),
                                  style: const TextStyle(
                                    color: Color(0xFF245C3B),
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  proximity?.filteredRssi == null
                                      ? 'Filtered RSSI: collecting...'
                                      : 'Filtered RSSI: '
                                            '${proximity!.filteredRssi!.toStringAsFixed(1)} dBm',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  proximity?.rssi == null
                                      ? 'Raw RSSI: --'
                                      : 'Raw RSSI: ${proximity!.rssi} dBm',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  proximity == null
                                      ? 'Confidence: --'
                                      : 'Confidence: '
                                            '${(proximity.confidence * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  proximity == null
                                      ? 'Samples: 0'
                                      : 'Samples: ${proximity.sampleCount}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: clearGuardianDevice,
                                  icon: const Icon(Icons.clear_rounded),
                                  label: const Text('Clear Guardian Device'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (bleDevices.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F8FA),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.bluetooth_disabled_rounded,
                                  color: Colors.black38,
                                  size: 30,
                                ),
                                SizedBox(height: 7),
                                Text(
                                  'No BLE devices found yet',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ...bleDevices.values.map((result) {
                          final device = result.device;
                          final name = result.advertisementData.advName;
                          final deviceId = device.remoteId.str;
                          final isGuardian = isGuardianAdvertisement(
                            result.advertisementData,
                          );
                          final isSelected = deviceId == guardianDeviceId;

                          return Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isGuardian
                                    ? const Color(0xFFBFE3CC)
                                    : const Color(0xFFE0E9EE),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isGuardian
                                            ? const Color(0xFFEAF7EF)
                                            : const Color(0xFFEAF6F7),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Icon(
                                        isGuardian
                                            ? Icons.shield_rounded
                                            : Icons.bluetooth_rounded,
                                        color: isGuardian
                                            ? const Color(0xFF2E8B57)
                                            : const Color(0xFF2F8F9D),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        name.isEmpty
                                            ? 'Unknown BLE Device'
                                            : name,
                                        style: const TextStyle(
                                          color: Color(0xFF1F3A52),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${result.rssi} dBm',
                                      style: const TextStyle(
                                        color: Color(0xFF24445F),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  'ID: $deviceId',
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  isGuardian
                                      ? 'GUARDIAN ADVERTISEMENT DETECTED'
                                      : 'Normal BLE advertisement',
                                  style: TextStyle(
                                    color: isGuardian
                                        ? const Color(0xFF2E8B57)
                                        : Colors.black54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  'Manufacturer Data: '
                                  '${manufacturerDataText(result.advertisementData)}',
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (isSelected)
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF2E8B57),
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'SELECTED AS GUARDIAN',
                                        style: TextStyle(
                                          color: Color(0xFF2E8B57),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        selectGuardianDevice(deviceId);
                                      },
                                      child: Text(
                                        isGuardian
                                            ? 'Select Guardian'
                                            : 'Use as Guardian',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // BACKEND
                  sectionCard(
                    icon: Icons.cloud_upload_rounded,
                    title: 'Backend Test',
                    subtitle: 'Verify patient event communication',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.api_rounded, color: Color(0xFF2F8F9D)),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Patient → Backend event test',
                                  style: TextStyle(
                                    color: Color(0xFF1F3A52),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Use the existing test event to verify the backend connection.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: sendingFall ? null : sendTestFall,
                              icon: Icon(
                                sendingFall
                                    ? Icons.hourglass_top_rounded
                                    : Icons.send_rounded,
                              ),
                              label: Text(
                                sendingFall ? 'Sending...' : 'Send Test Fall',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showEmergencyOverlay)
          Positioned.fill(child: _buildEmergencyOverlay()),
      ],
    );
  }

  Widget _buildEmergencyOverlay() {
    const navy = Color(0xFF101B32);
    const red = Color(0xFFFF5263);
    const green = Color(0xFF2DD881);

    return Material(
      color: navy,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF101B32), Color(0xFF1B3152)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.white, size: 34),
                      SizedBox(width: 10),
                      Text(
                        'GUARDIAN CIRCLE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                  Center(
                    child: Container(
                      width: 132,
                      height: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: red.withOpacity(0.13),
                        border: Border.all(
                          color: red.withOpacity(0.45),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: red,
                        size: 78,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'FALL DETECTED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Are you safe right now?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD6E1F0),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'If you are okay, confirm below. If you need help, stay somewhere safe and wait for assistance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF9FB1C9),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 68,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        bool caretakerNotified = false;
                        try {
                          final response = await http.post(
                            Uri.parse(eventsUrl),
                            headers: {
                              'Content-Type': 'application/json',
                              'Authorization': 'Bearer $accessToken',
                            },
                            body: jsonEncode({
                              'user_id': elderlyUserId,
                              'event_type': 'patient_ok',
                              'risk_level': 'low',
                            }),
                          );
                          caretakerNotified = response.statusCode == 200;
                          debugPrint(
                            'Patient OK event response: ${response.statusCode}',
                          );
                        } catch (e) {
                          debugPrint('Patient OK notification failed: $e');
                        }

                        await _stopAlarm();
                        if (!mounted) return;
                        setState(() => _showEmergencyOverlay = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              caretakerNotified
                                  ? 'You confirmed OK. Caretaker activity was updated.'
                                  : 'Alarm stopped on this phone, but caretaker was NOT notified. Check connection and login.',
                            ),
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 28),
                      label: const Text(
                        'I AM OK',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: const Color(0xFF09291B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: resetFallState,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Stop Alarm & Reset Detection'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'YOUR SAFETY MATTERS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7186A3),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
