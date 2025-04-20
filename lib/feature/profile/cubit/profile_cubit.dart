import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
  // Add a class variable to store the phone number
  String _phoneNumber = '';

  // Getter for the phone number
  String get phoneNumber => _phoneNumber;

  Future<void> getUserProfile() async {
    emit(ProfileLoading());
    try {
      final response = await _profileRepository.fetchUserProfile();
      await response.fold((l) {
        emit(ProfileError(l.message));
      }, (profile) async {
        log('right profile ${profile.data.toJson()}');
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
          emit(
            ProfileLoaded(
              user: profile,
              originalEmail: profile.data.email,
              originalPhone: profile.data.phone,
              countryCode: extractCountryCode(profile.data.phone),
            ),
          );
        } catch (e) {
          emit(ProfileError('Error updating local user data: $e'));
        }
      });
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
        if (file.path.isNotEmpty) {
          final fileSize = file.lengthSync();
          final megabytes = fileSize / (1024 * 1024);
          if (megabytes > 5) {
            emit(const ProfileError('Image size should be less than 5MB'));
            return;
          } else {
            emit(ProfileLoading());
            final response = await _profileRepository.updateProfile(file);
            response.fold((l) => emit(ProfileError(l.message)),
                (profile) => emit(const ImageUploaded()));
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

  // Updated to persist phone number
  void setPhoneNumber(String phoneNumber) {
    // Store the phone number in the class variable
    _phoneNumber = phoneNumber;
    // Emit state with the phone number
    emit(UpdatingNumber(phoneNumber: phoneNumber));
  }

  Future<void> requestNumberUpdate(String number) async {
    try {
      if (state is ProfileLoaded) {
        _phoneNumber = number;
        emit(UpdatingNumber(phoneNumber: number));

        final response = await _profileRepository.requestNumberUpdate(number);
        response.fold(
          (l) => emit(NumberUpdateError(l.message)),
          (profile) => emit(
            NumberUpdated(
              isUpdated: profile.success ?? false,
              phoneNumber: number,
              message: profile.message!,
            ),
          ),
        );
      }
    } catch (e) {
      emit(NumberUpdateError('Error updating phone number: $e'));
    }
  }

  Future<void> requestEmailUpdate(String email) async {
    if (state is ProfileLoaded) {
      try {
        emit(UpdatingEmail());
        final response = await _profileRepository.requestEmailUpdate(email);
        response.fold(
          (l) => emit(EmailUpdateError(l.message)),
          (profile) => emit(
            EmailUpdated(
                isUpdated: profile.success ?? false, message: profile.message!),
          ),
        );
      } catch (e) {
        emit(EmailUpdateError('Error updating email: $e'));
      }
    }
  }

  Future<void> verifyPhoneNumberUpdate(String otp) async {
    if (state is ProfileLoaded) {
      try {
        emit(VerifyingOtp(phoneNumber: _phoneNumber));

        final response = await _profileRepository.verifyPhoneUpDate(otp);
        response.fold(
          (l) =>
              emit(OtpVerificationError(l.message, phoneNumber: _phoneNumber)),
          (profile) => emit(
            OtpVerified(
                isVerified: profile.success ?? false,
                phoneNumber: _phoneNumber),
          ),
        );
      } catch (e) {
        emit(
          OtpVerificationError('Error verifying OTP: $e',
              phoneNumber: _phoneNumber),
        );
      }
    }
  }

  Future<void> updateUserNames(String firstName, String surname) async {
    if (state is ProfileLoaded) {
      try {
        emit(UpdateUserNamesInProgress());
        final response =
            await _profileRepository.updateUserNames(firstName, surname);
        response.fold(
          (l) => emit(UserNamesUpdateError(l.message)),
          (profile) => emit(
            UserNamesUpdated(
              isUpdated: profile.success!,
              message: profile.message!,
            ),
          ),
        );
      } catch (e) {
        emit(UserNamesUpdateError('Error updating user names: $e'));
      }
    }
  }

  String extractCountryCode(String phone) {
    if (phone.startsWith('+')) {
      final countryCodeMatch = RegExp(r'^\+\d+').firstMatch(phone);
      if (countryCodeMatch != null) {
        return countryCodeMatch.group(0) ?? '+233';
      }
    }
    return '+233';
  }

  void startEditingField(String field) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(activeField: field));
    }
  }

  void cancelEdit() {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(activeField: null));
    }
  }

  void updateCountryCode(String newCode) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      // When country code is changed, also set active field to phone
      emit(currentState.copyWith(
          countryCode: newCode,
          activeField: 'phone'
      ));
      log('Updated country code to: $newCode');
    }
  }
}
