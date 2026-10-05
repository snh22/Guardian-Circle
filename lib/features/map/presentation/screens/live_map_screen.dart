import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/location_provider.dart';
import '../../../trips/providers/trips_provider.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  Timer? _refreshTimer;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    // Automatically check for a new elderly location every 5 seconds.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (mounted) {
          ref.invalidate(elderlyLocationProvider);
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elderlyLocationAsync = ref.watch(elderlyLocationProvider);
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF163B68),
        foregroundColor: Colors.white,
        title: const Text(
          'Live Location',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: () {
              ref.invalidate(elderlyLocationProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: elderlyLocationAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF24598B),
          ),
        ),
        error: (error, stackTrace) => _MapMessageState(
          icon: Icons.location_off_rounded,
          title: 'Unable to load location',
          message: 'Please check the connection and try again.',
          actionLabel: 'Retry',
          onAction: () {
            ref.invalidate(elderlyLocationProvider);
          },
        ),
        data: (location) {
          if (location == null) {
            return _MapMessageState(
              icon: Icons.location_searching_rounded,
              title: 'No location available',
              message:
                  'The elderly person has not shared a location yet.',
              actionLabel: 'Refresh',
              onAction: () {
                ref.invalidate(elderlyLocationProvider);
              },
            );
          }

          final latitude = (location['latitude'] as num).toDouble();
          final longitude = (location['longitude'] as num).toDouble();

          final elderlyLatLng = LatLng(
            latitude,
            longitude,
          );

          final activeTrip = tripsAsync.when(
            data: (trips) {
              for (final trip in trips) {
                if (trip.isActive) {
                  return trip;
                }
              }
              return null;
            },
            loading: () => null,
            error: (_, __) => null,
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  elderlyLatLng,
                  16,
                ),
              );
            }
          });

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: elderlyLatLng,
                  zoom: 16,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      elderlyLatLng,
                      16,
                    ),
                  );
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('elderly_location'),
                    position: elderlyLatLng,
                    infoWindow: InfoWindow(
                      title: 'Elderly Person',
                      snippet:
                          'Lat: $latitude, Long: $longitude',
                    ),
                  ),
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),

              // Live status card
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE8ECF2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF183B60)
                            .withValues(alpha: 0.10),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F7EF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF1E8E5A),
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Elderly Person',
                              style: TextStyle(
                                color: Color(0xFF183B60),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Live location is being monitored',
                              style: TextStyle(
                                color: Color(0xFF7C8797),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F7EF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 7,
                              color: Color(0xFF1E8E5A),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Color(0xFF1E8E5A),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (activeTrip != null)
                Positioned(
                  top: 96,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFDCE8F2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF183B60).withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.route_rounded,
                            color: Color(0xFF24598B),
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Active Trip',
                                style: TextStyle(
                                  color: Color(0xFF183B60),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                activeTrip.destination,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF596678),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F7EF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'MONITORING',
                            style: TextStyle(
                              color: Color(0xFF1E8E5A),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Location details card
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE8ECF2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF183B60)
                            .withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFF24598B),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Current Location',
                            style: TextStyle(
                              color: Color(0xFF183B60),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _CoordinateTile(
                              label: 'Latitude',
                              value: latitude.toStringAsFixed(6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _CoordinateTile(
                              label: 'Longitude',
                              value: longitude.toStringAsFixed(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: Color(0xFF7C8797),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Patient ID: ${location['user_id']}',
                              style: const TextStyle(
                                color: Color(0xFF596678),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CoordinateTile extends StatelessWidget {
  const _CoordinateTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7C8797),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF183B60),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMessageState extends StatelessWidget {
  const _MapMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE8ECF2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF183B60).withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF24598B),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF183B60),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF7C8797),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24598B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
