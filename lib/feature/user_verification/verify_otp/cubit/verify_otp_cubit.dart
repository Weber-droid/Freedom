import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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

    response.fold(
        (l) => emit(
              state.copyWith(
                status: VerifyOtpStatus.failure,
                isError: true,
                errorMessage: l.message,
              ),
            ), (r) async {
      await RegisterLocalDataSource.setIsFirstTimer(isFirstTimer: false);
      final dataSource = RegisterLocalDataSource();
      await dataSource.saveUser(r);
      emit(
        state.copyWith(
          status: VerifyOtpStatus.success,
          isVerified: true,
          user: r,
        ),
      );
    });
  }
}
