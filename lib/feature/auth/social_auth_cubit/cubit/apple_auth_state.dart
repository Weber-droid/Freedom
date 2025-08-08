part of 'apple_auth_cubit.dart';

class AppleAuthState extends Equatable {
  const AppleAuthState({
    this.phone = '',
    this.firstName = '',
    this.surname = '',
    this.email = '',
    this.password = '',
    this.message = '',
    this.resendOtp = false,
    this.formStatus = FormStatus.initial,
    this.phoneStatus = PhoneStatus.initial,
    this.needsVerification = false,
  });

  factory AppleAuthState.fromJson(Map<String, dynamic> json) {
    return AppleAuthState(
      phone: json['phone'] as String? ?? '',
      firstName: json['name'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  final String phone;
  final String firstName;
  final String surname;
  final String email;
  final String password;
  final String message;
  final bool resendOtp;
  final FormStatus formStatus;
  final PhoneStatus phoneStatus;
  final bool needsVerification;

  AppleAuthState copyWith({
    String? phone,
    String? firstName,
    String? surname,
    String? password,
    String? email,
    String? message,
    bool? resendOtp,
    FormStatus? formStatus,
    PhoneStatus? phoneStatus,
    bool? needsVerification,
  }) {
    return AppleAuthState(
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      surname: surname ?? this.surname,
      password: password ?? this.password,
      email: email ?? this.email,
      message: message ?? this.message,
      resendOtp: resendOtp ?? this.resendOtp,
      formStatus: formStatus ?? this.formStatus,
      phoneStatus: phoneStatus ?? this.phoneStatus,
      needsVerification: needsVerification ?? this.needsVerification,
    );
  }

  @override
  List<Object> get props => [
    firstName,
    surname,
    phone,
    email,
    password,
    formStatus,
    message,
    resendOtp,
    phoneStatus,
    needsVerification,
  ];

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'firstName': firstName,
    'surname': surname,
    'email': email,
    'password': password,
  };
}
