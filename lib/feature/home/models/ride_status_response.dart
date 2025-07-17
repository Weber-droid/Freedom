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
  RideStatusData({
    required this.rideId,
    required this.status,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.isMultiStop,
    required this.estimatedDistance,
    required this.estimatedDuration,
    this.fare,
    this.currency,
    this.paymentMethod,
    this.paymentStatus,
    this.driver,
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    required this.messages,
  });

  final String rideId;
  final String status;
  final Location pickupLocation;
  final Location dropoffLocation;
  final bool isMultiStop;
  final EstimatedValue estimatedDistance;
  final EstimatedValue estimatedDuration;
  final double? fare;
  final String? currency;
  final String? paymentMethod;
  final String? paymentStatus;
  final Driver? driver;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final List<Message> messages;

  factory RideStatusData.fromJson(Map<String, dynamic> json) {
    return RideStatusData(
      rideId: json['rideId'] ?? '',
      status: json['status'] ?? '',
      pickupLocation: Location.fromJson(json['pickupLocation'] ?? {}),
      dropoffLocation: Location.fromJson(json['dropoffLocation'] ?? {}),
      isMultiStop: json['isMultiStop'] ?? false,
      estimatedDistance: EstimatedValue.fromJson(
        json['estimatedDistance'] ?? {},
      ),
      estimatedDuration: EstimatedValue.fromJson(
        json['estimatedDuration'] ?? {},
      ),
      fare: (json['fare'] != null) ? (json['fare'] as num).toDouble() : null,
      currency: json['currency'],
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      acceptedAt: DateTime.tryParse(json['acceptedAt'] ?? ''),
      arrivedAt: DateTime.tryParse(json['arrivedAt'] ?? ''),
      startedAt: DateTime.tryParse(json['startedAt'] ?? ''),
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((m) => Message.fromJson(m))
              .toList() ??
          [],
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
      type: json['type'] ?? '',
      coordinates: List<double>.from(
        (json['coordinates'] ?? []).map((x) => (x as num).toDouble()),
      ),
      address: json['address'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}

class EstimatedValue {
  final int value;
  final String text;

  EstimatedValue({required this.value, required this.text});

  factory EstimatedValue.fromJson(Map<String, dynamic> json) {
    return EstimatedValue(value: json['value'] ?? 0, text: json['text'] ?? '');
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      rating:
          (json['rating'] != null) ? (json['rating'] as num).toDouble() : 0.0,
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
      sender: json['sender'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      id: json['_id'] ?? '',
    );
  }
}
