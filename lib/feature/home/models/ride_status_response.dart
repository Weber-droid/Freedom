import 'package:json_annotation/json_annotation.dart';

part 'ride_status_response.g.dart';

@JsonSerializable()
class RideStatusResponse {
  RideStatusResponse({required this.success, this.data});

  factory RideStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$RideStatusResponseFromJson(json);
  final bool success;
  final RideStatusData? data;

  Map<String, dynamic> toJson() => _$RideStatusResponseToJson(this);
}

@JsonSerializable()
class RideStatusData {
  RideStatusData({
    required this.rideId,
    required this.status,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.isMultiStop,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.fare,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.driver,
    required this.createdAt,
    required this.acceptedAt,
    required this.messages,
  });

  factory RideStatusData.fromJson(Map<String, dynamic> json) =>
      _$RideStatusDataFromJson(json);
  final String rideId;
  final String status;
  final Location pickupLocation;
  final Location dropoffLocation;
  final bool isMultiStop;
  final Distance estimatedDistance;
  final Duration estimatedDuration;
  final int fare;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final Driver driver;
  final String createdAt;
  final String acceptedAt;
  final List<Message> messages;

  Map<String, dynamic> toJson() => _$RideStatusDataToJson(this);
}

@JsonSerializable()
class Location {
  Location({
    required this.type,
    required this.coordinates,
    required this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
  final String type;
  final List<double> coordinates;
  final String address;

  Map<String, dynamic> toJson() => _$LocationToJson(this);

  // Helper methods
  double get latitude => coordinates[1];
  double get longitude => coordinates[0];
}

@JsonSerializable()
class Distance {
  Distance({required this.value, required this.text});

  factory Distance.fromJson(Map<String, dynamic> json) =>
      _$DistanceFromJson(json);
  final int value;
  final String text;

  Map<String, dynamic> toJson() => _$DistanceToJson(this);
}

@JsonSerializable()
class RideStatusDuration {
  RideStatusDuration({required this.value, required this.text});

  factory RideStatusDuration.fromJson(Map<String, dynamic> json) =>
      _$RideStatusDurationFromJson(json);
  final int value;
  final String text;

  Map<String, dynamic> toJson() => _$RideStatusDurationToJson(this);
}

@JsonSerializable()
class Driver {
  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.profilePicture,
    required this.rating,
    required this.currentLocation,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String profilePicture;
  final double rating;
  final DriverLocation currentLocation;

  Map<String, dynamic> toJson() => _$DriverToJson(this);
}

@JsonSerializable()
class DriverLocation {
  DriverLocation({
    required this.type,
    required this.coordinates,
    required this.updatedAt,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) =>
      _$DriverLocationFromJson(json);
  final String type;
  final List<double> coordinates;
  final int updatedAt;

  Map<String, dynamic> toJson() => _$DriverLocationToJson(this);

  // Helper methods
  double get latitude => coordinates[1];
  double get longitude => coordinates[0];

  DateTime get lastUpdated => DateTime.fromMillisecondsSinceEpoch(updatedAt);
}

@JsonSerializable()
class Message {
  Message({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  final String sender;
  final String text;
  final String timestamp;
  final bool isRead;

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  DateTime get time => DateTime.parse(timestamp);
}
