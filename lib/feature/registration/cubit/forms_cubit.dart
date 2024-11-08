import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
part 'forms_state.dart';

class RegisterFormCubit extends Cubit<RegisterFormState> {
  RegisterFormCubit() : super(const RegisterFormState());
  void setPhoneNumber(String phoneNumber) {
    log('phoneNumber: $phoneNumber');
    emit(state.copyWith(phoneNumber: phoneNumber));
  }
}
