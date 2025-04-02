import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

part 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit()
      : super(LocationState(
          currentLocation: LocationState.defaultInitialPosition,
        ));

  // Method to get current location
  Future<void> getCurrentLocation() async {
    // Always start with loading state
    emit(state.copyWith(serviceStatus: LocationServiceStatus.loading));

    try {
      // Check location service availability
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          serviceStatus: LocationServiceStatus.serviceDisabled,
          errorMessage: 'Location services are disabled',
        ));
        return;
      }

      // Check and request location permissions
      var permissionStatus = await Permission.location.request();

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

      // Create LatLng from position
      final currentLocation = LatLng(position.latitude, position.longitude);

      // Emit new state with current location
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

  // Method to manually check and update permission status
  Future<void> checkPermissionStatus({bool requestPermissions = false}) async {
    log('Checking permission status ...');
    final permissionStatus = await Permission.location.status;
    log('permissionStatus: $permissionStatus');
    if (permissionStatus.isDenied) {
      emit(state.copyWith(
        serviceStatus: LocationServiceStatus.permissionDenied,
        errorMessage: 'Location permissions are required',
      ));
      if(requestPermissions) {
       await getCurrentLocation();
      }
    } else if (permissionStatus.isGranted) {
      emit(state.copyWith(
        serviceStatus: LocationServiceStatus.permissionGranted,
        errorMessage: 'Location permissions are required',
      ));
    }
  }
}
