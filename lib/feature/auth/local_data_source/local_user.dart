import 'package:hive/hive.dart';
part 'local_user.g.dart';

@HiveType(typeId: 0)
class User {
  User({
    this.id,
    this.phone,
    this.email,
    this.role,
    this.token,
    this.success,
    this.message,
    this.userId,
    this.userImage,
    // New fields
    this.firstName,
    this.surname,
    this.profilePicture,
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
    this.cardTokens,
    this.knownDevices,
    this.createdAt,
    this.updatedAt,
    this.notificationPreferences,
  });

  /// Factory constructor for creating a User from verification endpoint response
  factory User.fromVerificationResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return User(
      id: data?['id'] as String?,
      phone: data?['phone'] as String?,
      email: data?['email'] as String?,
      role: data?['role'] as String?,
      token: data?['token'] as String?,
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      token: json['token'] as String?,
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }

  /// Factory constructor for creating a User from new API response format
  factory User.fromNewApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return User();

    return User(
      id: data['_id'] as String?,
      email: data['email'] as String?,
      role: data['role'] as String?,
      userImage: data['profile_picture'] as String?,
      // New fields
      firstName: data['firstName'] as String?,
      surname: data['surname'] as String?,
      profilePicture: data['profile_picture'] as String?,
      isPhoneVerified: data['isPhoneVerified'] as bool?,
      isEmailVerified: data['isEmailVerified'] as bool?,
      authProvider: data['authProvider'] as String?,
      socialId: data['socialId'] as String?,
      socialProfile: data['socialProfile'] as Map<String, dynamic>?,
      rideHistory: (data['rideHistory'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      paymentMethod: data['paymentMethod'] as String?,
      paystackCustomerId: data['paystackCustomerId'] as String?,
      mobileMoneyProvider: data['mobileMoneyProvider'] as String?,
      preferredLanguage: data['preferredLanguage'] as String?,
      cardTokens: (data['cardTokens'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      knownDevices: (data['knownDevices'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt'] as String) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt'] as String) : null,
      notificationPreferences: data['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(data['notificationPreferences'] as Map<String, dynamic>)
          : null,
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }

  /// Factory constructor for creating a User from registration endpoint response
  factory User.fromRegistrationResponse(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String?,
      success: json['success'] as bool?,
      message: json['message'] as String?,
    );
  }

  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String? phone;

  @HiveField(2)
  final String? email;

  @HiveField(3)
  final String? role;

  @HiveField(4)
  final String? token;

  @HiveField(5)
  final bool? success;

  @HiveField(6)
  final String? message;

  @HiveField(7)
  final String? userId;

  @HiveField(8)
  final String? userImage;

  // New fields with new HiveField indices
  @HiveField(9)
  final String? firstName;

  @HiveField(10)
  final String? surname;

  @HiveField(11)
  final String? profilePicture;

  @HiveField(12)
  final bool? isPhoneVerified;

  @HiveField(13)
  final bool? isEmailVerified;

  @HiveField(14)
  final String? authProvider;

  @HiveField(15)
  final String? socialId;

  @HiveField(16)
  final Map<String, dynamic>? socialProfile;

  @HiveField(17)
  final List<Map<String, dynamic>>? rideHistory;

  @HiveField(18)
  final String? paymentMethod;

  @HiveField(19)
  final String? paystackCustomerId;

  @HiveField(20)
  final String? mobileMoneyProvider;

  @HiveField(21)
  final String? preferredLanguage;

  @HiveField(22)
  final List<Map<String, dynamic>>? cardTokens;

  @HiveField(23)
  final List<Map<String, dynamic>>? knownDevices;

  @HiveField(24)
  final DateTime? createdAt;

  @HiveField(25)
  final DateTime? updatedAt;

  @HiveField(26)
  final NotificationPreferences? notificationPreferences;

  /// Create a copy of this User but with the given fields replaced with the new values
  User copyWith({
    String? id,
    String? phone,
    String? email,
    String? role,
    String? token,
    bool? success,
    String? message,
    String? userId,
    String? userImage,
    // New fields
    String? firstName,
    String? surname,
    String? profilePicture,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    String? authProvider,
    String? socialId,
    Map<String, dynamic>? socialProfile,
    List<Map<String, dynamic>>? rideHistory,
    String? paymentMethod,
    String? paystackCustomerId,
    String? mobileMoneyProvider,
    String? preferredLanguage,
    List<Map<String, dynamic>>? cardTokens,
    List<Map<String, dynamic>>? knownDevices,
    DateTime? createdAt,
    DateTime? updatedAt,
    NotificationPreferences? notificationPreferences,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      success: success ?? this.success,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      userImage: userImage ?? this.userImage,
      // New fields
      firstName: firstName ?? this.firstName,
      surname: surname ?? this.surname,
      profilePicture: profilePicture ?? this.profilePicture,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authProvider: authProvider ?? this.authProvider,
      socialId: socialId ?? this.socialId,
      socialProfile: socialProfile ?? this.socialProfile,
      rideHistory: rideHistory ?? this.rideHistory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paystackCustomerId: paystackCustomerId ?? this.paystackCustomerId,
      mobileMoneyProvider: mobileMoneyProvider ?? this.mobileMoneyProvider,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      cardTokens: cardTokens ?? this.cardTokens,
      knownDevices: knownDevices ?? this.knownDevices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  /// Convert User instance to a JSON map
  Map<String, dynamic> toJson() {
    final notificationPreferencesJson = notificationPreferences?.toJson();

    return {
      'id': id,
      'phone': phone,
      'email': email,
      'role': role,
      'token': token,
      'success': success,
      'message': message,
      'userId': userId,
      'userImage': userImage,
      // New fields
      'firstName': firstName,
      'surname': surname,
      'profile_picture': profilePicture,
      'isPhoneVerified': isPhoneVerified,
      'isEmailVerified': isEmailVerified,
      'authProvider': authProvider,
      'socialId': socialId,
      'socialProfile': socialProfile,
      'rideHistory': rideHistory,
      'paymentMethod': paymentMethod,
      'paystackCustomerId': paystackCustomerId,
      'mobileMoneyProvider': mobileMoneyProvider,
      'preferredLanguage': preferredLanguage,
      'cardTokens': cardTokens,
      'knownDevices': knownDevices,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notificationPreferences': notificationPreferencesJson,
    }..removeWhere((key, value) => value == null);
  }
}

@HiveType(typeId: 1)
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

  @HiveField(0)
  final bool? loginAlerts;

  @HiveField(1)
  final bool? securityAlerts;

  @HiveField(2)
  final bool? marketingEmails;

  Map<String, dynamic> toJson() {
    return {
      'loginAlerts': loginAlerts,
      'securityAlerts': securityAlerts,
      'marketingEmails': marketingEmails,
    }..removeWhere((key, value) => value == null);
  }

  NotificationPreferences copyWith({
    bool? loginAlerts,
    bool? securityAlerts,
    bool? marketingEmails,
  }) {
    return NotificationPreferences(
      loginAlerts: loginAlerts ?? this.loginAlerts,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }
}