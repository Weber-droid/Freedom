import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freedom/feature/auth/repository/register_repository.dart';
import 'package:freedom/shared/enums/enums.dart';

part 'google_auth_state.dart';

class GoogleAuthCubit extends Cubit<GoogleAuthState> {
  GoogleAuthCubit(this.registerRepository) : super(const GoogleAuthState());

  final RegisterRepository registerRepository;
  Future<void> registerOrLoginWithGoogle() async {
    emit(state.copyWith(formStatus: FormStatus.submitting));
    try {
      final response = await registerRepository.registerOrLoginWithGoogle();

      await response.fold(
            (failure) {
          emit(state.copyWith(
            formStatus: FormStatus.failure,
            message: failure.message,
          ));
        },
            (success) async {
          emit(state.copyWith(
            formStatus: FormStatus.success,
            firstName: success?.data?.firstName,
            phone: '',
            message: success?.message,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        formStatus: FormStatus.failure,
        message: e.toString(),
      ));
    }
  }
}