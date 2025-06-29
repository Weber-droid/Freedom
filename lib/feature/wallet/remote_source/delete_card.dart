class DeleteCardResponse {
  DeleteCardResponse(this.message, {this.success});

  factory DeleteCardResponse.fromJson(Map<String, dynamic> json) {
    return DeleteCardResponse(
      json['message'] as String,
      success: json['success'] as bool? ?? false,
    );
  }
  final String? message;
  final bool? success;
}
