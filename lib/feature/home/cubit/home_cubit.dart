import 'dart:developer' as dev;
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freedom/app/view/app.dart';
import 'package:freedom/core/services/route_animation_services.dart';
import 'package:freedom/core/services/route_services.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/home/repository/location_repository.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/home/repository/models/place_prediction.dart';
import 'package:freedom/feature/home/repository/ride_request_repository.dart';
import 'package:freedom/feature/home/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required LocationRepository repository,
    required RideRequestRepository rideRequestRepository,
    RouteService? routeService,
    RouteAnimationService? animationService,
  }) : _repository = repository,
       _routeService = routeService ?? RouteService(),
       _animationService = animationService ?? RouteAnimationService(),
       super(
         const HomeState(currentLocation: HomeState.defaultInitialPosition),
       );

  final LocationRepository _repository;
  final RouteService _routeService;
  final RouteAnimationService _animationService;
  // final double _animationSpeed = 0.5;
  int _activeDestinationIndex = 0;

  int get activeDestinationIndex => _activeDestinationIndex;
  Timer? _debounce;

  ///setters and getters for locations
  void isPickUpLocation({required bool isPickUpLocation}) {
    emit(state.copyWith(isPickUpLocation: isPickUpLocation));
  }

  void isDestinationLocation({required bool isDestinationLocation}) {
    emit(state.copyWith(isDestinationLocation: isDestinationLocation));
  }

  void showRecentPickUpLocations({
    required bool showRecentlySearchedLocations,
  }) {
    emit(state.copyWith(isPickUpLocation: showRecentlySearchedLocations));
  }

  void setActiveDestinationIndex(int index) {
    _activeDestinationIndex = index;
    emit(state.copyWith());
  }

  void showDestinationRecentlySearchedLocations({
    required bool showDestinationRecentlySearchedLocations,
  }) {
    emit(
      state.copyWith(
        isDestinationLocation: showDestinationRecentlySearchedLocations,
      ),
    );
  }

  void addDestination() {
    emit(
      state.copyWith(
        locations: [...state.locations, generateNewDestinationString()],
      ),
    );
  }

  void removeLastDestination() {
    emit(state.copyWith(locations: List.from(state.locations)..removeLast()));
  }

  String generateNewDestinationString() {
    return 'Destination ${state.locations.length}';
  }

  set fieldIndex(int index) {
    dev.log('index: $index');
    emit(state.copyWith(fieldIndexSetter: index));
  }

  int get fieldIndex => state.fieldIndexSetter ?? 0;

  void setMarkers(Map<MarkerId, Marker> markers) {
    emit(state.copyWith(markers: markers));
  }

  void setPolylines(Set<Polyline> polylines) {
    emit(state.copyWith(polylines: polylines, status: MapSearchStatus.success));
  }

  void clearMarkers() {
    emit(state.copyWith(markers: {}));
  }

  Future<void> getCurrentLocation() async {
    emit(state.copyWith(serviceStatus: LocationServiceStatus.loading));

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(
          state.copyWith(
            serviceStatus: LocationServiceStatus.serviceDisabled,
            errorMessage: 'Location services are disabled',
          ),
        );
        return;
      }

      final permissionStatus = await Permission.location.request();

      if (!permissionStatus.isGranted) {
        emit(
          state.copyWith(
            serviceStatus: LocationServiceStatus.permissionDenied,
            errorMessage: 'Location permissions are required',
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      emit(
        state.copyWith(
          currentLocation: currentLocation,
          serviceStatus: LocationServiceStatus.located,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Unable to retrieve location: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> handleAdditionalDestinationLocation(
    PlacePrediction prediction,
    FocusNode destinationFocusNode,
    TextEditingController destinationController,
    int destinationIndex,
  ) async {
    destinationFocusNode.unfocus();
    emit(state.copyWith(status: MapSearchStatus.loading));
    try {
      final placesDetails = await _repository.getPlaceDetails(
        prediction.placeId,
      );
      if (placesDetails != null && destinationController.text.isNotEmpty) {
        destinationController.text = placesDetails.address;
        final recentLocation = await getIt<GetRecentLocations>()();

        final updatedDestinations = List<FreedomLocation>.from(
          state.destinationLocations,
        );

        while (updatedDestinations.length <= destinationIndex) {
          updatedDestinations.add(FreedomLocation.empty());
        }

        updatedDestinations[destinationIndex] = placesDetails;

        emit(
          state.copyWith(
            recentLocations: recentLocation,
            status: MapSearchStatus.success,
            destinationLocations: updatedDestinations,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to handle destination location: $e',
        ),
      );
    }
  }

  Future<void> getUserAddressFromLatLng(LatLng? latLng) async {
    try {
      double latitude;
      double longitude;

      if (latLng != null) {
        latitude = latLng.latitude;
        longitude = latLng.longitude;
      } else {
        latitude = 6.6667;
        longitude = -1.616;
      }

      final placeMarks = await placemarkFromCoordinates(latitude, longitude);

      final country = placeMarks.first.country ?? '';
      final subLocality = placeMarks.first.subLocality ?? '';
      final thoroughfare = placeMarks.first.thoroughfare ?? '';
      final locality = placeMarks.first.locality ?? '';

      final formattedAddress = [
        thoroughfare,
        subLocality,
        locality,
        country,
      ].where((element) => element.isNotEmpty).join(', ');

      emit(state.copyWith(userAddress: formattedAddress));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to get user address: $e'));
    }
  }

  Future<void> checkPermissionStatus({bool requestPermissions = false}) async {
    try {
      final permissionStatus = await Permission.location.status;

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        emit(
          state.copyWith(
            serviceStatus: LocationServiceStatus.permissionDenied,
            errorMessage:
                'Location permissions are required for accurate location',
          ),
        );

        await getUserAddressFromLatLng(HomeState.defaultInitialPosition);

        if (requestPermissions && permissionStatus.isDenied) {
          final requestResult = await Permission.location.request();
          if (requestResult.isGranted) {
            await getCurrentLocation();
            await getUserAddressFromLatLng(state.currentLocation);
          }
        }
      } else if (permissionStatus.isGranted) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          emit(
            state.copyWith(
              serviceStatus: LocationServiceStatus.serviceDisabled,
              errorMessage: 'Location services are disabled',
            ),
          );
          await getUserAddressFromLatLng(HomeState.defaultInitialPosition);
          return;
        }

        await getCurrentLocation();
        await getUserAddressFromLatLng(state.currentLocation);

        emit(
          state.copyWith(
            serviceStatus: LocationServiceStatus.permissionGranted,
            errorMessage: '',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Error checking location permissions: $e'),
      );
      await getUserAddressFromLatLng(HomeState.defaultInitialPosition);
    }
  }

  Future<void> fetchPredictions(String query) async {
    try {
      dev.log('query: $query');
      if (query.isEmpty) {
        emit(state.copyWith(status: MapSearchStatus.initial));
        return;
      }
      _debounce?.cancel();

      _debounce = Timer(const Duration(milliseconds: 500), () async {
        emit(state.copyWith(status: MapSearchStatus.loading));
        final predictions = await _repository.getPlacePredictions(query);
        if (state.isPickUpLocation) {
          emit(
            state.copyWith(
              pickUpPredictions: predictions,
              status: MapSearchStatus.success,
            ),
          );
        } else if (state.isDestinationLocation) {
          emit(
            state.copyWith(
              destinationPredictions: predictions,
              status: MapSearchStatus.success,
            ),
          );
        }
      });
    } catch (e) {
      emit(
        state.copyWith(
          status: MapSearchStatus.error,
          pickUpPredictions: [],
          destinationPredictions: [],
          locationSearchErrorMessage: 'Failed to fetch predictions: $e',
        ),
      );
    }
  }

  Future<void> fetchRecentLocations() async {
    try {
      final recentLocations = await getIt<GetRecentLocations>()();
      emit(
        state.copyWith(
          recentLocations: recentLocations,
          status: MapSearchStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to fetch recent locations: $e',
        ),
      );
    }
  }

  Future<void> handlePickUpLocation(
    PlacePrediction prediction,
    FocusNode pickUpFocusNode,
    FocusNode destinationFocusNode,
    TextEditingController pickUpController,
    TextEditingController destinationController,
  ) async {
    pickUpFocusNode.unfocus();
    destinationFocusNode.unfocus();
    emit(state.copyWith(status: MapSearchStatus.loading));
    try {
      final placesDetails = await _repository.getPlaceDetails(
        prediction.placeId,
      );
      log(
        'placesDetails: ${placesDetails?.latitude} ${placesDetails?.longitude}',
      );
      if (placesDetails != null && pickUpController.text.isNotEmpty) {
        pickUpController.text = placesDetails.address;
        emit(
          state.copyWith(
            pickUpLocation: placesDetails,
            status: MapSearchStatus.success,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to handle pick up location: $e',
        ),
      );
    }
  }

  Future<void> handleDestinationLocation(
    PlacePrediction prediction,
    FocusNode destinationFocusNode,
    TextEditingController destinationController,
  ) async {
    destinationFocusNode.unfocus();
    emit(state.copyWith(status: MapSearchStatus.loading));
    try {
      final placesDetails = await _repository.getPlaceDetails(
        prediction.placeId,
      );

      log(
        'placesDetails: ${placesDetails?.latitude} ${placesDetails?.longitude}',
      );
      if (placesDetails != null && destinationController.text.isNotEmpty) {
        destinationController.text = placesDetails.address;
        final recentLocation = await getIt<GetRecentLocations>()();

        // Create a copy of the current destination locations
        final updatedDestinations = List<FreedomLocation>.from(
          state.destinationLocations,
        );

        // Update or add the first destination
        if (updatedDestinations.isEmpty) {
          updatedDestinations.add(placesDetails);
        } else {
          updatedDestinations[0] = placesDetails;
        }

        emit(
          state.copyWith(
            recentLocations: recentLocation,
            status: MapSearchStatus.success,
            destinationLocation: placesDetails,
            destinationLocations: updatedDestinations,
          ),
        );
      }
      log('Exiting search sheet');
      navigatorKey.currentState?.pop();
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to handle destination location: $e',
        ),
      );
    }
  }

  Future<void> handleRecentLocation(
    FreedomLocation location,
    FocusNode destinationFocusNode,
    TextEditingController destinationController,
  ) async {
    destinationFocusNode.unfocus();
    emit(state.copyWith(status: MapSearchStatus.loading));
    try {
      if (state.isDestinationLocation) {
        destinationController.text = location.address;
        final recentLocation = await getIt<GetRecentLocations>()();
        final updatedDestinations = List<FreedomLocation>.from(
          state.destinationLocations,
        );
        if (updatedDestinations.isEmpty) {
          updatedDestinations.add(location);
        } else {
          updatedDestinations[0] = location;
        }

        emit(
          state.copyWith(
            recentLocations: recentLocation,
            status: MapSearchStatus.success,
            destinationLocation: location,
            destinationLocations: updatedDestinations,
          ),
        );
      }
      log('Exiting search sheet');
      navigatorKey.currentState?.pop();
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to handle recent location: $e',
        ),
      );
    }
  }

  Future<void> getRoutes(LatLng startLocation, LatLng endLocation) async {
    try {
      emit(state.copyWith(status: MapSearchStatus.loading));

      // Use the route service to get the route
      final routeResult = await _routeService.getRoute(
        startLocation,
        endLocation,
      );

      if (!routeResult.isSuccess) {
        emit(
          state.copyWith(
            serviceStatus: LocationServiceStatus.error,
            errorMessage: routeResult.errorMessage ?? 'Failed to get route',
            status: MapSearchStatus.error,
          ),
        );
        return;
      }

      // Create markers using the route service
      final location = FreedomLocation.empty();
      final pickupLocation = location.copyWith(
        latitude: startLocation.latitude,
        longitude: startLocation.longitude,
      );
      final destinationLocation = location.copyWith(
        latitude: endLocation.latitude,
        longitude: endLocation.longitude,
      );

      final markers = _routeService.createMarkers(
        pickupLocation,
        destinationLocation,
        state.bikeMarkerIcon,
      );

      // Update state with route and markers
      emit(
        state.copyWith(
          polylines: {routeResult.polyline!},
          markers: markers,
          status: MapSearchStatus.success,
        ),
      );

      // Start animation after a short delay
      if (routeResult.interpolatedPoints != null) {
        Future.delayed(
          const Duration(milliseconds: 300),
          () => _startRouteAnimation(routeResult.interpolatedPoints!),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to get routes: $e',
          status: MapSearchStatus.error,
        ),
      );
    }
  }

  Future<void> getRoutesForMultipleDestinations(
    LatLng startLocation,
    List<LatLng> destinationLocations,
  ) async {
    if (destinationLocations.isEmpty) return;

    try {
      emit(state.copyWith(status: MapSearchStatus.loading));

      // Use the route service to get multiple routes
      final routesResult = await _routeService.getRoutesForMultipleDestinations(
        startLocation,
        destinationLocations,
      );

      if (!routesResult.isSuccess) {
        emit(
          state.copyWith(
            serviceStatus: LocationServiceStatus.error,
            errorMessage: routesResult.errorMessage ?? 'Failed to get routes',
            status: MapSearchStatus.error,
          ),
        );
        return;
      }

      // Create all locations list for markers
      final allLocations = <FreedomLocation>[
        FreedomLocation.empty().copyWith(
          latitude: startLocation.latitude,
          longitude: startLocation.longitude,
        ),
      ];

      // Add all destination locations
      for (final destination in destinationLocations) {
        allLocations.add(
          FreedomLocation.empty().copyWith(
            latitude: destination.latitude,
            longitude: destination.longitude,
          ),
        );
      }

      // Create markers using the route service
      final markers = _routeService.createMarkersForMultipleLocations(
        allLocations,
        state.bikeMarkerIcon,
      );

      // Update state
      emit(
        state.copyWith(
          polylines: routesResult.polylines!,
          markers: markers,
          status: MapSearchStatus.success,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to get routes: $e',
          status: MapSearchStatus.error,
        ),
      );
    }
  }

  void _startRouteAnimation(List<LatLng> animationPoints) {
    _animationService.animateMarkerAlongRoute(
      animationPoints,
      onPositionUpdate: _updateAnimatedMarker,
      onAnimationComplete: () {
        debugPrint('Route animation completed');
      },
    );
  }

  /// Update animated marker position
  void _updateAnimatedMarker(LatLng position, double rotation) {
    final newMarkersMap = Map<MarkerId, Marker>.from(state.markers);
    const pickupMarkerId = MarkerId('pickup');

    if (newMarkersMap.containsKey(pickupMarkerId) &&
        state.bikeMarkerIcon != null) {
      newMarkersMap[pickupMarkerId] = Marker(
        markerId: pickupMarkerId,
        position: position,
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: state.bikeMarkerIcon!,
        anchor: const Offset(0.5, 0.5),
        rotation: rotation,
      );

      emit(state.copyWith(markers: newMarkersMap));
    }
  }

  void stopAnimation() {
    _animationService.stopAnimation();
  }

  void pauseAnimation() {
    _animationService.pauseAnimation();
  }

  bool get isAnimating => _animationService.isAnimating;

  double get animationProgress => _animationService.animationProgress;

  void upDateMarkers(
    FreedomLocation? pickUpLocation,
    FreedomLocation? destinationLocation,
    BitmapDescriptor? bikeIcon,
  ) {
    final markers = _routeService.createMarkers(
      pickUpLocation,
      destinationLocation,
      bikeIcon,
    );
    emit(state.copyWith(markers: markers));
  }

  Color getRouteColor(int index) {
    return _routeService.getRouteColor(index);
  }

  Future<void> createMotorcycleIcon({int width = 25, int height = 25}) async {
    log('Creating motorcycle icon with width: $width, height: $height');
    final imageData = await rootBundle.load('assets/images/bike_marker.png');
    final originalBytes = imageData.buffer.asUint8List();

    final codec = await ui.instantiateImageCodec(originalBytes);
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;

    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..save()
      ..drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint(),
      )
      ..restore();

    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(width, height);
    final resizedByteData = await resizedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (resizedByteData != null) {
      final resizedBytes = resizedByteData.buffer.asUint8List();
      final bikeMarkerIcon = BitmapDescriptor.bytes(resizedBytes);
      emit(state.copyWith(bikeMarkerIcon: bikeMarkerIcon));
    } else {
      dev.log('Failed to resize image');
    }
  }

  Future<void> clearPredictions() async {
    emit(
      state.copyWith(
        pickUpPredictions: [],
        destinationPredictions: [],
        status: MapSearchStatus.initial,
      ),
    );
  }

  Future<void> updateDestinationLocation(
    PlacePrediction prediction,
    int index,
    FocusNode focusNode,
    TextEditingController controller,
  ) async {
    focusNode.unfocus();
    emit(state.copyWith(status: MapSearchStatus.loading));
    try {
      final placesDetails = await _repository.getPlaceDetails(
        prediction.placeId,
      );
      if (placesDetails != null && controller.text.isNotEmpty) {
        controller.text = placesDetails.address;
        final updatedDestinations = List<FreedomLocation>.from(
          state.destinationLocations,
        );
        if (index < updatedDestinations.length) {
          updatedDestinations[index] = placesDetails;
        } else {
          while (updatedDestinations.length < index) {
            updatedDestinations.add(FreedomLocation.empty());
          }
          updatedDestinations.add(placesDetails);
        }
        final recentLocation = await getIt<GetRecentLocations>()();
        emit(
          state.copyWith(
            destinationLocations: updatedDestinations,
            recentLocations: recentLocation,
            status: MapSearchStatus.success,
          ),
        );
        if (index == 0) {
          emit(state.copyWith(destinationLocation: placesDetails));
        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to update destination location: $e',
        ),
      );
    }
  }

  void resetDestinations() {
    emit(
      state.copyWith(
        destinationLocation: FreedomLocation.empty(),
        destinationLocations: const [],
        locations: const [],
        destinationPredictions: const [],
        pickUpLocation: FreedomLocation.empty(),
        markers: {},
        polylines: {},
        status: MapSearchStatus.initial,
      ),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _animationService.dispose();
    return super.close();
  }
}
