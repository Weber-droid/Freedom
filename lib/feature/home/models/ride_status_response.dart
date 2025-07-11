class RideStatusResponse {
  final bool success;
  final RideStatusData data;

  RideStatusResponse({required this.success, required this.data});

  factory RideStatusResponse.fromJson(Map<String, dynamic> json) {
    return RideStatusResponse(
      success: json['success'],
      data: RideStatusData.fromJson(json['data']),
    );
  }
}

class RideStatusData {
  final String rideId;
  final String status;
  final Location pickupLocation;
  final Location dropoffLocation;
  final bool isMultiStop;
  final EstimatedValue estimatedDistance;
  final EstimatedValue estimatedDuration;
  final double fare;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final Driver driver;
  final DateTime createdAt;
  final DateTime acceptedAt;
  final DateTime arrivedAt;
  final DateTime startedAt;
  final List<Message> messages;

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
    required this.arrivedAt,
    required this.startedAt,
    required this.messages,
  });

  factory RideStatusData.fromJson(Map<String, dynamic> json) {
    return RideStatusData(
      rideId: json['rideId'],
      status: json['status'],
      pickupLocation: Location.fromJson(json['pickupLocation']),
      dropoffLocation: Location.fromJson(json['dropoffLocation']),
      isMultiStop: json['isMultiStop'],
      estimatedDistance: EstimatedValue.fromJson(json['estimatedDistance']),
      estimatedDuration: EstimatedValue.fromJson(json['estimatedDuration']),
      fare: json['fare'].toDouble(),
      currency: json['currency'],
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      driver: Driver.fromJson(json['driver']),
      createdAt: DateTime.parse(json['createdAt']),
      acceptedAt: DateTime.parse(json['acceptedAt']),
      arrivedAt: DateTime.parse(json['arrivedAt']),
      startedAt: DateTime.parse(json['startedAt']),
      messages:
          (json['messages'] as List).map((m) => Message.fromJson(m)).toList(),
    );
  }
}

class Location {
  final String type;
  final List<double> coordinates;
  final String address;
  final String id;

  Location({
    required this.type,
    required this.coordinates,
    required this.address,
    required this.id,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'],
      coordinates: List<double>.from(
        json['coordinates'].map((x) => x.toDouble()),
      ),
      address: json['address'],
      id: json['_id'],
    );
  }
}

class EstimatedValue {
  final int value;
  final String text;

  EstimatedValue({required this.value, required this.text});

  factory EstimatedValue.fromJson(Map<String, dynamic> json) {
    return EstimatedValue(value: json['value'], text: json['text']);
  }
}

class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final double rating;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.rating,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      vehicleType: json['vehicleType'],
      rating: (json['rating'] as num).toDouble(),
    );
  }
}

class Message {
  final String sender;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String id;

  Message({
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.isRead,
    required this.id,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      text: json['text'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
      id: json['_id'],
    );
  }
}
