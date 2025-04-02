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