import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/api_service.dart';
import '../../../auth/providers/auth_provider.dart';

class ElderlyTrackingScreen extends ConsumerStatefulWidget {
  const ElderlyTrackingScreen({super.key});

  @override
  ConsumerState<ElderlyTrackingScreen> createState() =>
      _ElderlyTrackingScreenState();
}

class _ElderlyTrackingScreenState
    extends ConsumerState<ElderlyTrackingScreen> {
  Timer? _locationTimer;

  String _status = 'Starting location tracking...';
  Position? _lastPosition;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      await _checkLocationPermission();

      // Send the first location immediately.
      await _sendCurrentLocation();

      // Then update every 5 seconds.
      _locationTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          _sendCurrentLocation();
        },
      );

      if (mounted) {
        setState(() {
          _status = 'Location sharing is active';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = e.toString();
        });
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are turned off. Please enable GPS.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Enable it in system settings.',
      );
    }
  }

  Future<void> _sendCurrentLocation() async {
    if (_isSending) return;

    _isSending = true;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final user = ref.read(authControllerProvider).user;

      if (user == null) {
        throw Exception('User is not logged in.');
      }

      await ApiService.postLocation(
        userId: user.userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        setState(() {
          _lastPosition = position;
          _status = 'Location sharing is active';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Unable to send location';
        });
      }
    } finally {
      _isSending = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Circle'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 80,
              ),

              const SizedBox(height: 24),

              const Text(
                'Location Sharing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 24),

              if (_lastPosition != null) ...[
                Text(
                  'Latitude: ${_lastPosition!.latitude}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Longitude: ${_lastPosition!.longitude}',
                ),
              ],

              const SizedBox(height: 30),

              const Text(
                'Your location is being shared with your caretaker.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}