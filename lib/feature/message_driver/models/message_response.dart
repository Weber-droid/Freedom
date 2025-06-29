class MessageResponse {
  MessageResponse({required this.status, required this.message, this.data});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: json['data'] != null
          ? MessageData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
  final bool status;
  final String message;
  final MessageData? data;
}

class MessageData {
  MessageData({required this.rideId, required this.messageId});
  factory MessageData.fromJson(Map<String, dynamic> json) {
    return MessageData(
      rideId: json['rideId'] as String,
      messageId: json['messageId'] as String,
    );
  }
  final String rideId;
  final String messageId;
}
