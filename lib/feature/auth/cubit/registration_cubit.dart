import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/feature/auth/remote_data_source/models/models.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';
import 'package:freedom/shared/enums/enums.dart';
import 'package:freedom/shared/network_helpers.dart';

part 'registration_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this.registerRepository) : super(const RegisterState());
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
        (l) => emit(state.copyWith(
          formStatus: FormStatus.failure,
          message: parseApiErrorMessage(l.message),
        )),
        (r) => emit(state.copyWith(
            formStatus: FormStatus.success,
            message: 'Success, please verify your number to login')),
      );
    } on Exception catch (_) {
      emit(state.copyWith(
          formStatus: FormStatus.failure, message: state.message));
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
    } on ServerException catch (e) {
      emit(state.copyWith(formStatus: FormStatus.failure, message: e.message));
    } on NetworkException catch (e) {
      emit(state.copyWith(formStatus: FormStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(
          formStatus: FormStatus.failure, message: e.toString()));
    }
  }
}
