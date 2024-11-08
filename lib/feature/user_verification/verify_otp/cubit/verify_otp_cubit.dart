import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'verify_otp_state.dart';

class VerifyOtpCubit extends Cubit<VerifyOtpState> {
  VerifyOtpCubit() : super(const VerifyOtpState());

  void verifyOtp(String otp) {
    emit(state.copyWith(isLoading: true));
    if (isOtpValid(otp)) {
      emit(state.copyWith(isVerified: true));
      emit(state.copyWith(isLoading: false));
    } else {
      emit(state.copyWith(isError: true));
      emit(state.copyWith(errorMessage: 'Invalid OTP'));
      emit(state.copyWith(isLoading: false));
    }
  }
}

bool isOtpValid(String otp) {
  const systemValue = 123456;
  if (otp.length == 6 && otp == systemValue.toString()) {
    return true;
  }
  return false;
}
