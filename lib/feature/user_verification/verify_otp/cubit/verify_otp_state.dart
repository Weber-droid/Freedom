part of 'verify_otp_cubit.dart';

class VerifyOtpState extends Equatable {
  const VerifyOtpState({
    this.status = VerifyOtpStatus.initial,
    this.isError = false,
    this.errorMessage,
    this.isVerified,
    this.user,
  });
  final VerifyOtpStatus status;
  final bool isError;
  final String? errorMessage;
  final bool? isVerified;
  final User? user;

  VerifyOtpState copyWith({
    VerifyOtpStatus? status,
    bool? isError,
    String? errorMessage,
    bool? isVerified,
    bool clearMessage = false,
    User? user,
  }) {
    return VerifyOtpState(
      status: status ?? this.status,
      isError: isError ?? this.isError,
      errorMessage: clearMessage ? null : (errorMessage ?? this.errorMessage),
      isVerified: isVerified ?? this.isVerified,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, isError, errorMessage, isVerified];
}
