part of 'forms_cubit.dart';

class RegisterFormState extends Equatable {
  const RegisterFormState({
    this.phoneNumber,
  });
  final String? phoneNumber;

  RegisterFormState copyWith({
    String? phoneNumber,
  }) {
    return RegisterFormState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  List<Object?> get props => [phoneNumber];
}
