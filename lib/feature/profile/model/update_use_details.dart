class UpdateUserDetails {
  UpdateUserDetails({this.success, this.data, this.message});

  factory UpdateUserDetails.fromJson(Map<String, dynamic> json) {
    return UpdateUserDetails(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data:
          UpdateUserDetailsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
  final bool? success;
  final String? message;
  final UpdateUserDetailsData? data;
}

class UpdateUserDetailsData {
  UpdateUserDetailsData({required this.message, this.success});

  factory UpdateUserDetailsData.fromJson(Map<String, dynamic> json) {
    return UpdateUserDetailsData(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }
  final String? message;
  final bool? success;
}
