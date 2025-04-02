import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:freedom/di/locator.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
import 'package:freedom/feature/profile/model/profile_model.dart';
import 'package:freedom/feature/profile/repository/profile_repository.dart';
import 'package:image_picker/image_picker.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository(),
        super(ProfileInitial());

  final ProfileRepository _profileRepository;

  Future<void> getUserProfile() async {
    emit(ProfileLoading());
    try {
      final response = await _profileRepository.fetchUserProfile();
      response.fold(
              (l) => emit(ProfileError(l.message)),
              (profile) async {
            try {
              final currentUser = await RegisterLocalDataSource().getUser();
              if (currentUser != null) {
                final updatedUser = currentUser.copyWith(
                  userImage: profile.data.profilePicture,
                );
                await RegisterLocalDataSource().saveUser(updatedUser);
                if (getIt.isRegistered<User>()) {
                  getIt.unregister<User>();
                }
                getIt.registerSingleton<User>(updatedUser);
              }
              emit(ProfileLoaded(user: profile));
            } catch (e) {
              emit(ProfileError('Error updating local user data: $e'));
            }
          }
      );
    } catch (e) {
      emit(ProfileError('Failed to get user profile: ${e.toString()}'));
    }
  }

  Future<void> pickImage({ImageSource source = ImageSource.camera}) async {
    try {
      emit(UploadingImage());
      final imagePicker = ImagePicker();

      final pickedFile = await imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        // Remove redundant null check - file cannot be null here
        if (file.path.isNotEmpty) {
          final fileSize = file.lengthSync();
          final megabytes = fileSize / (1024 * 1024);
          if (megabytes > 5) {
            emit(ProfileError('Image size should be less than 5MB'));
            return;
          } else {
            emit(ProfileLoading());
            final response = await _profileRepository.updateProfile(file);
            response.fold(
                    (l) => emit(ProfileError(l.message)),
                    (profile) => emit(ImageUploaded())
            );
          }
        }
      } else {
        // User canceled - revert to previous state instead of initial
        final currentState = state;
        if (currentState is ProfileLoaded) {
          emit(ProfileLoaded(user: currentState.user));
        } else {
          emit(ProfileInitial());
        }
      }
    } catch (e) {
      emit(ProfileError('Error picking image: $e'));
    }
  }
}