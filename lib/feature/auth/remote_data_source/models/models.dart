class UserModel {
  UserModel(
      {required this.surName, required this.firstName, required this.email, required this.phoneNumber});

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'surname': surName,
    'email': email,
    'phone': phoneNumber,
  };

  final String firstName;
  final String surName;
  final String email;
  final String phoneNumber;
}

class LoginResponse {
  LoginResponse({required this.success, required this.message});


  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }

  final bool success;
  final String message;

}
class AuthResult {

  AuthResult({
    required this.success,
    this.message,
    this.userId,
    this.verificationId,
  });
  final bool success;
  final String? message;
  final String? userId;
  final String? verificationId;
}
