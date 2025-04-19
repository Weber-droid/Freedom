class VerifyPhoneUpdateModel {
  VerifyPhoneUpdateModel({this.success, this.message, this.data});

  factory VerifyPhoneUpdateModel.fromJson(Map<String, dynamic> json) {
    return VerifyPhoneUpdateModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : VerifyPhoneUpdateModelData.fromJson(
              json['data'] as Map<String, dynamic>),
    );
  }

  final bool? success;
  final String? message;
  final VerifyPhoneUpdateModelData? data;
}

class VerifyPhoneUpdateModelData {
  VerifyPhoneUpdateModelData(this.phoneNumber);
  factory VerifyPhoneUpdateModelData.fromJson(Map<String, dynamic> json) {
    return VerifyPhoneUpdateModelData(json['phone'] as String?);
  }
  final String? phoneNumber;
}
