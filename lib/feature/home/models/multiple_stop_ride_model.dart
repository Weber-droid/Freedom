class MultipleStopRideModel {
  MultipleStopRideModel({
    required this.pickupLocation,
    required this.dropoffLocations, // Rename to plural for consistency
    required this.paymentMethod,
    required this.promoCode,
  });

  factory MultipleStopRideModel.fromJson(Map<String, dynamic> json) {
    return MultipleStopRideModel(
      pickupLocation: json['pickupLocation'] as String,
      dropoffLocations: List<String>.from(
        json['dropoffLocations'] as List<dynamic>,
      ),
      paymentMethod: json['paymentMethod'] as String,
      promoCode: json['promoCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pickupLocation': pickupLocation,
      'dropoffLocations': dropoffLocations,
      'paymentMethod': paymentMethod,
      'promoCode': promoCode,
    };
  }

  final String pickupLocation;
  final List<String> dropoffLocations;
  final String paymentMethod;
  final String promoCode;
}

// Multiple Stops Response Model

class MultipleStopsResponse {
  MultipleStopsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory MultipleStopsResponse.fromJson(Map<String, dynamic> json) {
    return MultipleStopsResponse(
      success: json['success'] is bool
          ? json['success'] as bool
          : (json['success']?.toString().toLowerCase() == 'true'),
      message: json['message'] is String
          ? json['message'] as String
          : (json['message']?.toString() ?? ''),
      data: MultipleStopsResponseData.fromJson(
        json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
    );
  }
  final bool success;
  final String message;
  final MultipleStopsResponseData data;

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class MultipleStopsResponseData {
  MultipleStopsResponseData({
    required this.rideId,
    required this.fare,
    required this.currency,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.fareBreakdown,
    required this.status,
    required this.paymentMethod,
    required this.isMultiStop,
    required this.stopCount,
    required this.driversNotified,
  });

  factory MultipleStopsResponseData.fromJson(Map<String, dynamic> json) {
    return MultipleStopsResponseData(
      rideId: (json['rideId'] ?? '').toString(),
      fare: (json['fare'] is int)
          ? (json['fare'] as int).toDouble()
          : (json['fare'] is double)
              ? json['fare'] as double
              : double.tryParse(json['fare']?.toString() ?? '0.0') ?? 0.0,
      currency: (json['currency'] ?? '').toString(),
      estimatedDistance: DistanceTime.fromJson(
        (json['estimatedDistance'] ?? {}) is Map<String, dynamic>
            ? json['estimatedDistance'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      estimatedDuration: DistanceTime.fromJson(
        (json['estimatedDuration'] ?? {}) is Map<String, dynamic>
            ? json['estimatedDuration'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      fareBreakdown: FareBreakdown.fromJson(
        (json['fareBreakdown'] ?? {}) is Map<String, dynamic>
            ? json['fareBreakdown'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),
      status: (json['status'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      isMultiStop: json['isMultiStop'] is bool
          ? json['isMultiStop'] as bool
          : (json['isMultiStop']?.toString().toLowerCase() == 'true'),
      stopCount: json['stopCount'] is int
          ? json['stopCount'] as int
          : int.tryParse(json['stopCount']?.toString() ?? '0') ?? 0,
      driversNotified: json['driversNotified'] is int
          ? json['driversNotified'] as int
          : int.tryParse(json['driversNotified']?.toString() ?? '0') ?? 0,
    );
  }
  final String rideId;
  final double fare;
  final String currency;
  final DistanceTime estimatedDistance;
  final DistanceTime estimatedDuration;
  final FareBreakdown fareBreakdown;
  final String status;
  final String paymentMethod;
  final bool isMultiStop;
  final int stopCount;
  final int driversNotified;

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'fare': fare,
      'currency': currency,
      'estimatedDistance': estimatedDistance.toJson(),
      'estimatedDuration': estimatedDuration.toJson(),
      'fareBreakdown': fareBreakdown.toJson(),
      'status': status,
      'paymentMethod': paymentMethod,
      'isMultiStop': isMultiStop,
      'stopCount': stopCount,
      'driversNotified': driversNotified,
    };
  }
}

class DistanceTime {
  DistanceTime({
    required this.value,
    required this.text,
  });

  factory DistanceTime.fromJson(Map<String, dynamic> json) {
    return DistanceTime(
      value: (json['value'] is int)
          ? json['value'] as int
          : int.tryParse(json['value']?.toString() ?? '0') ?? 0,
      text: (json['text'] ?? '').toString(),
    );
  }
  final int value;
  final String text;

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'text': text,
    };
  }
}

class FareBreakdown {
  FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.multiStopFare,
    required this.surgeMultiplier,
  });

  factory FareBreakdown.fromJson(Map<String, dynamic> json) {
    return FareBreakdown(
      baseFare: (json['baseFare'] is int || json['baseFare'] is double)
          ? (json['baseFare'] as num).toDouble()
          : 0.0,
      distanceFare:
          (json['distanceFare'] is int || json['distanceFare'] is double)
              ? (json['distanceFare'] as num).toDouble()
              : 0.0,
      timeFare: (json['timeFare'] is int || json['timeFare'] is double)
          ? (json['timeFare'] as num).toDouble()
          : 0.0,
      multiStopFare:
          (json['multiStopFare'] is int || json['multiStopFare'] is double)
              ? (json['multiStopFare'] as num).toDouble()
              : 0.0,
      surgeMultiplier:
          (json['surgeMultiplier'] is int || json['surgeMultiplier'] is double)
              ? (json['surgeMultiplier'] as num).toDouble()
              : 1.0,
    );
  }
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double multiStopFare;
  final double surgeMultiplier;

  Map<String, dynamic> toJson() {
    return {
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'multiStopFare': multiStopFare,
      'surgeMultiplier': surgeMultiplier,
    };
  }
}
