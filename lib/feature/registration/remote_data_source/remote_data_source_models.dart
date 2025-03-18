import 'dart:convert';

class User {
  User({
    required this.message,
    required this.userId,
    required this.success,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    message: json['message'] as String,
    userId: json['userId'] as String,
    success: json['success'] as bool,
  );
  final String message;
  final bool success;
  final String userId;
}

class UserModel {
  UserModel(
      {required this.name, required this.email, required this.phoneNumber});

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phoneNumber,
  };

  final String name;
  final String email;
  final String phoneNumber;
}