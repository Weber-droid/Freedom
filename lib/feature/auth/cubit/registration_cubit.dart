import 'dart:convert';
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
        (l) {
          final message = json.decode(l.message);
          log('message $message');
          final transformedMessage = message['msg'] as String;
          emit(state.copyWith(
            formStatus: FormStatus.failure,
            message: transformedMessage,
          ));
        },
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

      await response.fold(
            (failure) {
          // Properly handle the failure here
          emit(state.copyWith(
            formStatus: FormStatus.failure,
            message: failure.message,
          ));
        },
            (success) async {
          // Check if there's an error message in the success response
          if (success?.message?.contains("Duplicate value") == true ||
              success?.message?.contains("error") == true) {
            emit(state.copyWith(
              formStatus: FormStatus.failure,
              message: success?.message,
            ));
            return; // Stop execution to prevent proceeding to phone status check
          }

          emit(state.copyWith(
            formStatus: FormStatus.success,
            fullName: success?.data?.name,
            phone: '',
            message: success?.message,
          ));

          // Only check phone status if authentication was actually successful
          await _checkPhoneStatus();
        },
      );
    } catch (e) {
      emit(state.copyWith(
        formStatus: FormStatus.failure,
        message: e.toString(),
      ));
    }
  }

  Future<void> _checkPhoneStatus() async {
    emit(state.copyWith(phoneStatus: PhoneStatus.submitting));
    try {
      final response = await registerRepository.checkSocialAuthPhoneStatus();

      response.fold(
            (failure) {
          // Clear any previous success status
          emit(state.copyWith(
            phoneStatus: PhoneStatus.failure,
            message: failure.message,
            formStatus: FormStatus.initial, // Reset to initial state
          ));
        },
            (needsVerification) {
          emit(state.copyWith(
            phoneStatus: PhoneStatus.success,
            needsVerification: needsVerification,
          ));
        },
      );
    } catch (e) {
      // Reset form status on exception
      emit(state.copyWith(
        phoneStatus: PhoneStatus.failure,
        message: e.toString(),
        formStatus: FormStatus.initial,
      ));
    }
  }
}
