part of 'auth_cubit.dart';
abstract class AuthState {
  final String? phoneNumber;
  final String? verificationId;

  const AuthState({
    this.phoneNumber,
    this.verificationId,
  });

  // This allows copying state with new values
  AuthState copyWith({String? phone, String? verId}) {
    return this;
  }
}

class AuthInitial extends AuthState {
  const AuthInitial({super.phoneNumber, super.verificationId});

  @override
  AuthInitial copyWith({String? phone, String? verId}) {
    return AuthInitial(
      phoneNumber: phone ?? phoneNumber,
      verificationId: verId ?? verificationId,
    );
  }
}

class AuthLoading extends AuthState {
  const AuthLoading({super.phoneNumber, super.verificationId});

  @override
  AuthLoading copyWith({String? phone, String? verId}) {
    return AuthLoading(
      phoneNumber: phone ?? phoneNumber,
      verificationId: verId ?? verificationId,
    );
  }
}

class OtpSent extends AuthState {
  final String message;

  const OtpSent({
    required this.message,
    required String verificationId,
    super.phoneNumber,
  }) : super(verificationId: verificationId);

  @override
  OtpSent copyWith({String? phone, String? verId}) {
    return OtpSent(
      message: message,
      verificationId: verId ?? verificationId!,
      phoneNumber: phone ?? phoneNumber,
    );
  }
}

class AuthSuccess extends AuthState {
  final String userId;

  const AuthSuccess({
    required this.userId,
    super.phoneNumber,
    super.verificationId,
  });

  @override
  AuthSuccess copyWith({String? phone, String? verId}) {
    return AuthSuccess(
      userId: userId,
      phoneNumber: phone ?? phoneNumber,
      verificationId: verId ?? verificationId,
    );
  }
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({
    required this.message,
    super.phoneNumber,
    super.verificationId,
  });

  @override
  AuthFailure copyWith({String? phone, String? verId}) {
    return AuthFailure(
      message: message,
      phoneNumber: phone ?? phoneNumber,
      verificationId: verId ?? verificationId,
    );
  }
}