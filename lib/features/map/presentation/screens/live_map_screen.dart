import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../providers/location_provider.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  Timer? _refreshTimer;

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

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,

        title: const Text(
          'Elderly Live Location',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            color: Colors.black,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(elderlyLocationProvider);
            },
          ),
        ],
      ),

      body: elderlyLocationAsync.when(
        // ----------------------------------------------------------
        // LOADING
        // ----------------------------------------------------------
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        // ----------------------------------------------------------
        // ERROR
        // ----------------------------------------------------------
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Text(
                'Unable to load elderly location.\n\n$error',
                textAlign: TextAlign.center,

                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },

        // ----------------------------------------------------------
        // LOCATION DATA
        // ----------------------------------------------------------
        data: (location) {
          if (location == null) {
            return const Center(
              child: Text(
                'No elderly location available.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            );
          }

          final latitude =
              (location['latitude'] as num).toDouble();

          final longitude =
              (location['longitude'] as num).toDouble();

          final elderlyLatLng = LatLng(
            latitude,
            longitude,
          );

          return Stack(
            children: [
              // ----------------------------------------------------
              // GOOGLE MAP
              // ----------------------------------------------------
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: elderlyLatLng,
                  zoom: 16,
                ),

                markers: {
                  Marker(
                    markerId:
                        const MarkerId('elderly_location'),

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
              ),

              // ----------------------------------------------------
              // LOCATION INFORMATION CARD
              // ----------------------------------------------------
              Positioned(
                top: 16,
                left: 16,
                right: 16,

                child: Card(
                  color: Colors.white,
                  elevation: 6,

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Elderly Person Location',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Latitude: $latitude',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Longitude: $longitude',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'User ID: ${location['user_id']}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
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