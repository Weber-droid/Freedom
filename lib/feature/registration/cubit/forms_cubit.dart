import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freedom/feature/registration/remote_data_source/remote_data_source_models.dart';
import 'package:freedom/feature/registration/repository/register_repository.dart';
part 'forms_state.dart';

class RegisterFormCubit extends Cubit<RegisterFormState> {
  RegisterFormCubit(this.registerRepository) : super(const RegisterFormState());
  final RegisterRepository registerRepository;
  void setPhoneNumber(String phoneNumber) {
    log('phoneNumber: $phoneNumber');
    emit(state.copyWith(phone: phoneNumber));
  }

  void setUserDetails({
    String? phone,
    String? fullName,
    String? email,
    String? password,
  }) {
    emit(state.copyWith(
      phone: phone,
      fullName: fullName,
      email: email,
      password: password,
    ));
  }

  Future<void> registerUser() async {
    emit(state.copyWith(formStatus: FormStatus.submitting));
    try {
      final response = await registerRepository.registerUser(UserModel(
          name: state.fullName, email: state.email, phoneNumber: state.phone));

      response.fold(
        (l) => emit(state.copyWith(formStatus: FormStatus.failure)),
        (r) => emit(state.copyWith(
            formStatus: FormStatus.success,
            message: 'Success, please verify your number to login')),
      );
    } on Exception catch (_) {
      emit(state.copyWith(formStatus: FormStatus.failure));
    }
  }

  Future<void> registerOrLoginWithGoogle() async {
    emit(state.copyWith(formStatus: FormStatus.submitting));
    try {
      final response = await registerRepository.registerOrLoginWithGoogle();
      response.fold(
        (l) => emit(state.copyWith(formStatus: FormStatus.failure)),
        (r) => emit(state.copyWith(
            formStatus: FormStatus.success,
            fullName: r?.displayName,
            message: 'Success, please verify your number to login')),
      );
    } on Exception catch (_) {
      emit(state.copyWith(formStatus: FormStatus.failure));
    }
  }
}
