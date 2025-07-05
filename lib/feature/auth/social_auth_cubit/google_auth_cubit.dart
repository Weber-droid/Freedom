import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:freedom/feature/auth/local_data_source/local_user.dart';
import 'package:freedom/feature/auth/local_data_source/register_local_data_source.dart';
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
          emit(
            state.copyWith(
              formStatus: FormStatus.failure,
              message: failure.message,
            ),
          );
        },
        (success) async {
          await RegisterLocalDataSource().saveUser(
            User(
              firstName: success?.data?.firstName,
              surname: success?.data?.surname,
              email: success?.data?.email,
              phone: '',
              id: success?.data?.id,
              userId: success?.data?.id,
              role: success?.data?.role,
              isPhoneVerified: success?.data?.isPhoneVerified,
              isEmailVerified: success?.data?.isEmailVerified,
              authProvider: success?.data?.authProvider,
              socialId: success?.data?.socialId,
              socialProfile: success?.data?.socialProfile,
              rideHistory: success?.data?.rideHistory,
              paymentMethod: success?.data?.paymentMethod,
              paystackCustomerId: success?.data?.paystackCustomerId,
              mobileMoneyProvider: success?.data?.mobileMoneyProvider,
              preferredLanguage: success?.data?.preferredLanguage,
              cardTokens: success?.data?.cardTokens,
              knownDevices: success?.data?.knownDevices,
              createdAt: success?.data?.createdAt,
              updatedAt: success?.data?.updatedAt,
            ),
          );
          emit(
            state.copyWith(
              formStatus: FormStatus.success,
              firstName: success?.data?.firstName,
              phone: '',
              message: success?.message,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(formStatus: FormStatus.failure, message: e.toString()),
      );
    }
  }
}
