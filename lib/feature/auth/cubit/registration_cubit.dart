import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:freedom/feature/auth/remote_data_source/models/models.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';
import 'package:freedom/shared/enums/enums.dart';

part 'registration_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this.registerRepository)
    : _firebaseMessaging = FirebaseMessaging.instance,
      super(const RegisterState());
  final RegisterRepository registerRepository;
  final FirebaseMessaging _firebaseMessaging;

  void setPhoneNumber(String phoneNumber) {
    emit(state.copyWith(phone: phoneNumber));
  }

  void setUserDetails({
    String? phone,
    String? firstName,
    String? surName,
    String? email,
    String? password,
  }) {
    emit(
      state.copyWith(
        phone: phone,
        firstName: firstName,
        surname: surName,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> registerUser(
    String firstName,
    String surName,
    String email,
    String phone,
  ) async {
    emit(state.copyWith(formStatus: FormStatus.submitting));
    try {
      final response = await registerRepository.registerUser(
        UserModel(
          firstName: firstName,
          surName: surName,
          email: email,
          phoneNumber: phone,
        ),
      );

      await response.fold(
        (l) {
          log('message: ${l.message}');
          emit(
            state.copyWith(formStatus: FormStatus.failure, message: l.message),
          );
        },
        (r) async {
          log('message: ${r.toJson()}');
          emit(
            state.copyWith(formStatus: FormStatus.success, message: r.message),
          );
        },
      );
    } on Exception catch (_) {
      emit(
        state.copyWith(formStatus: FormStatus.failure, message: state.message),
      );
    }
  }

  Future<void> checkPhoneStatus() async {
    emit(state.copyWith(phoneStatus: PhoneStatus.submitting));
    try {
      final response = await registerRepository.checkSocialAuthPhoneStatus();

      response.fold(
        (failure) {
          log(failure.message);
          emit(
            state.copyWith(
              phoneStatus: PhoneStatus.failure,
              message: failure.message,
              formStatus: FormStatus.initial,
            ),
          );
        },
        (needsVerification) {
          log('needs verifaction: $needsVerification');
          emit(
            state.copyWith(
              phoneStatus: PhoneStatus.success,
              needsVerification: needsVerification,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          phoneStatus: PhoneStatus.failure,
          message: e.toString(),
          formStatus: FormStatus.initial,
        ),
      );
    }
  }
}
