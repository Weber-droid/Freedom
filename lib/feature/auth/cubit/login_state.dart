part of 'login_cubit.dart';

class LoginState extends Equatable {
  const LoginState({
    this.phone = '',
    this.message = '',
    this.formStatus = FormStatus.initial,
  });

  factory LoginState.fromJson(Map<String, dynamic> json) {
    return LoginState(
      phone: json['phone'] as String? ?? '',
      message: json['message'] as String? ?? ''
    );
  }

  final String phone;
  final String message;
  final FormStatus formStatus;

  LoginState copyWith({
    String? phone,
    String? fullName,
    String? password,
    String? email,
    String? message,
    FormStatus? formStatus,
  }) {
    return LoginState(
      phone: phone ?? this.phone,
      message: message ?? this.message,
      formStatus: formStatus ?? this.formStatus,
    );
  }

  @override
  List<Object> get props => [phone, formStatus, message];

  Map<String, dynamic> toJson() => {
    'phone': phone,
  };
}
