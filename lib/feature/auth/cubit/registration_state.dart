part of 'registration_cubit.dart';

class RegisterState extends Equatable {
  const RegisterState(
      {this.phone = '',
      this.fullName = '',
      this.email = '',
      this.password = '',
      this.message = '',
      this.resendOtp = false,
      this.formStatus = FormStatus.initial,
      this.phoneStatus = PhoneStatus.initial,
      this.needsVerification = false});

  factory RegisterState.fromJson(Map<String, dynamic> json) {
    return RegisterState(
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
  final bool resendOtp;
  final FormStatus formStatus;
  final PhoneStatus phoneStatus;
  final bool needsVerification;

  RegisterState copyWith({
    String? phone,
    String? fullName,
    String? password,
    String? email,
    String? message,
    bool? resendOtp,
    FormStatus? formStatus,
    PhoneStatus? phoneStatus,
    bool? needsVerification,
  }) {
    return RegisterState(
        phone: phone ?? this.phone,
        fullName: fullName ?? this.fullName,
        password: password ?? this.password,
        email: email ?? this.email,
        message: message ?? this.message,
        resendOtp: resendOtp ?? this.resendOtp,
        formStatus: formStatus ?? this.formStatus,
        phoneStatus: phoneStatus ?? this.phoneStatus,
        needsVerification: needsVerification ?? this.needsVerification);
  }

  @override
  List<Object> get props => [
        phone,
        email,
        password,
        formStatus,
        message,
        resendOtp,
        phoneStatus,
        needsVerification
      ];

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'name': fullName,
        'email': email,
        'password': password,
      };
}
