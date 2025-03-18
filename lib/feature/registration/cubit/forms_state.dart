part of 'forms_cubit.dart';

class RegisterFormState extends Equatable {
  const RegisterFormState({
    this.phone = '',
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.message = '',
    this.formStatus = FormStatus.initial,
  });

  factory RegisterFormState.fromJson(Map<String, dynamic> json) {
    return RegisterFormState(
      phone: json['phone'] as String? ?? '',
      fullName: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  final String phone;
  final String fullName;
  final String email;
  final String password;
  final String message;
  final FormStatus formStatus;

  RegisterFormState copyWith({
    String? phone,
    String? fullName,
    String? password,
    String? email,
    String? message,
    FormStatus? formStatus,
  }) {
    return RegisterFormState(
        phone: phone ?? this.phone,
        fullName: fullName ?? this.fullName,
        password: password ?? this.password,
        email: email ?? this.email,
        message: message ?? this.message,
        formStatus: formStatus ?? this.formStatus,
    );
  }

  @override
  List<Object> get props => [
    phone,
  email,
    password,
    formStatus,
    message
  ];

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'name': fullName,
    'email': email,
    'password': password,
  };
}

enum FormStatus { initial, submitting, success, failure }