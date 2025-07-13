import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryStatusResponse {
  final bool success;
  final String message;
  final String? status;
  final String? deliveryId;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final Map<String, dynamic>? driverLocation;
  final String? pickupLocation;
  final String? destinationLocation;
  final double? estimatedArrivalTime;
  final double? totalFare;
  final String? paymentMethod;
  final bool? isMultiStop;
  final int? numberOfStops;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DeliveryStatusResponse({
    required this.success,
    required this.message,
    this.status,
    this.deliveryId,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverLocation,
    this.pickupLocation,
    this.destinationLocation,
    this.estimatedArrivalTime,
    this.totalFare,
    this.paymentMethod,
    this.isMultiStop,
    this.numberOfStops,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryStatusResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      status: json['status'] as String?,
      deliveryId: json['deliveryId'] as String?,
      driverId: json['driverId'] as String?,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      driverLocation: json['driverLocation'] as Map<String, dynamic>?,
      pickupLocation: json['pickupLocation'] as String?,
      destinationLocation: json['destinationLocation'] as String?,
      estimatedArrivalTime: (json['estimatedArrivalTime'] as num?)?.toDouble(),
      totalFare: (json['totalFare'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'] as String?,
      isMultiStop: json['isMultiStop'] as bool?,
      numberOfStops: json['numberOfStops'] as int?,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'status': status,
      'deliveryId': deliveryId,
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverLocation': driverLocation,
      'pickupLocation': pickupLocation,
      'destinationLocation': destinationLocation,
      'estimatedArrivalTime': estimatedArrivalTime,
      'totalFare': totalFare,
      'paymentMethod': paymentMethod,
      'isMultiStop': isMultiStop,
      'numberOfStops': numberOfStops,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get hasDriverInfo => driverId != null && driverName != null;

  bool get hasLocationInfo =>
      driverLocation != null &&
      driverLocation!.containsKey('latitude') &&
      driverLocation!.containsKey('longitude');

  LatLng? get driverPosition {
    if (!hasLocationInfo) return null;
    return LatLng(
      (driverLocation!['latitude'] as num).toDouble(),
      (driverLocation!['longitude'] as num).toDouble(),
    );
  }

  String get statusDisplay {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Searching for driver';
      case 'accepted':
        return 'Driver found';
      case 'picked_up':
        return 'Package picked up';
      case 'in_progress':
        return 'Delivery in progress';
      case 'arrived':
        return 'Driver has arrived';
      case 'completed':
        return 'Delivery completed';
      case 'cancelled':
        return 'Delivery cancelled';
      default:
        return status ?? 'Unknown status';
    }
  }
}
