import 'package:bloc/bloc.dart';
import 'package:freedom/feature/profile/model/profile_model.dart';
import 'package:freedom/feature/profile/repository/profile_repository.dart';
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
      response.fold((l) => emit(ProfileError(l.message)),
          (user) => emit(ProfileLoaded(user)));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
