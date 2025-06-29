// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_status_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RideStatusResponse _$RideStatusResponseFromJson(Map<String, dynamic> json) =>
    RideStatusResponse(
      success: json['success'] as bool,
      data: json['data'] == null
          ? null
          : RideStatusData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RideStatusResponseToJson(RideStatusResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

RideStatusData _$RideStatusDataFromJson(Map<String, dynamic> json) =>
    RideStatusData(
      rideId: json['rideId'] as String,
      status: json['status'] as String,
      pickupLocation:
          Location.fromJson(json['pickupLocation'] as Map<String, dynamic>),
      dropoffLocation:
          Location.fromJson(json['dropoffLocation'] as Map<String, dynamic>),
      isMultiStop: json['isMultiStop'] as bool,
      estimatedDistance:
          Distance.fromJson(json['estimatedDistance'] as Map<String, dynamic>),
      estimatedDuration:
          Duration(microseconds: (json['estimatedDuration'] as num).toInt()),
      fare: (json['fare'] as num).toInt(),
      currency: json['currency'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      driver: Driver.fromJson(json['driver'] as Map<String, dynamic>),
      createdAt: json['createdAt'] as String,
      acceptedAt: json['acceptedAt'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RideStatusDataToJson(RideStatusData instance) =>
    <String, dynamic>{
      'rideId': instance.rideId,
      'status': instance.status,
      'pickupLocation': instance.pickupLocation,
      'dropoffLocation': instance.dropoffLocation,
      'isMultiStop': instance.isMultiStop,
      'estimatedDistance': instance.estimatedDistance,
      'estimatedDuration': instance.estimatedDuration.inMicroseconds,
      'fare': instance.fare,
      'currency': instance.currency,
      'paymentMethod': instance.paymentMethod,
      'paymentStatus': instance.paymentStatus,
      'driver': instance.driver,
      'createdAt': instance.createdAt,
      'acceptedAt': instance.acceptedAt,
      'messages': instance.messages,
    };

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      address: json['address'] as String,
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
      'address': instance.address,
    };

Distance _$DistanceFromJson(Map<String, dynamic> json) => Distance(
      value: (json['value'] as num).toInt(),
      text: json['text'] as String,
    );

Map<String, dynamic> _$DistanceToJson(Distance instance) => <String, dynamic>{
      'value': instance.value,
      'text': instance.text,
    };

RideStatusDuration _$RideStatusDurationFromJson(Map<String, dynamic> json) =>
    RideStatusDuration(
      value: (json['value'] as num).toInt(),
      text: json['text'] as String,
    );

Map<String, dynamic> _$RideStatusDurationToJson(RideStatusDuration instance) =>
    <String, dynamic>{
      'value': instance.value,
      'text': instance.text,
    };

Driver _$DriverFromJson(Map<String, dynamic> json) => Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      vehicleType: json['vehicleType'] as String,
      profilePicture: json['profilePicture'] as String,
      rating: (json['rating'] as num).toDouble(),
      currentLocation: DriverLocation.fromJson(
          json['currentLocation'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DriverToJson(Driver instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'vehicleType': instance.vehicleType,
      'profilePicture': instance.profilePicture,
      'rating': instance.rating,
      'currentLocation': instance.currentLocation,
    };

DriverLocation _$DriverLocationFromJson(Map<String, dynamic> json) =>
    DriverLocation(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$DriverLocationToJson(DriverLocation instance) =>
    <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
      'updatedAt': instance.updatedAt,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      sender: json['sender'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] as String,
      isRead: json['isRead'] as bool,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'sender': instance.sender,
      'text': instance.text,
      'timestamp': instance.timestamp,
      'isRead': instance.isRead,
    };
