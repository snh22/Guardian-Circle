import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

        // Reset the detector after successfully sending the alert.
        detector.resetFallState();

        // Allow the next fall to trigger another automatic alert.
        automaticFallSent = false;
      } else {
        // Allow another attempt if sending failed.
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

      // Allow another attempt if there was a connection error.
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

  void resetFallState() {
    automaticFallSent = false;
    detector.resetFallState();
  }

  @override
  void dispose() {
    detector.dispose();
    super.dispose();
  }

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
                onPressed: sendingFall ? null : sendTestFall,
                child: Text(
                  sendingFall ? 'Sending...' : 'SEND TEST FALL',
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
