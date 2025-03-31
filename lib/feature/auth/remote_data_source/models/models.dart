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