class ProfileModel {
  ProfileModel({
    required this.success,
    required this.data,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      success: json['success'] == true,
      data: ProfileData.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }
  final bool success;
  final ProfileData data;

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toJson(),
    };
  }
}

class ProfileData {
  ProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isPhoneVerified,
    required this.isEmailVerified,
    required this.authProvider,
    required this.role,
    required this.profilePicture,
    required this.mobileMoneyProvider,
    required this.mobileMoneyNumber,
    required this.createdAt,
    required this.updatedAt,
    // New fields
    this.socialId,
    this.socialProfile,
    this.rideHistory,
    this.paymentMethod,
    this.paystackCustomerId,
    this.preferredLanguage,
    this.cardTokens,
    this.knownDevices,
    this.notificationPreferences,
    this.firstName,
    this.surname,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isPhoneVerified: json['isPhoneVerified'] == true,
      isEmailVerified: json['isEmailVerified'] == true,
      authProvider: json['authProvider']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString() ?? '',
      mobileMoneyProvider: json['mobileMoneyProvider']?.toString() ?? '',
      mobileMoneyNumber: json['mobileMoneyNumber']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      // New fields
      firstName: json['firstName']?.toString(),
      surname: json['surname']?.toString(),
      socialId: json['socialId']?.toString(),
      socialProfile: json['socialProfile'] as Map<String, dynamic>?,
      rideHistory: (json['rideHistory'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      paymentMethod: json['paymentMethod']?.toString(),
      paystackCustomerId: json['paystackCustomerId']?.toString(),
      preferredLanguage: json['preferredLanguage']?.toString(),
      cardTokens: (json['cardTokens'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      knownDevices: (json['knownDevices'] as List<dynamic>?)
          ?.map((e) => KnownDevice.fromJson(e as Map<String, dynamic>))
          .toList(),
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(
          json['notificationPreferences'] as Map<String, dynamic>)
          : null,
    );
  }
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final String authProvider;
  final String role;
  final String profilePicture;
  final String mobileMoneyProvider;
  final String mobileMoneyNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New fields
  final String? firstName;
  final String? surname;
  final String? socialId;
  final Map<String, dynamic>? socialProfile;
  final List<Map<String, dynamic>>? rideHistory;
  final String? paymentMethod;
  final String? paystackCustomerId;
  final String? preferredLanguage;
  final List<Map<String, dynamic>>? cardTokens;
  final List<KnownDevice>? knownDevices;
  final NotificationPreferences? notificationPreferences;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'authProvider': authProvider,
      'role': role,
      'profile_picture': profilePicture,
      'mobileMoneyProvider': mobileMoneyProvider,
      'mobileMoneyNumber': mobileMoneyNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // New fields
      'firstName': firstName,
      'surname': surname,
      'socialId': socialId,
      'socialProfile': socialProfile,
      'rideHistory': rideHistory,
      'paymentMethod': paymentMethod,
      'paystackCustomerId': paystackCustomerId,
      'preferredLanguage': preferredLanguage,
      'cardTokens': cardTokens,
      'knownDevices': knownDevices?.map((device) => device.toJson()).toList(),
      'notificationPreferences': notificationPreferences?.toJson(),
    }

    // Remove null values
    ..removeWhere((key, value) => value == null);
    return data;
  }
}

class NotificationPreferences {
  NotificationPreferences({
    required this.loginAlerts,
    required this.securityAlerts,
    required this.marketingEmails,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      loginAlerts: json['loginAlerts'] == true,
      securityAlerts: json['securityAlerts'] == true,
      marketingEmails: json['marketingEmails'] == true,
    );
  }

  final bool loginAlerts;
  final bool securityAlerts;
  final bool marketingEmails;

  Map<String, dynamic> toJson() {
    return {
      'loginAlerts': loginAlerts,
      'securityAlerts': securityAlerts,
      'marketingEmails': marketingEmails,
    };
  }
}

class KnownDevice {
  KnownDevice({
    required this.id,
    required this.fingerprint,
    required this.browser,
    required this.os,
    required this.device,
    required this.firstLogin,
    required this.lastLogin,
  });

  factory KnownDevice.fromJson(Map<String, dynamic> json) {
    return KnownDevice(
      id: json['_id']?.toString() ?? '',
      fingerprint: json['fingerprint']?.toString() ?? '',
      browser: json['browser']?.toString() ?? '',
      os: json['os']?.toString() ?? '',
      device: json['device']?.toString() ?? '',
      firstLogin: json['firstLogin'] != null
          ? DateTime.parse(json['firstLogin'].toString())
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'].toString())
          : DateTime.now(),
    );
  }

  final String id;
  final String fingerprint;
  final String browser;
  final String os;
  final String device;
  final DateTime firstLogin;
  final DateTime lastLogin;

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fingerprint': fingerprint,
      'browser': browser,
      'os': os,
      'device': device,
      'firstLogin': firstLogin.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }
}