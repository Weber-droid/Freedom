class DeliveryRequestResponse {
  DeliveryRequestResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DeliveryRequestResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryRequestResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data:
          json['data'] != null
              ? DeliveryData.fromJson(json['data'] as Map<String, dynamic>)
              : null,
    );
  }
  final bool success;
  final String message;
  final DeliveryData? data;

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'data': data?.toJson()};
  }
}

class DeliveryData {
  DeliveryData({
    required this.deliveryId,
    required this.fare,
    required this.currency,
    required this.estimatedDistance,
    required this.estimatedDuration,
    required this.fareBreakdown,
    required this.status,
    required this.driversNotified,
    required this.paymentMethod,
    required this.isMultiStop,
    required this.numberOfStops,
  });

  factory DeliveryData.fromJson(Map<String, dynamic> json) {
    return DeliveryData(
      deliveryId: json['deliveryId'] as String,
      fare: (json['fare'] as num).toDouble(),
      currency: json['currency'] as String,
      estimatedDistance: EstimatedDistanceAndTimer.fromJson(
        json['estimatedDistance'] as Map<String, dynamic>,
      ),
      estimatedDuration: EstimatedDistanceAndTimer.fromJson(
        json['estimatedDuration'] as Map<String, dynamic>,
      ),
      fareBreakdown: FareBreakdown.fromJson(
        json['fareBreakdown'] as Map<String, dynamic>,
      ),
      status: json['status'] as String,
      driversNotified: json['driversNotified'] as int,
      paymentMethod: json['paymentMethod'] as String,
      isMultiStop: json['isMultiStop'] as bool,
      numberOfStops: json['numberOfStops'] as int,
    );
  }
  final String deliveryId;
  final double fare;
  final String currency;
  final EstimatedDistanceAndTimer estimatedDistance;
  final EstimatedDistanceAndTimer estimatedDuration;
  final FareBreakdown fareBreakdown;
  final String status;
  final int driversNotified;
  final String paymentMethod;
  final bool isMultiStop;
  final int numberOfStops;

  Map<String, dynamic> toJson() {
    return {
      'deliveryId': deliveryId,
      'fare': fare,
      'currency': currency,
      'estimatedDistance': estimatedDistance.toJson(),
      'estimatedDuration': estimatedDuration.toJson(),
      'fareBreakdown': fareBreakdown.toJson(),
      'status': status,
      'driversNotified': driversNotified,
      'paymentMethod': paymentMethod,
      'isMultiStop': isMultiStop,
      'numberOfStops': numberOfStops,
    };
  }
}

class EstimatedDistanceAndTimer {
  EstimatedDistanceAndTimer({required this.value, required this.text});

  factory EstimatedDistanceAndTimer.fromJson(Map<String, dynamic> json) {
    return EstimatedDistanceAndTimer(
      value: json['value'] as int,
      text: json['text'] as String,
    );
  }
  final int value;
  final String text;

  Map<String, dynamic> toJson() {
    return {'value': value, 'text': text};
  }
}

class FareBreakdown {
  FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.packageSizeMultiplier,
    required this.surgeMultiplier,
  });

  factory FareBreakdown.fromJson(Map<String, dynamic> json) {
    return FareBreakdown(
      baseFare: (json['baseFare'] as num).toDouble(),
      distanceFare: (json['distanceFare'] as num).toDouble(),
      timeFare: (json['timeFare'] as num).toDouble(),
      packageSizeMultiplier: (json['packageSizeMultiplier'] as num).toDouble(),
      surgeMultiplier: (json['surgeMultiplier'] as num).toDouble(),
    );
  }
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double packageSizeMultiplier;
  final double surgeMultiplier;

  Map<String, dynamic> toJson() {
    return {
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'packageSizeMultiplier': packageSizeMultiplier,
      'surgeMultiplier': surgeMultiplier,
    };
  }
}
