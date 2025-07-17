import 'dart:developer' as dev;

import 'package:freedom/feature/home/models/multiple_stop_ride_model.dart';
import 'package:freedom/feature/home/repository/models/location.dart';
import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';

class RideRequestModel {
  RideRequestModel({
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.paymentMethod,
    this.additionalDestinations,
    this.isMultiDestination = false,
    this.promoCode = '',
  });
  final FreedomLocation pickupLocation;
  final FreedomLocation dropoffLocation;
  final List<FreedomLocation>? additionalDestinations;
  final String paymentMethod;
  final bool isMultiDestination;
  final String promoCode;

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse pickup location
      final pickupData = json['pickupLocation'] as Map<String, dynamic>?;
      FreedomLocation pickupLocation;

      if (pickupData != null) {
        if (pickupData.containsKey('coordinates')) {
          final coordinates = pickupData['coordinates'] as List<dynamic>;
          pickupLocation = FreedomLocation(
            id: pickupData['id'] as String? ?? '',
            placeId: pickupData['place_id'] as String? ?? '',
            name: pickupData['name'] as String? ?? '',
            address: pickupData['address'] as String? ?? '',
            latitude: (coordinates[1] as num).toDouble(),
            longitude: (coordinates[0] as num).toDouble(),
            iconType: pickupData['icon_type'] as String? ?? '',
            isFavorite: pickupData['is_favorite'] as bool? ?? false,
          );
        } else if (pickupData.containsKey('latitude') &&
            pickupData.containsKey('longitude')) {
          pickupLocation = FreedomLocation(
            id: pickupData['id'] as String? ?? '',
            placeId: pickupData['place_id'] as String? ?? '',
            name: pickupData['name'] as String? ?? '',
            address: pickupData['address'] as String? ?? '',
            latitude: (pickupData['latitude'] as num).toDouble(),
            longitude: (pickupData['longitude'] as num).toDouble(),
            iconType: pickupData['icon_type'] as String? ?? '',
            isFavorite: pickupData['is_favorite'] as bool? ?? false,
          );
        } else {
          pickupLocation = FreedomLocation.fromJson(pickupData);
        }
      } else {
        throw ArgumentError('pickupLocation is required');
      }

      // Parse dropoff location
      final dropoffData = json['dropoffLocation'] as Map<String, dynamic>?;
      FreedomLocation dropoffLocation;

      if (dropoffData != null) {
        if (dropoffData.containsKey('coordinates')) {
          // Handle coordinate format: {'coordinates': [lng, lat], 'address': 'address'}
          final coordinates = dropoffData['coordinates'] as List<dynamic>;
          dropoffLocation = FreedomLocation(
            id: dropoffData['id'] as String? ?? '',
            placeId: dropoffData['place_id'] as String? ?? '',
            name: dropoffData['name'] as String? ?? '',
            address: dropoffData['address'] as String? ?? '',
            latitude: (coordinates[1] as num).toDouble(),
            longitude: (coordinates[0] as num).toDouble(),
            iconType: dropoffData['icon_type'] as String? ?? '',
            isFavorite: dropoffData['is_favorite'] as bool? ?? false,
          );
        } else if (dropoffData.containsKey('latitude') &&
            dropoffData.containsKey('longitude')) {
          // Handle direct format: {'latitude': lat, 'longitude': lng, 'address': 'address', ...}
          dropoffLocation = FreedomLocation(
            id: dropoffData['id'] as String? ?? '',
            placeId: dropoffData['place_id'] as String? ?? '',
            name: dropoffData['name'] as String? ?? '',
            address: dropoffData['address'] as String? ?? '',
            latitude: (dropoffData['latitude'] as num).toDouble(),
            longitude: (dropoffData['longitude'] as num).toDouble(),
            iconType: dropoffData['icon_type'] as String? ?? '',
            isFavorite: dropoffData['is_favorite'] as bool? ?? false,
          );
        } else {
          // Handle full Location.fromJson format
          dropoffLocation = FreedomLocation.fromJson(dropoffData);
        }
      } else {
        throw ArgumentError('dropoffLocation is required');
      }

      // Parse additional destinations if present
      List<FreedomLocation>? additionalDestinations;
      final additionalData = json['additionalDestinations'] as List<dynamic>?;

      if (additionalData != null && additionalData.isNotEmpty) {
        additionalDestinations =
            additionalData.map((destData) {
              final destination = destData as Map<String, dynamic>;

              if (destination.containsKey('coordinates')) {
                // Handle coordinate format
                final coordinates = destination['coordinates'] as List<dynamic>;
                return FreedomLocation(
                  id: destination['id'] as String? ?? '',
                  placeId: destination['place_id'] as String? ?? '',
                  name: destination['name'] as String? ?? '',
                  address: destination['address'] as String? ?? '',
                  latitude: (coordinates[1] as num).toDouble(),
                  longitude: (coordinates[0] as num).toDouble(),
                  iconType: destination['icon_type'] as String? ?? '',
                  isFavorite: destination['is_favorite'] as bool? ?? false,
                );
              } else if (destination.containsKey('latitude') &&
                  destination.containsKey('longitude')) {
                // Handle direct format
                return FreedomLocation(
                  id: destination['id'] as String? ?? '',
                  placeId: destination['place_id'] as String? ?? '',
                  name: destination['name'] as String? ?? '',
                  address: destination['address'] as String? ?? '',
                  latitude: (destination['latitude'] as num).toDouble(),
                  longitude: (destination['longitude'] as num).toDouble(),
                  iconType: destination['icon_type'] as String? ?? '',
                  isFavorite: destination['is_favorite'] as bool? ?? false,
                );
              } else {
                // Handle full Location.fromJson format
                return FreedomLocation.fromJson(destination);
              }
            }).toList();
      }

      return RideRequestModel(
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        paymentMethod: json['paymentMethod'] as String? ?? 'cash',
        additionalDestinations: additionalDestinations,
        isMultiDestination:
            json['isMultiDestination'] as bool? ??
            (additionalDestinations != null &&
                additionalDestinations.isNotEmpty),
        promoCode: json['promoCode'] as String? ?? '',
      );
    } catch (e) {
      dev.log('❌ Error parsing RideRequestModel from JSON: $e');
      dev.log('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'pickupLocation': {
        'coordinates': [pickupLocation.longitude, pickupLocation.latitude],
        'address': pickupLocation.address,
      },
      'dropoffLocation': {
        'coordinates': [dropoffLocation.longitude, dropoffLocation.latitude],
        'address': dropoffLocation.address,
      },
      'paymentMethod': paymentMethod,
      'promoCode': '',
    };
    log('actual json is: $json');
    return json;
  }

  MultipleStopRideModel toMultipleStopRideModel() {
    // Create pickup location map
    final pickupLocationMap = pickupLocation.address;

    // Create list of dropoff locations
    final dropoffLocations = <String>[dropoffLocation.address];

    // Add additional destinations
    if (additionalDestinations != null && additionalDestinations!.isNotEmpty) {
      for (final destination in additionalDestinations!) {
        dropoffLocations.add(destination.address);
      }
    }

    // Create and return the MultipleStopRideModel
    return MultipleStopRideModel(
      pickupLocation: pickupLocationMap,
      dropoffLocations: dropoffLocations,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
    );
  }

  String toString() {
    return 'RideRequestModel(pickupLocation: $pickupLocation, dropoffLocation: $dropoffLocation, additionalDestinations: $additionalDestinations, paymentMethod: $paymentMethod)';
  }
}
