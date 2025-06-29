import 'package:freedom/feature/user_verification/verify_otp/view/view.dart';

class RequestRideResponse {
  RequestRideResponse({
    required this.message,
    required this.success,
    required this.data,
  });

  factory RequestRideResponse.fromJson(Map<String, dynamic> json) {
    return RequestRideResponse(
      message: json['message'] as String,
      success: json['success'] as bool,
      data: RequestData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  final String message;
  final bool success;
  final RequestData data;
}

class RequestData {
  RequestData({
    this.rideId,
    this.fare,
    this.currency,
    this.estimatedDistance,
    this.estimatedDuration,
    this.fareBreakdown,
    this.rideStatus,
    this.paymentMethod,
    this.notifiedDriverCount,
  });

  factory RequestData.fromJson(Map<String, dynamic> json) {
    return RequestData(
      rideId: json['rideId'] as String?,
      fare: (json['fare'] ?? 0.0).toString(),
      currency: json['currency'] as String?,
      estimatedDistance: json['estimatedDistance'] as Map<String, dynamic>?,
      estimatedDuration: json['estimatedDuration'] as Map<String, dynamic>?,
      fareBreakdown: json['fareBreakdown'] as Map<String, dynamic>?,
      rideStatus: RideStatusExtension.fromJson(json['status'] as String?),
      paymentMethod: json['paymentMethod'] as String?,
      notifiedDriverCount: json['driversNotified'] as int?,
    );
  }

  final String? rideId;
  final String? fare;
  final String? currency;
  final Map<String, dynamic>? estimatedDistance;
  final Map<String, dynamic>? estimatedDuration;
  final Map<String, dynamic>? fareBreakdown;
  final RideStatus? rideStatus;
  final String? paymentMethod;
  final int? notifiedDriverCount;
}
