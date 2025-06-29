
class RideCancellationResponse {

  RideCancellationResponse({
    required this.success,
    required this.message,
  });

  factory RideCancellationResponse.fromJson(Map<String, dynamic> json) {
    return RideCancellationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
  final bool success;
  final String message;

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }

  RideCancellationResponse copyWith({
    bool? success,
    String? message,
  }) {
    return RideCancellationResponse(
      success: success ?? this.success,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'RideCancellationResponse{success: $success, message: $message}';
  }
}