class SocialResponseModel {
  SocialResponseModel({this.message, this.success, this.data});

  factory SocialResponseModel.fromJson(Map<String, dynamic>? json) =>
      SocialResponseModel(
        message: json?['msg'] as String?,
        success: json?['success'] as bool?,
        data:
            SocialResponseData.fromJson(json?['data'] as Map<String, dynamic>?),
      );
  bool? success;
  String? message;
  SocialResponseData? data;
}

class SocialResponseData {
  SocialResponseData({
    this.provider,
    this.providerUserId,
    this.email,
    this.name,
    this.verificationNeeded = false,
  });
  factory SocialResponseData.fromJson(Map<String, dynamic>? json) =>
      SocialResponseData(
        provider: json?['provider'] as String?,
        providerUserId: json?['providerUserId'] as String?,
        email: json?['email'] as String?,
        name: json?['name'] as String?,
      );
  String? provider;
  String? providerUserId;
  String? email;
  String? name;
  bool verificationNeeded;
}
