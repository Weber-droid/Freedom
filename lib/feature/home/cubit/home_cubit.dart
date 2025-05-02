import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/repository/models/PlacePrediction.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart'
    as loc;
import 'package:freedom/feature/location_search/use_cases/get_recent_locations.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required LocationRepository repository})
      : _repository = repository,
        super(
          const HomeState(
            currentLocation: HomeState.defaultInitialPosition,
          ),
        );

  Timer? _animationTimer;
  int _currentAnimationIndex = 0;
  List<LatLng> _animationPoints = [];
  final double _animationSpeed = 0.5;

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

  void showDestinationRecentlySearchedLocations({
    required bool showDestinationRecentlySearchedLocations,
  }) {
    emit(
      state.copyWith(
        isDestinationLocation: showDestinationRecentlySearchedLocations,
      ),
    );
  }

  Timer? _debounce;
  final LocationRepository _repository;
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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
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
        state.copyWith(
          errorMessage: 'Error checking location permissions: $e',
        ),
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
      final placesDetails =
          await _repository.getPlaceDetails(prediction.placeId);
      if (placesDetails != null && pickUpController.text.isNotEmpty) {
        pickUpController.text = placesDetails.address;
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
      final placesDetails =
          await _repository.getPlaceDetails(prediction.placeId);
      if (placesDetails != null && destinationController.text.isNotEmpty) {
        destinationController.text = placesDetails.address;
        final recentLocation = await getIt<GetRecentLocations>()();
        emit(
          state.copyWith(
            recentLocations: recentLocation,
            status: MapSearchStatus.success,
          ),
        );
        if (state.currentLocation == null) {
          await getCurrentLocation();
          await _getRoutes(
            state.currentLocation!,
            LatLng(placesDetails.latitude, placesDetails.longitude),
          );
        } else {
          await _getRoutes(
            state.currentLocation!,
            LatLng(placesDetails.latitude, placesDetails.longitude),
          );
        }
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

  Future<void> _getRoutes(
    LatLng startLocation,
    LatLng endLocation,
  ) async {
    try {
      final routeCoordinates = <LatLng>[];
      const polylineId = PolylineId('route');

      final polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: dotenv.env['DIRECTIONS_API_KEY'],
        request: PolylineRequest(
          origin: PointLatLng(
            startLocation.latitude,
            startLocation.longitude,
          ),
          destination: PointLatLng(
            endLocation.latitude,
            endLocation.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      routeCoordinates.clear();

      if (result.points.isNotEmpty) {
        for (final point in result.points) {
          routeCoordinates.add(
            LatLng(point.latitude, point.longitude),
          );
        }

        // Add interpolation here - create a smoother route with more points
        final interpolatedCoordinates = _interpolatePoints(routeCoordinates, 5);

        final polyline = Polyline(
          polylineId: polylineId,
          color: Colors.orange,
          points: routeCoordinates, // Keep original points for display
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        );

        final routes = <Polyline>{polyline};
        final location = loc.Location.empty();
        upDateMarkers(
          location.copyWith(
            latitude: startLocation.latitude,
            longitude: startLocation.longitude,
          ),
          location.copyWith(
            latitude: endLocation.latitude,
            longitude: endLocation.longitude,
          ),
          state.bikeMarkerIcon,
        );

        emit(state.copyWith(polylines: routes));

        // Store interpolated points for animation
        _animationPoints = interpolatedCoordinates;

        // Start animation after a short delay
        Future.delayed(
            const Duration(milliseconds: 300), animateMarkerAlongPolyline);
      } else {
        emit(
          state.copyWith(
            serviceStatus: LocationServiceStatus.error,
            errorMessage: 'No route found',
          ),
        );
        return;
      }
    } catch (e) {
      emit(
        state.copyWith(
          serviceStatus: LocationServiceStatus.error,
          errorMessage: 'Failed to get routes: $e',
        ),
      );
    }
  }

  void upDateMarkers(
    loc.Location? pickUpLocation,
    loc.Location? destinationLocation,
    BitmapDescriptor? bikeIcon,
  ) {
    final newMarkersMap = Map<MarkerId, Marker>.from(state.markers);

    if (pickUpLocation != null && bikeIcon != null) {
      const pickupMarkerId = MarkerId('pickup');
      dev.log('Adding pickup marker with ID: $pickupMarkerId');

      newMarkersMap[pickupMarkerId] = Marker(
        markerId: pickupMarkerId,
        position: LatLng(
          pickUpLocation.latitude,
          pickUpLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Pickup',
          snippet: pickUpLocation.name,
        ),
        icon: bikeIcon,
        anchor: const Offset(0.5, 0.5),
      );
    }

    if (destinationLocation != null) {
      const destinationMarkerId = MarkerId('destination');

      newMarkersMap[destinationMarkerId] = Marker(
        markerId: destinationMarkerId,
        position: LatLng(
          destinationLocation.latitude,
          destinationLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: destinationLocation.name,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }

    final markersMap = Map<MarkerId, Marker>.from(newMarkersMap)
      ..forEach((key, value) {
        dev.log('Marker ID: ${key.value}, Position: ${value.position}');
      });
    emit(state.copyWith(markers: markersMap));
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
    final resizedByteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.png);

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

  void animateMarkerAlongPolyline() {
    if (_animationPoints.isEmpty) {
      dev.log('No points to animate along');
      return;
    }

    // Reset animation index
    _currentAnimationIndex = 0;
    final totalPoints = _animationPoints.length;

    // Cancel any existing animation
    _animationTimer?.cancel();

    // Calculate total route distance for speed calculation
    var totalDistance = 0.0;
    for (var i = 0; i < _animationPoints.length - 1; i++) {
      totalDistance +=
          _calculateDistance(_animationPoints[i], _animationPoints[i + 1]);
    }

    // Desired travel speed in meters per second (adjust this to change speed)
    const speedMetersPerSecond = 5.0; // Average cycling speed ~ 15-20 km/h

    // Calculate total animation time based on distance and speed
    final totalTimeSeconds = totalDistance / speedMetersPerSecond;

    // Animation update interval (smaller = smoother)
    const updateIntervalMs = 100; // 10 updates per second

    // Total number of animation steps
    final totalSteps = (totalTimeSeconds * 1000 / updateIntervalMs).ceil();

    var progress = 0.0;

    _animationTimer = Timer.periodic(
      const Duration(milliseconds: updateIntervalMs),
      (timer) {
        if (progress >= 1.0) {
          timer.cancel();
          return;
        }

        // Increment progress
        progress += 1.0 / totalSteps;
        if (progress > 1.0) progress = 1.0;

        // Calculate index based on progress
        final indexDouble = progress * (totalPoints - 1);
        final index1 = indexDouble.floor();
        final index2 = math.min(index1 + 1, totalPoints - 1);
        final weight = indexDouble - index1;

        // Interpolate between points
        final position = LatLng(
          _animationPoints[index1].latitude * (1 - weight) +
              _animationPoints[index2].latitude * weight,
          _animationPoints[index1].longitude * (1 - weight) +
              _animationPoints[index2].longitude * weight,
        );

        _updateAnimatedMarker(position);
      },
    );
  }

  void _updateAnimatedMarker(LatLng position) {
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
        rotation: _calculateMarkerRotation(position),
      );

      emit(state.copyWith(markers: newMarkersMap));
    }
  }

  double _calculateMarkerRotation(LatLng currentPoint) {
    if (_currentAnimationIndex < 1 ||
        _currentAnimationIndex >= _animationPoints.length) {
      return 0;
    }

    final prevPoint = _animationPoints[_currentAnimationIndex - 1];

    final dx = currentPoint.longitude - prevPoint.longitude;
    final dy = currentPoint.latitude - prevPoint.latitude;

    return math.atan2(dx, dy) * 180 / math.pi;
  }

// Add a method to stop animation if needed
  void stopAnimation() {
    _animationTimer?.cancel();
  }

// Add this method to your HomeCubit class
  List<LatLng> _interpolatePoints(List<LatLng> points, int insertPointsCount) {
    final result = <LatLng>[];

    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      result.add(start);

      for (var j = 1; j <= insertPointsCount; j++) {
        final fraction = j / (insertPointsCount + 1);
        result.add(LatLng(
          start.latitude + (end.latitude - start.latitude) * fraction,
          start.longitude + (end.longitude - start.longitude) * fraction,
        ));
      }
    }

    // Add the last point
    if (points.isNotEmpty) {
      result.add(points.last);
    }

    return result;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // in meters

    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLng = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    _animationTimer?.cancel();
    return super.close();
  }
}
