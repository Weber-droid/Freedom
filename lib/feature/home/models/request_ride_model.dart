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
  final Location pickupLocation;
  final Location dropoffLocation;
  final List<Location>? additionalDestinations;
  final String paymentMethod;
  final bool isMultiDestination;
  final String promoCode;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'pickupLocation': {
        'coordinates': [pickupLocation.longitude, pickupLocation.latitude],
        'address': pickupLocation.address
      },
      'dropoffLocation': {
        'coordinates': [dropoffLocation.longitude, dropoffLocation.latitude],
        'address': dropoffLocation.address
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
