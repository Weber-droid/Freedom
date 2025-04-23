part of 'verify_login_cubit.dart';

class VerifyLoginState extends Equatable {
  const VerifyLoginState({
    this.status = VerifyLoginStatus.initial,
    this.isError = false,
    this.errorMessage,
    this.isVerified = false,
    this.user,
    this.phoneNumber,
  });
  final VerifyLoginStatus status;
  final bool isError;
  final String? errorMessage;
  final bool isVerified;
  final User? user;
  final String? phoneNumber;

  VerifyLoginState copyWith({
    VerifyLoginStatus? status,
    bool? isError,
    String? errorMessage,
    bool? isVerified,
    bool clearMessage = false,
    User? user,
    String? phoneNumber,
  }) {
    return VerifyLoginState(
      status: status ?? this.status,
      isError: isError ?? this.isError,
      errorMessage: clearMessage ? null : (errorMessage ?? this.errorMessage),
      isVerified: isVerified ?? this.isVerified,
      user: user ?? this.user,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  List<Object?> get props =>
      [status, isError, errorMessage, isVerified, phoneNumber, user];
}
