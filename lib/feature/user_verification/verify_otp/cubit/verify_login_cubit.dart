import 'dart:convert';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';
import 'package:freedom/shared/enums/enums.dart';

part 'verify_login_state.dart';

class VerifyLoginCubit extends Cubit<VerifyLoginState> {
  VerifyLoginCubit(this.registerRepository) : super(const VerifyLoginState());
  final RegisterRepository registerRepository;

  void setPhoneNumber(String phoneNumber) {
    log('phoneNumber: $phoneNumber');
    emit(state.copyWith(phoneNumber: phoneNumber));
  }

  Future<void> verifyLogin(String otp) async {
    emit(state.copyWith(status: VerifyLoginStatus.submitting));
    try {
      final response =
          await registerRepository.verifyLogin(state.phoneNumber!, otp);
      await Future.delayed(Duration(seconds: 2));
      await response.fold((l) {
        emit(
          state.copyWith(
            status: VerifyLoginStatus.failure,
            isError: true,
            errorMessage: l.message,
          ),
        );
      }, (r) async {
        log('right profile ${r?.toJson()}');
        await AppPreferences.setFirstTimer(false);
        if (r != null) {
          await AppPreferences.setToken(r.token!);
          final dataSource = RegisterLocalDataSource();
          await dataSource.saveUser(r);
        }
        emit(
          state.copyWith(
            status: VerifyLoginStatus.success,
            isVerified: true,
            user: r,
          ),
        );
      });
    } catch (e) {
      emit(
        state.copyWith(
          status: VerifyLoginStatus.failure,
          isError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
