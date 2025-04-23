class AddPhoneToSocialModel {
  AddPhoneToSocialModel({this.success, this.data});
  factory AddPhoneToSocialModel.fromJson(Map<String, dynamic> json) {
    return AddPhoneToSocialModel(
      success: json['success'] as bool?,
      data: json['data'] == null
          ? null
          : AddPhoneToSocialData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
  final bool? success;
  final AddPhoneToSocialData? data;
}

class AddPhoneToSocialData {
  AddPhoneToSocialData({
    this.phone,
    this.isVerified,
    this.requiresPhoneVerification,
  });

  factory AddPhoneToSocialData.fromJson(Map<String, dynamic> json) {
    return AddPhoneToSocialData(
      phone: json['phone'] as String?,
      isVerified: json['isVerified'] as bool?,
      requiresPhoneVerification: json['requiresPhoneVerification'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'isVerified': isVerified,
        'requiresPhoneVerification': requiresPhoneVerification,
      };
  final bool? requiresPhoneVerification;
  final String? phone;
  final bool? isVerified;
}
