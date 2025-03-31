import 'package:hive/hive.dart';
part 'local_user.g.dart';

@HiveType(typeId: 0)
class User {

  User({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.role,
    this.token,
    this.success,
    this.message,
    this.userId,
  });

  /// Factory constructor for creating a User from verification endpoint response
  factory User.fromVerificationResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    return User(
      id: data?['id'] as String?,
      name: data?['name'] as String?,
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
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      token: json['token'] as String?,
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
  final String? name;

  @HiveField(2)
  final String? phone;

  @HiveField(3)
  final String? email;

  @HiveField(4)
  final String? role;

  @HiveField(5)
  final String? token;

  @HiveField(6)
  final bool? success;

  @HiveField(7)
  final String? message;

  @HiveField(8)
  final String? userId;

  /// Create a copy of this User but with the given fields replaced with the new values
  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? token,
    bool? success,
    String? message,
    String? userId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      success: success ?? this.success,
      message: message ?? this.message,
      userId: userId ?? this.userId,
    );
  }

  /// Convert User instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'token': token,
      'success': success,
      'message': message,
      'userId': userId,
    }..removeWhere((key, value) => value == null);
  }
}