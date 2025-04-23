part of 'profile_cubit.dart';

// IMPROVED STATE CLASSES
// Make ProfileModel nullable in all relevant states to avoid null checks

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  ProfileLoaded({this.user, this.cloudinaryUrl});
  final ProfileModel? user;
  final String? cloudinaryUrl;

  ProfileLoaded copyWith({
    ProfileModel? user,
    String? cloudinaryUrl,
  }) {
    return ProfileLoaded(
      user: user ?? this.user,
      cloudinaryUrl: cloudinaryUrl ?? this.cloudinaryUrl,
    );
  }
}

class ProfileError extends ProfileState {
  ProfileError(this.message);
  final String message;
}

class UploadingImage extends ProfileState {}

class ImageUploaded extends ProfileState {
  ImageUploaded({this.isUploaded = false, this.user});
  final bool isUploaded;
  final ProfileModel? user;
}

class ImageUploadError extends ProfileState {
  ImageUploadError(this.message);
  final String message;
}

class UpdatingNumber extends ProfileState {

  UpdatingNumber({required this.phoneNumber});
  final String phoneNumber;
}

class NumberUpdated extends ProfileState {

  NumberUpdated({
    this.isUpdated = false,
    this.message = '',
    required this.phoneNumber,
  });
  final bool isUpdated;
  final String message;
  final String phoneNumber;
}

class NumberUpdateError extends ProfileState {

  NumberUpdateError(this.message);
  final String message;
}

class UpdatingEmail extends ProfileState {}

class EmailUpdated extends ProfileState {

  EmailUpdated({
    this.isUpdated = false,
    this.message = '',
  });
  final bool isUpdated;
  final String message;
}

class EmailUpdateError extends ProfileState {

  EmailUpdateError(this.message);
  final String message;
}

class VerifyingOtp extends ProfileState {

  VerifyingOtp({required this.phoneNumber});
  final String phoneNumber;
}

class OtpVerified extends ProfileState {

  OtpVerified({
    required this.isVerified,
    required this.phoneNumber,
  });
  final bool isVerified;
  final String phoneNumber;
}

class OtpVerificationError extends ProfileState {

  OtpVerificationError(this.message, {required this.phoneNumber});
  final String message;
  final String phoneNumber;
}