import 'dart:convert';

import 'package:flutter/material.dart';
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

  static const String backendUrl =
      'https://guardian-ka-circle-backend.onrender.com/fall';

  @override
  void initState() {
    super.initState();

    detector.onUpdate = () {
      if (!mounted) return;

      setState(() {});

      if (detector.fallState == 'POSSIBLE FALL' &&
          !automaticFallSent &&
          !sendingFall) {
        automaticFallSent = true;
        sendAutomaticFall();
      }
    };

    detector.start();
  }

  // ============================================================
  // FALL DETECTION
  // ============================================================

  Future<void> sendAutomaticFall() async {
    setState(() {
      sendingFall = true;
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'event': 'fall',
          'risk': 'critical',
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AUTOMATIC FALL ALERT SENT'),
          ),
        );

        detector.resetFallState();
        automaticFallSent = false;
      } else {
        automaticFallSent = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Automatic alert failed: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      automaticFallSent = false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Automatic alert error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sendingFall = false;
        });
      }
    }
  }

  Future<void> sendTestFall() async {
    setState(() {
      sendingFall = true;
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'event': 'fall',
          'risk': 'critical',
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fall event sent successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
        ),
      );
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
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final locationAccuracy =
        await Geolocator.getLocationAccuracy();

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
        final position =
            await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        locationFixCount++;

        if (bestPosition == null ||
            position.accuracy < bestPosition.accuracy) {
          bestPosition = position;
          bestLocationAccuracy = position.accuracy;
        }

        if (mounted) {
          setState(() {
            currentPosition = bestPosition;
            bestLocationAccuracy =
                bestPosition?.accuracy;

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

        if (bestPosition.accuracy <= 5) {
          break;
        }

        await Future.delayed(
          const Duration(milliseconds: 500),
        );
      } catch (_) {
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
      final position =
          await getAccurateLocation();

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location error: $e',
          ),
        ),
      );
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

  bool isGuardianAdvertisement(
    AdvertisementData advertisementData,
  ) {
    final manufacturerData =
        advertisementData.manufacturerData;

    final guardianData =
        manufacturerData[guardianManufacturerId];

    if (guardianData != null &&
        guardianData.isNotEmpty &&
        guardianData[0] == guardianIdentifierByte) {
      return true;
    }

    for (final entry in manufacturerData.entries) {
      final bytes = entry.value;

      final text = String.fromCharCodes(
        bytes.where(
          (byte) =>
              byte >= 32 &&
              byte <= 126,
        ),
      );

      if (text.contains('GUARDIAN')) {
        return true;
      }
    }

    final name =
        advertisementData.advName.toUpperCase();

    return name.contains('GUARDIAN');
  }

  String manufacturerDataText(
    AdvertisementData advertisementData,
  ) {
    if (advertisementData.manufacturerData.isEmpty) {
      return 'None';
    }

    final parts = <String>[];

    advertisementData.manufacturerData.forEach(
      (id, bytes) {
        final hex = bytes
            .map(
              (byte) =>
                  byte.toRadixString(16).padLeft(2, '0'),
            )
            .join(' ');

        parts.add(
          '0x${id.toRadixString(16)}: $hex',
        );
      },
    );

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
          content: Text(
            'Bluetooth LE is not supported on this phone.',
          ),
        ),
      );

      return;
    }

    final adapterState =
        await FlutterBluePlus.adapterState.first;

    if (adapterState != BluetoothAdapterState.on) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please turn Bluetooth ON.',
          ),
        ),
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

      final subscription =
          FlutterBluePlus.onScanResults.listen(
        (results) {
          if (!mounted) return;

          setState(() {
            for (final result in results) {
              totalBleResults++;

              final deviceId =
                  result.device.remoteId.str;

              bleDevices[deviceId] = result;

              proximityEngines.putIfAbsent(
                deviceId,
                () => BleProximityEngine(),
              );

              final isGuardian =
                  isGuardianAdvertisement(
                result.advertisementData,
              );

              if (isGuardian &&
                  guardianDeviceId == null) {
                guardianDeviceId = deviceId;

                proximityEngines[deviceId]!.reset();
              }

              if (deviceId == guardianDeviceId) {
                guardianProximity =
                    proximityEngines[deviceId]!
                        .addRssi(result.rssi);
              }
            }
          });
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 60),
        androidScanMode:
            AndroidScanMode.lowLatency,
        continuousUpdates: true,
        continuousDivisor: 1,
      );

      await FlutterBluePlus.isScanning
          .where((value) => value == false)
          .first;

      await subscription.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'BLE scan error: $e',
            ),
          ),
        );
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
    proximityEngines.putIfAbsent(
      deviceId,
      () => BleProximityEngine(),
    );

    setState(() {
      guardianDeviceId = deviceId;
      guardianProximity = null;
    });

    final device = bleDevices[deviceId];

    final name =
        device?.advertisementData.advName ?? '';

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

  String proximityStateText(
    ProximityState? state,
  ) {
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
  }

  @override
  void dispose() {
    detector.dispose();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Detection Sensor'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ==================================================
              // ACCELEROMETER
              // ==================================================

              const Text(
                'ACCELEROMETER',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'X: ${detector.x.toStringAsFixed(2)} m/s²',
                style: const TextStyle(fontSize: 18),
              ),

              Text(
                'Y: ${detector.y.toStringAsFixed(2)} m/s²',
                style: const TextStyle(fontSize: 18),
              ),

              Text(
                'Z: ${detector.z.toStringAsFixed(2)} m/s²',
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 15),

              const Text(
                'Linear Acceleration',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '${detector.magnitude.toStringAsFixed(2)} m/s²',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Peak Acceleration',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '${detector.peakAcceleration.toStringAsFixed(2)} m/s²',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Divider(),

              // ==================================================
              // GYROSCOPE
              // ==================================================

              const SizedBox(height: 15),

              const Text(
                'GYROSCOPE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'X: ${detector.gyroX.toStringAsFixed(2)} rad/s',
                style: const TextStyle(fontSize: 18),
              ),

              Text(
                'Y: ${detector.gyroY.toStringAsFixed(2)} rad/s',
                style: const TextStyle(fontSize: 18),
              ),

              Text(
                'Z: ${detector.gyroZ.toStringAsFixed(2)} rad/s',
                style: const TextStyle(fontSize: 18),
              ),

              const SizedBox(height: 15),

              const Text(
                'Rotation Magnitude',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '${detector.gyroMagnitude.toStringAsFixed(2)} rad/s',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Peak Rotation',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '${detector.peakGyro.toStringAsFixed(2)} rad/s',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Window Gyro Peak',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '${detector.windowGyroPeak.toStringAsFixed(2)} rad/s',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: detector.resetPeak,
                child: const Text('Reset Peaks'),
              ),

              const Divider(),

              // ==================================================
              // FALL STATUS
              // ==================================================

              const SizedBox(height: 15),

              const Text(
                'LIVE SENSOR STATUS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                detector.status,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Fall Detection State',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                detector.fallState,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Impact Window Peak',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '${detector.windowPeak.toStringAsFixed(2)} m/s²',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Low Movement Readings',
                style: TextStyle(fontSize: 16),
              ),

              Text(
                '${detector.lowMovementCount}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: resetFallState,
                child: const Text('Reset Fall State'),
              ),

              // ==================================================
              // GPS
              // ==================================================

              const SizedBox(height: 25),

              const Divider(),

              const SizedBox(height: 15),

              const Text(
                'GPS LOCATION',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (currentPosition == null)
                const Text(
                  'Location not obtained yet',
                  style: TextStyle(fontSize: 16),
                )
              else ...[
                Text(
                  'Latitude: '
                  '${currentPosition!.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 16),
                ),

                Text(
                  'Longitude: '
                  '${currentPosition!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 16),
                ),

                Text(
                  'Best Accuracy: '
                  '${currentPosition!.accuracy.toStringAsFixed(1)} m',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'Fixes collected: $locationFixCount',
                  style: const TextStyle(fontSize: 16),
                ),

                Text(
                  'GPS Quality: $locationQuality',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed:
                    gettingLocation ? null : getLocation,
                child: Text(
                  gettingLocation
                      ? 'Getting Location...'
                      : 'GET BEST LOCATION',
                ),
              ),

              // ==================================================
              // BLE
              // ==================================================

              const SizedBox(height: 25),

              const Divider(),

              const SizedBox(height: 15),

              const Text(
                'BLUETOOTH LE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                scanningBle
                    ? 'Scanning continuously...'
                    : 'Devices found: ${bleDevices.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                'Scan results received: $totalBleResults',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed:
                    scanningBle ? null : startBleScan,
                child: Text(
                  scanningBle
                      ? 'SCANNING FOR 60 SECONDS...'
                      : 'SCAN FOR BLE DEVICES',
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // GUARDIAN CIRCLE STATUS
              // ==================================================

              if (guardianDeviceId != null) ...[
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [

                        const Text(
                          'GUARDIAN CIRCLE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          proximityStateText(
                            guardianProximity?.state,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          guardianProximity?.filteredRssi == null
                              ? 'Filtered RSSI: collecting...'
                              : 'Filtered RSSI: '
                                  '${guardianProximity!.filteredRssi!.toStringAsFixed(1)} dBm',
                          style: const TextStyle(
                            fontSize: 18,
                          ),
                        ),

                        Text(
                          guardianProximity?.rssi == null
                              ? 'Raw RSSI: --'
                              : 'Raw RSSI: '
                                  '${guardianProximity!.rssi} dBm',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        Text(
                          guardianProximity == null
                              ? 'Confidence: --'
                              : 'Confidence: '
                                  '${(guardianProximity!.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        Text(
                          guardianProximity == null
                              ? 'Samples: 0'
                              : 'Samples: '
                                  '${guardianProximity!.sampleCount}',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 15),

                        ElevatedButton(
                          onPressed: clearGuardianDevice,
                          child: const Text(
                            'CLEAR GUARDIAN DEVICE',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],

              if (bleDevices.isEmpty)
                const Text(
                  'No BLE devices found yet',
                  style: TextStyle(fontSize: 16),
                ),

              ...bleDevices.values.map(
                (result) {
                  final device = result.device;

                  final name =
                      result.advertisementData.advName;

                  final deviceId =
                      device.remoteId.str;

                  final isGuardian =
                      isGuardianAdvertisement(
                    result.advertisementData,
                  );

                  final isSelected =
                      deviceId == guardianDeviceId;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name.isEmpty
                                      ? 'Unknown BLE Device'
                                      : name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              Text(
                                '${result.rssi} dBm',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'RSSI: ${result.rssi} dBm',
                            style: const TextStyle(
                              fontSize: 17,
                            ),
                          ),

                          Text(
                            'ID: $deviceId',
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            isGuardian
                                ? '🟢 GUARDIAN ADVERTISEMENT DETECTED'
                                : '⚪ Normal BLE advertisement',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Manufacturer Data:\n'
                            '${manufacturerDataText(result.advertisementData)}',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (isSelected)
                            const Text(
                              '✓ SELECTED AS GUARDIAN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () {
                                selectGuardianDevice(
                                  deviceId,
                                );
                              },
                              child: Text(
                                isGuardian
                                    ? 'SELECT GUARDIAN'
                                    : 'USE AS GUARDIAN',
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ==================================================
              // BACKEND
              // ==================================================

              const SizedBox(height: 25),

              const Divider(),

              const SizedBox(height: 15),

              const Text(
                'BACKEND TEST',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton(
                onPressed:
                    sendingFall ? null : sendTestFall,
                child: Text(
                  sendingFall
                      ? 'Sending...'
                      : 'SEND TEST FALL',
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}