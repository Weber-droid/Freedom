class SocialResponseModel {
  SocialResponseModel({this.message, this.success, this.data});

  factory SocialResponseModel.fromJson(Map<String, dynamic>? json) =>
      SocialResponseModel(
        message: json?['message'] as String?,
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
    this.id,
    this.firstName,
    this.surname,
    this.profilePicture,
    this.email,
    this.isPhoneVerified,
    this.isEmailVerified,
    this.authProvider,
    this.socialId,
    this.socialProfile,
    this.rideHistory,
    this.paymentMethod,
    this.paystackCustomerId,
    this.mobileMoneyProvider,
    this.preferredLanguage,
    this.role,
    this.cardTokens,
    this.knownDevices,
    this.createdAt,
    this.updatedAt,
    this.notificationPreferences,
  });

  factory SocialResponseData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SocialResponseData();

    return SocialResponseData(
      id: json['_id'] as String?,
      firstName: json['firstName'] as String?,
      surname: json['surname'] as String?,
      profilePicture: json['profile_picture'] as String?,
      email: json['email'] as String?,
      isPhoneVerified: json['isPhoneVerified'] as bool?,
      isEmailVerified: json['isEmailVerified'] as bool?,
      authProvider: json['authProvider'] as String?,
      socialId: json['socialId'] as String?,
      socialProfile: json['socialProfile'] as Map<String, dynamic>?,
      rideHistory:
          (json['rideHistory'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      paymentMethod: json['paymentMethod'] as String?,
      paystackCustomerId: json['paystackCustomerId'] as String?,
      mobileMoneyProvider: json['mobileMoneyProvider'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      role: json['role'] as String?,
      cardTokens:
          (json['cardTokens'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      knownDevices: (json['knownDevices'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(
              json['notificationPreferences'] as Map<String, dynamic>)
          : null,
    );
  }

  String? id;
  String? firstName;
  String? surname;
  String? profilePicture;
  String? email;
  bool? isPhoneVerified;
  bool? isEmailVerified;
  String? authProvider;
  String? socialId;
  Map<String, dynamic>? socialProfile;
  List<Map<String, dynamic>>? rideHistory;
  String? paymentMethod;
  String? paystackCustomerId;
  String? mobileMoneyProvider;
  String? preferredLanguage;
  String? role;
  List<Map<String, dynamic>>? cardTokens;
  List<Map<String, dynamic>>? knownDevices;
  DateTime? createdAt;
  DateTime? updatedAt;
  NotificationPreferences? notificationPreferences;
}

class NotificationPreferences {
  NotificationPreferences({
    this.loginAlerts,
    this.securityAlerts,
    this.marketingEmails,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      loginAlerts: json['loginAlerts'] as bool?,
      securityAlerts: json['securityAlerts'] as bool?,
      marketingEmails: json['marketingEmails'] as bool?,
    );
  }

  bool? loginAlerts;
  bool? securityAlerts;
  bool? marketingEmails;
}
