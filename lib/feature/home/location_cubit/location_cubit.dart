import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

part 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit()
      : super(const LocationState(
          currentLocation: LocationState.defaultInitialPosition,
        ));

  // Method to get current location
  Future<void> getCurrentLocation() async {
    // Always start with loading state
    emit(state.copyWith(serviceStatus: LocationServiceStatus.loading));

    try {
      // Check location service availability
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          serviceStatus: LocationServiceStatus.serviceDisabled,
          errorMessage: 'Location services are disabled',
        ));
        return;
      }

      // Check and request location permissions
      final permissionStatus = await Permission.location.request();

      if (!permissionStatus.isGranted) {
        emit(state.copyWith(
          serviceStatus: LocationServiceStatus.permissionDenied,
          errorMessage: 'Location permissions are required',
        ));
        return;
      }

      // Get current position with high accuracy
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));

      final currentLocation = LatLng(position.latitude, position.longitude);
      log('My current-location: $currentLocation');
      await getUserAddressFromLatLng(currentLocation);
      emit(state.copyWith(
        currentLocation: currentLocation,
        serviceStatus: LocationServiceStatus.located,
      ));
    } catch (e) {
      // Handle location retrieval errors
      emit(state.copyWith(
        serviceStatus: LocationServiceStatus.error,
        errorMessage: 'Unable to retrieve location: ${e.toString()}',
      ));
    }
  }

  Future<void> getUserAddressFromLatLng(LatLng? latLng) async {
    try {
      final placeMarks = await placemarkFromCoordinates(
          latLng?.latitude ?? 6.6667, latLng?.longitude ?? -1.616);
      log('User address: ${placeMarks.first}');
      emit(state.copyWith(
          userAddress:
              '${placeMarks.first.country} ${placeMarks.first.subLocality} ${placeMarks.first.thoroughfare}'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to get user address: $e'));
    }
  }

  // Method to manually check and update permission status
  Future<void> checkPermissionStatus({bool requestPermissions = false}) async {
    final permissionStatus = await Permission.location.status;
    if (permissionStatus.isDenied) {
      emit(state.copyWith(
        serviceStatus: LocationServiceStatus.permissionDenied,
        errorMessage: 'Location permissions are required',
      ));
      if (requestPermissions) {
        await getCurrentLocation();
      }
    } else if (permissionStatus.isGranted) {
      log('Location permissions are granted');
      await getCurrentLocation();
      emit(state.copyWith(
        serviceStatus: LocationServiceStatus.permissionGranted,
        errorMessage: 'Location permissions are required',
      ));
    }
  }
}
