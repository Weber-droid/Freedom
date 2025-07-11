// UPDATED: DeliveryStatusResponse models to match your actual API

import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryStatusResponse {
  final bool success;
  final String? message;
  final DeliveryStatusData? data;

  const DeliveryStatusResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory DeliveryStatusResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data:
          json['data'] != null
              ? DeliveryStatusData.fromJson(json['data'])
              : null,
    );
  }
}

class DeliveryStatusData {
  final String deliveryId;
  final String
  status; // 'pending', 'accepted', 'started', 'in_progress', 'completed', 'cancelled'
  final DriverLocation? driverLocation;
  final EtaInfo? eta;
  final bool isDeliveryVerified;

  const DeliveryStatusData({
    required this.deliveryId,
    required this.status,
    this.driverLocation,
    this.eta,
    required this.isDeliveryVerified,
  });

  factory DeliveryStatusData.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusData(
      deliveryId: json['deliveryId'] ?? '',
      status: json['status'] ?? '',
      driverLocation:
          json['driverLocation'] != null
              ? DriverLocation.fromJson(json['driverLocation'])
              : null,
      eta: json['eta'] != null ? EtaInfo.fromJson(json['eta']) : null,
      isDeliveryVerified: json['isDeliveryVerified'] ?? false,
    );
  }

  // Helper getters
  bool get isActive =>
      ['pending', 'accepted', 'started', 'in_progress'].contains(status);
  bool get hasDriver => status != 'pending';
  bool get isInProgress => ['started', 'in_progress'].contains(status);
  LatLng? get driverPosition => driverLocation?.position;
}

class DriverLocation {
  final String type;
  final List<double> coordinates;
  final int updatedAt;

  const DriverLocation({
    required this.type,
    required this.coordinates,
    required this.updatedAt,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      type: json['type'] ?? 'Point',
      coordinates: List<double>.from(json['coordinates'] ?? []),
      updatedAt: json['updatedAt'] ?? 0,
    );
  }

  // Helper getters
  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;

  LatLng get position => LatLng(latitude, longitude);

  DateTime get lastUpdate => DateTime.fromMillisecondsSinceEpoch(updatedAt);

  bool get isRecent {
    final now = DateTime.now();
    final updateTime = lastUpdate;
    return now.difference(updateTime).inMinutes < 5;
  }
}

class EtaInfo {
  final int value;
  final String text;

  const EtaInfo({required this.value, required this.text});

  factory EtaInfo.fromJson(Map<String, dynamic> json) {
    return EtaInfo(value: json['value'] ?? 0, text: json['text'] ?? '');
  }

  // Helper getters
  Duration get duration => Duration(seconds: value);

  String get formattedTime {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
