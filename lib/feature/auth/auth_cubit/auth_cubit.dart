import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this.registerRepository}) : super(const AuthInitial());
  final RegisterRepository registerRepository;

  // Method to set phone number
  void setPhoneNumber(String phoneNumber) {
    log('Setting phone number: $phoneNumber');
    emit(state.copyWith(phone: phoneNumber));
  }

  // Method to set verification ID (useful if you need to set it manually)
  void setVerificationId(String verificationId) {
    log('Setting verification ID: $verificationId');
    emit(state.copyWith(verId: verificationId));
  }

  Future<void> sendOtp(String phoneNumber) async {
    // Preserve verification ID if it exists in current state
    final currentVerId = state.verificationId;

    // Transition to loading state
    emit(AuthLoading(
      phoneNumber: phoneNumber,
      verificationId: currentVerId,
    ));

    final result = await registerRepository.sendOtp(phoneNumber);

    result.fold(
            (f) => emit(AuthFailure(
          message: f.message,
          phoneNumber: phoneNumber,
          verificationId: currentVerId, // Preserve verification ID in error state
        )),
            (s) {
          if (s.success && s.verificationId != null) {
            emit(OtpSent(
              verificationId: s.verificationId!,
              message: s.message ?? 'OTP sent successfully',
              phoneNumber: phoneNumber,
            ));
          } else if (s.success && s.userId != null) {
            emit(AuthSuccess(
              userId: s.userId!,
              phoneNumber: phoneNumber,
              verificationId: s.verificationId ?? currentVerId,
            ));
          }
        }
    );
  }

  Future<void> verifyOtp(String otp) async {
    // We need both phone number and verification ID from current state
    final currentPhone = state.phoneNumber;
    final verificationId = state.verificationId;

    if (verificationId == null) {
      emit(AuthFailure(
        message: 'Verification ID not found',
        phoneNumber: currentPhone,
      ));
      return;
    }

    emit(AuthLoading(
      phoneNumber: currentPhone,
      verificationId: verificationId,
    ));

    final result = await registerRepository.verifyOtp(verificationId, otp);
    result.fold(
            (f) => emit(AuthFailure(
          message: f.message,
          phoneNumber: currentPhone,
          verificationId: verificationId, // Keep verification ID in failure state
        )),
            (s) {
          if (s.success && s.userId != null) {
            emit(AuthSuccess(
              userId: s.userId!,
              phoneNumber: currentPhone,
              verificationId: verificationId, // Keep verification ID in success state
            ));
          }
        }
    );
  }

  Future<void> checkCurrentUser() async {
    final currentPhone = state.phoneNumber;
    final currentVerId = state.verificationId;

    emit(AuthLoading(
      phoneNumber: currentPhone,
      verificationId: currentVerId,
    ));

    final result = await registerRepository.getCurrentUser();
    result.fold(
            (f) => emit(AuthInitial(
          phoneNumber: currentPhone,
          verificationId: currentVerId,
        )),
            (s) {
          if (s.success && s.userId != null) {
            emit(AuthSuccess(
              userId: s.userId!,
              phoneNumber: currentPhone,
              verificationId: currentVerId,
            ));
          }
        }
    );
  }

  Future<void> signOut() async {
    final currentPhone = state.phoneNumber;
    emit(AuthLoading(phoneNumber: currentPhone));

    await registerRepository.signOut();
    emit(AuthInitial(phoneNumber: currentPhone));
  }
}