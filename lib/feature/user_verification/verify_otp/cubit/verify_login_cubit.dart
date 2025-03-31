import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freedom/core/client/data_layer_exceptions.dart';
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
    emit(state.copyWith(phoneNumber:  phoneNumber));
  }

  Future<void> verifyLogin(String otp) async {
    emit(state.copyWith(status: VerifyLoginStatus.submitting));

    try {
      final response = await registerRepository.verifyLogin(state.phoneNumber!, otp);

      response.fold(
              (l) => emit(
            state.copyWith(
              status: VerifyLoginStatus.failure,
              isError: true,
              errorMessage: l.message,
            ),
          ),
              (r) async {
            await RegisterLocalDataSource.setIsFirstTimer(isFirstTimer: false);
            final dataSource = RegisterLocalDataSource();
            await dataSource.saveUser(r ?? User());
            emit(
              state.copyWith(
                status: VerifyLoginStatus.success,
                isVerified: true,
                user: r,
              ),
            );
          }
      );
    } on ServerException catch (e) {
      emit(
        state.copyWith(
          status: VerifyLoginStatus.failure,
          isError: true,
          errorMessage: e.message,
        ),
      );
    } on NetworkException catch (e) {
      emit(
        state.copyWith(
          status: VerifyLoginStatus.failure,
          isError: true,
          errorMessage: e.message,
        ),
      );
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