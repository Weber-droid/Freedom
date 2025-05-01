import 'dart:async';
import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/location_search/repository/location_repository.dart';
import 'package:freedom/feature/location_search/repository/models/PlacePrediction.dart';
import 'package:freedom/feature/location_search/repository/models/location.dart'
    as loc;
import 'package:freedom/feature/location_search/use_cases/get_recent_locations.dart';
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
          const HomeState(currentLocation: HomeState.defaultInitialPosition),
        );

  ///setters and getters for locations
  void isPickUpLocation({required bool isPickUpLocation}) {
    emit(state.copyWith(isPickUpLocation: isPickUpLocation));
  }

  void isDestinationLocation({required bool isDestinationLocation}) {
    emit(state.copyWith(isDestinationLocation: isDestinationLocation));
  }

  void showRecentPickUpLocations(
      {required bool showRecentlySearchedLocations}) {
    emit(state.copyWith(isPickUpLocation: showRecentlySearchedLocations));
  }

  void showDestinationRecentlySearchedLocations(
      {required bool showDestinationRecentlySearchedLocations}) {
    emit(state.copyWith(
        isDestinationLocation: showDestinationRecentlySearchedLocations));
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

  void addMarker(Marker marker) {
    final currentMarkers = Set<Marker>.from(state.markers)..add(marker);
    emit(state.copyWith(markers: currentMarkers));
  }

  void setMarkers(Set<Marker> markers) {
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
      assert(query.isNotEmpty, 'Query cannot be empty');
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
}
