part of 'verify_otp_cubit.dart';

class VerifyOtpState extends Equatable {
  const VerifyOtpState({
    this.isLoading = false,
    this.isError = false,
    this.errorMessage = '',
    this.isVerified = false,
  });
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final bool isVerified;

  VerifyOtpState copyWith({
    String? otp,
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    bool? isVerified,
  }) {
    return VerifyOtpState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [isLoading, isError, errorMessage, isVerified];
}
