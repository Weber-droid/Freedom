import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/home/cubit/home_cubit.dart';
import 'package:freedom/feature/home/view/welcome_screen.dart';
import 'package:freedom/feature/location_search/cubit/map_search_cubit.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart';
import 'package:freedom/feature/location_search/view/smart_search.dart';
import 'package:freedom/shared/theme/app_colors.dart';
import 'package:freedom/shared/utilities.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  _LocationSearchScreenState createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  // Map controller
  final Completer<GoogleMapController> _controller = Completer();

  // Selected locations
  Location? _pickupLocation;
  Location? _destinationLocation;

  // Markers set
  Set<Marker> _markers = {};

  // Route polylines
  Set<Polyline> _polylines = {};

  // Initial camera position
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Location retrieval logic
      // ...
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Handle selection of pickup location
  void _onPickupSelected(Location location) {
    setState(() {
      _pickupLocation = location;
      _updateMarkers();
    });

    _moveCameraToLocation(location);
    _calculateRoute();
  }

  // Handle selection of destination location
  void _onDestinationSelected(Location location) {
    setState(() {
      _destinationLocation = location;
      _updateMarkers();
    });

    _moveCameraToLocation(location);
    _calculateRoute();
  }

  // Move camera to selected location
  Future<void> _moveCameraToLocation(Location location) async {
    final controller = await _controller.future;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            location.latitude,
            location.longitude,
          ),
          zoom: 16,
        ),
      ),
    );
  }

  // Update markers on the map
  void _updateMarkers() {
    final markers = <Marker>{};

    if (_pickupLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
            _pickupLocation!.latitude,
            _pickupLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: _pickupLocation!.name,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (_destinationLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            _destinationLocation!.latitude,
            _destinationLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationLocation!.name,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  // Calculate route between locations
  Future<void> _calculateRoute() async {
    if (_pickupLocation == null || _destinationLocation == null) {
      return;
    }

    // Route calculation logic
    // ...
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapSearchCubit>(
          create: (context) => getIt<MapSearchCubit>(),
        ),
      ],
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.only(top: 18),
        decoration: BoxDecoration(
          gradient: whiteAmberGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14.32),
            topRight: Radius.circular(14.32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(right: 11, bottom: 11),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: Colors.black.withOpacity(0.059),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HSpace(6.4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: 12,
                            bottom: 4.62,
                            top: 6.38,
                          ),
                          child: Text(
                            'Pickup Location',
                            style: TextStyle(
                              fontSize: 10.13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    BlocBuilder<MapSearchCubit, MapSearchState>(
                      buildWhen: (previous, current) {
                        return current.status == MapSearchStatus.success;
                      },
                      builder: (context, state) {
                        return SmartPickupLocationWidget(
                          state: HomeState(),
                          hintText: 'Pickup Location',
                          iconPath: 'assets/images/location_pointer_icon.svg',
                          iconBaseColor: Colors.orange,
                          isPickUpLocation: true,
                          isInitialDestinationField: false,
                          clearRecentLocations: getIt(),
                          getPlaceDetails: getIt(),
                          getPlacePredictions: getIt(),
                          getRecentLocations: getIt(),
                          getSavedLocations: getIt(),
                          onLocationSelected: _onPickupSelected,
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Destination location search with BLoC
                    BlocBuilder<MapSearchCubit, MapSearchState>(
                      buildWhen: (previous, current) {
                        return current.status == MapSearchStatus.success ||
                            current.status == MapSearchStatus.error;
                      },
                      builder: (context, state) {
                        return SmartLocationSearch(
                          hint: 'Where to?',
                          initialText: _destinationLocation?.name,
                          onLocationSelected: _onDestinationSelected,
                          getPlacePredictions: getIt(),
                          getPlaceDetails: getIt(),
                          getSavedLocations: getIt(),
                          getRecentLocations: getIt(),
                          clearRecentLocations: getIt(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom panel with ride options (visible only when route is calculated)
              if (_pickupLocation != null && _destinationLocation != null)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Route info
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            const Text(
                              '15 min',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.straighten, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            const Text(
                              '5.2 km',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Ride options
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildRideOption(
                                icon: Icons.local_taxi,
                                title: 'Standard',
                                price: '\$12.50',
                                isSelected: true,
                              ),
                              const SizedBox(width: 12),
                              _buildRideOption(
                                icon: Icons.star,
                                title: 'Premium',
                                price: '\$18.75',
                                isSelected: false,
                              ),
                              const SizedBox(width: 12),
                              _buildRideOption(
                                icon: Icons.groups,
                                title: 'XL',
                                price: '\$22.00',
                                isSelected: false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Payment method
                        const Row(
                          children: [
                            Icon(Icons.credit_card, size: 20),
                            SizedBox(width: 8),
                            Text('Visa •••• 4582'),
                            Spacer(),
                            Text(
                              'Change',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Book button
                        ElevatedButton(
                          onPressed: () {
                            // Handle booking
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Booking confirmed! Driver is on the way.',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Book Ride',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              BlocBuilder<MapSearchCubit, MapSearchState>(
                builder: (context, state) {
                  if (state.status == MapSearchStatus.loading) {
                    return Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading...'),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Error messages from BLoC
              BlocListener<MapSearchCubit, MapSearchState>(
                listener: (context, state) {
                  if (state.status == MapSearchStatus.error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.locationSearchErrorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build ride option card
  Widget _buildRideOption({
    required IconData icon,
    required String title,
    required String price,
    required bool isSelected,
  }) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? Colors.blue : Colors.black,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
