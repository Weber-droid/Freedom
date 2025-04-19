part of 'registration_cubit.dart';

class RegisterState extends Equatable {
  const RegisterState(
      {this.phone = '',
      this.firstName = '',
      this.surname = '',
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

  RegisterState copyWith({
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
    return RegisterState(
        phone: phone ?? this.phone,
        firstName: firstName ?? this.firstName,
        surname: surname ?? this.surname,
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
        firstName,
        surname,
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
        'firstName': firstName,
        'surname': surname,
        'email': email,
        'password': password,
      };
}
