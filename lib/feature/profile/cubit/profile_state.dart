part of 'profile_cubit.dart';

abstract class ProfileState extends Equatable {
  const ProfileState(
      {this.activeField,
      this.originalEmail,
      this.originalPhone,
      this.countryCode = '+233'});
  final String? activeField;
  final String? originalEmail;
  final String? originalPhone;
  final String? countryCode;

  @override
  List<Object?> get props =>
      [activeField, originalEmail, originalPhone, countryCode];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded({
    this.user,
    super.activeField,
    super.originalEmail,
    super.originalPhone,
    super.countryCode,
  });
  final ProfileModel? user;

  ProfileLoaded copyWith({
    ProfileModel? user,
    String? cloudinaryUrl,
    String? activeField,
    String? originalEmail,
    String? originalPhone,
    String? countryCode,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      activeField: activeField ?? this.activeField,
      originalEmail: originalEmail ?? this.originalEmail,
      originalPhone: originalPhone ?? this.originalPhone,
      countryCode: countryCode ?? this.countryCode,
    );
  }

  @override
  List<Object?> get props =>
      [user, activeField, originalEmail, originalPhone, countryCode];
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}

class UploadingImage extends ProfileState {}

class ImageUploaded extends ProfileState {
  const ImageUploaded({this.isUploaded = false, this.user});
  final bool isUploaded;
  final ProfileModel? user;
}

class ImageUploadError extends ProfileState {
  const ImageUploadError(this.message);
  final String message;
}

class UpdatingNumber extends ProfileState {
  const UpdatingNumber({required this.phoneNumber});
  final String phoneNumber;
}

class NumberUpdated extends ProfileState {
  const NumberUpdated({
    this.isUpdated = false,
    this.message = '',
    required this.phoneNumber,
  });
  final bool isUpdated;
  final String message;
  final String phoneNumber;
}

class NumberUpdateError extends ProfileState {
  const NumberUpdateError(this.message);
  final String message;
}

class UpdatingEmail extends ProfileState {}

class EmailUpdated extends ProfileState {
  const EmailUpdated({
    this.isUpdated = false,
    this.message = '',
  });
  final bool isUpdated;
  final String message;
}

class EmailUpdateError extends ProfileState {
  const EmailUpdateError(this.message);
  final String message;
}

class VerifyingOtp extends ProfileState {
  const VerifyingOtp({required this.phoneNumber});
  final String phoneNumber;
}

class OtpVerified extends ProfileState {
  const OtpVerified({
    required this.isVerified,
    required this.phoneNumber,
  });
  final bool isVerified;
  final String phoneNumber;
}

class OtpVerificationError extends ProfileState {
  const OtpVerificationError(this.message, {required this.phoneNumber});
  final String message;
  final String phoneNumber;
}

class UpdateUserNamesInProgress extends ProfileState {}

class UserNamesUpdated extends ProfileState {
  const UserNamesUpdated({
    this.isUpdated = false,
    this.message = '',
    this.user,
  });
  final bool isUpdated;
  final String message;
  final User? user;
}

class UserNamesUpdateError extends ProfileState {
  const UserNamesUpdateError(this.message);
  final String message;
}
