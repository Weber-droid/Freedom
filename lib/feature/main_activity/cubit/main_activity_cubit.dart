import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'main_activity_state.dart';

class MainActivityCubit extends Cubit<MainActivityState> {
  MainActivityCubit() : super(const MainActivityState());

  void changeIndex(int index) {
    emit(state.copyWith(currentIndex: index));
  }
}
