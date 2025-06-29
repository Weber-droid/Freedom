class RideHistoryResponse {
  RideHistoryResponse({
    required this.success,
    required this.count,
    required this.totalPages,
    required this.currentPage,
    required this.data,
  });

  factory RideHistoryResponse.fromJson(Map<String, dynamic> json) {
    return RideHistoryResponse(
      success: json['success'] as bool,
      count: json['count'] as int,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      data: (json['data'] as List<dynamic>)
          .map((e) => RideData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  final bool success;
  final int count;
  final int totalPages;
  final int currentPage;
  final List<RideData> data;

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

// Ride data class
class RideData {
  RideData({
    required this.id,
    required this.userId,
    required this.driver,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.totalFare,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.requestedAt,
    required this.completedAt,
  });

  factory RideData.fromJson(Map<String, dynamic> json) {
    return RideData(
      id: json['_id'] as String,
      userId: json['user'] as String,
      driver: Driver.fromJson(json['driver'] as Map<String, dynamic>),
      pickupLocation:
      Location.fromJson(json['pickupLocation'] as Map<String, dynamic>),
      dropoffLocation:
      Location.fromJson(json['dropoffLocation'] as Map<String, dynamic>),
      status: json['status'] as String,
      totalFare: json['totalFare'] as int,
      currency: json['currency'] as String,
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
  final String id;
  final String userId;
  final Driver driver;
  final Location pickupLocation;
  final Location dropoffLocation;
  final String status;
  final int totalFare;
  final String currency;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime requestedAt;
  final DateTime completedAt;

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'driver': driver.toJson(),
      'pickupLocation': pickupLocation.toJson(),
      'dropoffLocation': dropoffLocation.toJson(),
      'status': status,
      'totalFare': totalFare,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'requestedAt': requestedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

// Driver class
class Driver {
  Driver({
    required this.id,
    required this.name,
    required this.ratings,
    required this.profilePicture,
    required this.vehicle,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['_id'] as String,
      name: json['name'] as String,
      ratings: json['ratings'] as double,
      profilePicture: json['profilePicture'] as String,
      vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
    );
  }
  final String id;
  final String name;
  final double ratings;
  final String profilePicture;
  final Vehicle vehicle;

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'ratings': ratings,
      'profilePicture': profilePicture,
      'vehicle': vehicle.toJson(),
    };
  }
}

// Vehicle class
class Vehicle {
  Vehicle({
    required this.type,
    required this.color,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      type: json['type'] as String,
      color: json['color'] as String,
    );
  }
  final String type;
  final String color;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'color': color,
    };
  }
}

// Location class
class Location {
  Location({
    required this.type,
    required this.coordinates,
    required this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      type: json['type'] as String,
      coordinates: (json['coordinates'] as List<dynamic>)
          .map((e) => e as double)
          .toList(),
      address: json['address'] as String,
    );
  }
  final String type;
  final List<double> coordinates;
  final String address;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
      'address': address,
    };
  }
}