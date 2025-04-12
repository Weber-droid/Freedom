import 'dart:convert';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';
import 'package:freedom/shared/enums/enums.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({RegisterRepository? registerRepository})
      : _registerRepository = registerRepository ?? RegisterRepository(),
        super(const LoginState());
  final RegisterRepository _registerRepository;

  void setPhoneNumber(String phoneNumber) {
    log('phoneNumber: $phoneNumber');
    emit(state.copyWith(phone: phoneNumber));
  }

  Future<void> loginUserWithPhoneNumber() async {
    final phoneNumber = state.phone;

    if (phoneNumber == null || phoneNumber.isEmpty) {
      emit(state.copyWith(
        message: 'Phone number is required',
        formStatus: FormStatus.failure,
      ));
      return;
    }

    try {
      emit(state.copyWith(formStatus: FormStatus.submitting));
      final response = await _registerRepository.loginUser(phoneNumber);
      response.fold((fail) {
        final message = json.decode(fail.message);
        log('message $message');
        final transformedMessage = message['msg'] as String;
        emit(state.copyWith(
            message: transformedMessage, formStatus: FormStatus.failure));
      }, (r) {
        emit(
          state.copyWith(message: r?.message, formStatus: FormStatus.success),
        );
      });
    } on Exception catch (e) {
      emit(state.copyWith(
        message: e.toString(),
        formStatus: FormStatus.failure,
      ));
    }
  }
}
