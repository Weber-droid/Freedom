import 'package:bloc/bloc.dart';
import 'package:freedom/feature/History/enums.dart';
import 'package:freedom/feature/History/model/history_model.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(const HistoryState());

  void setActiveTab(RideTabEnum tab) {
    emit(state.copyWith(rideTabEnum: tab));
  }
}
