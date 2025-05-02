import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freedom/app_preference.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';
import 'package:freedom/shared/enums/enums.dart';

part 'verify_otp_state.dart';

class VerifyOtpCubit extends Cubit<VerifyOtpState> {
  VerifyOtpCubit(this.registerRepository) : super(const VerifyOtpState());
  final RegisterRepository registerRepository;
  Future<void> verifyOtp(String phone, String otp) async {
    emit(state.copyWith(status: VerifyOtpStatus.submitting));
    final response = await registerRepository.verifyPhoneNumber(phone, otp);

    await response.fold(
            (l) {
          emit(
            state.copyWith(
              status: VerifyOtpStatus.failure,
              isError: true,
              errorMessage: l.message,
              isVerified: false,
            ),
          );
        }, (r) async {
      await AppPreferences.setFirstTimer(false);
      await AppPreferences.setToken(r.token!);
      final dataSource = RegisterLocalDataSource();
      await dataSource.saveUser(r);
      emit(
        state.copyWith(
          status: VerifyOtpStatus.success,
          isVerified: r.success,
          user: r,
        ),
      );
    });
  }

  Future<void> resendOtp(String phoneNumber, String purpose) async {
    emit(state.copyWith(status: VerifyOtpStatus.submitting));
    try {
      final response = await registerRepository.resendOtp(phoneNumber, purpose);
      response.fold((l) {
        emit(state.copyWith(
            errorMessage: l.message, status: VerifyOtpStatus.failure));
      }, (s) {
        emit(state.copyWith(status: VerifyOtpStatus.success));
      });
    } on Exception catch (_) {
      emit(state.copyWith(
          status: VerifyOtpStatus.failure, errorMessage: state.errorMessage));
    }
  }
}
