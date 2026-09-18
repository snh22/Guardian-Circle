import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/domain/models/guardian_status.dart';
import '../../dashboard/providers/dashboard_provider.dart';

const double _placeholderHomeLat = 28.6139;
const double _placeholderHomeLng = 77.2090;
const double _safeZoneRadiusMeters = 500;

Future<Position> getCurrentPosition() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    throw Exception(
      'Location services are turned off on this device.',
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

  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

final currentLocationProvider =
    FutureProvider.autoDispose<Position>((ref) async {
  final position = await getCurrentPosition();

  final user = ref.read(authControllerProvider).user;

  if (user != null) {
    ApiService.postLocation(
      userId: user.userId,
      latitude: position.latitude,
      longitude: position.longitude,
    ).catchError((_) {});
  }

  final distanceMeters = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    _placeholderHomeLat,
    _placeholderHomeLng,
  );

  ref.read(safeZoneStateProvider.notifier).state = SafeZoneState(
    status: distanceMeters <= _safeZoneRadiusMeters
        ? SafeZoneStatus.insideHome
        : SafeZoneStatus.outsideUnplanned,
    zoneLabel: 'Home Zone',
  );

  return position;
});

final elderlyLocationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  // Backend automatically finds the elderly user
  // linked to the currently logged-in caretaker.
  return ApiService.getLatestLocation();
});