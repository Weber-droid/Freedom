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

  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}